package Teng::Plugin::Pager::DataPageset;
use 5.008005;

use strict;
use warnings;
use utf8;
use Data::Pageset;
use Teng::Iterator;
use Carp ();

our $VERSION = "0.01";

our @EXPORT = qw/search_with_data_pageset/;

sub search_with_data_pageset {
    my ($self, $table_name, $where, $opt) = @_;

    my $table = $self->schema->get_table($table_name) or Carp::croak("'$table_name' is unknown table");

    my $page  = $opt->{page} || 1;
    my $rows  = $opt->{rows} || 1;
    my $mode  = $opt->{mode} || 'fixed';
    my $pages_per_set = $opt->{pages_per_set} || 5;
    my $total_entries = $opt->{total_entries} or Carp::croak("please input 'total_entries' option");

    my $columns = $opt->{'+columns'} ? [@{$table->{columns}}, @{$opt->{'+columns'}}]
                                     : ($opt->{columns} || $table->{columns})
                                     ;

    my ($sql, @binds) = $self->sql_builder->select(
        $table_name,
        $columns,
        $where, +{
            %$opt,
            limit  => $rows,
            offset => $rows*($page-1),
        },
    );
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;

    my $itr = Teng::Iterator->new(
        teng             => $self,
        sth              => $sth,
        sql              => $sql,
        row_class        => $self->schema->get_row_class($table_name),
        table            => $table,
        table_name       => $table_name,
        suppress_object_creation => $self->suppress_row_objects,
    );

    my $pager = Data::Pageset->new({
        'total_entries'       => $total_entries,
        'entries_per_page'    => $rows,
        'current_page'        => $page,
        'pages_per_set'       => $pages_per_set,
        'mode'                => $mode,
    });

    return ([$itr->all], $pager);
}

1;

__END__

=encoding utf-8

=head1 NAME

Teng::Plugin::Pager::DataPageset - Pager using DataPageset

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Pager::DataPageset');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page');

    my ($rows, $pager) = $db->search_with_data_pageset(user => {
        type => 3
    },{
        page  => $page,
        rows  => 5,
        total_entries => 10000,
        pages_per_set => 5,
    });

=head1 DESCRIPTION

This is a helper for pagination using Data::Pageset.

=head1 METHODS

=head2 search_with_data_pageset($table_name, \%where, \%opts)

This method returns ArrayRef[Teng::Row] and instance of L<Data::Pageset>.

=over 4

=item $opts->{page}

Current page number.

=item $opts->{rows}

The number of entries per page.

=item $opts->{total_entries}

See L<Data::Pageset>.

=item $opts->{paegs_per_set}

See L<Data::Pageset>.

=item $opts->{mode}

See L<Data::Pageset>.

=back

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut



