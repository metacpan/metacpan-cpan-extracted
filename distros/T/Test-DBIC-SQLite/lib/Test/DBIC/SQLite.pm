package Test::DBIC::SQLite;
use v5.10.1;
use utf8;
use warnings;
use strict;

our $VERSION = '0.01';

use parent 'Test::Builder::Module';

our @EXPORT = qw/ connect_dbic_sqlite_ok /;

=head1 NAME

Test::DBIC::SQLite - Connect and deploy a DBIx::Class::Schema on SQLite

=head1 SYNOPSIS

    use Test::More;
    use Test::DBIC::SQLite;
    my $schema = connect_dbic_sqlite_ok('My::Schema');
    done_testing();

=head1 DESCRIPTION

=begin hide

=head2 import_extra

L<Test::Builder::Module>'s way to import extra stuff, in this case enable
L<warnings> and L<strict> in the calling scope.

=end hide

=cut

sub import_extra {
    strict->import();
    warnings->import();
}

=head2 connect_dbic_sqlite_ok($class[, $dbname[, $callback]])

Create an SQLite database (default in memory) and deploy the schema.

=head3 Arguments

Positional.

=over

=item $class (Required)

The class name of the L<DBIx::Class::Schema> to use.

=item $dbname (Optional)

The default is B<:memory:>, but a name for diskfile can be set here.

=item $callback (Optional)

The callback is a codereference that is called after deploy and just before
returning the schema instance. Usefull for populating the database.

=back

=head3 Returns

An initialized instance of C<$class>.

=cut

sub connect_dbic_sqlite_ok {
    my $tb = __PACKAGE__->builder;

    my ($dbic_class, $dbname, $callback) = @_;
    $dbname ||= ':memory:';
    $tb->note("dbname => $dbname");

    my $msg = "$dbname ISA $dbic_class";

    my $wants_deploy = $dbname eq ':memory:' ? 1 : 0;
    if (! $wants_deploy) {
        $wants_deploy = (! -f $dbname) ? 1 : 0;
    }
    $tb->note("wants_deploy => $wants_deploy");


    eval "require $dbic_class";
    if (my $error = $@) {
        $tb->diag("Error loading '$dbic_class': «$error»");
        return $tb->ok(0, $msg);
    }
    $tb->note("Loaded => $dbic_class");
    my $db = eval {
        $dbic_class->connect(
            "dbi:SQLite:dbname=$dbname", undef, undef,
            {$wants_deploy ? (ignore_version => 1) : ()}
        );
    };
    if (my $error = $@) {
        $tb->diag("Error connecting $dbic_class to $dbname: «$error»");
        return $tb->ok(0, $msg);
    }

    if ($wants_deploy) {
        eval { $db->deploy };
        if (my $error = $@) {
            $tb->diag("Error deploying $dbic_class to $dbname: «$error»");
            return $tb->ok(0, $msg);
        }
    }
    if (ref($callback) eq 'CODE') {
        eval { $callback->($db) };
        if (my $error = $@) {
            $tb->diag("Error in callback: «$error»");
            return $tb->ok(0, $msg);
        }
    }
    $tb->is_eq(ref($db), $dbic_class, $msg);

    return $db;
}

1;

=head1 LICENSE

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
