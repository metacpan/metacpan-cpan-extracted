package Test::Class::Date::Holidays;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More; # done_testing
use Test::Fatal qw(dies_ok);
use Env qw($TEST_VERBOSE);

#run prior and once per suite
sub startup : Test(startup => 1) {

    # Testing compilation of component
    use_ok('Date::Holidays');
}

sub constructor : Test(5) {

    # Constructor requires country code so this test relies on
    # Date::Holidays::DK
    SKIP: {
        eval { require Date::Holidays::DK };
        skip "Date::Holidays::DK not installed", 5 if $@;

        ok( my $dh = Date::Holidays->new( countrycode => 'DK', nocheck => 1 ) );

        isa_ok( $dh, 'Date::Holidays', 'checking wrapper object' );

        can_ok( $dh, qw(new), 'new' );

        can_ok( $dh, qw(holidays), 'holidays' );

        can_ok( $dh, qw(is_holiday), 'is_holiday' );
    }
}


sub test_at : Test(5) {
    SKIP: {
        eval { require Date::Holidays::AT };
        skip "Date::Holidays::AT not installed", 5 if $@;

        ok(! Date::Holidays::AT->can('is_holiday'));
        can_ok('Date::Holidays::AT', qw(holidays));

        ok( my $dh = Date::Holidays->new( countrycode => 'at' ),
            'Testing Date::Holidays::AT' );

        ok( $dh->holidays( year => 2017 ),
            'Testing holidays with argument for Date::Holidays::AT' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'at' ],
        );

        ok( $holidays_hashref->{'at'},
            'Checking for Austrian first day of year' );
    }
}

sub test_au : Test(7) {
    SKIP: {
        eval { require Date::Holidays::AU };
        skip "Date::Holidays::AU not installed", 7 if $@;

        can_ok('Date::Holidays::AU', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'au' ),
            'Testing Date::Holidays::AU' );

        ok( $dh->holidays( year => 2006 ),
            'Testing holidays for Date::Holidays::AU' );

        ok( $dh->holidays(
                year  => 2006,
                state => 'VIC',
            ),
            'Testing holidays for Date::Holidays::AU'
        );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'au' ],
        );

        ok( $holidays_hashref->{'au'},
            'Checking for Australian christmas' );

        ok(my $au = Date::Holidays->new(countrycode => 'au'));

        ok($au->is_holiday(
            day   => 9,
            month => 3,
            year  => 2015,
            state => 'TAS',
        ), 'Asserting 8 hour day in Tasmania, Australia');
    }
}

sub test_aw : Test(7) {
    SKIP: {
        eval { require Date::Holidays::AW };
        skip "Date::Holidays::AW not installed", 7 if $@;

        can_ok('Date::Holidays::AW', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'aw' ),
            'Testing Date::Holidays::AW' );

        ok( $dh->holidays( year => 2020 ),
            'Testing holidays for Date::Holidays::AW' );

        ok($dh->is_holiday(
            year   => 2020,
            month  => 1,
            day    => 1,
        ), 'Testing Aruban national holiday');

        ok(! $dh->is_holiday(
            year   => 2020,
            month  => 1,
            day    => 15,
        ), 'Testing Aruban national holiday');

        can_ok('Date::Holidays::AW', qw(holidays is_holiday));
    }
}

sub test_br : Test(4) {
    SKIP: {
        eval { require Date::Holidays::BR };
        skip "Date::Holidays::BR not installed", 4 if $@;

        can_ok('Date::Holidays::BR', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'br' ),
            'Testing Date::Holidays::BR' );

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays for Date::Holidays::BR' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'br' ],
        );

        ok( $holidays_hashref->{'br'},
            'Checking for Brazillian first day of year' );
    }
}

sub test_by : Test(4) {
    SKIP: {
        eval { require Date::Holidays::BY };
        skip "Date::Holidays::BY not installed", 4 if $@;

        can_ok('Date::Holidays::BY', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'by' ),
            'Testing Date::Holidays::BY' );

        ok( $dh->holidays( year => 2017 ),
            'Testing holidays with argument for Date::Holidays::BY' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'by' ],
        );

        ok( $holidays_hashref->{by}, 'Checking for Belarys New Year' );
    }
}

sub test_ca : Test(3) {
    SKIP: {
        eval { require Date::Holidays::CA };
        skip "Date::Holidays::CA not installed", 3 if $@;

        can_ok('Date::Holidays::CA', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'ca' ),
            'Testing Date::Holidays::CA' );

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays for Date::Holidays::CA' );
    }
}

