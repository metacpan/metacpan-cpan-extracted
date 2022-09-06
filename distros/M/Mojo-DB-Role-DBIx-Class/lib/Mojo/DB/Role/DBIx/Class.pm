package Mojo::DB::Role::DBIx::Class;

# ABSTRACT: provides a convenience role creating a DBIx::Class for your Mojo database

use Mojo::Base -role;
use Mojo::Util qw/dumper/;

use strict;
use warnings;

use DBIx::Class::Schema::Loader;
use Module::Load;

# use Test::Schema;

$\ = "\n"; $, = "\t";

sub dbic {
    my $self = shift;
    my $opts = shift;

    my $class =
	$opts ? 
	ref $opts ? 
	delete $opts->{class}
	:
	$opts
	:
	'DBIx::Class::Schema::Loader';

    load $class unless $class eq 'DBIx::Class::Schema::Loader';
    $opts = {} unless ref $opts eq 'HASH';

    $opts->{unsafe} = 1 if $self->dbh->{Driver}{Name} =~ /SQLite/;

    $class->naming(delete $opts->{naming} || 'current') if $class eq 'DBIx::Class::Schema::Loader';

    state $connect = $class->connect(sub { $self->dbh }, $opts);
}

sub resultset {
    return shift->dbic()->resultset(@_);
}

1;


=encoding utf8

=pod 

=head1 NAME

Mojo::DB::Role::DBIx::Class - A Mojo role connecting DBIx::Class to Mojo::Pg and Mojo::SQLite

=head1 SYNOPSIS

    use Mojo::SQLite;

    $\ = "\n"; $, = "\t";

    my $sql = Mojo::SQLite->new;

    my $db = $sql->db;
    $db = $db->with_roles('Mojo::DB::Role::DBIx::Class');

    my $rs = $db->resultset('SomeTable')->search({ some_field => 'some_value' })

    print for $db->dbic->sources

=head1 DESCRIPTION

This module adds a dbic method loading a DBIx::Class on top of an existing Mojo::Pg or Mojo::SQLite database

=head2 Methods

=over 12

=item C<dbic>

Connects the database via the schema either with a schema class passed as the parameter:

    $db->dbic('My::Schema')

or with a schema class passed as "class" option:

    $db->dbic({ class => 'My::Schema' })

or without any schema - in which case DBIx::Class::Schema::Loader gets used

    $db->dbic($opts)

All other options get passed on to the class being connected.

Returns the DBIx::Class::Schema so that it can be used like this

    print for $db->dbic->sources;

    my $rs = $db->dbic->resultset('SomeTable')->search({ some_field => 'some_value' })

=item C<resultset>

Shortcut for $db->dbic->resultset

    my $rs = $db->resultset('SomeTable')->search({ some_field => 'some_value' })

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::Schema::Loader>, L<Mojo::Pg>, L<Mojo::SQLite>

=head1 AUTHOR

Simone Cesano

=cut

