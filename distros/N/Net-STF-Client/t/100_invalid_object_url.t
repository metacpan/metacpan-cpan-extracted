use strict;
use Test::More;
use_ok "Net::STF::Client";

{
    my $client = Net::STF::Client->new(
        username => "hoge",
        password => "fuga",
    );

    my %urls = (
        'only bucket name + no trailing slash' =>
            "http://stf.example.com/foo",
        'only bucket name' =>
            "http://stf.example.com/foo/",
        'only bucket name + multiple trailing slashes' =>
            "http://stf.example.com/foo//",
        'trailing period' =>
            "http://stf.example.com/foo/.",
        'multiple trailing period' =>
            "http://stf.example.com/foo/..",
        'trailing period + multiple trailing slashes' =>
            "http://stf.example.com/foo//.",
        'multiple trailing period + multiple trailing slashes' =>
            "http://stf.example.com/foo//..",
    );

    foreach my $method ( qw( put_object delete_object ) ) {
        foreach my $key (keys %urls) {
            my $url = $urls{$key};
            note "Trying $url ($method)";
            eval {
                $client->$method( $url );
            };
            my $e = $@;
            ok $e, "Invalid URL ($key) should die";
            like $e, qr/Invalid object URL/, "Error message matches";
        }
    }
}

done_testing;
