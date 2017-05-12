# cleaning the namespace using "no Moo"
use strict;
use warnings;

use Test::More;

{
    package NoMoo::Moo;
    use Moo;
    no Moo;
}

{
    package NoMoo::HandlesVia;
    use Moo;
    use MooX::HandlesVia;
    no Moo;
}

{
    package NoMoo::HandlesVia::Role;
    use Moo::Role;
    use MooX::HandlesVia;
    no Moo::Role;
}

{
    package NoMoo::WithRole;
    use Moo;
    with qw/NoMoo::HandlesVia::Role/;
    no Moo;
}


my $moo_obj = new_ok "NoMoo::Moo";
my $handlesvia_obj = new_ok "NoMoo::HandlesVia";
my $role_obj = new_ok "NoMoo::WithRole";

ok ! $moo_obj->can("has"), 'plain Moo: namespace is cleaned';
ok ! $handlesvia_obj->can("has"), 'HandlesVia: namespace is cleaned';
ok ! $role_obj->can("has"), 'HandlesVia in a Role: namespace is cleaned';

done_testing;