sub test_cn : Test(6) {
    SKIP: {
        eval { require Date::Holidays::CN };
        skip "Date::Holidays::CN not installed", 6 if $@;

        ok(! Date::Holidays::CN->can('holidays'));
        ok(! Date::Holidays::CN->can('is_holiday'));

        ok( my $dh = Date::Holidays->new( countrycode => 'cn' ),
            'Testing Date::Holidays::CN' );

        ok($dh->is_holiday(
            year   => 2017,
            month  => 1,
            day    => 1,
        ), 'Testing Chinese national holiday');

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays method for Date::Holidays::CN' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'cn' ],
        );

        ok( $holidays_hashref->{'cn'},
            'Checking for Chinese first day of year' );
    }
}


sub test_cz : Test(6) {
    SKIP: {
        eval { require Date::Holidays::CZ };
        skip "Date::Holidays::CZ not installed", 6 if $@;

        ok(Date::Holidays::CZ->can('holidays'), 'Is holidays method implemented');
        ok(! Date::Holidays::CZ->can('is_holiday'), 'Is is_holiday method implemented');

        ok( my $dh = Date::Holidays->new( countrycode => 'cz' ),
            'Testing Date::Holidays::CZ' );

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays method for Date::Holidays::CZ' );

        ok($dh->is_holiday(
            year   => 2017,
            month  => 1,
            day    => 1,
        ), 'Testing Czech national holiday');

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'cz' ],
        );

        ok( $holidays_hashref->{'cz'},
            'Checking for Czech first day of year' );
    }
}

sub test_de : Test(8) {
    SKIP: {
        eval { require Date::Holidays::DE };
        skip "Date::Holidays::DE not installed", 8 if $@;

        ok(Date::Holidays::DE->can('holidays'), 'Is holidays method implemented');
        ok(! Date::Holidays::DE->can('is_holiday'), 'Is is_holiday method implemented');

        ok( my $dh = Date::Holidays->new( countrycode => 'de' ),
            'Testing Date::Holidays::DE' );

        ok( $dh->holidays(),
            'Testing holidays with no arguments for Date::Holidays::DE' );

        ok( $dh->holidays( year => 2006 ),
            'Testing holidays with argument for Date::Holidays::DE' );

        is( ref $dh->holidays( year => 2006 ), 'HASH',
            'Testing return value of holidays with argument for Date::Holidays::DE' );

        ok( $dh->is_holiday(day => 1, month => 1, year => 2018), 'Testing the adapted implementation of is_holidays for DE');

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'de' ],
        );

        ok( $holidays_hashref->{'de'},
            'Checking for German first day of year' );
    }
}

sub test_dk : Test(6) {
    SKIP: {
        eval { require Date::Holidays::DK };
        skip "Date::Holidays::DK not installed", 4 if $@;

        ok(! Date::Holidays::DK->can('holidays'), 'Is holidays method implemented');
        ok(! Date::Holidays::DK->can('is_holiday'), 'Is is_holiday method implemented');

        ok( my $dh = Date::Holidays->new( countrycode => 'dk' ),
            'Testing Date::Holidays::DK' );

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays for Date::Holidays::DK' );

        ok($dh->is_holiday(
            year   => 2017,
            month  => 1,
            day    => 1,
        ), 'Testing Danish national hoiday');

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'dk' ],
        );

        ok( $holidays_hashref->{'dk'}, 'Checking for Danish holidays' );

    }
}

sub test_es : Test(11) {
    SKIP: {
        eval { require Date::Holidays::ES; require Date::Holidays::CA_ES; };
        skip "Date::Holidays::ES or Date::Holidays::CA_ES not installed", 11 if $@;

        can_ok('Date::Holidays::ES', qw(holidays is_holiday));
        can_ok('Date::Holidays::CA_ES', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'es' ),
            'Testing Date::Holidays::ES' );

        ok( $dh->holidays( year => 2006 ),
            'Testing holidays with argument for Date::Holidays::ES' );

        ok($dh->is_holiday(
            year   => 2017,
            month  => 1,
            day    => 1,
        ), 'Testing spanish national hoiday');

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'es' ],
        );

        ok( $holidays_hashref->{'es'}, 'Checking for Spanish holidays' );

        # Catalan region
        ok( my $holidays = $dh->holidays( year => 2006, region => 'ca' ),
            'Testing holidays with argument for Date::Holidays::ES Catalan region' );

        ok($dh->is_holiday(
            year   => 2017,
            month  => 1,
            day    => 1,
            region => 'ca'
        ), 'Testing spanish national holiday');

        ok($dh->is_holiday(
            year   => 2017,
            month  => 6,
            day    => 24,
            region => 'ca'
        ), 'Testing local Catalan holiday');

        ok( $dh = Date::Holidays->new( countrycode => 'es' ),
            'Testing Date::Holidays::ES' );

        is($dh->is_holiday(
            year   => 2017,
            month  => 6,
            day    => 24,
        ), undef, 'Testing local Catalan holiday is not a holiday in Spain');
    }
}

