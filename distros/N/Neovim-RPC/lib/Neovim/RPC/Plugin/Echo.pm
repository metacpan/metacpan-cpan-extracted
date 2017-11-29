package Neovim::RPC::Plugin::Echo;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: echo back message to nvim
$Neovim::RPC::Plugin::Echo::VERSION = '1.0.1';
use 5.20.0;

use strict;
use warnings;

use Neovim::RPC::Plugin;

use experimental qw/ signatures /;

subscribe echo => sub($self,$event) {
    my $message = $event->params->[0];
    $self->api->vim_command( qq{echo "$message"} );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin::Echo - echo back message to nvim

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
