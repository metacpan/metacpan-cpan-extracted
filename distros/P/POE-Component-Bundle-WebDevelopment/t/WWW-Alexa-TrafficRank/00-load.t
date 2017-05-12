#!/usr/bin/env perl

use Test::More tests => 9;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::Alexa::TrafficRank');
	use_ok( 'POE::Component::WWW::Alexa::TrafficRank' );
}

diag( "Testing POE::Component::WWW::Alexa::TrafficRank $POE::Component::WWW::Alexa::TrafficRank::VERSION, Perl $], $^X" );

my $poco = POE::Component::WWW::Alexa::TrafficRank->spawn( debug => 1);

POE::Session->create(
    package_states => [ main => [qw(_start rank )] ],
);

$poe_kernel->run;

sub _start {
    $poco->rank( {
            uri   => 'google.com',
            event => 'rank',
            _user => 'defined argument',
        }
    );
}

sub rank {
    my $in_ref = $_[ARG0];

    is(ref $in_ref, 'HASH', '$_[ARG0] contains a hashref');
    if ( $in_ref->{error} ) {
        diag "Got error while fetching results: $in_ref->{error}";
        ok(length($in_ref->{error}), 'we got an error, make sure we have an error message');
    }
    else {
        diag "Got page rank: $in_ref->{rank}";
        like($in_ref->{rank}, qr/^[\d,]+$/, 'we have a rank, make sure it matches what we expect');
    }
    is($in_ref->{uri}, 'google.com', '{uri} contains passed uri');
    is($in_ref->{_user}, 'defined argument', 'user defined arguments');
    $poco->shutdown;
}