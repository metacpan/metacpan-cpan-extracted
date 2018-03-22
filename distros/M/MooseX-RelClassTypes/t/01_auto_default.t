use strict;
use warnings;

use Test::More;

{
    package TestAD::NoAuto_NoDefault_NoBuilder;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 0 };

    has rel_pack => (is => 'ro', isa => '{CLASS}::RelPack');

};

{
    package TestAD::NoAuto_NoDefault_WithBuilder;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 0 };

    has rel_pack => (is => 'ro', isa => '{CLASS}::RelPack', builder => '_builder');

    sub _builder{
        my $module = ref( $_[0] ).'::RelPack';
        my $obj = $module->new( param => 'NoAuto_NoDefault_WithBuilder' );
        return $obj;
    }
};

{
    package TestAD::NoAuto_WithDefault_NoBuilder;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 0 };

    has rel_pack => (is => 'ro', isa => '{CLASS}::RelPack', default => sub{
        my $module = ref( $_[0] ).'::RelPack';
        my $obj = $module->new( param => 'NoAuto_WithDefault_NoBuilder' );
    });
};

{
    package TestAD::WithAuto_NoDefault_NoBuilder;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 1 };

    has rel_pack => (is => 'ro', isa => '{CLASS}::RelPack');

};

{
    package TestAD::WithAuto_NoDefault_WithBuilder;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 1 };

    has rel_pack => (is => 'ro', isa => '{CLASS}::RelPack', builder => '_builder');

    sub _builder{
        my $module = ref( $_[0] ).'::RelPack';
        my $obj = $module->new( param => 'WithAuto_NoDefault_WithBuilder' );
        return $obj;
    }
};

{
    package TestAD::WithAuto_WithDefault_NoBuilder;
    use Moose;
    with 'MooseX::RelClassTypes' => { auto_default => 0 };

    has rel_pack => (is => 'ro', isa => '{CLASS}::RelPack', default => sub{
        my $module = ref( $_[0] ).'::RelPack';
        my $obj = $module->new( param => 'WithAuto_WithDefault_NoBuilder' );
    });

};



{
    package TestAD::NoAuto_NoDefault_NoBuilder::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package TestAD::NoAuto_NoDefault_WithBuilder::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package TestAD::NoAuto_WithDefault_NoBuilder::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package TestAD::WithAuto_NoDefault_NoBuilder::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package TestAD::WithAuto_NoDefault_WithBuilder::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

{
    package TestAD::WithAuto_WithDefault_NoBuilder::RelPack;
    use Moose;
    has param => (is => 'rw', isa => 'Str');
}

my $expected = {

    NoAuto_NoDefault_NoBuilder => [ 0, undef ],
    NoAuto_NoDefault_WithBuilder => [1, 'NoAuto_NoDefault_WithBuilder'],
    NoAuto_WithDefault_NoBuilder => [1, 'NoAuto_WithDefault_NoBuilder'],
    WithAuto_NoDefault_NoBuilder => [1, undef],
    WithAuto_NoDefault_WithBuilder => [1, 'WithAuto_NoDefault_WithBuilder'],
    WithAuto_WithDefault_NoBuilder => [1, 'WithAuto_WithDefault_NoBuilder']

};


foreach my $suffix (keys %$expected){
    
    my $module = "TestAD::$suffix";
    my $obj = $module->new;

    isa_ok( $obj, $module, "->new" );

    if ($expected->{$suffix}->[0]){
        isa_ok( $obj->rel_pack, $module."::RelPack", "$module ->rel_pack");

        is( $obj->rel_pack->param, $expected->{$suffix}->[1], "$module ->rel_pack->param" );

    } else {
        is( $obj->rel_pack, undef, "$module ->rel_pack" );
    }

}

done_testing();
    
