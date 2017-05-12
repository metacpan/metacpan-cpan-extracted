package Neovim::RPC::Plugin::LoadPlugin;
our $AUTHORITY = 'cpan:YANICK';
$Neovim::RPC::Plugin::LoadPlugin::VERSION = '0.2.0';
use 5.20.0;

use strict;
use warnings;

use Moose;
with 'Neovim::RPC::Plugin';

use Try::Tiny;

use experimental 'signatures';

sub BUILD($self,@) {

    $self->subscribe('load_plugin',sub ($msg) { 
        # TODO also deal with it as a request?
        my $plugin = $msg->args->[0];
        try {
            $self->rpc->load_plugin( $plugin );           
        }
        catch {
            $self->api->vim_report_error( str => "failed to load $plugin" );
        }
    });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin::LoadPlugin

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
