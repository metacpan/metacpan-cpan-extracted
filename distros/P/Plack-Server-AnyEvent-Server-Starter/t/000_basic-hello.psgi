use AnyEvent;
my $handler = sub {
    return sub {
        my $start_response = shift;
        warn "will wait 3 seconds before returning...";
        my $w; $w = AE::timer 3, 0, sub {
            $start_response->( [ 200, [ "Content-Type" => "text/plain", "Content-Length" => 5 ], [ "hello" ] ] );
            undef $w;
        };
    }
};
