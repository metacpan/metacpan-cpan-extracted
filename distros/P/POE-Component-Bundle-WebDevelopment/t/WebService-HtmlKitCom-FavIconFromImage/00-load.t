#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

ok(1,'...');

### This test seems to be currently hanging up
### Seems WebService::HtmlKitCom::FavIconFromImage is broken

__END__

BEGIN {
    use_ok('Carp');
    use_ok('WebService::HtmlKitCom::FavIconFromImage');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
	use_ok( 'POE::Component::WebService::HtmlKitCom::FavIconFromImage' );
}

diag( "Testing POE::Component::WebService::HtmlKitCom::FavIconFromImage $POE::Component::WebService::HtmlKitCom::FavIconFromImage::VERSION, Perl $], $^X" );

my $poco = POE::Component::WebService::HtmlKitCom::FavIconFromImage->spawn(
    debug   => 1,
    obj_args => { timeout => 30 },
);

isa_ok($poco,'POE::Component::WebService::HtmlKitCom::FavIconFromImage');
can_ok($poco, qw(favicon));

POE::Session->create(
    package_states => [ main => [ qw(_start result) ], ],
);

$poe_kernel->run;

sub _start {
    $poco->favicon({ event => 'result', image => 't/WebService-HtmlKitCom-FavIconFromImage/pic.jpg', _x => 'y'});
}
sub result {
    my $in_ref = $_[ARG0];
    is(ref $in_ref, 'HASH', '$_[ARG0] must be a hashref');
    is( $in_ref->{image}, 't/pic.jpg', '{image}');
    is( $in_ref->{_x}, 'y', 'user defined args');

    SKIP: {
    if ( exists $in_ref->{error} ) {
        ok( (defined $in_ref->{error} and length $in_ref->{error}),
            '{error}');

        diag "\nGot error: $in_ref->{error}\n\n";
        skip "Got error", 1;
    }
    else {
        isa_ok( $in_ref->{response}, 'HTTP::Response', '{response}');
        is( $in_ref->{response}->header('Content-type'),
            'application/zip',
            'should get zip file from favicon()',
        );
    }
    }
    $poco->shutdown;
}