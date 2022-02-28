#!perl
BEGIN
{
    use 5.004;
    use strict;
    use warnings;
    use lib './lib';
    # use Test::More tests => 22;
    use Test::More qw( no_plan );
};

BEGIN
{
    use_ok( 'Class' );
    use_ok( 'Class::Array' );
    use_ok( 'Class::Boolean' );
    use_ok( 'Class::Exception' );
    use_ok( 'Class::File' );
    use_ok( 'Class::Finfo' );
    use_ok( 'Class::Assoc' );
    use_ok( 'Class::NullChain' );
    use_ok( 'Class::Number' );
    use_ok( 'Class::Scalar' );
};

#use strict;

subtest 'inheritance' => sub
{
    my $obj = Class->new;
    isa_ok( $obj => 'Module::Generic' );
    my $arr = Class::Array->new;
    isa_ok( $arr => 'Module::Generic::Array' );
    my $bool = Class::Boolean->new;
    isa_ok( $bool => 'Module::Generic::Boolean' );
    my $ex = Class::Exception->new;
    isa_ok( $ex => 'Module::Generic::Exception' );
    my $file = Class::File->new( 'test.txt' );
    isa_ok( $file => 'Module::Generic::File' );
    is( $file->basename, 'test.txt' );
    my $finfo = Class::Finfo->new( __FILE__ );
    isa_ok( $finfo, 'Module::Generic::Finfo' );
    my $hash = Class::Assoc->new;
    isa_ok( $hash, 'Module::Generic::Hash' );
    my $null = Class::NullChain->new;
    isa_ok( $null, 'Module::Generic::Null' );
    my $num = Class::Number->new(10);
    isa_ok( $num, 'Module::Generic::Number' );
    my $str = Class::Scalar->new( 'test' );
    isa_ok( $str, 'Module::Generic::Scalar' );
};

package Foo;
use Class;

::is( CLASS, __PACKAGE__, 'CLASS is right' );
::is( $CLASS, __PACKAGE__, '$CLASS is right' );

sub bar { 23 }
sub check_caller { caller }

::is( CLASS->bar, 23, 'CLASS->meth' );
::is( $CLASS->bar, 23, '$CLASS->meth' );

#line 42
eval { CLASS->i_dont_exist };
my $CLASS_death = $@;
#line 42
eval { $CLASS->i_dont_exist };
my $CLASS_scalar_death = $@;
#line 42
eval { __PACKAGE__->i_dont_exist };
my $Foo_death = $@;
::is( $CLASS_death, $Foo_death, '__PACKAGE__ and CLASS die the same' );
::is( $CLASS_scalar_death, $Foo_death, '__PACKAGE__ and $CLASS die the same' );

#line 29
my $CLASS_caller = CLASS->check_caller;
my $CLASS_scalar_caller = $CLASS->check_caller;
my $Foo_caller   = __PACKAGE__->check_caller;
::is($CLASS_caller, $Foo_caller,  'caller preserved' );
::is($CLASS_scalar_caller, $Foo_caller,  'caller preserved' );

sub foo { return join ':', @_ }

::is( CLASS->foo,         'Foo',        'Right CLASS  to class method call' );
::is( $CLASS->foo,         'Foo',       'Right $CLASS to class method call' );
::is( CLASS->foo('bar'),  'Foo:bar',    'CLASS:  Arguments preserved' );
::is( $CLASS->foo('bar'),  'Foo:bar',   '$CLASS: Arguments preserved' );

{
    package Bar;
    use Class;

    sub Yarrow::Func {
        my($passed_class, $passed_class_scalar) = @_;
        ::is( CLASS, __PACKAGE__, 'CLASS works in tricky subroutine' );
        ::is( $CLASS, __PACKAGE__, '$CLASS works in tricky subroutine' );

        ::is( $passed_class,        'Foo', 'CLASS as sub argument'  );
        ::is( $passed_class_scalar, 'Foo', '$CLASS as sub argument' );

        ::is( $_[0], 'Foo', 'CLASS in @_'  );
        ::is( $_[1], 'Foo', '$CLASS in @_' );
    }
}

Yarrow::Func( CLASS, $CLASS );


# Make sure AUTOLOAD is preserved.
package Bar;
sub AUTOLOAD { return "Autoloader" }

::is( CLASS->i_dont_exist, 'Autoloader', 'CLASS:  AUTOLOAD preserved' );
::is( $CLASS->i_dont_exist, 'Autoloader', '$CLASS: AUTOLOAD preserved' );


package main;
eval q{ CLASS(42); };
like( $@, '/^Too many arguments for main::CLASS/', 
                                                'CLASS properly prototyped' );
