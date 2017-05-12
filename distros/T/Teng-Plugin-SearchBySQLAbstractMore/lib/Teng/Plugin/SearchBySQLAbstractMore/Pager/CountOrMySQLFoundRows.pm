package Teng::Plugin::SearchBySQLAbstractMore::Pager::CountOrMySQLFoundRows;

use strict;
use warnings;
use utf8;
use Carp ();
use Teng::Iterator;
use Data::Page;
use Teng::Plugin::SearchBySQLAbstractMore ();
use Teng::Plugin::SearchBySQLAbstractMore::Pager::Count ();
use Teng::Plugin::SearchBySQLAbstractMore::Pager::MySQLFoundRows ();

our @EXPORT = qw/search_by_sql_abstract_more_with_pager/;

sub init {
    $_[1]->Teng::Plugin::SearchBySQLAbstractMore::_init();
}

# work around
push @EXPORT, qw/sql_abstract_more_instance/;
*sql_abstract_more_instance = \&Teng::Plugin::SearchBySQLAbstractMore::sql_abstract_more_instance;

sub search_by_sql_abstract_more_with_pager {
    my ($self, $table_name, $where, $_opt) = @_;

    my $sql_abstract_more = $self->sql_abstract_more_instance;

    ($table_name, my($args, $rows, $page)) = Teng::Plugin::SearchBySQLAbstractMore::_arrange_args($table_name, $where, $_opt);

    $args->{-page} = $args->{-offset} ? $args->{-offset} / $args->{-limit} + 1 : 1;
    $args->{-rows} = $args->{-limit};
    if ($args->{-group_by}) {
        return $self->Teng::Plugin::SearchBySQLAbstractMore::Pager::MySQLFoundRows::search_by_sql_abstract_more_with_pager($args);
    } else {
        return $self->Teng::Plugin::SearchBySQLAbstractMore::Pager::Count::search_by_sql_abstract_more_with_pager($args);
    }
}

=pod

=head1 NAME

Teng::Plugin::SearchBySQLAbstractMore::Pager::CountOrMySQLFoundRows - pager plugin using SQL::AbstractMore. count total entry by count(*) or CALC FOUND_ROWS of mysql

=head1 DESCRIPTION

If group by is used, use Pager::MySQLFoundRows.
If group by is not used, use Pager::Count;

=head1 SYNOPSIS

see Teng::Plugin::SearchBySQLAbstractMore

=head1 METHODS

=head2 search_by_sql_abstract_more_with_pager

C<search_by_sql_abstract_more> with paging feature.
additional parameter can be taken, C<page> and C<rows>.

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
