
package OpusVL::Preferences::Schema::ResultSet::PrfDefault;

use strict;
use warnings;
use Moose;

extends 'DBIx::Class::ResultSet';

sub active
{
    my $self = shift;
    return $self->search({ active => 1 }, {
        order_by => ['name'], # just ensure we always have a consistent order
    });
}

sub active_first
{
    my $self = shift;
    return $self->search(undef, {
        order_by => [ { -desc => ['active'] }, { -asc => ['display_order', 'name'] } ], 
    });
}

sub not_hidden
{
    my $self = shift;
    return $self->search({ -or => [ hidden => 0, hidden => undef ] });
}

sub display_order
{
    my $self = shift;
    return $self->search(undef, { order_by => [ 'display_order', 'name' ] } );
}

sub display_on_search
{
    my $self = shift;
    return $self->search({ display_on_search => 1 });
}

sub searchable
{
    my $self = shift;
    return $self->search({ searchable => 1 });
}

sub for_search
{
    my $self = shift;
    return $self->active->display_on_search->display_order;
}

sub for_search_criteria
{
    my $self = shift;
    return $self->active->searchable->display_order;
}

sub for_report
{
    my $self = shift;
    return $self->active->not_hidden->display_order;
}

return 1;

=head1 DESCRIPTION

=head1 METHODS

=head2 active

=head2 active_first

=head2 not_hidden

=head2 display_on_search

=head2 for_search

=head2 searchable

=head2 for_search_criteria

=head2 display_order

Returns the preferences in the display order.

=head2 for_report

Returns a resultset ordered and filtered for use on the transaction report.

=head1 ATTRIBUTES


=cut
