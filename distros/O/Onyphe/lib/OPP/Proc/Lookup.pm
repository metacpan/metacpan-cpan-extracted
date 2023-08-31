#
# $Id: Lookup.pm,v 69a3d7308875 2023/04/05 15:11:02 gomor $
#
package OPP::Proc::Lookup;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use File::Slurp qw(read_file);
use Text::CSV_XS;
use Net::IPv4Addr qw(ipv4_in_network);

# Load CSV data here, one time
my $csv;
my $match_fields;  # Prepare for supporting matching with AND filters
my $lookup_field;  # Support only last column as a match

sub _load {
   my $self = shift;
   my ($file) = @_;

   # Load CSV lookup:
   unless (defined($csv)) {
      my $csvxs = Text::CSV_XS->new({
         binary => 1,
         sep_char => ',',
         allow_loose_quotes => 1,
         allow_loose_escapes => 1,
         escape_char => '"',
      }) or die("lookup: cannot initiate Text::CSV_XS\n");
      #my @lines = read_file($file) or die("lookup: cannot read or empty file: $file\n");
      open(my $fd, '<', $file) or die("lookup: cannot open file: $file\n");

      # First line is considered the header
      my $header = $csvxs->getline($fd) or die("lookup: cannot get header\n");
      die("lookup: no line found\n") unless defined $header;
      #print STDERR Data::Dumper::Dumper($header)."\n";
      my $lookup = pop @$header;  # Last field is the data to add
      $lookup_field = $lookup;
      $match_fields = [ sort { $a cmp $b } @$header ];
      $header = join('+', sort { $a cmp $b } @$header);

      while (my $line = $csvxs->getline($fd)) {
         my $last = pop @$line;  # Last field is the data to add
         my $key = join('+', sort { $a cmp $b } @$line);
         $csv->{$header}{$key} = { $lookup_field => $last };
      }

      #print STDERR Data::Dumper::Dumper($csv)."\n";
   }

   return [ $csv, $match_fields, $lookup_field ];
}

#
# echo domain,mytags > lookup.csv
# echo amazonaws.com,aws >> lookup.csv
#
# | lookup lookup.csv
#
# echo ip,mytags
# echo 8.8.8.0/24,google
#
# | lookup lookup.csv cidr=ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $file = $options->{0};
   die("lookup: file not given\n") unless defined $file;
   die("lookup: file not found: $file\n") unless -f $file;

   my $cidr = $options->{cidr} || 'ip';  # Use ip field by default for cidr matches

   $self->_load($file);

   # Touch nothing when matching fields are not found in input:
   for my $field (@$match_fields) {
      my $values = $self->value($input, $field);
      unless (defined($values)) {  # Field not found here
         $self->output->add($input);
         return 1;
      }
   }

   # All fields to match against were found in input, we can search a match:
   for my $field (@$match_fields) {
      my $values = $self->value($input, $field) or next;
      if ($field eq $cidr) {  # CIDR match mode
         for my $v (@$values) {
            for my $this (keys %{$csv->{$cidr}}) {
               if (ipv4_in_network($this, $v)) {
                  for my $k (keys %{$csv->{$field}{$this}}) {
                     $self->set($input, $k, $csv->{$field}{$this}{$k});
                  }
               }
            }
         }
      }
      else {  # Exact match mode
         for my $v (@$values) {
            if (defined($csv->{$field}) && defined($csv->{$field}{$v})) {
               for my $k (keys %{$csv->{$field}{$v}}) {
                  $self->set($input, $k, $csv->{$field}{$v}{$k});
               }
            }
         }
      }
   }

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Lookup - lookup processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
