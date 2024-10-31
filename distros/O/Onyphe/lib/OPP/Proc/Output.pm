#
# $Id: Output.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Output;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use utf8;

#
# NOTE: default output format is txt
#
# | output
# | output format=txt
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $format = $options->{format} || 'txt';

   if ($format ne 'txt') {
      die("output: invalid format given: $format, only accepts 'format=txt'\n");
   }

   my $print = '';
   for my $field (sort { $a cmp $b } @{$self->fields($input)}) {
      next if $field =~ m{^_};
      my $value = $self->value($input, $field);
      for my $v (@$value) {
         $v =~ s{"}{\\"}g;
         $print .= "$field:\"$v\" ";
      }
   }

   return 1 unless length $print;

   $print =~ s{\s*$}{};
   utf8::encode($print);
   print "$print\n";

   # We don't add to output so nothing will be displayed after this proc:
   #$self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Output - output processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
