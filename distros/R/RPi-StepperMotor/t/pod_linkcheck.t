use strict; use warnings;
 
use Test::More;
 
eval "use Test::Pod::LinkCheck";
if ($@) {
    plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
} 
if (! $ENV{RELEASE_TESTING}){
    plan skip_all => 'Test::POD::LinkCheck tests not required for install.';
}

Test::Pod::LinkCheck->new->all_pod_ok;
