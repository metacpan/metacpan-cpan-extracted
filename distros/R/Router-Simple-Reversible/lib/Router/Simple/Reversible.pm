package Router::Simple::Reversible;
use 5.008001;
use strict;
use warnings;
use parent 'Router::Simple';

our $VERSION = "0.02";

sub path_for {
    my ($self, $dest, $args) = @_;

    $dest ||= {};
    $args ||= {};

ROUTE:
    foreach my $route (@{ $self->routes }) {
        foreach my $key (keys %$dest) {
            if ($route->dest->{$key} ne $dest->{$key}) {
                next ROUTE;
            }
        }

        my $splat_index = 0;
        my $path = $route->pattern;
        $path =~ s!
                \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
                :([A-Za-z0-9_]+)              | # /blog/:year
                (\*)                          | # /blog/*/*
                ([^{:*]+)                       # normal string
            !
                if ($1) {
                    my ($name) = split /:/, $1, 2;
                    defined $args->{$name} ? $args->{$name} : '';
                } elsif ($2) {
                    $args->{$2};
                } elsif ($3) {
                    $args->{splat}->[$splat_index++];
                } else {
                    $4;
                }
            !gex;

        return $path;
    }

    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Router::Simple::Reversible - Router::Simple equipped with reverse routing

=head1 SYNOPSIS

    use Router::Simple::Reversible;

    my $router = Router::Simple::Reversible->new;

    # Same as Router::Simple
    $router->connect('/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'});

    $router->path_for({ controller => 'Blog', action => 'monthly' }, { year => 2015, month => 10 });
    # => '/blog/2015/10'

=head1 DESCRIPTION

Router::Simple::Reversible inherits L<< Router::Simple >>
and provides C<< path_for >> method which produces a string from
routing destination and path parameters given.

=head1 LICENSE

Copyright (C) motemen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=cut

