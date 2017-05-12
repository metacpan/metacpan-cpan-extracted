package Otogiri::Plugin::TableInfo;
use 5.008005;
use strict;
use warnings;

use Otogiri;
use Otogiri::Plugin;
use DBIx::Inspector;
use Otogiri::Plugin::TableInfo::Pg;
use Carp qw();

our $VERSION = "0.04";

our @EXPORT = qw(show_tables show_views show_create_table show_create_view desc);

sub show_tables {
    my ($self, $like_regex) = @_;
    my $inspector = DBIx::Inspector->new(dbh => $self->dbh);
    my @result = map { $_->name } $inspector->tables;
    @result = grep { $_ =~ /$like_regex/ } @result if ( defined $like_regex );
    return @result;
}

sub show_views {
    my ($self, $like_regex) = @_;
    my $inspector = DBIx::Inspector->new(dbh => $self->dbh);
    my @result = map { $_->name } $inspector->views;
    @result = grep { $_ =~ /$like_regex/ } @result if ( defined $like_regex );
    return @result;
}


sub show_create_table {
    my ($self, $table_name) = @_;
    my $inspector = DBIx::Inspector->new(dbh => $self->dbh);
    my $table = $inspector->table($table_name);

    return if ( !defined $table );

    my $driver_name = $self->maker->driver;

    if ( $driver_name eq 'mysql' ) {
        my ($row) = $self->search_by_sql("SHOW CREATE TABLE $table_name");
        return $row->{'Create Table'};
    }
    elsif ( $driver_name eq 'SQLite' ) {
        return $table->{SQLITE_SQL};
    }
    elsif ( $driver_name eq 'Pg' ) {
        my $pg = Otogiri::Plugin::TableInfo::Pg->new($self);
        return $pg->show_create_table($table_name);
    }

    Carp::carp "unsupported driver : $driver_name";
    return;
}

sub show_create_view {
    my ($self, $view_name) = @_;
    my $inspector = DBIx::Inspector->new(dbh => $self->dbh);
    my $view = $inspector->view($view_name);

    return if ( !defined $view );

    my $driver_name = $self->maker->driver;

    if ( $driver_name eq 'mysql' ) {
        my ($row) = $self->search_by_sql("SHOW CREATE VIEW $view_name");
        return $row->{'Create View'};
    }
    elsif ( $driver_name eq 'SQLite' ) {
        return $view->{SQLITE_SQL};
    }
    elsif ( $driver_name eq 'Pg' ) {
        my $pg = Otogiri::Plugin::TableInfo::Pg->new($self);
        return $pg->show_create_view($view_name);
    }

    Carp::carp "unsupported driver : $driver_name";
    return;
}

sub desc {
    my ($self, $table_name) = @_;
    $self->show_create_table($table_name);
}



1;
__END__

=encoding utf-8

=for stopwords desc

=head1 NAME

Otogiri::Plugin::TableInfo - retrieve table information from database

=head1 SYNOPSIS

    use Otogiri::Plugin::TableInfo;
    my $db = Otogiri->new( connect_info => [ ... ] );
    $db->load_plugin('TableInfo');
    my @table_names = $db->show_tables();


=head1 DESCRIPTION

Otogiri::Plugin::TableInfo is Otogiri plugin to fetch table information from database.

=head1 METHODS

=head2 my @table_names = $self->show_tables([$like_regex]);

returns table names in database.

parameter C<$like_regex> is optional. If it is passed, table name is filtered by regex like MySQL's C<SHOW TABLES LIKE ...> statement.

    my @table_names = $db->show_tables(qr/^user_/); # return table names that starts with 'user_'

If C<$like_regex> is not passed, all table_names in current database are returned.

=head2 my @view_names = $self->show_views([$like_regex]);

returns view names in database.


=head2 my $create_table_ddl = $self->desc($table_name);

=head2 my $create_table_ddl = $self->show_create_table($table_name);

returns create table statement like MySQL's 'show create table'.


=head2 my $create_view_sql = $self->show_create_view($view_name);

returns create view SQL like MySQL's 'show create view'.

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

