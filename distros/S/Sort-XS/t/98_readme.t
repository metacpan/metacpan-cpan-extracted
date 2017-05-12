use strict;
use warnings;

BEGIN {
    use Test::More;
    plan( skip_all => "Enable DEVEL_TESTS environment variable" )
      unless ( $ENV{DEVEL_TESTS} );

    eval "use Pod::Readme";
    plan( skip_all => "Pod::Readme required for updating README" )
      if $@;
}

my $parser = Pod::Readme->new();
ok $parser->parse_from_file( 'lib/Sort/XS.pm', 'README' );

done_testing();
