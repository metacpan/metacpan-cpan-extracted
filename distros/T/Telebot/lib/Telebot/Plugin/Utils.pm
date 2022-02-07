package Telebot::Plugin::Utils;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Carp 'croak';
use Mojo::Util qw(dumper);

has ['app'];

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);

    # $app->dump($var1, $var2, ...)
    $app->helper(dump => sub {
      my $c = shift;
      $app->log->info(dumper([@_]));
    });
    $self;
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Plugin::Utils - Useful helpers

=head1 SYNOPSIS

    # Records dump into log.
    $app->dump('Foo', {bar => 'foo'}, ['foo', 'bar']);
    
=head1 DESCRIPTION

L<Telebot::Plugin::Utils> - plugin with some useful helpers.

=head1 HELPERS

L<Telebot::Plugin::Utils> implements the following helpers.

=head2 dump

Dumps into log arguments with Data::Dumper.

=head1 METHODS

L<Telebot::Plugin::Utils> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register
    
    my $tg = $plugin->register(Mojolicious->new);

Register plugin in Mojolicious application and define helpers.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api>.

=cut
