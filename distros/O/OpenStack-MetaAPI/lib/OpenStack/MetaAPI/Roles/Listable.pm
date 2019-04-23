package OpenStack::MetaAPI::Roles::Listable;

use strict;
use warnings;

use Moo::Role;

sub _list {
    my ($self, $all_args, $caller_args) = @_;

  # all_args are arguments from the internal OpenStack::MetaAPI::API
  # caller_args are coming from the user to filter the results
  #   if some filters are also arguments to the request
  #   then appending them to the query will shorten the output and run it faster

    my @all;
    {
        my ($uri, @extra) = @$all_args;
        $uri = $self->root_uri($uri)
          if $uri !~ m{^/v};    # can be removed once dynmaic methods are used

        my $extra_filters =
          $self->api_specs()->query_filters_for('/get', $uri, $caller_args);

        if ($extra_filters) {
            if (scalar @extra == 1) {
                push @extra, {};
            } elsif (scalar @extra > 1) {
                die "Too many args when calling _list for all...";
            }
            $extra[-1] = {%{$extra[-1]}, %$extra_filters};
        }

        @all = $self->client->all($uri, @extra);
    }

    my @args = @$caller_args;

    # apply our filters to the raw results
    my $nargs = scalar @args;
    if ($nargs && $nargs % 2 == 0) {
        my %opts = @args;
        foreach my $filter (sort keys %opts) {
            my @keep;
            my $filter_isa = ref $opts{$filter} // '';
            foreach my $candidate (@all) {
                next unless ref $candidate;
                if ($filter_isa eq 'Regexp') {

                    # can use a regexp as a filter
                    next
                      unless $candidate->{$filter}
                      && $candidate->{$filter} =~ $opts{$filter};
                } else {

                    # otherwise do one 'eq' check
                    next
                      unless $candidate->{$filter}
                      && $candidate->{$filter} eq $opts{$filter};
                }

                push @keep, $candidate;
            }

            @all = @keep;

        }
    }

    # avoid to return a list when possible
    return $all[0] if scalar @all <= 1;

    # return a list
    return @all;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::Roles::Listable

=head1 VERSION

version 0.002

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
