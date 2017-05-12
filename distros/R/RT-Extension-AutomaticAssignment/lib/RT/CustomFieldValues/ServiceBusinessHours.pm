package RT::CustomFieldValues::ServiceBusinessHours;
use strict;
use warnings;

use base qw(RT::CustomFieldValues::External);

=head1 NAME

RT::CustomFieldValues::Groups - Provide RT's %ServiceBusinessHours as a dynamic list of CF values

=head1 SYNOPSIS

To use as a source of CF values, add the following to your F<RT_SiteConfig.pm>
and restart RT.

    # In RT_SiteConfig.pm
    Set( @CustomFieldValuesSources, "RT::CustomFieldValues::ServiceBusinessHours" );

Then visit the modify CF page in the RT admin configuration.

=head1 METHODS

Most methods are inherited from L<RT::CustomFieldValues::External>, except the
ones below.

=head2 SourceDescription

Returns a brief string describing this data source.

=cut

sub SourceDescription {
    return 'RT service business hours';
}

=head2 ExternalValues

Returns an arrayref containing a hashref for each possible value in this data
source, where the value name is the service business hours name.

=cut

sub ExternalValues {
    my $self = shift;

    my @res;
    for my $name (sort keys %RT::ServiceBusinessHours) {
        push @res, {
            name => $name,
        };
    }
    return \@res;
}

1;

