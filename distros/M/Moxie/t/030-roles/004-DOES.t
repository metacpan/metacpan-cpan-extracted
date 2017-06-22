#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# roles ...
package Foo {
    use Moxie;
}
package Bar {
    use Moxie;
}
package Baz {
    use Moxie;
}
package Bat {
    use Moxie;

    with 'Baz';
}

# classes ...
package Quux {
    use Moxie;

    extends 'Moxie::Object';
       with 'Foo', 'Bar';
}

package Quuux {
    use Moxie;

    extends 'Quux';
       with 'Foo', 'Baz';
}

package Xyzzy {
    use Moxie;

    extends 'Moxie::Object';
       with 'Foo', 'Bat';
}

ok(Quux->DOES($_),  "... Quux DOES $_")  for qw( Foo Bar         Quux       UNIVERSAL::Object UNIVERSAL );
ok(Quuux->DOES($_), "... Quuux DOES $_") for qw( Foo Bar Baz     Quux Quuux UNIVERSAL::Object UNIVERSAL );
ok(Xyzzy->DOES($_), "... Xyzzy DOES $_") for qw( Foo     Baz Bat      Xyzzy UNIVERSAL::Object UNIVERSAL );

#{ local $TODO = "broken in core perl" if $] < 5.019005;
#push @UNIVERSAL::ISA, 'Blorg';
#ok(Quux->DOES('Blorg'));
#ok(Quuux->DOES('Blorg'));
#ok(Xyzzy->DOES('Blorg'));
#}

done_testing;
