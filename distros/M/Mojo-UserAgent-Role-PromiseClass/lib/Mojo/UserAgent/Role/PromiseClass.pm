package Mojo::UserAgent::Role::PromiseClass 0.008;

# ABSTRACT: Choose the promise class used by Mojo::UserAgent

use Mojo::Base -role;

with 'Mojo::Base::Role::PromiseClass';

around start_p => sub {
    my ($start_p, $ua) = (shift, shift);
    bless $ua->$start_p(@_), $ua->promise_class;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::UserAgent::Role::PromiseClass - Choose the promise class used by Mojo::UserAgent

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  $ua = Mojo::UserAgent->new(...)->with_roles('+PromiseClass');

  # add promise features you want
  $ua->promise_roles('+Repeat');

  # and they show up on every request promise
  $ua->get_p('http://example.com')->repeat(sub{...});

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::PromiseClass> is a role that allows specifying the promise class to be used for the promise-returning methods like L<UserAgent/get_p> and L<UserAgent/post_p>, if you want something different from L<Mojo::Promise>.

Note that since most methods on L<Mojo::Promise> will use L<clone|Mojo::Promise/clone> to create new instances, roles assigned in this way will usually propagate down method chains.  (As of version 8.25, the only places in core L<Mojolicious> other than L<Mojo::UserAgent> where promises are being created from scratch is L<Mojolicious::Plugin::DefaultHelpers/proxy-E<gt>start_p> and related helpers, which you would need to wrap if your application uses them.)

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::PromiseClass> inherits the following attributes from L<Mojo::Base::Role::PromiseClass>

=head2 promise_class

  $pclass = $ua->promise_class;
  $ua     = $ua->promise_class('Mojo::Promise');

Get or set the user agent's preferred promise class.  This will be used for promises returned by L<start_p|User::Agent/start_p> and all derived routines (L<get_p|User::Agent/get_p>, L<post_p|User::Agent/post_p>, ...).

For altering the promise class, you will more likely want to use L<promise_roles|Mojo::Base::Role::PromiseClass/promise_roles>.

=head1 METHODS

L<Mojo::UserAgent::Role::PromiseClass> inherits all methods from L<Mojo::Base::Role::PromiseClass>.

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::Promise>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Roger Crew <wrog@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Roger Crew.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
