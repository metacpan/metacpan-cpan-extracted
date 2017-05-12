use Test::Most tests => 35;

my @TYPES;

BEGIN {
    @TYPES = qw(
            SitemapURL
            SitemapUrlStore
            SitemapChangeFreq
            SitemapLastMod
            SitemapPriority
            XMLPrettyPrintValue
            XMLTwig
            SitemapPinger
        );
    use_ok( 'Search::Sitemap::Types', @TYPES );
};

use POSIX qw( strftime );
use DateTime;
use HTTP::Date ();
use HTTP::Response ();

for my $type ( @TYPES ) {
    ok my $code = __PACKAGE__->can($type), "$type() was exported";
}

my $_NOW = time();
my $_FN = __FILE__;
sub format_time($) { strftime( "%FT%T+00:00", gmtime( shift ) ) };
my $_formatted_NOW = format_time($_NOW);

my %tests = (
    SitemapLastMod => {
        Str => [
            [ '1997', '1997' ],
            [ '1997-07', '1997-07' ],
            [ '1997-07-16', '1997-07-16' ],
            [ '1997-07-16T19:20', '1997-07-16T19:20' ],
            [ '1997-07-16T19:20:30', '1997-07-16T19:20:30' ],
            [ '1997-07-16T19:20Z', '1997-07-16T19:20Z' ],
            [ '1997-07-16T19:20+01:00', '1997-07-16T19:20+01:00' ],
            [ '1997-07-16T19:20:30-01:00', '1997-07-16T19:20:30-01:00' ],
            [ '1997-07-16T19:20:30Z', '1997-07-16T19:20:30Z' ],
            [ '1997-07-16T19:20:30.45-01:00', '1997-07-16T19:20:30.45-01:00' ],
            [ '1997-07-16T19:20:30.45Z', '1997-07-16T19:20:30.45Z' ],
            [ 'now', $_formatted_NOW ],
            [ "$_NOW", $_formatted_NOW ],
        ],
        Num => [
            [ $_NOW, $_formatted_NOW ],
        ],
        DateTime => [
            map {
                my $tz = $_;
                my $dt2coerce = DateTime->from_epoch( epoch => $_NOW, time_zone => $tz);
                my ($datetime, $tzoff) = $dt2coerce->strftime("%FT%T", "%z");
                $tzoff = $tzoff ?
                    substr($tzoff, 0, 3) . ':'. ( substr($tzoff, 3, 2) || '00' )
                    :
                    '+00:00';
                [ $dt2coerce, "$datetime$tzoff" ]
            } qw(
                Asia/Taipei
                America/Vancouver
                Atlantic/Azores
                Europe/London
                Europe/Warsaw
                Pacific/Chatham
                -071234
            ), 
        ],
        'HTTP::Response' => [
            [
                HTTP::Response->new(200, "OK",
                    [ "Last-Modified" => HTTP::Date::time2str($_NOW) ]
                ),
                $_formatted_NOW,
            ],
            [
                HTTP::Response->new(200, "OK",
                    [ "Client-Date" => $_NOW ]
                ),
                $_formatted_NOW,
            ]
        ],
    }, 
);
eval "use File::stat";
if ( $@ ) {
    SKIP: {
        skip "File::stat is not installed", 1;
    };
} else {
    eval <<'EOE';
    $tests{SitemapLastMod}->{'File::stat'} = [
            map {
                my $fn = $_;
                my $st = File::stat::stat($fn);

                [ $st, format_time($st->mtime) ]
            } ( $_FN )
        ];
EOE
}

eval "use Path::Class::File";
if ( $@ ) {
    SKIP: {
        skip "Path::Class::File is not installed", 1;
    };
} else {
    eval <<'EOE';
    $tests{SitemapLastMod}->{'Path::Class::File'} = [
            map {
                my $fn = $_;
                my $file = Path::Class::File->new($fn);

                [ $file, format_time($file->stat->mtime) ]
            } ( $_FN )
        ];
EOE
}

for my $type ( sort keys %tests ) {
    ok my $code = __PACKAGE__->can("to_$type"), "to_$type() was exported";
    for my $coerce_from ( sort keys %{ $tests{$type} } ) {
        for my $test ( @{ $tests{$type}->{$coerce_from} } ) {
            is $code->( $test->[0] ), $test->[1],
                "Coercion from $coerce_from gives correct result $test->[1]";
        }
    }
}
