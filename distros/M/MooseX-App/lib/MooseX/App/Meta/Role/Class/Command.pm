# ============================================================================
package MooseX::App::Meta::Role::Class::Command;
# ============================================================================

use utf8;
use 5.010;

use Moose::Role;

has 'app_attribute_metaroles' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    predicate       => 'has_app_attribute_metaroles',
    traits          => ['Array'],
    handles         => {
        app_attribute_metaroles_add     => 'push',
        app_attribute_metaroles_uniq    => 'uniq',
    }
);

1;