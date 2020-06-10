#line 1
package JSON::PP::Boolean;

use strict;
require overload;
local $^W;
overload::import('overload',
    "0+"     => sub { ${$_[0]} },
    "++"     => sub { $_[0] = ${$_[0]} + 1 },
    "--"     => sub { $_[0] = ${$_[0]} - 1 },
    fallback => 1,
);

$JSON::PP::Boolean::VERSION = '4.04';

1;

__END__

#line 41

