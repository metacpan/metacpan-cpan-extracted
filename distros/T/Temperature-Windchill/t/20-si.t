#!perl -T

use Test::More tests => 19;

use_ok('Temperature::Windchill', 'windchill_si');

# check a range of valid values
{
    my $wc = sub {
        return 0 + sprintf('%.1f' , windchill_si(@_))
    };
    my @valid = (
        # temperature, windspeed, windchill
        [   5,  20,   1.1 ],
        [   0,  20,  -5.2 ],
        [  -5,  20, -11.6 ],
        [ -10,  20, -17.9 ],
        [ -15,  20, -24.2 ],
        [ -20,  20, -30.5 ],
        [ -25,  20, -36.8 ],
        [ -30,  20, -43.1 ],
        [ -35,  20, -49.4 ],
        [ -40,  20, -55.7 ],
        [ -45,  20, -62.0 ],
        [ -10,   5, -12.9 ],
        [ -10,  25, -18.8 ],
        [ -10,  50, -21.8 ],
        [ -10,  75, -23.7 ],
        [ -10, 100, -25.1 ],
        [ -10, 125, -26.3 ],
        [ -10, 150, -27.3 ],
    );
    for (@valid) {
        my ($temp, $speed, $chill) = @$_;
        is($wc->($temp, $speed), $chill);
    }
}

