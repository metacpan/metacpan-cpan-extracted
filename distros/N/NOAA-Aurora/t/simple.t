use Test2::V0;
use File::Temp;

use HTTP::Response;
use LWP::UserAgent;
use NOAA::Aurora;

my $aurora = NOAA::Aurora->new(swpc => 'https://services.swpc.noaa.gov');

my @responses = do {
    local $/ = undef;   # Slurp each section
    split /^__EOF__$/m, <DATA>;
};

my $base    = 'https://services.swpc.noaa.gov';
my $content = $responses[0];
my $request = "";
my $counter = 0;
my $mock = Test2::Mock->new(
    class    => 'LWP::UserAgent',
    track    => 1,
    override => [
        get => sub {
            $request = $_[1];
            $counter++;
            return HTTP::Response->new(200, 'SUCCESS', undef, $content);
        }
    ]
);

subtest 'constructor' => sub {
    is($aurora->{cache}, 120, 'default cache');
    $aurora = NOAA::Aurora->new(cache => 60);
    is($aurora->{cache}, 60, 'set cache');
};

subtest 'get_image' => sub {
    $content = 'IMGDATA1';
    my $url = "$base/images/animations/ovation";
    my $img = $aurora->get_image();
    is($request, "$url/north/latest.jpg", 'Request north default');
    is($img, $content, 'Got content');
    $content = 'IMGDATA2';
    $img = $aurora->get_image();
    is($img, 'IMGDATA1', 'Cached content');
    $img = $aurora->get_image(hemisphere => 'south');
    is($request, "$url/south/latest.jpg", 'Request south');
    is($img, $content, 'Got fresh content');
    $img = $aurora->get_image(hem => 's');
    is($request, "$url/south/latest.jpg", 'Still south');

    $aurora = NOAA::Aurora->new(cache => 0);
    $img = $aurora->get_image();
    is($img, $content, 'New content');
    $content = 'IMGDATA3';
    $img = $aurora->get_image();
    is($img, $content, 'No cache');

    # Try output to temp file
    my $tmp = File::Temp->new();
    my $fname = $tmp->filename;
    close($tmp); # Just need the name, method opens it

    $aurora->get_image(output => $fname);
    ok(-e $fname, 'File created');

    # Read back
    open(my $fh, '<', $fname);
    my $data = do { local $/; <$fh> };
    close($fh);
    is($data, $content, 'File content correct');
    unlink $fname;
};

subtest 'get_probability' => sub {
    $content = '{"coordinates":[[0,0,50], [10,15,60]]}';
    $aurora = NOAA::Aurora->new();

    my $cnt = $counter;
    my $prob = $aurora->get_probability();
    is($prob, '{"coordinates":[[0,0,50], [10,15,60]]}', 'Got JSON string');
    is($counter, $cnt+1, 'Fetched fresh results');

    $prob = $aurora->get_probability(hash => 1);
    is($prob, {0=>{0=>50},10=>{15=>60}}, 'Got Hash');

    my $val = $aurora->get_probability(lat => 0, lon => 0);
    is($val, 50, 'Got specific value');

    $val = $aurora->get_probability(lat => 15, lon => 10);
    is($val, 60, 'Got another specific value');

    $val = $aurora->get_probability(lat => 15.4, lon => 9.8);
    is($val, 60, 'Float is OK');

    $val = $aurora->get_probability(lat => 50, lon => 50);
    is($val, 0, 'Got zero for unknown location');

    is($counter, $cnt+1, 'No further fetches');
};

