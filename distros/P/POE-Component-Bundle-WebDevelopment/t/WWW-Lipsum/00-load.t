#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::Lipsum');
	use_ok( 'POE::Component::WWW::Lipsum' );
}

diag( "Testing POE::Component::WWW::Lipsum $POE::Component::WWW::Lipsum::VERSION, Perl $], $^X" );

use POE qw/Component::WWW::Lipsum/;
my $poco = POE::Component::WWW::Lipsum->spawn;

POE::Session->create( package_states => [ main => [qw/_start lipsum/] ], );

$poe_kernel->run;

sub _start {
    $poco->generate({
            event => 'lipsum',
            args  => {
                amount => 5,
                what   => 'paras',
                start  => 'no',
                html   => 1,
            },
        }
    );
}

sub lipsum {
    my $in_ref = $_[ARG0];

    if ( exists $in_ref->{error} ) {
        ok(length $in_ref->{error});
    }
    else {
        is( ref($in_ref->{lipsum}), 'ARRAY');
    }
    $poco->shutdown;
}