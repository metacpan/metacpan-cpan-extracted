package PerlIO::eol;

use 5.007003;

use strict;
use warnings;

use XSLoader;
use Exporter;

our $VERSION = '0.17';
our @ISA = qw(Exporter);

# symbols to export on request
our @EXPORT_OK = qw(eol_is_mixed CR LF CRLF NATIVE);

XSLoader::load __PACKAGE__, $VERSION;

1;

=head1 NAME

PerlIO::eol - PerlIO layer for normalizing line endings

=head1 VERSION

This document describes version 0.15 of PerlIO::eol, released
December 18, 2006.

=head1 SYNOPSIS

    binmode STDIN, ":raw:eol(LF)";
    binmode STDOUT, ":raw:eol(CRLF)";
    open FH, "+<:raw:eol(LF-Native)", "file";

    binmode STDOUT, ":raw:eol(CRLF?)"; # warns on mixed newlines
    binmode STDOUT, ":raw:eol(CRLF!)"; # dies on mixed newlines

    use PerlIO::eol qw( eol_is_mixed );
    my $pos = eol_is_mixed( "mixed\nstring\r" );

=head1 DESCRIPTION

This layer normalizes any of C<CR>, C<LF>, C<CRLF> and C<Native> into the
designated line ending.  It works for both input and output handles.

If you specify two different line endings joined by a C<->, it will use the
first one for reading and the second one for writing.  For example, the
C<LF-CRLF> encoding means that all input should be normalized to C<LF>, and
all output should be normalized to C<CRLF>.

By default, data with mixed newlines are normalized silently.  Append a C<!>
to the line ending will raise a fatal exception when mixed newlines are
spotted.  Append a C<?> will raise a warning instead.

It is advised to pop any potential C<:crlf> or encoding layers before this
layer; this is usually done using a C<:raw> prefix.

This module also optionally exports a C<eol_is_mixed> function; it takes a
string and returns the position of the first inconsistent line ending found
in that string, or C<0> if the line endings are consistent.

The C<CR>, C<LF>, C<CRLF> and C<NATIVE> constants are also exported at request.

=head1 EXPORTS

=head2 CR

A carriage return constant.

=head2 CRLF

A carriage return/line feed constant.

=head2 LF

A line feed constant.

=head2 NATIVE

The native line ending.

=head2 eol_is_mixed

This module also optionally exports a C<eol_is_mixed> function; it takes a
string and returns the position of the first inconsistent line ending found
in that string, or C<0> if the line endings are consistent.

=head1 AUTHORS

Audrey Tang E<lt>autrijus@autrijus.orgE<gt>.

Janitorial help by Gaal Yahas E<lt>gaal@forum2.orgE<gt>.

Inspired by L<PerlIO::nline> by Ben Morrow, E<lt>PerlIO-eol@morrow.me.ukE<gt>.

=head1 COPYRIGHT

Copyright 2004-2006 by Audrey Tang E<lt>audreyt@audreyt.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
