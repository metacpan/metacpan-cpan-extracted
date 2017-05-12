use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep '!blessed';
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Scalar::Util 'blessed';

my %loaded_file;
my %configfile_sub;
my %constructor_args;


# nothing special going on here
{
    package Generic;
    use Moose;
    with 'MooseX::ConfigFromFile';
    sub get_config_from_file
    {
        my ($class, $file) = @_;
        $loaded_file{$file}++;
        +{}
    }
    around BUILDARGS => sub {
        my ($orig, $class) = (shift, shift);
        my $args = $class->$orig(@_);
        $constructor_args{$class} = $args;
    };
    sub __my_configfile
    {
        my $class = blessed($_[0]) || $_[0];
        $configfile_sub{$class}++;
        $class . ' file'
    }
}

is(
    exception {
        my $obj = Generic->new_with_config;
        is($obj->configfile, undef, 'no configfile set');
        cmp_deeply(\%loaded_file, {}, 'no files loaded');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            { },
            'correct constructor args passed',
        );
    },
    undef,
    'no exceptions',
);

{
    package Base;
    use Moose;
}
{
    package GenericRole;
    use Moose::Role;
    with 'MooseX::ConfigFromFile';
    sub get_config_from_file
    {
        my ($class, $file) = @_;
        $loaded_file{$file}++;
        +{}
    }
    around BUILDARGS => sub {
        my ($orig, $class) = (shift, shift);
        my $args = $class->$orig(@_);
        $constructor_args{$class} = $args;
    };
    sub __my_configfile
    {
        my $class = blessed($_[0]) || $_[0];
        $configfile_sub{$class}++;
        $class . ' file'
    }
}

is(
    exception {
        my $obj = Moose::Meta::Class->create_anon_class(
            superclasses => ['Base'],
            roles => ['GenericRole'],
        )->name->new_with_config;
        is($obj->configfile, undef, 'no configfile set');
        cmp_deeply(\%loaded_file, {}, 'no files loaded');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            { },
            'correct constructor args passed',
        );
    },
    undef,
    'no exceptions',
);

# this is a classic legacy usecase from old documentation that we must
# continue to support
{
    package OverriddenDefault;
    use Moose;
    extends 'Generic';
    has '+configfile' => (
        default => 'OverriddenDefault file',
    );
}

is(
    exception {
        my $obj = OverriddenDefault->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden default');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);

{
    package OverriddenDefaultMethod;
    use Moose;
    extends 'Generic';
    has '+configfile' => (
        default => sub { shift->__my_configfile },
    );
}

is(
    exception {
        my $obj = OverriddenDefaultMethod->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden default');
        is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);


# legacy usecase, and configfile init_arg has been changed
{
    package OverriddenDefaultAndChangedName;
    use Moose;
    extends 'Generic';
    has '+configfile' => (
        init_arg => 'my_configfile',
        default => 'OverriddenDefaultAndChangedName file',
    );
}

is(
    exception {
        my $obj = OverriddenDefaultAndChangedName->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden default');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            {  my_configfile => blessed($obj) . ' file' },
            'correct constructor args passed',
        );
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);

# "reader" method is overridden to provide for configfile default
{
    package OverriddenMethod;
    use Moose;
    extends 'Generic';
    around configfile => sub { my $orig = shift; shift->__my_configfile };
}

is(
    exception {
        my $obj = OverriddenMethod->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden sub');
        # this is not fixable - the reader method has been shadowed
        # is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);

{
    package OverriddenMethodAsRole;
    use Moose::Role;
    with 'GenericRole';
    around configfile => sub { my $orig = shift; shift->__my_configfile };
}

is(
    exception {
        my $obj = Moose::Meta::Class->create_anon_class(
            superclasses => ['Base'],
            roles => ['OverriddenMethodAsRole'],
        )->name->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden sub');
        # this is not fixable - the reader method has been shadowed
        # is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);


# overridable method for configfile default, and configfile init_arg is changed
{
    package OverriddenMethodAndChangedName;
    use Moose;
    extends 'Generic';
    has '+configfile' => (
        init_arg => 'my_configfile',
    );
    around configfile => sub { my $orig = shift; shift->__my_configfile };
}

is(
    exception {
        my $obj = OverriddenMethodAndChangedName->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden sub');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            {  my_configfile => blessed($obj) . ' file' },
            'correct constructor args passed',
        );
        # this is not fixable - the reader method has been shadowed
        # is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);

{
    package OverriddenMethodAndChangedNameAsRole;
    use Moose::Role;
    with 'GenericRole';
    use MooseX::Types::Path::Tiny 'Path';
    use MooseX::Types::Moose 'Undef';
    has configfile => (
        is => 'ro',
        isa => Path|Undef,
        coerce => 1,
        predicate => 'has_configfile',
        lazy => 1,
        # it sucks that we have to do this rather than using a builder, but some old code
        # simply swaps in a new default sub into the attr definition
        default => sub { shift->_get_default_configfile },

        # this is the overridden bit
        init_arg => 'my_configfile',
    );
    around configfile => sub { my $orig = shift; shift->__my_configfile };
}

is(
    exception {
        my $obj = Moose::Meta::Class->create_anon_class(
            superclasses => ['Base'],
            roles => ['OverriddenMethodAndChangedNameAsRole'],
        )->name->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden sub');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            { my_configfile => blessed($obj) . ' file' },
            'correct constructor args passed',
        );
        # this is not fixable - the reader method has been shadowed
        # is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);


# newly-supported overridable method for configfile default
{
    package NewSub;
    use Moose;
    extends 'Generic';
    sub _get_default_configfile { shift->__my_configfile }
}

is(
    exception {
        my $obj = NewSub->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via new sub');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            {  configfile => blessed($obj) . ' file' },
            'correct constructor args passed',
        );
        is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);

{
    package NewSubAsRole;
    use Moose::Role;
    with 'GenericRole';
    sub _get_default_configfile { shift->__my_configfile }
}

is(
    exception {
        my $obj = Moose::Meta::Class->create_anon_class(
            superclasses => ['Base'],
            roles => ['NewSubAsRole'],
        )->name->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via new sub');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            {  configfile => blessed($obj) . ' file' },
            'correct constructor args passed',
        );
        is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);


# newly-supported overridable method for configfile default, and configfile
# init_arg has been changed
{
    package NewSubAndChangedName;
    use Moose;
    extends 'Generic';
    has '+configfile' => (
        init_arg => 'my_configfile',
    );
    sub _get_default_configfile { shift->__my_configfile }
}

is(
    exception {
        my $obj = NewSubAndChangedName->new_with_config;
        is($obj->configfile, blessed($obj) . ' file', 'configfile set via overridden sub');
        cmp_deeply(
            $constructor_args{blessed($obj)},
            {  my_configfile => blessed($obj) . ' file' },
            'correct constructor args passed',
        );
        is($configfile_sub{blessed($obj)}, 1, 'configfile was calculated just once');
        is($loaded_file{blessed($obj) . ' file'}, 1, 'correct file was loaded from');
    },
    undef,
    'no exceptions',
);

done_testing;
