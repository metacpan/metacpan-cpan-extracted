
use Test::More;

BEGIN {
  eval "use PDLA::Slatec;";
  if ( !$@ ) {
    eval "use PDLA::Graphics::Limits;";
    plan tests => 1;
  } else {
     print "$@\n";
    plan skip_all => 'PDLA::Slatec not available';
  }
  use_ok('PDLA::Graphics::Limits');
};

# end
