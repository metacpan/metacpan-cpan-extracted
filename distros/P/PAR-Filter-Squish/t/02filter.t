#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 2 }

ok (eval { require PAR::Filter::Squish; 1 });

my $code = <<'HERE';

use strict;
require PAR::Filter::Squish;



my $text = <<'FOO';
Hello World.
FOO

"$text"   ;

HERE
    use warnings;


ok(
    eval($code) eq
    eval(
        PAR::Filter::Squish->apply(\$code, 'foo', 'foo')
    )
);

__END__
