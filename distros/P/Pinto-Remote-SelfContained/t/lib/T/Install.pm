package
    T::Install; # hide from PAUSE

use v5.10;
use Moo;

use Path::Tiny qw(path);

use namespace::clean;

my $FAKECPANM = path(__FILE__)->parent->sibling('fakecpanm');

extends 'Pinto::Remote::SelfContained::Action::Install';

# This is slightly sneaky: we're overriding a scalar-returning method, but it's
# only ever called in list context, so this will seem to work.
around cpanm_exe => sub { $^X, $FAKECPANM };

1;
