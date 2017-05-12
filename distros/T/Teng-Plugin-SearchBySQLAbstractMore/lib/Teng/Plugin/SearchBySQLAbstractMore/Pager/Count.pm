package Teng::Plugin::SearchBySQLAbstractMore::Pager::Count;

use strict;
use warnings;
use utf8;
use Carp ();
use Teng::Iterator;
use Data::Page;
use Teng::Plugin::SearchBySQLAbstractMore ();

our @EXPORT = qw/search_by_sql_abstract_more_with_pager/;

sub init {
    $_[1]->Teng::Plugin::SearchBySQLAbstractMore::_init();
}

# work around
push @EXPORT, qw/sql_abstract_more_instance/;
*sql_abstract_more_instance = \&Teng::Plugin::SearchBySQLAbstractMore::sql_abstract_more_instance;

sub search_by_sql_abstract_more_with_pager {
    my ($self, $table_name, $where, $_opt) = @_;

    ($table_name, my($args, $rows, $page)) = Teng::Plugin::SearchBySQLAbstractMore::_arrange_args($table_name, $where, $_opt);

    my $table = $self->schema->get_table($table_name) or Carp::croak("No such table $table_name");
    my ($sql, $binds, $count_sql, $count_binds) = _create_sqls($self, $args);
    my ($total_entries, $itr);
    do {
        my $txn_scope = $self->txn_scope;
        my $count_sth = $self->execute($count_sql, \@$count_binds);
        my $sth       = $self->execute($sql,       \@$binds);
        ($total_entries) = $count_sth->fetchrow_array();
        $itr = Teng::Iterator->new(
                                   teng             => $self,
                                   sth              => $sth,
                                   sql              => $sql,
                                   row_class        => $self->schema->get_row_class($table_name),
                                   table_name       => $table_name,
                                   suppress_object_creation => $self->suppress_row_objects,
                                  );
        $txn_scope->commit;
    };
    my $pager = Data::Page->new();
    $pager->entries_per_page($rows);
    $pager->current_page($page);
    $pager->total_entries($total_entries);
    return ([$itr->all], $pager);
}

sub _create_sqls {
    my ($self, $args) = @_;

    my $sql_abstract_more = $self->sql_abstract_more_instance;
    my $hint_columns = delete $args->{-hint_columns};
    my ($sql, @binds) = $sql_abstract_more->select(%$args);

    delete @{$args}{qw/-offset -limit -order_by/};
    if ($args->{-group_by} and $self->dbh->{Driver}->{Name} eq 'mysql') {
        $args->{-order_by}  = 'NULL';
    }

    if (not $args->{-group_by}) {
        $args->{-columns} = ['count(*)'];
    } elsif ($hint_columns) {
        $args->{-columns} = $hint_columns;
    }
    my ($count_sql, @count_binds) = $sql_abstract_more->select(%$args);
    if ($args->{-group_by}) {
        $count_sql = "SELECT COUNT(*) AS cnt FROM ($count_sql) AS total_count";
    }
    return ($sql, \@binds, $count_sql, \@count_binds);
}

=pod

=head1 NAME

Teng::Plugin::SearchBySQLAbstractMore::Pager::Count - pager plugin using SQL::AbstractMore. count total entry by count(*)

=head1 SYNOPSIS

see Teng::Plugin::SearchBySQLAbstractMore

=head1 CAUTION

This solution is bad when you have many records.  You re-consider the implementation where you want to use this module.
If you are using MySQL, I recommend to use Pager::CountOrMySQLFoundRows or Pager::MySQLFoundRows.

=head1 METHODS

=head2 search_by_sql_abstract_more_with_pager

C<search_by_sql_abstract_more> with paging feature.
additional parameter can be taken, C<page>, C<rows> and C<hint_columns>.

=head3 hint_columns

If you pass C<hint_columns>, or C<-hint_columns> as option and select using "GROUP BY", it uses these values as select columns for calculating total count.

For example:

 my ($rows, $pager) = $teng->search_by_sql_abstrat_more_with_pager
                              ('clicks',
                               {},
                               {-columns  => [qw/user_id count(*) date(clicked_datetime)/],
                                -group_by => [qw/user_id date(clicked_datetime)/],
                                -rows     => 20,
                                -page     => 1,
                               }
                             );

It execute the following 2 SQLs.

 SELECT COUNT(*) AS cnt FROM (SELECT user_id,DATE(clicked_datetime),COUNT(*) FROM clicks GROUP BY user_id, date(clicked_datetime)) AS total_count;
 SELECT user_id, date(clicked_datetime), COUNT(*) FROM clicks GROUP BY user_id, date(clicked_datetime) LIMIT 20 OFFSET 0;

If you pass -hint_columns option.

 my ($rows, $pager) = $teng->search_by_sql_abstrat_more_with_pager
                              ('clicks',
                               {},
                               {-columns      => [qw/user_id count(*) date(clicked_datetime)/],
                                -group_by     => [qw/user_id date(clicked_datetime)/],
                                -hint_columns => [qw/user_id/],
                                -rows         => 20,
                                -page         => 1,
                               }
                             );

It execute the following 2 SQLs.

 SELECT COUNT(*) AS cnt  FROM (SELECT user_id FROM clicks GROUP BY user_id, date(clicked_datetime)) AS total_count;
 SELECT user_id,date(clicked_datetime) FROM clicks GROUP BY user_id, date(clicked_datetime) LIMIT 20 OFFSET 0;

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-teng-plugin-searchbysqlabstractmore at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Teng-Plugin-SearchBySQLAbstractMore>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Teng::Plugin::SearchBySQLAbstractMore

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Teng-Plugin-SearchBySQLAbstractMore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Teng-Plugin-SearchBySQLAbstractMore>

=item * Search CPAN

L<http://search.cpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Teng::Plugin::SearchBySQLAbstractMore::Pager::Count
