#!perl -w

use strict;
use warnings;
use Samba::LDAP::Base;
use Test::More tests => 93;

#------------------------------------------------------------------------
# Taken from Class::Base test.pl - Gavin Henry 2006
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# quick hack to allow STDERR to be tied to a variable.
#------------------------------------------------------------------------

package Tie::File2Str;

sub TIEHANDLE {
    my ($class, $textref) = @_;
    bless $textref, $class;
}
sub PRINT {
    my $self = shift;
    $$self .= join('', @_);
}


package main;

# tie STDERR to a variable
my $stderr = '';
tie(*STDERR, "Tie::File2Str", \$stderr);


#------------------------------------------------------------------------
# Class::Test::Fail always fails, but we check it reports errors OK
#------------------------------------------------------------------------

package Class::Test::Fail;
use base qw( Samba::LDAP::Base );
use vars qw( $ERROR );

sub init {
    my $self = shift;
    return $self->error('expected failure');
}


package main;

my ($pkg, $mod);

# instantiate a base class object and test error reporting/returning
$mod = Samba::LDAP::Base->new();
ok( $mod );
ok( ! defined $mod->error('barf') );
ok( $mod->error() eq 'barf' );

# Class::Test::Fail should never work, but we check it reports errors OK
$pkg = 'Class::Test::Fail';
ok( ! $pkg->new() );
is( $pkg->error, 'expected failure' );
is( $Class::Test::Fail::ERROR, 'expected failure' );


#------------------------------------------------------------------------
# Class::Test::Name should only work with a 'name'parameters
#------------------------------------------------------------------------

package Class::Test::Name;
use base qw( Samba::LDAP::Base );
use vars qw( $ERROR );

sub init {
    my ($self, $params) = @_;
    $self->{ NAME } = $params->{ name } 
	|| return $self->error("No name!");
    return $self;
}

sub name {
    $_[0]->{ NAME };
}

package main;

$mod = Class::Test::Name->new();
ok( ! $mod );
is( $Class::Test::Name::ERROR, 'No name!' );
is( Class::Test::Name->error(), 'No name!' );

# give it what it wants...
$mod = Class::Test::Name->new({ name => 'foo' });
ok( $mod );
ok( ! $mod->error() );
is( $mod->name(), 'foo' );

# ... in 2 different flavours
$mod = Class::Test::Name->new(name => 'foo');
ok( $mod );
ok( ! $mod->error() );
is( $mod->name(), 'foo' );

#------------------------------------------------------------------------
# test clone() method
#------------------------------------------------------------------------

my $clone = $mod->clone();
ok( $mod );
ok( ! $mod->error() );
is( $mod->name(), 'foo', 'clone is ok' );


#------------------------------------------------------------------------
# test id method and constructor parameters
#------------------------------------------------------------------------

my $obj = Samba::LDAP::Base->new();
ok( $obj );
ok( $obj->id eq 'Samba::LDAP::Base' );
ok( $obj->id('foo') eq 'foo' );

$obj = Samba::LDAP::Base->new( ID => 'foo' );
ok( $obj );
ok( $obj->id eq 'foo' );

$obj = Samba::LDAP::Base->new( id => 'bar' );
ok( $obj );
ok( $obj->id eq 'bar' );
ok( $obj->id('baz') eq 'baz' );
ok( $obj->id eq 'baz' );

package My::Samba::LDAP::Base;
use base qw( Samba::LDAP::Base );
our $DEBUG;

package main;

$obj = My::Samba::LDAP::Base->new( );
ok( $obj );
ok( $obj->id() eq 'My::Samba::LDAP::Base' );

$obj = My::Samba::LDAP::Base->new( ID => 'wiz', DEBUG => 1 );
ok( $obj );
ok( $obj->id() eq 'wiz' );
$stderr = '';
$obj->debug('hello world');
ok( $stderr eq '[wiz] hello world' ) 
    or print "stderr is [$stderr] not '[wiz] hello world'\n";

#------------------------------------------------------------------------
# test debugging method and params
#------------------------------------------------------------------------

