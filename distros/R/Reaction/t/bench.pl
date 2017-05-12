use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'ComponentUI' }


my $i = 1;
for(30..60){
  ok( request('/')->is_success, 'Request should succeed' );
  ok( request('/testmodel/foo')->is_success, 'Request should succeed' );
  ok( request('/testmodel/baz')->is_success, 'Request should succeed' );
  ok( request("/testmodel/foo/id/${_}/update")->is_success, 'Request should succeed' );
  ok( request("/testmodel/foo/id/${_}/view")->is_success, 'Request should succeed' );

  $i = 1 if $i > 4;
  ok( request("/testmodel/baz/id/${i}/update")->is_success, 'Request should succeed' );
  ok( request("/testmodel/baz/id/${i}/view")->is_success, 'Request should succeed' );
  $i++;
}



