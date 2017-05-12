package HTTP::Client;
use strict;
use warnings;
use base qw(Object);
use SHashtable;
use HTTP::DOM;
use AnyEvent::HTTP;
use AnyEvent;

sub new {
    my $pkg = shift;
    return bless {}, $pkg;
}

=head1 web_get
    my $url = 'http://www.baidu.com/';
    my $content = web_get($url);
    say "Scalar: " . $content->xml;

    my @urls = qw(http://www.baidu.com http://www.sina.com.cn);
    web_get(@urls, sub {
    #web_get($url, sub {
        my ($content, $code, $res_headers) = @_;   # $res_headers 是 SHashtable 类型
        say "HTTP: " . $code;
        say "Body: " . $content->text;
        $res_headers->each(
            sub {
                my ($header_k, $header_v) = @_;
                say "$header_k: $header_v";
            }
        );
    });
=cut

sub web_get {
    my $cb;
    if ( ref( $_[-1] ) eq 'CODE' ) {
        $cb = pop @_;
    }
    my @urls = @_;
    my $content;
    my $w = AnyEvent->condvar;
    for my $url (@urls) {
        $w->begin;
        http_get $url, sub {
            my ( $data, $headers ) = @_;
            my $code        = delete $headers->{Status};
            my $res_headers = SHashtable->new(%$headers);
            $content        = HTTP::DOM->new($data);
            $w->end;
            if ( defined $cb ) {
                $cb->( $content, $code, $res_headers );
            };
        };
    }
    $w->recv;
    if ( !defined $cb ) {
        return $content;
    }
}

1;
