use Test::More tests => 4;

BEGIN {
  use_ok( 'POE::Component::DirWatch' );
  use_ok( 'POE::Component::DirWatch::New' );
  use_ok( 'POE::Component::DirWatch::Modified' );
  use_ok( 'POE::Component::DirWatch::Unmodified' );
}

diag( "Testing POE::Component::DirWatch $POE::Component::DirWatch::VERSION, Perl $], $^X" );
