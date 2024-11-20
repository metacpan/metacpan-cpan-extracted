package Tapper::Reports::Web::Util::Filter::Report;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Util::Filter::Report::VERSION = '5.0.17';
use strict;
use warnings;




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
                                suite       => \&suite,
                                success     => \&success,
                                owner       => sub { hr_set_filter_default( @_, 'owner' ); },
                                host        => sub { hr_set_filter_default( @_, 'host' ); },
                                idlist      => sub { hr_set_filter_default( @_, 'report_id' ); },
                        }
                )
        );

}


sub suite
{
        my ($self, $filter_condition, $suite) = @_;
        my $suite_id;
        if ($suite =~/^\d+$/) {
                $suite_id = $suite;
        } else {
                my $suite_rs = $self->context->model('TestrunDB')->resultset('Suite')->search({name => $suite});
                $suite_id = $suite_rs->search({}, {rows => 1})->first->id if $suite_rs->count;
        }

        my @suites;
           @suites = @{$filter_condition->{suite_id}} if $filter_condition->{suite_id};
        push @suites, $suite_id;

        $filter_condition->{suite_id} = \@suites;
        return $filter_condition;
}


sub success
{
        my ($self, $filter_condition, $success) = @_;

        if ( $success =~/^\d+$/ ) {
                push @{$filter_condition->{success_ratio} ||= []}, int($success);
        }
        else {
                push @{$filter_condition->{successgrade} ||= []}, uc($success);
        }
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

Tapper::Reports::Web::Util::Filter::Report

=head1 SYNOPSIS

 use Tapper::Reports::Web::Util::Filter::Report;
 my $filter              = Tapper::Reports::Web::Util::Filter::Report->new(context => $c);
 my $filter_args         = ['host','bullock','days','3'];
 my $allowed_filter_keys = ['host','days'];
 my $searchoptions       = $filter->parse_filters($filter_args, $allowed_filter_keys);

=head2 suite

Add test suite to early filters.

@param hash ref - current version of filters
@param string   - suite name or id

@return hash ref - updated filters

=head2 success

Add success filters to early filters. Valid values are pass, fail and a
ratio in percent.

@param hash ref - current version of filters
@param string   - success grade

@return hash ref - updated filters

=head1 NAME

Tapper::Reports::Web::Util::Filter::Report - Filter utilities for report listing

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
