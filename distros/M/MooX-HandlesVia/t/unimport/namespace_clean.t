# cleaning the namespace using 'namespace::clean'
use strict;
use warnings;

use Test::More;

eval { require namespace::clean };
plan skip_all => "namespace::clean is required for this test" if $@;


eval <<END
    package Clean::Moo;
    use Moo;
    use namespace::clean;
END
;

eval <<END
    package Clean::HandlesVia;
    use Moo;
    use MooX::HandlesVia;
    use namespace::clean;
END
;

eval <<END
    package Clean::HandlesVia::Role;
    use Moo::Role;
    use MooX::HandlesVia;
    use namespace::clean;
END
;

eval <<END
    package Clean::HandlesVia::WithRole;
    use Moo;
    with qw/Clean::HandlesVia::Role/;
    use namespace::clean;
END
;


my $moo_obj = new_ok "Clean::Moo";
my $handlesvia_obj = new_ok "Clean::HandlesVia";
my $role_obj = new_ok "Clean::HandlesVia::WithRole";

ok ! $moo_obj->can("has"), 'plain Moo: namespace is cleaned';
ok ! $handlesvia_obj->can("has"), 'HandlesVia: namespace is cleaned';
ok ! $role_obj->can("has"), 'HandlesVia in a role: namespace is cleaned';

done_testing;
