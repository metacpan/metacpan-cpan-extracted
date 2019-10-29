package Mojo::Pg::Role::PromiseClass 0.001;

# ABSTRACT: Choose the Mojo::Promise class used by Mojo::Pg objects

use Mojo::Pg::Database ();

use Mojo::Base -role;

with 'Mojo::Base::Role::PromiseClass';

has database_class => Mojo::Pg::Database->with_roles('+PgPromiseClass');

1;
__END__

=encoding utf8

=head1 NAME

Mojo::Pg::Role::PromiseClass - Choose the Promise class used by Mojo::Pg

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  $pg = Mojo::Pg->new(...)->with_roles('+PromiseClass')

  # add promise features you want
  $pg->promise_roles('+Repeat');

  # and they will show up on every query promise
  $pg->db->select_p(...)->repeat(sub{...});

=head1 DESCRIPTION

L<Mojo::Pg::Role::PromiseClass> is a role that allows specifying the promise class to be used for the promise-returning methods like L<Mojo::Pg::Database/select_p> and L<Mojo::Pg::Database/insert_p>, if you want something different from L<Mojo::Promise>.

Note that if you are also using a custom L<database_class|Mojo::Pg/database_class>, you will need to extend it using L<Mojo::Pg::Database::Role::PgPromiseClass/synopsis>.

=head1 ATTRIBUTES

L<Mojo::Pg::Role::PromiseClass> inherits the following attributes from L<Mojo::Base::Role::PromiseClass>

=head2 promise_class

  $pclass = $pg->promise_class;
  $pg     = $pg->promise_class('Mojo::Promise');

Get or set the preferred promise class.  This will be referenced by any L<db|Mojo::Pg::Database> when creating query promises (via L<select_p|Mojo::Pg::Database/select_p>, L<insert_p|Mojo::Pg::Database/insert_p>, ...)

For altering the promise class, you will more likely want to use L<promise_roles|Mojo::Base::Role::PromiseClass/promise_roles>.

=head1 METHODS

L<Mojo::Pg::Role::PromiseClass> inherits all methods (L<promise_roles|Mojo::Base::Role::PromiseClass/promise_roles>) from L<Mojo::Base::Role::PromiseClass> and does not define any new ones.

=head1 SEE ALSO

L<Mojo::Pg>, L<Mojo::Promise>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
