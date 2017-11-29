package Neovim::RPC::API::AutoDiscover;
our $AUTHORITY = 'cpan:YANICK';
$Neovim::RPC::API::AutoDiscover::VERSION = '1.0.1';
use strict;
use warnings;

use Moose;
with 'Neovim::RPC::API';

use Promises qw/ deferred /;

use experimental 'postderef';

sub BUILD {
    my $self = shift;
    
    $self->add_command({ name => 'vim_get_api_info' });

    $self->vim_get_api_info->then(sub {
        my( $response ) = @_;

        $self->channel_id( $response->[0] );

        my @funcs = $response->[1]{'functions'}->@*;

        for my $f ( @funcs ) {
            next if $self->has_command( $f->{name} );
            $self->log->debugf( "adding function %s", $f->{name} );
            $self->add_command( $f );
        }

        while ( my ( $type, $val ) = each $response->[1]{'types'}->%* ) {
            $self->types->{$type} = $val->{id};
        }
    })
    ->then(sub{
        $self->vim_set_var( name => 'nvimx_channel', value => $self->channel_id );
    })
    ->then(sub{ $self->ready->resolve($self) });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::API::AutoDiscover

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
