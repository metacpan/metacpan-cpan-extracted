#!/usr/bin/env perl

use Test::More tests => 15;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Wheel::Run');
    use_ok('POE::Filter::Reference');
    use_ok('POE::Filter::Line');
    use_ok('WWW::WebDevout::BrowserSupportInfo');
	use_ok( 'POE::Component::WWW::WebDevout::BrowserSupportInfo' );
}

diag( "Testing POE::Component::WWW::WebDevout::BrowserSupportInfo $POE::Component::WWW::WebDevout::BrowserSupportInfo::VERSION, Perl $], $^X" );


use strict;
use warnings;
use POE qw(Component::WWW::WebDevout::BrowserSupportInfo);

my $poco = POE::Component::WWW::WebDevout::BrowserSupportInfo->spawn(
    debug => 1,
    obj_args => { ua_args => { timeout => 10 } },
);

isa_ok( $poco, 'POE::Component::WWW::WebDevout::BrowserSupportInfo' );
can_ok( $poco, qw(shutdown session_id spawn fetch) );

POE::Session->create(
    package_states => [
        main => [ qw(_start fetched) ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->fetch( { event => 'fetched', what => 'css', _user => 'foos'} );
}

sub fetched {
    my $in = $_[ARG0];
    is(
        ref $in,
        'HASH',
        '$_[ARG0] in results handler',
    );

    ok( (exists $in->{error} or exists $in->{results}),
        'either {results} or {error} keys must exist',
    );

    SKIP: {
        if ( $in->{error} ) {
            skip "Got error '$in->{error}'...", 3;
        }
        else {
            is( $in->{what}, 'css', '{what} must contain the term' );
            like(
                $in->{uri_info},
                qr{^http://www.webdevout.net},
                '{uri_info} must contain a URL to webdevout.net'
            );
            is(
                ref $in->{results},
                'HASH',
                '{results} in the fetched() result handler',
            );
        }
    }
    is(
        $in->{_user},
        'foos',
        'user defined args',
    );

    $poco->shutdown;
}


