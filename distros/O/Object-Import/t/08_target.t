use warnings; no warnings qw"uninitialized reserved prototype"; use strict;
use Test::More tests => 9;
use Scalar::Util;

BEGIN { 
$::W4 = 0;
$SIG{__WARN__} = sub { 
	my($t) = @_;
	if ($t =~ m"\Awarning: Object::Import cannot find methods of " ||
		$t =~ m"\ASubroutine .* redefined at .*\bObject/Import\.pm ") 
	{
		$::W4++;
	}
	warn $t;
};
}

is($::W4, 0, "no warn 0");

{
package X;
sub greet {
	my($o, $i) = @_;
	(ref($o) ? $$o[0] : $o) . ", " . $i;
}
}


{
package Hi;
BEGIN { @Hi::ISA = X::; }
}

{
package Hi::DSL;
use Object::Import;
use Carp qw(croak);
sub import {
	    my ($class, %options);
	    if (@_ == 2) {
		($class, $options{ name }) = @_;
	    } else {
		($class, %options) = @_;
	    };
	    my $target = delete $options{ target } || caller;
	    my $name = delete $options{ name } || '$obj';
	    my $obj = bless(["hello"], Hi::);
	    
	    $name =~ s/^[\$]//
		or croak 'Variable name must start with $';
	    {
		no strict 'refs';
		*{"$target\::$name"} = \$obj;
		# Now install in $target::
		import Object::Import \${"$target\::$name"},
				      deref => 1,
				      target => $target;
	    }
}
}

{
package X::DSL;
use Object::Import;
use Carp qw(croak);
sub import {
	    my ($class, %options);
	    if (@_ == 2) {
		($class, $options{ name }) = @_;
	    } else {
		($class, %options) = @_;
	    };
	    my $target = delete $options{ target } || caller;
	    my $name = delete $options{ name } || '$obj';
	    my $obj = bless(["hello"], X::);
	    
	    $name =~ s/^[\$]//
		or croak 'Variable name must start with $';
	    {
		no strict 'refs';
		*{"$target\::$name"} = \$obj;
		# Now install in $target::
		import Object::Import \${"$target\::$name"},
				      deref => 1,
				      target => $target;
	    }
}
}

{
package G0;
use Test::More;

# use Hi::DSL;
BEGIN{ Hi::DSL->import() };

ok(defined(\&greet), "G0 def&greet");
is(Scalar::Util::blessed($G0::obj), "Hi", "exported \$obj");
is(greet("world"), "hello, world", "G0 &greet");
$$G0::obj[0] = "bye";
is(greet("world"), "bye, world", "G0.1 &greet");

is($::W4, 0, "no warn G0");
}

{
package G1;
use Test::More;

# use Hi::DSL;
BEGIN{ X::DSL->import() };

ok(defined(\&greet), "G1 def&greet");
is(greet("world"), "hello, world", "G1 &greet");


is($::W4, 0, "no warn G0");
}

__END__
