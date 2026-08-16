package POUA;

# A Fetch-shaped UA that dispatches into in-process PSGI apps instead of
# the network: the provider `ua` seam. Maps origin => app; get/post
# return POUA::Future whose ->get yields a POUA::Response with the
# Fetch::Response surface the provider code uses (status, json, content,
# header, is_success).

use 5.024;
use strict;
use warnings;
use File::Raw::JSON ();

sub new {
    my ($class, %args) = @_;
    return bless { map => $args{map} // {}, log => [] }, $class;
}

sub map_origin { $_[0]{map}{ $_[1] } = $_[2]; $_[0] }
sub log        { $_[0]{log} }

sub get  { my $self = shift; $self->request(GET  => @_) }
sub post { my $self = shift; $self->request(POST => @_) }

sub request {
    my ($self, $method, $url, %opts) = @_;
    push @{ $self->{log} }, [$method, $url];
    my ($origin, $path_query) = $url =~ m{\A(https?://[^/]+)(/.*|\z)}
        or die "POUA: unparsable url '$url'";
    my $app = $self->{map}{$origin}
        or die "POUA: no app mapped for origin '$origin'";
    $path_query = '/' unless length $path_query;
    my ($path, $query) = split /\?/, $path_query, 2;

    my $body = $opts{body} // '';
    open my $in, '<', \$body or die $!;
    my %env = (
        REQUEST_METHOD    => $method,
        PATH_INFO         => $path,
        QUERY_STRING      => $query // '',
        SERVER_NAME       => 'poua',
        SERVER_PORT       => 80,
        'psgi.version'    => [1, 1],
        'psgi.url_scheme' => ($origin =~ /\Ahttps/ ? 'https' : 'http'),
        'psgi.errors'     => \*STDERR,
        'psgi.input'      => $in,
        CONTENT_LENGTH    => length $body,
    );
    for my $h (keys %{ $opts{headers} // {} }) {
        (my $key = uc $h) =~ tr/-/_/;
        $key = $key eq 'CONTENT_TYPE' ? 'CONTENT_TYPE' : "HTTP_$key";
        $env{$key} = $opts{headers}{$h};
    }
    my $triplet = $app->(\%env);
    return POUA::Future->new(POUA::Response->new($triplet));
}

package POUA::Future;

sub new { bless { res => $_[1] }, $_[0] }
sub get { $_[0]{res} }
sub can { $_[1] eq 'get' ? \&get : $_[0]->SUPER::can($_[1]) }

package POUA::Response;

sub new {
    my ($class, $triplet) = @_;
    my %headers = @{ $triplet->[1] };
    my $body = join '', @{ $triplet->[2] };
    return bless {
        status  => $triplet->[0],
        headers => { map { lc $_ => $headers{$_} } keys %headers },
        body    => $body,
    }, $class;
}

sub status     { $_[0]{status} }
sub content    { $_[0]{body} }
sub header     { $_[0]{headers}{ lc $_[1] } }
sub is_success { $_[0]{status} >= 200 && $_[0]{status} < 300 }
sub json       { File::Raw::JSON::file_json_decode($_[0]{body}) }

1;