$obj = Samba::LDAP::Base->new( );
ok( $obj, 'debugging object created' );
ok( ! $obj->debugging );
ok(   $obj->debugging(1) );
ok(   $obj->debugging );

$obj = Samba::LDAP::Base->new( debug => 1 );
ok( $obj );
ok(   $obj->debugging );
ok( ! $obj->debugging(0) );
ok( ! $obj->debugging );

$obj = Samba::LDAP::Base->new( DEBUG => 1 );
ok( $obj );
ok(   $obj->debugging );
ok( ! $obj->debugging(0) );
ok( ! $obj->debugging );

$obj = My::Samba::LDAP::Base->new( );
ok( $obj );
ok( ! $obj->debugging );
ok( ! $My::Samba::LDAP::Base::DEBUG );
$stderr = '';
$obj->debug('hello world');
ok( ! $stderr ) or print "stderr is [$stderr] not empty'\n";


# no explicit debug flag set in object, so should use package var
$My::Samba::LDAP::Base::DEBUG = 1;
ok( ! $obj->debugging, 'object is not debugging' );
ok( My::Samba::LDAP::Base->debugging, 'class is debugging' );
$stderr = '';
$obj->debug('hello world');
ok( ! $stderr, 'stderr is empty' );
My::Samba::LDAP::Base->debug('hello world');
ok( $stderr eq '[My::Samba::LDAP::Base] hello world' ) 
    or print "stderr is [$stderr] not '[My::Samba::LDAP::Base] hello world'\n";

# now we set an object debug flag which should also change pkg var
$obj->debugging(0);
ok( ! $obj->debugging, 'object debuggin off' );
ok( $My::Samba::LDAP::Base::DEBUG, 'class debugging on' );
$stderr = '';
$obj->debug('hello world');
ok( ! $stderr ) 
    or print "stderr is [$stderr] not empty\n";

# now that object has debug value defined, it not longer uses pkg var
$My::Samba::LDAP::Base::DEBUG = 1;
ok( ! $obj->debugging );
$obj->debug('hello world');
ok( ! $stderr ) 
    or print "stderr is [$stderr] not empty\n";

# test debugging works as class method
My::Samba::LDAP::Base->debugging(0);
ok( ! $My::Samba::LDAP::Base::DEBUG );

My::Samba::LDAP::Base->debugging(1);
ok( $My::Samba::LDAP::Base::DEBUG );

#------------------------------------------------------------------------
# test package $DEBUG variable sets default object DEBUG flag
#------------------------------------------------------------------------

My::Samba::LDAP::Base->debugging(0);
ok( ! $My::Samba::LDAP::Base::DEBUG, 'class debugging is off' );

my $obj1 = My::Samba::LDAP::Base->new( );
ok( $obj1, 'object 1 created' );
ok( ! $obj1->debugging, 'object not debugging' );
$stderr = '';
$obj1->debug('foo');
ok( ! $stderr, 'nothing printed' );

My::Samba::LDAP::Base->debugging(1);
ok( $My::Samba::LDAP::Base::DEBUG, 'class debugging is now on' );

my $obj2 = My::Samba::LDAP::Base->new( );
ok( $obj2, 'object 2 created' );
ok( $obj2->debugging, 'object is debugging' );
$stderr = '';
$obj2->debug('foo');
is( $stderr, '[My::Samba::LDAP::Base] foo', 'foo printed' );


#------------------------------------------------------------------------
# test package var $DEBUG influences debug flag of new objects
#------------------------------------------------------------------------

package Some::Class;
use base qw( Samba::LDAP::Base );

our $DEBUG = 0 unless defined $DEBUG;
local $" = ', ';

sub one {
    my ($self, @args) = @_;
    $self->debug("one(@args)\n");
}

sub two {
    my ($self, @args) = @_;
    $self->debug("two(@args)\n") if $DEBUG;
}

;

package main;

my $a = Some::Class->new(debug => 1);
my $b = Some::Class->new(debug => 1);

