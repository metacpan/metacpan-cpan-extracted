package NephiaX::Auth::Twitter;
use strict;
use warnings;
use Nephia;
use Net::Twitter::Lite::WithAPIv1_1;
use URI;
use Carp;

our $VERSION = 0.01;
my $TWITTER;

app {
    my $c = shift;
    $TWITTER ||= Net::Twitter::Lite::WithAPIv1_1->new(%{$c->{config}});
    return [303, ['Location' => $TWITTER->get_authentication_url(callback => req->uri->as_string)], []] unless param('oauth_token');
    my $twitter_id = _verify_token(param('oauth_token'), param('oauth_verifier')) or return [403,[],[$!]];
    $c->{config}{handler}->($c, $twitter_id);
};

sub _verify_token {
    my ($token, $verifier) = @_;
    my $twitter_id = eval { $TWITTER->request_access_token( 
        token        => $token, 
        token_secret => $TWITTER->{consumer_secret}, 
        verifier     => $verifier 
    ) };
    if ($@) {
        croak "verify failure: $@";
        return;
    }
    return $twitter_id;
}

1;

=encoding utf-8

=head1 NAME

NephiaX::Auth::Twitter - Twitter Authorizer

=head1 DESCRIPTION

An web application that powered by Nephia.

=head1 SYNOPSIS

    use Plack::Builder;
    use NephiaX::Auth::Twitter;
    builder {
        mount '/auth' => NephiaX::Auth::Twitter->run(
            consumer_key    => 'your consumer key',
            consumer_secret => 'your consumer secret',
            handler => sub {
                my ($c, $twitter_id) = @_;
                ### You have to imprement logic that stores twitter_id into your db and/or cookie.
                [302, [Location => '/userarea/somepage'], []];
            },
        );
        mount '/' => Your::App->run;
    };

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Nephia>

=cut

