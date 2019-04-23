package OpenStack::MetaAPI::API::Specs::Roles::Service;

use strict;
use warnings;

use Moo::Role;

use OpenStack::MetaAPI::Helpers::DataAsYaml;

has 'specs' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $specs =
          OpenStack::MetaAPI::Helpers::DataAsYaml::LoadDataFrom(ref $self)
          // {};

        # populate missing keys
        $specs->{$_} //= {} for qw/get post put delete/;

        return $specs;
    });

sub get {
    my ($self, $route) = @_;

    $route = '/' . $route unless $route =~ m{^/};

    return $self->specs()->{get}->{$route};
}

sub put {
    die "must be implemented";
}

sub post {
    die "must be implemented";
}

sub query_filters_for {
    my ($self, $method, $route, $args) = @_;

    die unless defined $method;
    die unless defined $route;
    die unless ref $args eq 'ARRAY';

    return unless @$args % 2 == 0;

    my %filters = @$args;

    $method =~ s{^/+}{};

    my $spec = $self->can($method)->($self, $route);

    return
         unless ref $spec eq 'HASH'
      && ref $spec->{request}
      && ref $spec->{request}->{query};

    my %valid_filters = map { $_ => 1 } sort keys %{$spec->{request}->{query}};

    my $use_filters = {};

    foreach my $filter (sort keys %filters) {
        next unless defined $valid_filters{$filter};
        ### ... can use type & co ...
        $use_filters->{$filter} = $filters{$filter};
    }

    return unless scalar keys %$use_filters;
    return $use_filters;
}

## hook all methods to our object
sub setup_api_methods_for_service {
    my ($self, $service) = @_;

    my $specs = $self->specs;
    foreach my $method (sort keys %$specs) {
        foreach my $route (sort keys %{$specs->{$method}}) {
            my $rule = $specs->{$method}->{$route};
            next unless ref $rule && ref $rule->{perl_api};
            my $perl_api = $rule->{perl_api};

            my $code = sub { };

            my $from_txt =
              "from spec " . (ref $self->specs) . " for route $route";

            my $method_name = $perl_api->{method}
              or die "method is missing $from_txt";
            my $type = $perl_api->{type} or die "type is missing $from_txt";
            if ($type eq 'getfromid') {
                my $token = $perl_api->{uid} or die "uid is missing $from_txt";

                $code = sub {
                    my ($self, $uid) = @_;

                    my $r = $route;
                    $r =~ s[\Q$token\E][$uid]g;

                    return $self->_get_from_id_spec($r, $uid);
                };
            } elsif ($type eq 'listable') {
                my $listable_key = $perl_api->{listable_key}
                  or die "listable_key is missing $from_txt";
                $code = sub {
                    my ($self, @args) = @_;
                    return $self->_list([$route, $listable_key], \@args);
                };
            } else {
                die "Unknown type '$type' $from_txt";
            }

            $service->setup_method($method_name, $code);
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Specs::Roles::Service

=head1 VERSION

version 0.002

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
