package Neovim::RPC::Plugin;
our $AUTHORITY = 'cpan:YANICK';
$Neovim::RPC::Plugin::VERSION = '0.2.0';
use strict;
use warnings;

use Moose::Role;

has "rpc" => (
    is => 'ro',
    required => 1,
    handles => [ 'api', 'subscribe' ],
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