subtest 'get_forecast' => sub {
    $content = $responses[0];
    my $forecast = $aurora->get_forecast(format => 'text');
    is($request, "$base/text/3-day-forecast.txt", '3 day forecast');
    is($forecast, $responses[0], 'Raw content as expected');
    
    $forecast = $aurora->get_forecast();
    is($request, "$base/text/3-day-forecast.txt", '3 day forecast');
    ok(@$forecast > 0, 'Got entries');
    is(
        $forecast,
        [{
                'time' => '1751500800',
                'kp'   => '4.67'
            },
            {
                'time' => '1751511600',
                'kp'   => '4.67'
            },
            {
                'time' => '1751522400',
                'kp'   => '4.00'
            },
            {
                'time' => '1751533200',
                'kp'   => '2.67'
            },
            {
                'kp'   => '2.33',
                'time' => '1751544000'
            },
            {
                'time' => '1751554800',
                'kp'   => '2.67'
            },
            {
                'time' => '1751565600',
                'kp'   => '3.00'
            },
            {
                'time' => '1751576400',
                'kp'   => '3.67'
            },
            {
                'time' => '1751587200',
                'kp'   => '2.67'
            },
            {
                'time' => '1751598000',
                'kp'   => '4.00'
            },
            {
                'time' => '1751608800',
                'kp'   => '3.00'
            },
            {
                'time' => '1751619600',
                'kp'   => '2.67'
            },
            {
                'time' => '1751630400',
                'kp'   => '1.67'
            },
            {
                'time' => '1751641200',
                'kp'   => '1.67'
            },
            {
                'time' => '1751652000',
                'kp'   => '2.00'
            },
            {
                'kp'   => '2.67',
                'time' => '1751662800'
            },
            {
                'time' => '1751673600',
                'kp'   => '3.00'
            },
            {
                'kp'   => '2.67',
                'time' => '1751684400'
            },
            {
                'time' => '1751695200',
                'kp'   => '2.33'
            },
            {
                'kp'   => '2.00',
                'time' => '1751706000'
            },
            {
                'kp'   => '2.33',
                'time' => '1751716800'
            },
            {
                'time' => '1751727600',
                'kp'   => '2.33'
            },
            {
                'time' => '1751738400',
                'kp'   => '2.33'
            },
            {
                'time' => '1751749200',
                'kp'   => '2.67'
            }
        ],
        'Forecast correct'
    );

    $content = $responses[2];
    $aurora = NOAA::Aurora->new(date_format => 'rfc');
    $forecast = $aurora->get_forecast();
    is(
        $forecast,
        [{
                'time' => '2024-12-31 00:00:00Z',
                'kp'   => '0.33'
            },
            {
                'time' => '2024-12-31 03:00:00Z',
                'kp'   => '0.67'
            },
            {
                'time' => '2024-12-31 06:00:00Z',
                'kp'   => '2.33'
            },
            {
                'kp'   => '1.33',
                'time' => '2024-12-31 09:00:00Z'
            },
            {
                'time' => '2024-12-31 12:00:00Z',
                'kp'   => '5.00'
            },
            {
                'kp'   => '6.67',
                'time' => '2024-12-31 15:00:00Z'
            },
            {
                'time' => '2024-12-31 18:00:00Z',
                'kp'   => '5.33'
            },
            {
                'time' => '2024-12-31 21:00:00Z',
                'kp'   => '5.00'
            },
            {
                'kp'   => '5.00',
                'time' => '2025-01-01 00:00:00Z'
            },
            {
                'time' => '2025-01-01 03:00:00Z',
                'kp'   => '3.33'
            },
            {
                'time' => '2025-01-01 06:00:00Z',
                'kp'   => '4.33'
            },
            {
                'kp'   => '3.67',
                'time' => '2025-01-01 09:00:00Z'
            },
            {
                'kp'   => '2.67',
                'time' => '2025-01-01 12:00:00Z'
            },
            {
                'kp'   => '2.33',
                'time' => '2025-01-01 15:00:00Z'
            },
            {
                'kp'   => '2.00',
                'time' => '2025-01-01 18:00:00Z'
            },
            {
                'time' => '2025-01-01 21:00:00Z',
                'kp'   => '3.00'
            },
            {
                'kp'   => '2.67',
                'time' => '2025-01-02 00:00:00Z'
            },
            {
                'kp'   => '2.00',
                'time' => '2025-01-02 03:00:00Z'
            },
            {
                'time' => '2025-01-02 06:00:00Z',
                'kp'   => '2.00'
            },
            {
                'kp'   => '2.00',
                'time' => '2025-01-02 09:00:00Z'
            },
            {
                'time' => '2025-01-02 12:00:00Z',
                'kp'   => '2.00'
            },
            {
                'kp'   => '2.00',
                'time' => '2025-01-02 15:00:00Z'
            },
            {
                'time' => '2025-01-02 18:00:00Z',
                'kp'   => '2.00'
            },
            {
                'kp'   => '2.33',
                'time' => '2025-01-02 21:00:00Z'
            }
        ],
        'Correct forecast with RFC times'
    );
};

