package # hide from PAUSE indexer
 TypeLib;

use MooseX::Types
    -declare => [ qw( XAccount ) ];

use MooseX::Types::Moose qw/HashRef/;
class_type XAccount, { class => 'Account' };
coerce XAccount,
    from HashRef,
    via { Account->new(%$_) };

