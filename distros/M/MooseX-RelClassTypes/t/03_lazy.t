use strict;
use warnings;

use Test::More;


# project "LazyParent"

{
    package LazyParent::Parent;
    use Moose;

    with 'MooseX::RelClassTypes';

    has parent_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack',
        default => sub{
            my $pack = ref( $_[0] )."::RelPack";
            $pack->new;
        },
        lazy => 1
    );
}

{
    package LazyParent::Child;
    use Moose;
    extends 'LazyParent::Parent';
    with 'MooseX::RelClassTypes';

    has child_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack'
    );

}

{
    package LazyParent::Parent::RelPack;
    use Moose;

    has param => (is => 'ro', isa => 'Str', default => __PACKAGE__);
}
    
{
    package LazyParent::Child::RelPack;
    use Moose;

    has param => (
        is => 'ro',
        isa => 'Str',
        default => __PACKAGE__." param"
    );
}


# project "LazyChild"

{
    package LazyChild::Parent;
    use Moose;

    with 'MooseX::RelClassTypes';

    has parent_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack'
    );
}

{
    package LazyChild::Child;
    use Moose;
    extends 'LazyChild::Parent';
    with 'MooseX::RelClassTypes';

    has child_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack',
        lazy => 1,
        default => sub{
            my $pack = ref( $_[0] )."::RelPack";
            $pack->new;
        }
    );

}

{
    package LazyChild::Parent::RelPack;
    use Moose;

    has param => (is => 'ro', isa => 'Str', default => __PACKAGE__);
}
    
{
    package LazyChild::Child::RelPack;
    use Moose;

    has param => (
        is => 'ro', 
        isa => 'Str', 
        default => __PACKAGE__." param"
   );
}


# project "LazyParam";

{
    package LazyParam::Parent;
    use Moose;

    with 'MooseX::RelClassTypes';

    has parent_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack'
    );
}

{
    package LazyParam::Child;
    use Moose;
    extends 'LazyParam::Parent';
    with 'MooseX::RelClassTypes';

    has child_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack'
    );

}

{
    package LazyParam::Parent::RelPack;
    use Moose;

    has param => (
        is => 'ro',
        isa => 'Str',
        default => __PACKAGE__,
        lazy => 1
    );
}
    
{
    package LazyParam::Child::RelPack;
    use Moose;

    has param => (
        is => 'ro',
        isa => 'Str',
        default => __PACKAGE__." param",
        lazy => 1
    );
}


# project "LazyAll";

{
    package LazyAll::Parent;
    use Moose;

    with 'MooseX::RelClassTypes';

    has parent_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack',
        lazy => 1,
        default => sub{
            my $pack = ref( $_[0] )."::RelPack";
            $pack->new;
        },
    );
}

{
    package LazyAll::Child;
    use Moose;
    extends 'LazyAll::Parent';
    with 'MooseX::RelClassTypes';

    has child_rel_pack => (
        is => 'rw',
        isa => '{CLASS}::RelPack',
        lazy => 1,
        default => sub{
            my $pack = ref( $_[0] )."::RelPack";
            $pack->new;
        },
    );

}

{
    package LazyAll::Parent::RelPack;
    use Moose;

    has param => (
        is => 'ro',
        isa => 'Str',
        default => __PACKAGE__,
        lazy => 1
    );
}
    
{
    package LazyAll::Child::RelPack;
    use Moose;

    has param => (
        is => 'ro',
        isa => 'Str',
        default => __PACKAGE__." param",
        lazy => 1
    );
}


foreach my $project ( qw(Parent Child Param All) ){

    my $child_pack = "Lazy$project\::Child";

    my $child = $child_pack->new;

    isa_ok( $child, $child_pack, '->new' );
    isa_ok( $child->parent_rel_pack, ref( $child )."::RelPack", '->parent_rel_pack' );
    is( $child->parent_rel_pack->param, ref( $child )."::RelPack param", '->parent_rel_pack->param ok');

    isa_ok( $child->child_rel_pack, ref( $child )."::RelPack", '->child_rel_pack' );
    is ( $child->child_rel_pack->param, ref( $child )."::RelPack param", '->child_rel_pack->param ok' );

}

done_testing();
