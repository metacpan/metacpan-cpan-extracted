package POTest;

# In-process browser: drives the client app and the MockIdP as two PSGI
# apps, carrying cookies by hand and following the cross-app redirects
# of an OAuth2 login.

use 5.024;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(hit run_login client_origin idp_origin);

sub client_origin { 'http://app.local' }
sub idp_origin    { $MockIdP::ISSUER }

# hit($app, $method, $path_query, %opts): one PSGI request. %opts:
# cookies => \%jar (updated from Set-Cookie), headers, body, type.
sub hit {
    my ($app, $method, $path_query, %opts) = @_;
    my ($path, $query) = split /\?/, $path_query, 2;
    my $body = $opts{body} // '';
    open my $in, '<', \$body or die $!;
    my %env = (
        REQUEST_METHOD    => $method,
        PATH_INFO         => $path,
        QUERY_STRING      => $query // '',
        SERVER_NAME       => 'potest',
        SERVER_PORT       => 80,
        'psgi.version'    => [1, 1],
        'psgi.url_scheme' => 'http',
        'psgi.errors'     => \*STDERR,
        'psgi.input'      => $in,
        CONTENT_LENGTH    => length $body,
        (defined $opts{type} ? (CONTENT_TYPE => $opts{type}) : ()),
        %{ $opts{env} // {} },
    );
    if (my $jar = $opts{cookies}) {
        $env{HTTP_COOKIE} = join '; ',
            map { "$_=$jar->{$_}" } sort keys %$jar
            if %$jar;
    }
    for my $h (keys %{ $opts{headers} // {} }) {
        (my $key = uc $h) =~ tr/-/_/;
        $env{"HTTP_$key"} = $opts{headers}{$h};
    }
    my $res = $app->(\%env);
    my ($status, $harr, $barr) = @$res;
    my (%headers, @set);
    for (my $i = 0; $i < @$harr; $i += 2) {
        if (lc $harr->[$i] eq 'set-cookie') { push @set, $harr->[$i + 1] }
        else { $headers{ lc $harr->[$i] } = $harr->[$i + 1] }
    }
    if (my $jar = $opts{cookies}) {
        for my $sc (@set) {
            my ($pair) = split /;/, $sc, 2;
            my ($name, $value) = split /=/, $pair, 2;
            if (defined $value && length $value) { $jar->{$name} = $value }
            else { delete $jar->{$name} }
        }
    }
    return ($status, \%headers, join('', @{ $barr // [] }), \@set);
}

# The whole login dance: start on the client app, bounce through the
# IdP's authorize, land on the callback. Returns the final client
# response. %opts: start (initiation path), cookies (jar hashref),
# mangle_callback => sub { $path_query } to corrupt the return trip.
sub run_login {
    my ($client_app, $idp_app, %opts) = @_;
    my $jar   = $opts{cookies} // {};
    my $start = $opts{start} // '/auth/idp';

    my ($status, $headers) = hit($client_app, GET => $start,
                                 cookies => $jar);
    return (initiation => $status) unless $status == 302;
    my $auth_url = $headers->{location};
    my $origin = idp_origin();
    return (initiation_location => $auth_url)
        unless $auth_url =~ s/\A\Q$origin\E//;

    ($status, $headers) = hit($idp_app, GET => $auth_url);
    return (authorize => $status) unless $status == 302;
    my $cb_url = $headers->{location};
    my $client = client_origin();
    return (authorize_location => $cb_url)
        unless $cb_url =~ s/\A\Q$client\E//;

    $cb_url = $opts{mangle_callback}->($cb_url)
        if $opts{mangle_callback};

    return hit($client_app, GET => $cb_url, cookies => $jar);
}

1;
