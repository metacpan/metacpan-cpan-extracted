#!perl -w

use Test::More tests => 5;
use File::Basename;

BEGIN {
    use_ok( 'Tempest' );
}

SKIP: {
    ## check that class can be instantiated (ie: a supported lib can be found)
    my $instance = eval {
        new Tempest(
            'input_file' => dirname(__FILE__) . '/data/screenshot.png',
            'output_file' => dirname(__FILE__) . '/data/output_gd.png',
            'coordinates' => [ [0,0] ],
        )
    };
    skip "No supported image library could be found", 4 if $@;
    
    ok( ref($instance) eq 'Tempest', 'class instantiation' );
    
    ## check that static methods give same result whether called from instance or not
    foreach $method (['version'], ['api_version'], ['has_image_lib', Tempest::LIB_GD]) {
        my $method_name = shift @{$method};
        
        my $static = 'Tempest::'   . $method_name . '(@{$method});';
        diag("calling $static");
        $static = eval($static);
        
        my $member = '$instance->' . $method_name . '(@{$method});';
        diag("calling $member");
        $member = eval($member);
        
        is($static, $member, "$method_name static method");
    }
}