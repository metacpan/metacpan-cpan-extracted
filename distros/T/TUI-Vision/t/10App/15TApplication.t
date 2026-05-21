use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App::Application';
}

my $app;

# Test case for the constructor
{
  $app = TApplication->new();
  isa_ok( $app, TApplication, 'TApplication object created' );
}

# Test case for the suspend method
{
  can_ok( $app, 'suspend' );
  lives_ok { $app->suspend() } 'TApplication suspend method executed';
}

# Test case for the resume method
{
  can_ok( $app, 'resume' );
  lives_ok { $app->resume() } 'TApplication resume method executed';
}

# Test case for the destructor
{
  lives_ok { $app = undef } 'TApplication object destroyed';
}

done_testing();
