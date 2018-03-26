use strict;
use warnings;

use Test::More;

{
    package Parent;

    use Moose;
    with 'MooseX::RelClassTypes';
    #use MooseX::RelClassTypes;

    has parent_rel_pack => (
        is => 'rw', 
        isa => '{CLASS}::RelPack',
        default => sub{
            my $module = ref( $_[0] ).'::RelPack';
            my $obj = $module->new(
                param => 'this param should belong to a Child::RelPack in a "parent_rel_pack" attribute'
            );
            return $obj;
        },
        lazy => 1
    );

    has parent_abs_pack => (  
        is => 'ro', 
        isa => 'Parent::AbsPack',
        default => sub{
            Parent::AbsPack->new;
        },
        lazy => 1
    );
}


{
    package Child;

    use Moose;
    extends 'Parent';
    with 'MooseX::RelClassTypes';
    #use MooseX::RelClassTypes;

    has child_rel_pack => (
        is => 'rw', 
        isa => '{CLASS}::RelPack'
#        default => sub {
#            Child::RelPack->new;
#        }
    );

    has child_abs_pack => (
        is => 'rw',
        isa => 'Child::AbsPack',
        default => sub{
            Child::AbsPack->new;
        }
    );
}


{
    package Child::AbsPack;
        use Moose;

        has param => (is => 'rw', isa => 'Str', default => 'child abspack param value');
}

{
    package Child::RelPack;
        use Moose;

        has param => (is => 'rw', isa => 'Str', default => 'child relpack param value');
}

{
    package Parent::AbsPack;
        use Moose;

        has param => (is => 'rw', isa => 'Str', default => 'parent abspack param value');
}

{
    package Parent::RelPack;
        use Moose;

        has param => (is => 'rw', isa => 'Str', default => 'parent relpack param value');

}

use Parent;
use Child;
use Child::AbsPack;
use Child::RelPack;
use Parent::AbsPack;
use Parent::RelPack;

my $child = Child->new;
isa_ok( $child, 'Child', '->new works' );
isa_ok( $child->child_abs_pack, 'Child::AbsPack', '->child_abs_pack' );
is( $child->child_abs_pack->param, 'child abspack param value', 'Absolute child class param value correct');
isa_ok( $child->child_rel_pack, 'Child::RelPack', '->child_rel_pack' );
is( $child->child_rel_pack->param, 'child relpack param value', 'Relative class param value correct');
isa_ok( $child->parent_abs_pack, 'Parent::AbsPack', '->parent_abs_pack');
is( $child->parent_abs_pack->param, 'parent abspack param value', 'Absolute parent class type param value correct');
isa_ok( $child->parent_rel_pack, 'Child::RelPack', '->parent_rel_pack' );
is( $child->parent_rel_pack->param, 
    'this param should belong to a Child::RelPack in a "parent_rel_pack" attribute',
    'Relative parent class type param value correct');

done_testing();