sub test_fr : Test(6) {
    SKIP: {
        eval { require Date::Holidays::FR };
        skip "Date::Holidays::FR not installed", 6 if $@;

        ok(! Date::Holidays::FR->can('holidays'));
        ok(! Date::Holidays::FR->can('is_holiday'));

        ok( my $dh = Date::Holidays->new( countrycode => 'fr' ),
            'Testing Date::Holidays::FR' );

        dies_ok { $dh->holidays(); }
            'Testing holidays with no arguments for Date::Holidays::FR';

        dies_ok { $dh->holidays( year => 2017 ); }
            'Testing holidays with argument for Date::Holidays::FR';

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'fr' ],
        );

        ok( $holidays_hashref->{'fr'}, 'Checking for French christmas' );
    }
}

sub test_gb : Test(10) {
    SKIP: {
        eval { require Date::Holidays::GB };
        skip "Date::Holidays::GB not installed", 10 if $@;

        can_ok('Date::Holidays::GB', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'gb' ),
            'Testing Date::Holidays::GB' );

        ok( $dh->holidays(),
            'Testing holidays with no arguments for Date::Holidays::GB' );

        ok( $dh->holidays( year => 2014 ),
            'Testing holidays with argument for Date::Holidays::GB' );

        can_ok('Date::Holidays::GB', qw(holidays is_holiday));

        ok( my $holidays_hashref_sct = Date::Holidays::GB::holidays(year => 2014, regions => ['SCT']));

        ok( my $holidays_hashref_eaw = Date::Holidays::GB::holidays(year => 2014, regions => ['EAW']));

        ok( keys %{$holidays_hashref_eaw} != keys %{$holidays_hashref_sct});

        ok(my $gb = Date::Holidays->new(countrycode => 'gb'));

        ok($gb->is_holiday(
            day   => 17,
            month => 3,
            year  => 2015,
            region => 'NIR',
        ), 'Asserting St Patrick’s Day in Northern Ireland');
    }
}

sub test_kr : Test(5) {
    SKIP: {
        eval { require Date::Holidays::KR };
        skip "Date::Holidays::KR not installed", 5 if $@;

        can_ok('Date::Holidays::KR', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'kr' ),
            'Testing Date::Holidays::KR' );

        dies_ok { $dh->holidays(); }
            'Testing holidays with no arguments for Date::Holidays::KR';

        dies_ok { $dh->holidays( year => 2014 ) }
            'Testing holidays with argument for Date::Holidays::KR';

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'kr' ],
        );

        ok(! $holidays_hashref->{'kr'}, 'Checking for Korean holiday' );
    }
}

sub test_kz : Test(5) {
    SKIP: {
        eval { require Date::Holidays::KZ };
        skip "Date::Holidays::KZ not installed", 5 if $@;

        ok( Date::Holidays::KZ->can('holidays') );
        ok( Date::Holidays::KZ->can('is_holiday') );

        ok( my $dh = Date::Holidays->new( countrycode => 'kz' ),
            'Testing Date::Holidays::KZ' );

        ok( $dh->holidays( year => 2018 ),
            'Testing holidays with argument for Date::Holidays::KZ' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2018,
            month => 1,
            day   => 2,
            countries => [ 'kz' ],
        );

        ok( $holidays_hashref->{kz}, 'Checking for Kazakhstan New Year' );
    }
}

sub test_nl : Test(6) {
    SKIP: {
        eval { require Date::Holidays::NL };
        skip "Date::Holidays::NL not installed", 6 if $@;

        can_ok('Date::Holidays::NL', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'nl' ),
            'Testing Date::Holidays::NL' );

        ok( $dh->holidays( year => 2020 ),
            'Testing holidays for Date::Holidays::NL' );

        ok($dh->is_holiday(
            year   => 2020,
            month  => 1,
            day    => 1,
        ), 'Testing Netherlands national holiday');

        can_ok('Date::Holidays::NL', qw(holidays is_holiday));
    }
}

