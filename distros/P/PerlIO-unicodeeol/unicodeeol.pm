package PerlIO::unicodeeol;

use 5.007003;
use XSLoader;
use Exporter;

our $VERSION = "1.002";
$VERSION = eval $VERSION;
our @ISA = qw(Exporter);

# symbols to export on request
our @EXPORT_OK = ();

XSLoader::load __PACKAGE__, $VERSION;

1;

=head1 NAME

PerlIO::unicodeeol - PerlIO layer for normalizing line endings from \R to \n

=head1 VERSION

This document describes version 1.0 of PerlIO::unicodeeol

=head1 SYNOPSIS

    binmode STDIN, ":raw:unicodeeol";
    open FH, "+<:raw:unicodeeol", "file";

=head1 DESCRIPTION

This layer normalizes any of the code points matched by \R into \n.

=head1 AUTHORS

Peter Martini E<lt>pcm@cpan.orgE<gt>.

Inspired by L<PerlIO::eol> by Audrey Tang

=head1 COPYRIGHT

Copyright 2013 by Peter Martini E<lt>pcm@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
