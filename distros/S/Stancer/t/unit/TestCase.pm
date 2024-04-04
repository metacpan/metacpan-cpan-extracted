package TestCase;

use 5.020;
use strict;
use warnings;
use base 'Exporter';

use Carp qw(croak);
use Cwd qw(cwd);
use JSON qw(decode_json);
use List::MoreUtils ();
use List::Util qw(shuffle);
use Log::Any::Test; # Loaded before to mock $log
use Log::Any qw($log);
use POSIX qw(floor);

## no critic (ProhibitAutomaticExportation, ProhibitPackageVars, RequireFinalReturn)
our @EXPORT = qw(
    cmp_deeply_json
    random_date
    random_string
    random_integer
    random_phone
    read_file
    bic_provider
    card_number_provider
    currencies_for_card_provider
    currencies_for_sepa_provider
    currencies_provider
    iban_provider
    ipv4_provider
    ipv6_provider
    valid_card_number_provider
    $mock_ua
    $mock_request
    $mock_response
    $true
    $false
    $log
);
our ($mock_ua, $mock_request, $mock_response);

our $false = 1 == 2;
our $true = !$false;
## use critic

sub cmp_deeply_json {
    my $object = shift;
    my $hash = shift;
    my $message = shift;

    cmp_deeply(decode_json($object->toJSON), $hash, $message);
}

sub random_date {
    my ($min, $max) = @_;
    my $year = random_integer($min, $max);
    my $month = random_integer(1, 12);

    my $day_max = 31;

    if ($month == 2) {
        $day_max = 27;
    } elsif (List::MoreUtils::any { $_ == $month } qw(4 6 9 11) ) {
        $day_max = 30;
    }

    my $day = random_integer(1, $day_max);

    return sprintf '%04d-%02d-%02d', $year, $month, $day;
}

sub random_string {
    my $length = shift;
    my @chars = ('a'..'z', 'A'..'Z', 0..9, '_');
    my $string = q//;

    ## no critic (PostfixControls)
    $string .= $chars[rand @chars] for 1..$length;
    ## use critic

    return $string;
}

sub random_integer {
    my ($min, $max) = @_;

    if (!defined $max) {
        $max = 0;
    }

    if ($min > $max) {
        ($min, $max) = ($max, $min);
    }

    return floor(rand($max - $min) + $min);
}

sub random_phone {
    # Simulate a french mobile phone number
    my $first = random_integer(6, 7);
    my $loop = 3;

    my $number = '+33' . $first;

    if ($first == 7) {
        my $tmp = random_integer(30, 99);

        $number .= '0' x (2 - length $tmp) . $tmp;
        $loop--;
    }

    for (0..$loop) {
        my $tmp = random_integer(0, 99);

        $number .= '0' x (2 - length $tmp) . $tmp;
    }

    return $number;
}

sub read_file {
    my ($path, %opts) = @_;

    local $/ = undef; ## no critic (ProhibitPunctuationVars)

    open my $fh, '<', cwd() . $path or croak 'Unable to open ' . $path;

    my $content = <$fh>;

    close $fh or croak 'Unable to close ' . $path;

    if (defined $opts{json} && $opts{json}) {
        return decode_json $content;
    }

    return $content;
}

sub bic_provider { # 9 BIC
    my @bics = ();

    # BIC list from https://github.com/gitpan/Business-SWIFT/blob/master/t/01-validate.t

    push @bics, 'DEUTDEFF';
    push @bics, 'DEUTDEFFXXX';
    push @bics, 'DEUTGBFFA23';
    push @bics, 'DEUTDEFF500';
    push @bics, 'UKCBUau102v';
    push @bics, 'UKIOLT2XXXX';
    push @bics, 'GBMCMRMRXXX';
    push @bics, 'gbtxus31xxx';
    push @bics, 'JUBIGB21XXX';

    @bics = shuffle(@bics);

    return @bics if wantarray; ## no critic (Community::Wantarray)
    return shift @bics;
}