sub test_no : Test(4) {
    SKIP: {
        eval { require Date::Holidays::NO };
        skip "Date::Holidays::NO not installed", 4 if $@;

        can_ok('Date::Holidays::NO', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'no' ),
            'Testing Date::Holidays::NO' );

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays for Date::Holidays::NO' );

        ok($dh->is_holiday(
            year   => 2020,
            month  => 1,
            day    => 1,
        ), 'Testing Norwegian national holiday');
    }
}

sub test_nz : Test(7) {
    SKIP: {
        eval { require Date::Holidays::NZ };
        skip "Date::Holidays::NZ not installed", 7 if $@;

        ok(! Date::Holidays::NZ->can('holidays'));
        ok(! Date::Holidays::NZ->can('is_holiday'));

        ok( my $dh = Date::Holidays->new( countrycode => 'nz' ),
            'Testing Date::Holidays::NZ' );

        ok( $dh->holidays( year => 2004 ),
            'Testing holidays for Date::Holidays::NZ' );

        ok( $dh->holidays( year => 2004, region => 2 ),
            'Testing holidays for Date::Holidays::NZ with region parameter' );

        ok($dh->is_holiday(year => 2018, month => 1, day => 1, region => 2), 'Testing is_holiday with region parameter');

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2018,
            month => 1,
            day   => 1,
            countries => [ 'nz' ],
        );

        ok($holidays_hashref->{'nz'}, 'Checking for New Zealand holiday' );
    }
}

sub test_pl : Test(5) {
    SKIP: {
        eval { require Date::Holidays::PL };
        skip "Date::Holidays::PL not installed", 5 if $@;

        can_ok('Date::Holidays::PL', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'pl' ),
            'Testing Date::Holidays::PL');

        dies_ok { $dh->holidays() }
            'Testing holidays for Date::Holidays::PL';

        dies_ok { $dh->holidays( year => 2004 ) }
            'Testing holidays for Date::Holidays::PL';

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'pl' ],
        );

        ok( $holidays_hashref->{'pl'},
            'Checking for Polish first day of year' );
    }
}

sub test_pt : Test(4) {
    SKIP: {
        eval { require Date::Holidays::PT };
        skip "Date::Holidays::PT not installed", 4 if $@;

        can_ok('Date::Holidays::PT', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'pt' ),
            'Testing Date::Holidays::PT' );

        ok( $dh->holidays( year => 2005 ),
            'Testing holidays for Date::Holidays::PT' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2017,
            month => 1,
            day   => 1,
            countries => [ 'pt' ],
        );

        ok( $holidays_hashref->{'pt'},
            'Checking for Portuguese first day of year' );
    }
}

sub test_ru : Test(4) {
    SKIP: {
        eval { require Date::Holidays::RU };
        skip "Date::Holidays::RU not installed", 4 if $@;

        can_ok('Date::Holidays::RU', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'ru' ),
            'Testing Date::Holidays::RU' );

        ok( $dh->holidays( year => 2014 ),
            'Testing holidays with argument for Date::Holidays::RU' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2015,
            month => 1,
            day   => 7,
            countries => [ 'ru' ],
        );

        ok( $holidays_hashref->{ru}, 'Checking for Russian christmas' );
    }
}

sub test_sk : Test(6) {
    SKIP: {
        eval { require Date::Holidays::SK };
        skip "Date::Holidays::SK not installed", 6 if $@;

        ok(! Date::Holidays::SK->can('is_holiday'));
        ok(! Date::Holidays::SK->can('holidays'));

        ok( my $dh = Date::Holidays->new( countrycode => 'sk' ),
            'Testing Date::Holidays::SK' );

        ok( $dh->holidays(),
            'Testing holidays without argument for Date::Holidays::SK' );

        ok( $dh->holidays( year => 2018 ),
            'Testing holidays with argument for Date::Holidays::SK' );

        my $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2014,
            month => 1,
            day   => 1,
            countries => [ 'sk' ],
        );

        ok( $holidays_hashref->{sk}, 'Checking for Slovakian holiday' );
    }
}

sub test_uk : Test(4) {
    SKIP: {
        eval { require Date::Holidays::GB };
        skip "Date::Holidays::GB not installed", 4 if $@;

        can_ok('Date::Holidays::GB', qw(holidays is_holiday));

        ok( my $dh = Date::Holidays->new( countrycode => 'uk', nocheck => 1 ),
            'Testing Date::Holidays::Adapter::UK' );

        dies_ok { $dh->holidays() }
            'Testing holidays without argument for Date::Holidays::Adapter::UK';

        dies_ok { $dh->holidays( year => 2014 ) }
            'Testing holidays with argument for Date::Holidays::Adapter::UK';
    }
}

