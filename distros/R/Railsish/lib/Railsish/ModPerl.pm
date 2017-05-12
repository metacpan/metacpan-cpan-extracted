package Railsish::ModPerl;
our $VERSION = '0.21';

use Moose;
extends 'HTTP::Engine::Interface::ModPerl';

use Railsish::Bootstrap;
Railsish::Bootstrap->load_controllers;
Railsish::Bootstrap->load_configs;

use Railsish::Dispatcher;
use HTTP::Engine;

sub create_engine {
    my($class, $r, $context_key) = @_;

    HTTP::Engine->new(
        interface => {
            module => "ModPerl",
            request_handler => sub {
                my ($request) = @_;
                warn $request->method . " " . $request->path . "\n";
                Railsish::Dispatcher->dispatch(@_);
            }
        }
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=head1 NAME

Railsish::ModPerl

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

