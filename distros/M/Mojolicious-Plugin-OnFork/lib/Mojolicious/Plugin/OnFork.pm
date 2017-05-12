package Mojolicious::Plugin::OnFork;

use Mojo::Base 'Mojolicious::Plugin';

use Carp 'croak';
use Mojo::IOLoop;

our $VERSION = '0.006';

sub register {
    my $code = $_[2];

    croak 'Plugin "OnFork" needs a sub { } to execute.'
	unless ref $code eq 'CODE';

    Mojo::IOLoop->timer(0 => $code);
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::OnFork - Do Something Whenever a Worker Starts

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('OnFork' => sub { srand })
    if $ENV{HYPNOTOAD_APP};

  # Mojolicious::Lite
  plugin OnFork => sub { srand }
    if $ENV{HYPNOTOAD_APP};

=head1 DESCRIPTION

L<Mojolicious::Plugin::OnFork> is a plugin to easily define code, that
is executed whenever a new worker process of the web server forks.

All this plugin actually does is

  Mojo::IOLoop->timer(0 => $code)

The motivation for this plugin was, that L<hypnotoad> does not guarantee
to call L<perlfunc/srand> after a L<perlfunc/fork>, so worker processes
might all get the same sequence of "random" numbers from L<perlfunc/rand>.

Starting with L<Mojolicious> 5.76 C<srand> is actually called after a fork,
but this fact is not officially documented and according to the author can
be removed in the future without any previous notice.

As a consequence depending on the Mojolicious version and for this use
case C<srand> might be called twice after a worker starts.

=head1 METHODS

L<Mojolicious::Plugin::OnFork> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

Register plugin hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>,
L<https://github.com/kraih/mojo/issues/402>.

=head1 AUTHOR

Bernhard Graf <graf(a)cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 - 2017 Bernhard Graf

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
