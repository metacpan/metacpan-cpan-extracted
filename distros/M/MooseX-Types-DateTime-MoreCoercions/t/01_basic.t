use strict;
use warnings;

use Test::More tests => 28;

use Test::Fatal;
use DateTime;

use ok 'MooseX::Types::DateTime::MoreCoercions';

=head1 NAME

t/02_datetimex.t - Check that we can properly coerce a string.

=head1 DESCRIPTION

Run some tests to make sure the the Duration and DateTime types continue to
work exactly as from the L<MooseX::Types::DateTime> class, as well as perform
the correct string to object coercions.

=head1 TESTS

This module defines the following tests.

=head2 Test Class

Create a L<Moose> class that is using the L<MooseX::Types::DateTime::MoreCoercions> types.

=cut

{
    package MooseX::Types::DateTime::MoreCoercions::CoercionTest;

    use Moose;
    use MooseX::Types::DateTime::MoreCoercions qw(DateTime Duration);

    has 'date' => (is=>'rw', isa=>DateTime, coerce=>1);
    has 'duration' => (is=>'rw', isa=>Duration, coerce=>1);
}

ok my $class = MooseX::Types::DateTime::MoreCoercions::CoercionTest->new
=> 'Created a good class';


=head2 ParseDateTime Capabilities

parse some dates and make sure the system can actually find something.

=cut

sub coerce_ok ($;$) {
    my ( $date, $canon ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    SKIP: {
        skip "DateTimeX::Easy couldn't parse '$date'", $canon ? 2 : 1 unless DateTimeX::Easy->new($date);
        ok( $class->date($date), "coerced a DateTime from '$date'" );
        is( $class->date, $canon, 'got correct date' ) if $canon;
    }
}

## Skip this test until I can figure out better timezone handling
#coerce_ok ('2/13/1969 noon', '1969-02-13T11:00:00' );


coerce_ok( '2/13/1969', '1969-02-13T00:00:00' );

coerce_ok( '2/13/1969 America/New_York', '1969-02-13T00:00:00' );

SKIP: {
    skip "couldn't parse", 1 unless $class->date;
    isa_ok $class->date->time_zone => 'DateTime::TimeZone::America::New_York'
    => 'Got Correct America/New_York TimeZone';
}

coerce_ok( 'jan 1 2006', '2006-01-01T00:00:00' );

=head2 relative dates

Stuff like "yesterday".  We can make sure they returned something but we have
no way to make sure the values are really correct.  Manual testing suggests
they work well enough, given the inherent ambiguity we are dealing with.

=cut

coerce_ok("now");

coerce_ok("yesterday");

coerce_ok("tomorrow");

coerce_ok("last week");

=head2 check inherited constraints

Just a few tests to make sure the object, hash, etc coercions and type checks
still work.

=cut

ok my $datetime = DateTime->now()
=> 'Create a datetime object for testing';

ok my $anyobject = bless({}, 'Bogus::Does::Not::Exist')
=> 'Created a random object for proving the object constraint';

ok $class->date($datetime)
=> 'Passed Object type constraint test.';

    isa_ok $class->date => 'DateTime'
    => 'Got a good DateTime Object';

like(
    exception { $class->date($anyobject) },
    qr/Attribute \(date\) does not pass the type constraint/,
   'Does not allow the bad object',
);

ok $class->date(1000)
=> 'Passed Num coercion test.';

    isa_ok $class->date => 'DateTime'
    => 'Got a good DateTime Object';

    is $class->date => '1970-01-01T00:16:40'
    => 'Got correct DateTime';

ok $class->date({year=>2000,month=>1,day=>10})
=> 'Passed HashRef coercion test.';

    isa_ok $class->date => 'DateTime'
    => 'Got a good DateTime Object';

    is $class->date => '2000-01-10T00:00:00'
    => 'Got correct DateTime';

=head2 check duration

make sure the Duration type constraint works as expected

=cut

ok $class->duration(100)
=> 'got duration from integer';

    is $class->duration->seconds, 100
    => 'got correct duration from integer';


ok $class->duration('1 minute')
=> 'got duration from string';

    is $class->duration->seconds, 60
    => 'got correct duration string';


=head1 AUTHOR

John Napiorkowski E<lt>jjn1056 at yahoo.comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008 John Napiorkowski. All rights reserved
    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

1;

