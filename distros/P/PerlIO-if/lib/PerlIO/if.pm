#
# This file is part of PerlIO-if
#
# This software is copyright (c) 2011 by Leon Timmermans.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package PerlIO::if;
BEGIN {
  $PerlIO::if::VERSION = '0.003';
}
use 5.008;
use strict;
use warnings;

use XSLoader;

our $VERSION;
XSLoader::load(__PACKAGE__, $VERSION);

1;

#ABSTRACT: Push layers conditionally


__END__
=pod

=head1 NAME

PerlIO::if - Push layers conditionally

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 open my $fh, '<:if(!crlf,crlf)', $filename;

=head1 DESCRIPTION

This module provides a conditional PerlIO layer.

=head1 SYNTAX

This modules does not have to be loaded explicitly, it will be loaded automatically by using it in an open mode

The argument must have the following general syntax:

 :if(condition,layer)

C<layer> may be any layer installed on the system.

C<condition> may be any test from the following list:

=over 4

=item * buffered

True if there is a buffered layer in the IO stack.

=item * crlf

True if there is a layer doing crlf translation

=item * can_crlf

True if there is a layer that is capable of doing crlf translation

=back

=head1 TODO

=over 4

=item * Add more conditions

=item * Add and ifelse pseudo-layer

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

