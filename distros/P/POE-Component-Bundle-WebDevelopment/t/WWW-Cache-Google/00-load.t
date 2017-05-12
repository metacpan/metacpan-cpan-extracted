#!/usr/bin/env perl

use Test::More tests => 11;

BEGIN {
	use_ok( 'POE::Component::WWW::Cache::Google' );
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::Cache::Google');
    use_ok('LWP::UserAgent');
}

diag( "Testing POE::Component::WWW::Cache::Google $POE::Component::WWW::Cache::Google::VERSION, Perl $], $^X" );


my $poco = POE::Component::WWW::Cache::Google->spawn(debug=>1);

isa_ok($poco, 'POE::Component::WWW::Cache::Google');

POE::Session->create(
    package_states => [ main => [ qw/_start results/ ] ],
);

POE::Kernel->run;

sub _start {
    $poco->cache( {
            uri     => 'http://zoffix.com',
            event   =>'results',
            _user   =>'bar'
        }
    );
}

sub results {
    my $in_ref = $_[ARG0];
    is(ref $in_ref, 'HASH', 'ARG0 is a hashref');

    isa_ok($in_ref->{cache}, qw/URI::http/);
    is($in_ref->{cache}, 'http://www.google.com/search?q=cache:zoffix.com',
    'got proper cache URI');
    is($in_ref->{_user}, 'bar', 'user arguments are valid');
    $poco->shutdown;
}











