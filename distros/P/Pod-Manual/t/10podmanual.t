use strict;
use warnings;

use Test::More tests => 3;    # last test to print

my @args = qw/ -format docbook -output stdout -silent /;    # std args

like run_podmanual( @args, 'Pod::Manual' ), qr/<\?xml/,
  'podmanual finds modules';

like run_podmanual( @args, './script/podmanual' ), qr/<\?xml/,
  'podmanual finds files';

like run_podmanual( @args, '-title' => 'Foo', 'Pod::Manual' ), qr/<title>Foo/,
  'option -title';

# run_podmanual( '-pdf' => 'test.pdf', 'Pod::Manual' );
# ok -f 'test.pdf', 'can create pdfs';

### utility functions ######################################

sub run_podmanual {
    my $args = join ' ', @_;
    return `$^X ./script/podmanual $args`;
}