sub card_number_provider { # 36 card numbers
    # Card number found on https://www.freeformatter.com/credit-card-number-generator-validator.html
    my @cards = ();

    # VISA
    push @cards, qw(
        4532160583905253
        4103344114503410
        4716929813250776300
    );

    # MasterCard
    push @cards, qw(
        5312580044202748
        2720995588028031
        5217849688268117
    );

    # American Express (AMEX)
    push @cards, qw(
        370301138747716
        340563568138644
        371461161518951
    );

    # Discover
    push @cards, qw(
        6011651456571367
        6011170656779399
        6011693048292929421
    );

    # JCB
    push @cards, qw(
        3532433013111566
        3544337258139297
        3535502591342895821
    );

    # Diners Club - North America
    push @cards, qw(
        5480649643931654
        5519243149714783
        5509141180527803
    );

    # Diners Club - Carte Blanche
    push @cards, qw(
        30267133988393
        30089013015810
        30109478108973
    );

    # Diners Club - International
    push @cards, qw(
        36052879958170
        36049904526204
        36768208048819
    );

    # Maestro
    push @cards, qw(
        5893433915020244
        6759761854174320
        6759998953884124
    );

    # Visa Electron
    push @cards, qw(
        4026291468019846
        4844059039871494
        4913054050962393
    );

    # InstaPayment
    push @cards, qw(
        6385037148943057
        6380659492219803
        6381454097795863
    );

    # Classic one
    push @cards, qw(
        4111111111111111
        4242424242424242
        4444333322221111
    );

    @cards = shuffle(@cards);

    return @cards if wantarray; ## no critic (Community::Wantarray)
    return shift @cards;
}

sub currencies_for_card_provider {
    return currencies_provider();
}

sub currencies_for_sepa_provider {
    my @currencies = qw(EUR);

    return @currencies if wantarray; ## no critic (Community::Wantarray)
    return shift @currencies;
}

sub currencies_provider {
    my @currencies = shuffle(qw(AUD CAD CHF DKK EUR GBP JPY NOK PLN SEK USD));

    return @currencies if wantarray; ## no critic (Community::Wantarray)
    return shift @currencies;
}

sub iban_provider { # 17 IBAN
    my @ibans = ();

    push @ibans, 'AT611904300234573201';
    push @ibans, 'BE62510007547061';
    push @ibans, 'CH2089144321842946678';
    push @ibans, 'DE89370400440532013000';
    push @ibans, 'EE38 2200 2210 2014 5685';
    push @ibans, 'ES07 0012 0345 0300 0006 7890';
    push @ibans, 'FI21 1234 5600 0007 85';
    push @ibans, 'FR14 2004 1010 0505 0001 3M02 606';
    push @ibans, 'GB33 BUKB 2020 1555 5555 55';
    push @ibans, 'IE29 AIBK 9311 5212 3456 78 ';
    push @ibans, 'LT121000011101001000';
    push @ibans, 'LU280019400644750000';
    push @ibans, 'IT02A0301926102000000490887';
    push @ibans, 'NL39 RABO 0300 0652 64';
    push @ibans, 'NO9386011117947 ';
    push @ibans, 'PT50000201231234567890154';
    push @ibans, 'SE3550000000054910000003';

    @ibans = shuffle(@ibans);

    return @ibans if wantarray; ## no critic (Community::Wantarray)
    return shift @ibans;
}

## no critic (ProhibitLongChainsOfMethodCalls ProhibitStringyEval RequireFinalReturn)

