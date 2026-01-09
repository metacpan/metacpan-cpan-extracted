use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use ok 'MooseX::Types::DateTime';

use Moose::Util::TypeConstraints qw(find_type_constraint);

isa_ok( find_type_constraint($_), "Moose::Meta::TypeConstraint" ) for qw(DateTime DateTime::TimeZone DateTime::Locale);

{
    {
        package Foo;
        use Moose;

        has date => (
            isa => "DateTime",
            is  => "rw",
            coerce => 1,
        );
    }

    my $epoch = time;

    my $coerced = Foo->new( date => $epoch )->date;

    isa_ok( $coerced, "DateTime", "coerced epoch into datetime" );

    is( $coerced->epoch, $epoch, "epoch is correct" );

    isa_ok( Foo->new( date => { year => 2000, month => 1, day => 1 } )->date, "DateTime" );

    isa_ok( Foo->new( date => 'now' )->date, "DateTime" );

    like(exception { Foo->new( date => "junk1!!" ) }, qr/DateTime/, "constraint");
}

{
    {
        package Quxx;
        use Moose;

        has duration => (
            isa => "DateTime::Duration",
            is  => "rw",
            coerce => 1,
        );
    }

    my $coerced = Quxx->new( duration => 10 )->duration;

    isa_ok( $coerced, "DateTime::Duration", "coerced from seconds" );

    my $time = time;

    my $now = DateTime->from_epoch( epoch => $time );

    my $future = $now + $coerced;

    is( $future->epoch, ( $time + 10 ), "coerced value" );

    isa_ok( Quxx->new( duration => { minutes => 2 } )->duration, "DateTime::Duration", "coerced from hash" );

    like(exception { Quxx->new( duration => "ahdstkljhat" ) }, qr/DateTime/, "constraint");
}

{
    {
        package Bar;
        use Moose;

        has time_zone => (
            isa => "DateTime::TimeZone",
            is  => "rw",
            coerce => 1,
        );
    }

    my $tz = Bar->new( time_zone => "Africa/Timbuktu" )->time_zone;

    isa_ok( $tz, "DateTime::TimeZone", "coerced string into time zone object" );

    like( $tz->name, qr/^Africa/, "correct time zone" );

    like(exception { Bar->new( time_zone => "Space/TheMoon" ) }, qr{The timezone 'Space/TheMoon' could not be loaded}, "bad time zone");
}

{
    {
        package Gorch;
        use Moose;

        has loc => (
            isa => "DateTime::Locale",
            is  => "rw",
            coerce => 1,
        );
    }

    my $loc = Gorch->new( loc => "he_IL" )->loc;

    like( $loc->id, qr/he[_\-]IL/, "coerced from string" );

    like(exception { Gorch->new( loc => "not_a_place_or_a_locale" ) }, qr/Invalid locale/, "bad locale name");

    SKIP: {
        skip "No Locale::Maketext", 2 unless eval { +require Locale::Maketext; 1 };

        {
            package Some::L10N;
            our @ISA = qw(Locale::Maketext);

            package Some::L10N::ja;
            our @ISA = qw(Some::L10N);

            our %Lexicon = (
                goodbye => "sayonara",
            );
        }

        my $handle = Some::L10N->get_handle("ja");

        isa_ok( $handle, "Some::L10N", "maketext handle" );

        is( Gorch->new( loc => $handle )->loc->id, "ja", "coerced from maketext" );;
    }
}

{
    {
        package Gondor;

        use Moose;
        use MooseX::Types::DateTime qw(DateTime Duration);

        has 'date' => (is=>'rw', isa=>DateTime, coerce=>1);
        has 'duration' => (is=>'rw', isa=>Duration, coerce=>1);

    }

    my $epoch = time;

    ok my $gondor = Gondor->new(date=>$epoch, duration=>10)
    => 'Instantiated object using export types';

}

done_testing;