subtest 'get_outlook' => sub {
    $content = $responses[1];

    my $outlook = $aurora->get_outlook(format => 'text');
    is($request, "$base/text/27-day-outlook.txt", '27 day outlook');
    is($outlook, $responses[1],                   'Content as expected');

    $aurora = NOAA::Aurora->new();
    $outlook = $aurora->get_outlook();
    is(
        $outlook,
        [{
                'kp'   => '5',
                'flux' => '170',
                'ap'   => '20',
                'time' => 1742774400
            },
            {
                'time' => 1742860800,
                'ap'   => '30',
                'flux' => '170',
                'kp'   => '6'
            },
            {
                'time' => 1742947200,
                'ap'   => '20',
                'flux' => '165',
                'kp'   => '5'
            },
            {
                'time' => 1743033600,
                'ap'   => '15',
                'flux' => '160',
                'kp'   => '4'
            },
            {
                'kp'   => '4',
                'flux' => '160',
                'ap'   => '12',
                'time' => 1743120000
            },
            {
                'time' => 1743206400,
                'ap'   => '8',
                'flux' => '160',
                'kp'   => '3'
            },
            {
                'time' => 1743292800,
                'ap'   => '5',
                'flux' => '165',
                'kp'   => '2'
            },
            {
                'time' => 1743379200,
                'ap'   => '5',
                'flux' => '165',
                'kp'   => '2'
            },
            {
                'flux' => '170',
                'kp'   => '2',
                'time' => 1743465600,
                'ap'   => '5'
            },
            {
                'flux' => '170',
                'kp'   => '2',
                'time' => 1743552000,
                'ap'   => '5'
            },
            {
                'flux' => '175',
                'kp'   => '3',
                'time' => 1743638400,
                'ap'   => '10'
            },
            {
                'kp'   => '5',
                'flux' => '180',
                'ap'   => '20',
                'time' => 1743724800
            },
            {
                'kp'   => '6',
                'flux' => '180',
                'ap'   => '35',
                'time' => 1743811200
            },
            {
                'kp'   => '3',
                'flux' => '180',
                'ap'   => '10',
                'time' => 1743897600
            },
            {
                'ap'   => '12',
                'time' => 1743984000,
                'kp'   => '4',
                'flux' => '180'
            },
            {
                'ap'   => '30',
                'time' => 1744070400,
                'kp'   => '5',
                'flux' => '180'
            },
            {
                'time' => 1744156800,
                'ap'   => '40',
                'flux' => '185',
                'kp'   => '6'
            },
            {
                'ap'   => '25',
                'time' => 1744243200,
                'kp'   => '5',
                'flux' => '185'
            },
            {
                'time' => 1744329600,
                'ap'   => '18',
                'flux' => '185',
                'kp'   => '5'
            },
            {
                'kp'   => '3',
                'flux' => '180',
                'ap'   => '10',
                'time' => 1744416000
            },
            {
                'flux' => '175',
                'kp'   => '5',
                'time' => 1744502400,
                'ap'   => '15'
            },
            {
                'ap'   => '12',
                'time' => 1744588800,
                'kp'   => '4',
                'flux' => '170'
            },
            {
                'kp'   => '3',
                'flux' => '170',
                'ap'   => '8',
                'time' => 1744675200
            },
            {
                'kp'   => '2',
                'flux' => '165',
                'ap'   => '5',
                'time' => 1744761600
            },
            {
                'kp'   => '3',
                'flux' => '160',
                'ap'   => '10',
                'time' => 1744848000
            },
            {
                'time' => 1744934400,
                'ap'   => '12',
                'flux' => '160',
                'kp'   => '4'
            },
            {
                'kp'   => '3',
                'flux' => '160',
                'ap'   => '8',
                'time' => 1745020800
            }
        ],
        'Corrent outlook entries'
    );

    $aurora = NOAA::Aurora->new(date_format => 'iso');
    my $iso_o = $aurora->get_outlook(
        format => 'none'
    );
    like(
        $iso_o->[0],
        {
            'kp'   => '5',
            'flux' => '170',
            'ap'   => '20',
            'time' => '2025-03-24T00:00:00Z'
        },
        'Got ISO time match'
    );

};

subtest 'kp_to_g' => sub {
    my @test = qw/4 5 6 7 7.5 8 9/;
    my @exp  = qw/0 G1 G2 G3 G4 G4 G5/;
    is(NOAA::Aurora::kp_to_g($test[$_]), $exp[$_], 'G as expected') for 0..6;
};

done_testing;

__DATA__
:Product: 3-Day Forecast
:Issued: 2025 Jul 03 0030 UTC
# Prepared by the U.S. Dept. of Commerce, NOAA, Space Weather Prediction Center
#
A. NOAA Geomagnetic Activity Observation and Forecast

The greatest observed 3 hr Kp over the past 24 hours was 2 (below NOAA
Scale levels).
The greatest expected 3 hr Kp for Jul 03-Jul 05 2025 is 4.67 (NOAA Scale
G1).

NOAA Kp index breakdown Jul 03-Jul 05 2025

             Jul 03       Jul 04       Jul 05
00-03UT       4.67 (G1)    2.67         3.00     
03-06UT       4.67 (G1)    4.00         2.67     
06-09UT       4.00         3.00         2.33     
09-12UT       2.67         2.67         2.00     
12-15UT       2.33         1.67         2.33     
15-18UT       2.67         1.67         2.33     
18-21UT       3.00         2.00         2.33     
21-00UT       3.67         2.67         2.67     

Rationale: G1 (Minor) geomagnetic storm levels are likely on 03 Jul due
to the arrival of the 28 Jun CME.

B. NOAA Solar Radiation Activity Observation and Forecast

Solar radiation, as observed by NOAA GOES-18 over the past 24 hours, was
below S-scale storm level thresholds.

