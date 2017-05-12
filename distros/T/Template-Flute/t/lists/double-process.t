#
# Test demonstrating failure of subsequent calls to process (GH #85).
#

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Template::Flute;

my $spec = q{<specification>
<list name="list" iterator="test">
<param name="value"/>
</list>
</specification>
};

my $html = q{<html><div class="list"><div class="value">TEST</div></div></html>};
my $value;
my $flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    values        => { test => [ { value => $value } ] },
);

$flute->process;

TODO: {
    local $TODO = "Fix planned for later release.";

    is(exception(sub{$flute->process}),
       undef,
       "No exception running process the second time."
   );
}

done_testing;
