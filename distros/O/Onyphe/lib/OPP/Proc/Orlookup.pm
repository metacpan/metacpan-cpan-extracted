#
# $Id: Orlookup.pm,v 1a6ad59d015b 2024/02/16 09:27:25 gomor $
#
package OPP::Proc::Orlookup;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use File::Slurp qw(read_file);
use Text::CSV_XS;
use Net::IPv4Addr qw(ipv4_in_network);
use Data::Dumper;

sub _load {
   my $self = shift;
   my ($file) = @_;

   my $csv = $self->state->value('csv', $self->idx);
   my $match_fields = $self->state->value('match_fields', $self->idx);
   my $lookup_field = $self->state->value('lookup_field', $self->idx);

   # Load CSV lookup:
   unless (defined($csv)) {
      my $csvxs = Text::CSV_XS->new({
         binary => 1,
         sep_char => ',',
         allow_loose_quotes => 1,
         allow_loose_escapes => 1,
         escape_char => '"',
      }) or die("orlookup: cannot initiate Text::CSV_XS\n");
      #my @lines = read_file($file) or die("orlookup: cannot read or empty file: $file\n");
      open(my $fd, '<', $file) or die("orlookup: cannot open file: $file\n");

      # First line is considered the header
      my $header = $csvxs->getline($fd) or die("orlookup: cannot get header\n");
      die("orlookup: no line found\n") unless defined $header;
      #print STDERR Data::Dumper::Dumper($header)."\n";
      my $lookup = pop @$header;  # Last field is the data to add
      $lookup_field = $lookup;
      $match_fields = [ @$header ];

      while (my $line = $csvxs->getline($fd)) {
         my $last = pop @$line;  # Last field is the data to add
         #print STDERR "CSVline: ".Data::Dumper::Dumper($line)."\n";
         my $c = @$line - 1;
         #print STDERR "count: $c\n";
         for my $idx (0..$c) {
            next unless (defined($line->[$idx]) && length($line->[$idx]));
            push @$csv, { lc($match_fields->[$idx]) => lc($line->[$idx]), $lookup_field => $last };
         }
      }

      $self->state->add('csv', $csv, $self->idx);
      $self->state->add('match_fields', $match_fields, $self->idx);
      $self->state->add('lookup_field', $lookup_field, $self->idx);
      #print STDERR "match_fields[".Data::Dumper::Dumper($match_fields)."]\n";
      #print STDERR "lookup_field[$lookup_field]\n";
   }

   #print STDERR Data::Dumper::Dumper($csv)."\n";

   return [ $csv, $match_fields, $lookup_field ];
}

#
# echo domain,tag,mytags > lookup.csv
# echo amazonaws.com,cloud,aws >> lookup.csv
#
# | orlookup lookup.csv
#
# echo ip,mytags
# echo 8.8.8.0/24,google
#
# | orlookup lookup.csv cidr=ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $file = $options->{0};
   die("orlookup: file not given\n") unless defined $file;
   die("orlookup: file not found: $file\n") unless -f $file;

   my $cidr = $options->{cidr} || 'ip';  # Use ip field by default for cidr matches

   my $r = $self->_load($file);
   my $csv = $r->[0];
   my $match_fields = $r->[1];
   my $lookup_field = $r->[2];

   #print STDERR "match_fields[".Data::Dumper::Dumper($match_fields)."]\n";
   #print STDERR "lookup_field[$lookup_field]\n";

   # Touch nothing when matching fields are not found in input:
   my $some = 0;
   for my $field (@$match_fields) {
      my $values = $self->value($input, $field);
      if (defined($values)) {  # Field found here
         $some++;
         last;
      }
   }
   unless ($some) {
      $self->output->add($input);
      return 1;
   }

   # Some fields to match against were found in input, we can search a match:
   for my $field (@$match_fields) {
      #print STDERR "field1[$field]\n";
      my $values = $self->value($input, $field) or next;
      if ($field eq $cidr) {  # CIDR match mode
         for my $v (@$values) {
            #print STDERR "field2[$field] v[$v]\n";
            for my $h (@$csv) {
               next unless $h->{$cidr};
               #print STDERR "h:". Data::Dumper::Dumper($h)."\n";
               if (defined($input->{$field}) && defined($h->{$field})) {
                  #print STDERR "input:". $v."\n";
                  #print STDERR "vs:".$h->{$field}."\n";
                  if (ipv4_in_network($h->{$field}, $v)) {
                     #print STDERR "Match\n";
                     $self->set($input, $lookup_field, $h->{$lookup_field}, 1); # As ARRAY
                  }
               }
            }
         }
      }
      else {  # Exact match mode
         for my $v (@$values) {
            #print STDERR "field2[$field] v[$v]\n";
            for my $h (@$csv) {
               #print STDERR "h:". Data::Dumper::Dumper($h)."\n";
               if (defined($h->{$field}) && lc($h->{$field}) eq lc($v)) {
                  #print STDERR "match: field[$field] v[$v] lookup_field[$lookup_field]\n";
                  $self->set($input, $lookup_field, $h->{$lookup_field}, 1) # As ARRAY
                     if (defined($h->{$lookup_field}) && length($h->{$lookup_field}));
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

OPP::Proc::Orlookup - orlookup processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
