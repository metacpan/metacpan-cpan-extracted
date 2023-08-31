#
# $Id: Blocklist.pm,v a6091d726551 2023/04/05 15:44:32 gomor $
#
package OPP::Proc::Blocklist;
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
my $match_fields;  # Support all fields as a match (AND match)

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
      }) or die("blocklist: cannot initiate Text::CSV_XS\n");
      #my @lines = read_file($file) or die("blocklist: cannot read or empty file: $file\n");
      open(my $fd, '<', $file) or die("blocklist: cannot open file: $file\n");

      # First line is considered the header
      my $header = $csvxs->getline($fd) or die("blocklist: cannot get header\n");
      die("blocklist: no line found\n") unless defined $header;
      #print STDERR Data::Dumper::Dumper($header)."\n";
      $match_fields = $header;  # All fields can be used in a match (AND match)

      while (my $line = $csvxs->getline($fd)) {
         my $h = {};
         my $idx = 0;
         for my $this (@$header) {
            $h->{$this} = $line->[$idx++];
         }
         push @$csv, $h if keys %$h;
      }

      #print STDERR Data::Dumper::Dumper($csv)."\n";
   }

   return [ $csv, $match_fields ];
}

#
# echo domain > blocklist.csv
# echo amazonaws.com >> blocklist.csv
#
# | blocklist blocklist.csv
# | blocklist blocklist.csv cidr=ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $file = $options->{0};
   die("blocklist: file not given\n") unless defined $file;
   die("blocklist: file not found: $file\n") unless -f $file;

   my $cidr = $options->{cidr} || 'ip';  # Use ip field by default for cidr matches

   my $loaded = $self->_load($file);
   $csv = $loaded->[0];
   $match_fields = $loaded->[1];

   # Touch nothing when matching fields are not found in input:
   for my $field (@$match_fields) {
      my $values = $self->value($input, $field);
      unless (defined($values)) {  # Field not found here
         $self->output->add($input);  # We keep result
         return 1;
      }
   }

   # All fields to match against were found in input, we can search a match:
   my $skip = 0;
   my $total = @$match_fields;
   for my $line (@$csv) {
      for my $field (@$match_fields) {
         my $this_skip = 0;
         my $values = $self->value($input, $field) or next;
         if ($field eq $cidr) {  # CIDR match mode
            for my $v (@$values) {
               #print STDERR "*** match field [$field] vs v[$v]\n";
               if (defined($line->{$field}) && ipv4_in_network($line->{$field}, $v)) {
                  $this_skip++;
               }
            }
         }
         else {  # Exact field match mode
            for my $v (@$values) {
               #print STDERR "*** match field [$field] vs v[$v]\n";
               if (defined($line->{$field}) && $v eq $line->{$field}) {
                  $this_skip++;
                  last;
               }
            }
         }
         $skip++ if $this_skip;
      }
   }

   #print STDERR "*** skip[$skip] total[$total]\n";

   if ($skip != $total) {  # Not all fields have matched, it is NOT blocklisted
      $self->output->add($input);
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Blocklist - blocklist processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