sub import {
    my ($this, @tags) = @_;

    $this->export_to_level(1, @tags);

    my @modules = qw(JSON Test::Most);

    foreach my $module (@modules) {
        eval "use $module"; ## no critic (ProhibitStringyEval RequireCheckingReturnValueOfEval)

        $module->export_to_level(1);
    }

    if (List::MoreUtils::any { $_ eq ':lwp' } @tags) { # Prevent collision with Test::Deep::any
        require Stancer::Config;
        require Test::MockObject;
        require Test::MockObject::Extends;

        my $config = Stancer::Config::init(['sprod_' . random_string(24), 'stest_' . random_string(24)]);

        $mock_request = Test::MockObject::Extends->new('HTTP::Request');
        $mock_request->fake_module('HTTP::Request', new => sub { $mock_request->{new_args} = [@_]; $mock_request });
        $mock_request->mock('-new_args', sub { delete $mock_request->{new_args} });
        $mock_request
            ->set_always('authorization_basic', q//)
            ->set_always('content', q//)
            ->set_always('decoded_content', q//)
            ->set_always('header', q//)
            ->mock(method => sub { $mock_request->{new_args}[1] })
            ->mock(url => sub { $mock_request->{new_args}[2] })
        ;

        $mock_ua = Test::MockObject::Extends->new('LWP::UserAgent');
        $mock_response = Test::MockObject::Extends->new('HTTP::Response');

        $mock_response
            ->set_always('code', 200)
            ->set_always('header', q//)
            ->set_always('content', q//)
            ->set_always('is_success', 1)
            ->mock(is_error => sub { !$mock_response->is_success })
        ;

        $mock_request->{_headers} = Test::MockObject::Extends->new('HTTP::Headers');
        $mock_response->{_headers} = Test::MockObject::Extends->new('HTTP::Headers');

        $mock_ua
            ->set_true('timeout')
            ->mock(request => sub { $mock_response })
            ->mock(called_count => sub {
                my ($self, $method) = @_;
                my $nb = 0;

                for my $called (reverse @{ $self->_calls() }) {
                    $nb++ if $called->[0] eq $method;
                }

                return $nb;
            })
            ->mock(clear => sub {
                my $self = shift;

                $self->Test::MockObject::clear(); # Call regular clear
                $mock_request->clear();
                $mock_response->clear();
                $log->clear();

                splice @{$mock_request->_calls}; # Force an empty list, I have a mysterious "content" call
            })
        ;

        $config->lwp($mock_ua);
    }
}

## use critic

sub ipv4_provider { # 7 addresses
    my @ips = ();

    push @ips, '212.27.48.10'; # www.free.fr

    push @ips, '216.58.206.238'; # www.google.com

    push @ips, '17.178.96.59'; # www.apple.com
    push @ips, '17.142.160.59'; # www.apple.com
    push @ips, '17.172.224.47'; # www.apple.com

    push @ips, '179.60.192.36'; # www.facebook.com

    push @ips, '198.41.0.4'; # a.root-servers.org

    @ips = shuffle(@ips);

    return @ips if wantarray; ## no critic (Community::Wantarray)
    return shift @ips;
}

sub ipv6_provider { # 9 addresses
    my @ips = ();

    push @ips, '2a01:0e0c:0001:0000:0000:0000:0000:0001'; # www.free.fr
    push @ips, '2a01:e0c:1:0:0:0:0:1'; # www.free.fr
    push @ips, '2a01:e0c:1::1'; # www.free.fr

    push @ips, '2a00:1450:4007:080f:0000:0000:0000:200e'; # www.google.com
    push @ips, '2a00:1450:4007:80f::200e'; # www.google.com

    push @ips, '2a03:2880:f11f:0083:face:b00c:0000:25de'; # www.facebook.com
    push @ips, '2a03:2880:f11f:83:face:b00c:0:25de'; # www.facebook.com

    push @ips, '2001:0503:ba3e:0000:0000:0000:0002:0030'; # a.root-servers.org
    push @ips, '2001:503:ba3e::2:30'; # a.root-servers.org

    @ips = shuffle(@ips);

    return @ips if wantarray; ## no critic (Community::Wantarray)
    return shift @ips;
}

sub valid_card_number_provider {
    my @cards = ();

    # USA
    push @cards, '4242424242424242';
    push @cards, '5555555555554444';

    # Europe
    push @cards, '4000000760000002';
    push @cards, '4000001240000000';
    push @cards, '4000004840000008';
    push @cards, '4000000400000008';
    push @cards, '4000000560000004';
    push @cards, '4000002080000001';
    push @cards, '4000002460000001';
    push @cards, '4000002500000003';
    push @cards, '4000002760000016';
    push @cards, '4000003720000005';
    push @cards, '4000003800000008';
    push @cards, '4000004420000006';
    push @cards, '4000005280000002';
    push @cards, '4000005780000007';
    push @cards, '4000006200000007';
    push @cards, '4000006430000009';
    push @cards, '4000007240000007';
    push @cards, '4000007520000008';
    push @cards, '4000007560000009';
    push @cards, '4000008260000000';

    # Asia / Pacific
    push @cards, '4000000360000006';
    push @cards, '4000001560000002';
    push @cards, '4000003440000004';
    push @cards, '4000003920000003';
    push @cards, '3530111333300000';
    push @cards, '4000007020000003';
    push @cards, '4000005540000008';

    @cards = shuffle(@cards);

    return @cards if wantarray; ## no critic (Community::Wantarray)
    return shift @cards;
}

1;
