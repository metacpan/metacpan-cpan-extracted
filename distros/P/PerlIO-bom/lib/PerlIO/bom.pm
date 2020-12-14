package PerlIO::bom;
$PerlIO::bom::VERSION = '0.001';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: Automatic BOM handling in Unicode IO

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlIO::bom - Automatic BOM handling in Unicode IO

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 open my $fh, '<:bom(utf-8)', $filename;

=head1 DESCRIPTION

This module will automate BOM handling. On a reading handle, it will try to detect a BOM and push an appropriate decoding layer for that encoding. If no BOM is detected the specified encoding is used, or UTF-8 if none is given.

A writing handle will be opened with the specified encoding, and a BOM will be written to it.

=head1 SYNTAX

This modules does not have to be loaded explicitly, it will be loaded automatically by using it in an open mode. The module has the following general syntax: C<:bom(encoding)> or C<:bom>. The encoding may be anything C<:encoding> accepts.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
