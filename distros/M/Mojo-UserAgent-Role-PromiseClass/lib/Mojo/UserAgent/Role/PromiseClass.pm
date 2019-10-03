package Mojo::UserAgent::Role::PromiseClass;

# ABSTRACT: Specify the Mojo::Promise class used by Mojo::UserAgent

use Mojo::Base -role;

our $VERSION = '0.003';

has promise_class => sub { 'Mojo::Promise' };

around start_p => sub {
    my ($start_p, $ua) = (shift, shift);
    bless $ua->$start_p(@_), $ua->promise_class;
};

sub promise_roles {
    my $self = shift;
    my $pclass = $self->promise_class;
    my @roles =
      grep { !Role::Tiny::does_role($pclass, $_) }
      map  { /^\+(.+)$/ ? "Mojo::Promise::Role::$1" : $_ }
      @_;
    $self->promise_class($pclass->with_roles(@roles)) if @roles || !@_;
    return $self;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::PromiseClass - Choose the Promise class used by Mojo::UserAgent

=head1 SYNOPSIS

  $ua = Mojo::UserAgent->new(...)
        ->with_roles('+PromiseClass')
        ->promise_roles('+Repeat');  # add promise features you want

  $ua->get_p('http://example.com')
     ->repeat(sub{...});  # and they show up on every get_p call


=head1 DESCRIPTION

L<Mojo::UserAgent::Role::PromiseClass> is a role that allows specifying the promise class to be used for the promise-returning methods like L<UserAgent/get_p> and L<UserAgent/post_p>, if you want something different from L<Mojo::Promise>.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::PromiseClass> implements the following attributes.

=head2 promise_class

  $pclass = $ua->promise_class;
  $ua     = $ua->promise_class('Mojo::Promise');

Specifieds the class to use for promises returned by L<User::Agent/start_p> and all derived routines (L<User::Agent/get_p>, L<User::Agent/post_p>, ...).

=head1 METHODS

L<Mojo::UserAgent::Role::PromiseClass> supplies the following methods:

=head2 promise_roles

  $ua->promise_roles(@roles);

This is a shortcut to add the specified C<@roles> to the user agent's promise_class, returning the original L<User::Agent>, equivalent to

  $ua->promise_class($ua->promise_class->with_roles(@roles));

For roles following the naming scheme C<Mojo::Promise::Role::RoleName> you can use the shorthand C<+RoleName>.

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::Promise>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Roger Crew <wrog@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
