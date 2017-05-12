# cleaning the namespace using 'namespace::clean'
use strict;
use warnings;

use Test::More;

eval { require namespace::autoclean };
plan skip_all => "namespace::autoclean is required for this test" if $@;

eval <<END
    package Autoclean::Moo;
    use namespace::autoclean;
    use Moo;
END
;

eval <<END
    package Autoclean::HandlesVia;
    use namespace::autoclean;
    use Moo;
    use MooX::HandlesVia;
END
;

eval <<END
    package Autoclean::HandlesVia::Role;
    use Moo::Role;
    use MooX::HandlesVia;
    use namespace::autoclean;
END
;

eval <<END
    package Autoclean::HandlesVia::WithRole;
    use Moo;
    with qw/Clean::HandlesVia::Role/;
    use namespace::autoclean;
END
;


my $moo_obj = new_ok "Autoclean::Moo";
my $handlesvia_obj = new_ok "Autoclean::HandlesVia";
my $role_obj = new_ok "Autoclean::HandlesVia::WithRole";

ok ! $moo_obj->can("has"), 'plain Moo: namespace is cleaned';
ok ! $handlesvia_obj->can("has"), 'HandlesVia: namespace is cleaned';
ok ! $role_obj->can("has"), 'HandlesVia in a role: namespace is cleaned';

done_testing;