sub test_jp : Test(5) {
    SKIP: {
        eval { require Date::Japanese::Holiday };
        skip "Date::Japanese::Holiday not installed", 5 if $@;

        ok(!Date::Japanese::Holiday->can('holidays') );
        ok( Date::Japanese::Holiday->can('is_holiday') );

        ok( my $dh = Date::Holidays->new( countrycode => 'jp' ),
            'Testing Date::Japanese::Holiday' );

        dies_ok { $dh->holidays() }
            'Testing holidays without argument for Date::Japanese::Holiday';

        dies_ok { $dh->holidays( year => 2014 ) }
            'Testing holidays with argument for Date::Japanese::Holiday';
    }
}

sub test_us : Test(8) {
    SKIP: {
        eval { require Date::Holidays::USFederal };
        skip "Date::Holidays::USFederal not installed", 8 if $@;

        ok(! Date::Holidays::USFederal->can('holidays') );
        ok(! Date::Holidays::USFederal->can('is_holiday') );

        ok( my $dh = Date::Holidays->new( countrycode => 'USFederal', nocheck => 1 ),
            'Testing Date::Holidays::USFederal' );

        dies_ok { $dh->holidays() }
            'Testing holidays without argument for Date::Holidays::USFederal';

        my $holidays_hashref = Date::Holidays->is_holiday(
            year      => 2018,
            month     => 1,
            day       => 1,
            countries => [ 'USFederal' ],
            nocheck   => 1,
        );

        ok( $holidays_hashref->{USFederal}, 'Checking for US Federal New Year' );

        ok( $dh = Date::Holidays->new( countrycode => 'US' ),
            'Testing Date::Holidays::USFederal' );

        dies_ok { $dh->holidays() }
            'Testing holidays without argument for Date::Holidays::USFederal';

        $holidays_hashref = Date::Holidays->is_holiday(
            year      => 2018,
            month     => 1,
            day       => 1,
            countries => [ 'US' ],
        );

        ok( $holidays_hashref->{US}, 'Checking for US Federal New Year' );
    }
}

sub test_ua : Test(5) {
    SKIP: {
        eval { require Date::Holidays::UA };
        skip "Date::Holidays::UA not installed", 4 if $@;

        can_ok('Date::Holidays::UA', qw(holidays is_holiday));

        ok(my $dh = Date::Holidays->new( countrycode => 'ua' ),'Testing Date::Holidays::UA');

        dies_ok { $dh->holidays() }
            'Testing holidays without argument for Date::Holidays::UA';

        ok( $dh->holidays( year => 2018 ),
            'Testing holidays with argument for Date::Holidays::UA' );

        ok($dh->is_holiday(year => 2020, month => 8, day => 24), 'Checking for Ukrainian independence day');
    }
}

sub test_norway_and_denmark_combined : Test(6) {
    SKIP: {
        eval { load Date::Holidays::DK };
        skip "Date::Holidays::DK not installed", 6 if ($@);

        eval { load Date::Holidays::NO };
        skip "Date::Holidays::NO not installed", 6 if ($@);

        my $dh = Date::Holidays->new( countrycode => 'dk' );

        isa_ok( $dh, 'Date::Holidays', 'Testing Date::Holidays object' );

        ok( $dh->is_holiday(
                year  => 2004,
                month => 12,
                day   => 25
            ),
            'Testing whether 1. christmas day is a holiday in DK'
        );

        my $holidays_hashref;

        ok( $holidays_hashref = $dh->is_holiday(
                year      => 2004,
                month     => 12,
                day       => 25,
                countries => [ 'no', 'dk' ],
            ),
            'Testing whether 1. christmas day is a holiday in NO and DK'
        );

        is( keys %{$holidays_hashref},
            2, 'Testing to see if we got two definitions' );

        ok( $holidays_hashref->{'dk'}, 'Testing whether DK is set' );
        ok( $holidays_hashref->{'no'}, 'Testing whether NO is set' );
    }
}

sub test_without_object : Test(1) {

    my $holidays_hashref;

    ok( $holidays_hashref = Date::Holidays->is_holiday(
            year  => 2014,
            month => 12,
            day   => 25,
        ),
        'Testing is_holiday called without an object'
    );
}

1;
