package Tapper::Reports::Web::Util::Filter::Testrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Util::Filter::Testrun::VERSION = '5.0.15';




use Moose;
use Hash::Merge::Simple 'merge';
use Set::Intersection 'get_intersection';

use Tapper::Model 'model';

extends 'Tapper::Reports::Web::Util::Filter';

sub BUILD {

        my $self = shift;
        my $args = shift;

        $self->dispatch(
                merge(
                        $self->dispatch,
                        {
                                host    => \&host,
                                owner   => \&owner,
                                state   => sub { hr_set_filter_default( @_, 'state' );      },
                                success => sub { hr_set_filter_default( @_, 'success' );    },
                                topic   => sub { hr_set_filter_default( @_, 'topic' );      },
                                idlist  => sub { hr_set_filter_default( @_, 'testrun_id' ); },
                        }
                )
        );
}



sub host
{
        my ($self, $filter_condition, $host) = @_;
        my $host_result = model('TestrunDB')->resultset('Host')->search({name => $host}, {rows => 1})->first;

        # (XXX) do we need to throw an error when someone filters for an unknown host?
        if (not $host_result) {
                return $filter_condition;
        }

        push @{$filter_condition->{host} ||= []}, $host_result->id;

        return $filter_condition;
}



sub owner
{
        my ($self, $filter_condition, $owner) = @_;

        my $owner_result = model('TestrunDB')->resultset('Owner')->search({login => $owner}, {rows => 1})->first;

        if (not $owner_result) {
                $filter_condition->{error} = "No owner with login '$owner' found";
                return $filter_condition;
        }

        push @{$filter_condition->{owner} ||= []}, $owner_result->id;

        return $filter_condition;
}

sub hr_set_filter_default {
    my ( $or_self, $hr_filter, $value, $s_filter_name ) = @_;
    push @{$hr_filter->{$s_filter_name} ||= []}, $value;
    return $hr_filter;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Util::Filter::Testrun

=head1 SYNOPSIS

 use Tapper::Testruns::Web::Util::Filter::Testrun;
 my $filter              = Tapper::Testruns::Web::Util::Filter::Testrun->new();
 my $filter_args         = ['host','bullock','days','3'];
 my $allowed_filter_keys = ['host','days'];
 my $searchoptions       = $filter->parse_filters($filter_args, $allowed_filter_keys);

=head2 host

Add host filters to early filters.

@param hash ref - current version of filters
@param string   - host name

@return hash ref - updated filters

=head2 owner

Add owner filters to early filters.

@param hash ref - current version of filters
@param string   - owner login

@return hash ref - updated filters

=head1 NAME

Tapper::Reports::Web::Util::Filter::Testrun - Filter utilities for testrun listing

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
