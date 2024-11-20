package Tapper::Reports::Web::Controller::Base;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Base::VERSION = '5.0.17';
use strict;
use warnings;

use parent qw(Catalyst::Controller::HTML::FormFu);


sub reduced_filter_path
{
        my ($self, $filters, $remove) = @_;
        my %new_filters = %$filters;
        delete $new_filters{$remove};
        return join('/', %new_filters );
}


sub prepare_filter_path
{
        my ($self, $c, $days) = @_;
        my @args = @{$c->req->arguments};
        my %args;
        %args = @args if (int @args % 2 == 0);

        $args{days} = $days if $days;

        return join('/', %args );
}


sub begin :Private
{
        my ( $self, $c ) = @_;

        require Tapper::Config;
        if (Tapper::Config->subconfig->{web}->{we_have_a_problem}) {
                $c->stash->{we_have_a_problem} = Tapper::Config->subconfig->{web}->{we_have_a_problem};
        }
        $c->stash->{logo}   = Tapper::Config->subconfig->{web}{logo};
        $c->stash->{title}  = Tapper::Config->subconfig->{web}{title};
        $c->stash->{footer} = Tapper::Config->subconfig->{web}{footer};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Base

=head2 reduced_filter_path

Create a filter path out of the filters given as first argument that
does not contain the second argument.

@param hash ref - current filter settings
@param string   - new path without that filter (should be a key in the hash)

@return string  - new path

=head2 prepare_filter_path

Create the URL part for the current filter setting with the requested
number of days.

@param catalyst context
@param int - number of days

@return url part

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
