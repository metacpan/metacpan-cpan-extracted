package PerlIO::buffersize;
{
  $PerlIO::buffersize::VERSION = '0.001';
}
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: Set the buffersize of a handle



=pod

=head1 NAME

PerlIO::buffersize - Set the buffersize of a handle

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 open my $fh, '<:buffersize(65536)', $filename;

=head1 DESCRIPTION

This module sets the buffer-size of a filehandle to an other value than the default. This can only be done before the handle is used, as once the buffer has been allocated it can not be changed.

=head1 SYNTAX

This modules does not have to be loaded explicitly, it will be loaded automatically by using it in an open mode.  The module has the following general syntax: C<:buffersize(size)>. The size can be any positive integer.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