Solar Radiation Storm Forecast for Jul 03-Jul 05 2025

              Jul 03  Jul 04  Jul 05
S1 or greater    1%      1%      1%

Rationale: No S1 (Minor) or greater solar radiation storms are expected.
No significant active region activity favorable for radiation storm
production is forecast.

C. NOAA Radio Blackout Activity and Forecast

No radio blackouts were observed over the past 24 hours.

Radio Blackout Forecast for Jul 03-Jul 05 2025

              Jul 03        Jul 04        Jul 05
R1-R2           15%           15%           15%
R3 or greater    1%            1%            1%

Rationale: A slight chance for R1-R2 (Minor-Moderate) radio blackouts
due to isolated M-class flare activity will persist through 05 July.
__EOF__
:Product: 27-day Space Weather Outlook Table 27DO.txt
:Issued: 2025 Mar 24 0202 UTC
# Prepared by the US Dept. of Commerce, NOAA, Space Weather Prediction Center
# Product description and SWPC contact on the Web
# https://www.swpc.noaa.gov/content/subscription-services
#
#      27-day Space Weather Outlook Table
#                Issued 2025-03-24
#
#   UTC      Radio Flux   Planetary   Largest
#  Date       10.7 cm      A Index    Kp Index
2025 Mar 24     170          20          5
2025 Mar 25     170          30          6
2025 Mar 26     165          20          5
2025 Mar 27     160          15          4
2025 Mar 28     160          12          4
2025 Mar 29     160           8          3
2025 Mar 30     165           5          2
2025 Mar 31     165           5          2
2025 Apr 01     170           5          2
2025 Apr 02     170           5          2
2025 Apr 03     175          10          3
2025 Apr 04     180          20          5
2025 Apr 05     180          35          6
2025 Apr 06     180          10          3
2025 Apr 07     180          12          4
2025 Apr 08     180          30          5
2025 Apr 09     185          40          6
2025 Apr 10     185          25          5
2025 Apr 11     185          18          5
2025 Apr 12     180          10          3
2025 Apr 13     175          15          5
2025 Apr 14     170          12          4
2025 Apr 15     170           8          3
2025 Apr 16     165           5          2
2025 Apr 17     160          10          3
2025 Apr 18     160          12          4
2025 Apr 19     160           8          3
__EOF__
:Product: 3-Day Forecast
:Issued: 2024 Dec 31 1230 UTC
# Prepared by the U.S. Dept. of Commerce, NOAA, Space Weather Prediction Center
#
A. NOAA Geomagnetic Activity Observation and Forecast

The greatest observed 3 hr Kp over the past 24 hours was 2 (below NOAA
Scale levels).
The greatest expected 3 hr Kp for Dec 31-Jan 02 2025 is 6.67 (NOAA Scale
G3).

NOAA Kp index breakdown Dec 31-Jan 02 2025

             Dec 31       Jan 01       Jan 02
00-03UT       0.33         5.00 (G1)    2.67     
03-06UT       0.67         3.33         2.00     
06-09UT       2.33         4.33         2.00     
09-12UT       1.33         3.67         2.00     
12-15UT       5.00 (G1)    2.67         2.00     
15-18UT       6.67 (G3)    2.33         2.00     
18-21UT       5.33 (G1)    2.00         2.00     
21-00UT       5.00 (G1)    3.00         2.33     

Rationale: Isolated periods of G3 (Strong) geomagnetic storming are
likely by mid to late UTC day on 31 Dec due to CME effects from a
partial-halo event from 29 Dec. Lingering G1 (Minor) geomagnetic
storming is likely, with a chance for G2 (Moderate) levels, on 01 Jan
with the arrival of the second CME, also from 29 Dec.

B. NOAA Solar Radiation Activity Observation and Forecast

Solar radiation, as observed by NOAA GOES-18 over the past 24 hours, was
below S-scale storm level thresholds.

Solar Radiation Storm Forecast for Dec 31-Jan 02 2025

              Dec 31  Jan 01  Jan 02
S1 or greater   20%     20%     20%

Rationale: A slight chance for an S1 (Minor) solar radiation storm
event will persist through 02 Jan given the current total disk
potential.

C. NOAA Radio Blackout Activity and Forecast

Radio blackouts reaching the R2 levels were observed over the past 24
hours. The largest was at Dec 30 2024 1654 UTC.

Radio Blackout Forecast for Dec 31-Jan 02 2025

              Dec 31        Jan 01        Jan 02
R1-R2           80%           80%           80%
R3 or greater   25%           25%           25%

Rationale: M-class flares are expected (R1-R2/Minor-Moderate), with a
chance for an isolated X-class flares (R3/Strong) through 02 Jan,
primarily due to the flare potential of Region 3936.
__EOF__
