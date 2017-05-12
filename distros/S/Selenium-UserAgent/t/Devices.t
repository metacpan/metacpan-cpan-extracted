use JSON;
use LWP::UserAgent;
use Net::SSL;
use Selenium::UserAgent;
use Test::Spec;

my $ua = LWP::UserAgent->new;
my $devices_url = 'https://code.cdn.mozilla.net/devices/devices.json';
my $res = $ua->get($devices_url);

plan skip_all => 'Cannot get device source document'
  unless $res->code == 200;

my $devices = decode_json($res->content);

describe 'Device information' => sub {
    my $expected_phones = [ @{ $devices->{phones} }, @{ $devices->{tablets} }];
    my $expected_tablets = $devices->{tablets};

    my $phones = {
        iphone4 => 'Apple iPhone 4',
        iphone5 => 'Apple iPhone 5',
        iphone6 => 'Apple iPhone 6',
        iphone6plus => 'Apple iPhone 6 Plus',
        galaxy_s3 => 'Samsung Galaxy S3',
        galaxy_s4 => 'Samsung Galaxy S4',
        galaxy_s5 => 'Samsung Galaxy S5',
        nexus4 => 'Google Nexus 4',

        # for this tablet, the height/width is provided in portrait
        # mode
        galaxy_note3 => 'Samsung Galaxy Note 3'
    };

    my $actual = get_actual_phones();

    describe 'phones' => sub {

        foreach my $name (keys %$phones) {
            my $converted_name = $phones->{$name};
            my @details = grep { $_->{name} eq $converted_name } @$expected_phones;
            my $expected = $details[0];

            it 'should match width for ' . $name => sub {
                is($actual->{$name}->{portrait}->{width}, $expected->{width});
            };

            it 'should match height for ' . $name => sub {
                is($actual->{$name}->{portrait}->{height}, $expected->{height});
            };

            it 'should match pixel ratio for ' . $name => sub {
                is($actual->{$name}->{pixel_ratio}, $expected->{pixelRatio});
            };
        }
    };

    describe 'tablets' => sub {
        # the default height/width for (some) tablets is given in
        # landscape mode in Mozilla's devices.json
        my $tablets = {
            ipad_mini => 'Apple iPad Mini',
            ipad => 'Apple iPad',
            nexus10 => 'Google Nexus 10'
        };

        foreach my $name (keys %$tablets) {
            my $converted_name = $tablets->{$name};
            my @details = grep { $_->{name} eq $converted_name } @$expected_tablets;
            my $expected = $details[0];

            it 'should match width for ' . $name => sub {
                is($actual->{$name}->{landscape}->{width}, $expected->{width});
            };

            it 'should match height for ' . $name => sub {
                is($actual->{$name}->{landscape}->{height}, $expected->{height});
            };

            it 'should match pixel ratio for ' . $name => sub {
                is($actual->{$name}->{pixel_ratio}, $expected->{pixelRatio});
            };
        }
    };
};

sub get_actual_phones {
    return Selenium::UserAgent->new(
        agent => 'iphone', browserName => 'chrome'
    )->_specs;
}

runtests;
