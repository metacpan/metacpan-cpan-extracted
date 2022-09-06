use strict;
use warnings;
use utf8;

BEGIN {
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
}

use Test::More;
use Object::Pad qw(:experimental);

subtest 'create a rôle' => sub {
    ok(eval <<'EOF', 'create rôle')
package Example::Role;
use Myriad::Class type => 'role';
1;
EOF
        or diag explain $@;
    ok(my $mop = Object::Pad::MOP::Class->for_class('Example::Role'), 'MOP exists');
    ok($mop->is_role, 'and we created a rôle');
    done_testing;
};

done_testing;