$stderr = '';
$a->one(2);
$a->two(3);
$b->one(5);
$b->two(7);
is( $stderr, "[Some::Class] one(2)\n[Some::Class] one(5)\n",
    'output 1 matches');

$a->debugging(0);
$stderr = '';
$a->one(11);
$a->two(13);
$b->one(17);
$b->two(19);
is( $stderr, "[Some::Class] one(17)\n",
    'output 2 matches');

Some::Class->debugging(1);

$stderr = '';
$a->one(23);
$a->two(29);
$b->one(31);
$b->two(37);
is( $stderr, "[Some::Class] one(31)\n[Some::Class] two(37)\n",
    'output 3 matches');

#------------------------------------------------------------------------
# test params() method
#------------------------------------------------------------------------

package My::Params::Test;
use base qw( Samba::LDAP::Base );

sub init {
    my ($self, $config) = @_;

    my ($one, $two, $three) = $self->params($config, qw( ONE TWO THREE ))
	|| return;

    return $self;
}

package main;

$pkg = 'My::Params::Test';
$obj = $pkg->new();
ok( $obj, 'got an object' );
ok( ! exists $obj->{ ONE }, 'ONE does not exist' );

$obj = $pkg->new( ONE => 2 );
ok( $obj, 'got an object' );
is( $obj->{ ONE }, 2, 'ONE is 2' );

$obj = $pkg->new( one => 3, TWO => 4 );
ok( $obj, 'got an object' );
is( $obj->{ ONE }, 3, 'ONE is 3' );
is( $obj->{ TWO }, 4, 'TWO is 4' );
ok( ! exists $obj->{ THREE }, 'THREE does not exist' );


#------------------------------------------------------------------------
# same passing list of args
#------------------------------------------------------------------------

package My::Other::Params::Test;
use base qw( Samba::LDAP::Base );

sub init {
    my ($self, $config) = @_;

    my ($one, $two, $three) = $self->params($config, [ qw( ONE TWO THREE ) ])
	|| return;

    return $self;
}

package main;

$pkg = 'My::Params::Test';
$obj = $pkg->new();
ok( $obj, 'got a list ref object' );
ok( ! exists $obj->{ ONE }, 'ONE does not exist' );

$obj = $pkg->new( ONE => 2 );
is( $obj->{ ONE }, 2, 'ONE is 2' );

$obj = $pkg->new( one => 3, TWO => 4 );
is( $obj->{ ONE }, 3, 'ONE is 3' );
is( $obj->{ TWO }, 4, 'TWO is 4' );
ok( ! exists $obj->{ THREE }, 'THREE does not exist' );

#------------------------------------------------------------------------
# same passing hash of defaults
#------------------------------------------------------------------------

package My::Hash::Params::Test;
use base qw( Samba::LDAP::Base );

sub init {
    my ($self, $config) = @_;

    my ($one, $two, $three) = $self->params($config, {
	FOO => 'the foo item',
	BAR => undef,
	BAZ => \&baz,
    }) || return;

    return $self;
}

sub baz {
    my ($self, $key, $value) = @_;
    $value = '<undef>' unless defined $value;
    $self->{ MSG } = "$key set to $value";
    $self->{ BAZ } = $value;
}

package main;

$pkg = 'My::Hash::Params::Test';
$obj = $pkg->new();
ok( $obj, 'got a hash ref object' );
is( $obj->{ FOO }, 'the foo item', 'foo default set' );
ok( ! exists $obj->{ BAR }, 'BAR does not exist' );
is( $obj->{ BAZ }, '<undef>', 'BAZ is undef' );
is( $obj->{ MSG }, 'BAZ set to <undef>', 'BAZ is undef' );

$obj = $pkg->new( foo => 'hello world',
		  bar => 99,
		  baz => 'bazmatic' );

is( $obj->{ FOO }, 'hello world', 'foo set' );
is( $obj->{ BAR }, '99', 'bar set' );
is( $obj->{ BAZ }, 'bazmatic', 'baz is set' );
is( $obj->{ MSG }, 'BAZ set to bazmatic', 'MSG is set' );



