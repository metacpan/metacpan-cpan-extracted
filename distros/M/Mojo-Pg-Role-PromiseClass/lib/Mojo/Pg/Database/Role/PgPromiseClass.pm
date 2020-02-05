package Mojo::Pg::Database::Role::PgPromiseClass 0.002;

# ABSTRACT: db query promises use Pg's promise_class

use Mojo::Base -role;

around query_p => sub {
    my ($query_p, $db) = (shift, shift);
    bless $db->$query_p(@_), $db->pg->promise_class;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::Pg::Database::Role::PgPromiseClass - db query promises use Pg's promise_class

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # extend $pg to allow messing with promise_class
  $pg = Mojo::Pg->new(...)->with_roles('+PromiseClass');

  # but we also want funky database with spoons and llamas
  $pg->database_class(
     Mojo::Pg::Database->with_roles('+PgPromiseClass','+Spoons','+Llamas',...)
  );

  # declare additional promise roles on $pg
  $pg->promise_roles('+Repeat');

  # and they will show up on every subsequent query_p
  $pg->db->query_p('SELECT * FROM wombats')->repeat(sub{...});

=head1 DESCRIPTION

L<Mojo::Pg::Database::Role::PgPromiseClass> is a role to be applied to L<Mojo::Pg::Database>-derived objects that has them refer to their parent L<Mojo::Pg> instance to determine the class used for promises returned by L<query_p|Mojo::Pg::Database/query_p> et al, for situations where you want that class to be different from L<Mojo::Promise>.

You should only be needing to explicitly add this role in cases where you are customizing I<both> the promise class and the database class.  The default database class already includes this role when the Pg wrapper has been extended via L<Mojo::Pg::Role::PromiseClass>.

Note that since nearly all L<Mojo::Promise> methods use L<clone|Mojo::Promise/clone> to create new instances, roles assigned to promises in this way will generally propagate down method chains.

=head1 ATTRIBUTES

This role adds no additional attributes.

=head1 METHODS

This role adds no additional methods.

L<query_p|Mojo::Pg::Database/query_p> and all methods that are derived from it (L<delete_p|Mojo::Pg::Database/delete_p>, L<insert_p|Mojo::Pg::Database/insert_p>, L<select_p|Mojo::Pg::Database/select_p>, and L<update_p|Mojo::Pg::Database/update_p>) are all modified to return promises of the specified class.

=head1 SEE ALSO

L<Mojo::Pg::Database>, L<Mojo::Promise>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Roger Crew <wrog@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Roger Crew.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
