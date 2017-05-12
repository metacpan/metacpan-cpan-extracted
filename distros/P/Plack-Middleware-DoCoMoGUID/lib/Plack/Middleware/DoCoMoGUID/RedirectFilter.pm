package Plack::Middleware::DoCoMoGUID::RedirectFilter;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util;
use URI;

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    if ( $res->[0] == 301 || $res->[0] == 302 ) {
        my $location = Plack::Util::header_get($res->[1], 'location');
        my $uri = URI->new($location);

        # Is there any case to using not match host?
        if ( $uri->host eq ( $env->{HTTP_HOST} || $env->{SERVER_NAME} ) ) {
            my $params = $self->{params} || +{};
            $params->{guid} ||= 'ON';

            my %query_form = $uri->query_form;
            my %fill_param_of;
            for my $key ( keys %{ $params } ) {
                if ( ! defined $query_form{$key} ) {
                    $fill_param_of{$key} = 1;
                }
            }
            if ( keys %fill_param_of ) {
                my @args = map { ( $_ => $params->{$_} ) } keys %fill_param_of;
                push @args, $uri->query_form;
                $uri->query_form(@args);
                Plack::Util::header_set($res->[1], 'location', $uri->as_string);
            }
        }
    }

    return $res;
}

1;
__END__

=head1 NAME

Plack::Middleware::DoCoMoGUID::HTMLStickyQuery - added guid=ON to Location header when redirect.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $_[0]->{HTTP_USER_AGENT} =~ /DoCoMo/i } 'DoCoMoGUID::RedirectFilter';
    };

=head1 DESCRIPTION

Plack::Middleware::DoCoMoGUID::RedirectFilter append ?guid=on param to Location header when redirect.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

+<HTMLStickyQuery::DoCoMoGUID>, +<Plack::Middleware>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
