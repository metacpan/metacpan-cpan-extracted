#!/usr/bin/env perl 

package Neovim::RPC::App;
our $AUTHORITY = 'cpan:YANICK';
$Neovim::RPC::App::VERSION = '1.0.0';
use Log::Any::Adapter;
Log::Any::Adapter->set( 
    #{ category => 'MsgPack::Decoder' }, 
    'Stderr', log_level => 'debug' );

use 5.10.0;

use strict;
use warnings;
$| = 0;

use MooseX::App::Simple;

use Getopt::Long;
use Neovim::RPC;

use Log::Any '$Log';

option std => (
    is => 'ro',
    documentation => 'use stdin/stdout',
    isa => 'Bool',
);

option include => (
    cmd_aliases => [ 'I' ],
    is => 'ro',
    documentation => 'custom library path',
    trigger => sub {
        push @INC, split ',', $_[1];
    },
);

parameter io => (
    documentation => 'socket/address to use, defaults to NVIM_LISTEN_ADDRESS',
    is => 'ro',
    lazy => 1,
    default => sub { 
        return [*STDIN, *STDOUT] if $_[0]->std;

        $ENV{NVIM_LISTEN_ADDRESS}
            or die "io not provided and NVIM_LISTEN_ADDRESS not set\n"
    },
);

has rpc => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $rpc = Neovim::RPC->new(
              io            => $_[0]->io,
        );

   $rpc->subscribe( 'write', sub { $Log->debugf( 'write %s', $_[0]->message ) } );
    $rpc->subscribe( 'receive', sub { $Log->debugf( "receive %s", $_[0]->message ) } );
        $rpc->api->ready->done( sub {
            $rpc->load_plugin( 'LoadPlugin' );
        });

        return $rpc;
    },
);


sub run {
    my $self = shift;

    $self->rpc->loop->run;
}

1;


Neovim::RPC::App->new_with_options->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::App

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
