use warnings;
use strict;
use Test::More;
use Config;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;

my @modules;

if ( $Config{useithreads} ) {

    @modules = all_modules();

}
else {

    my @tmp = all_modules();

    foreach my $mod (@tmp) {

        push( @modules, $mod ) unless ( $mod eq 'Term::YAP::iThread' );

    }

}

foreach my $module (@modules) {

    pod_coverage_ok( $module, 'Pod coverage is ok' );

}

done_testing();
