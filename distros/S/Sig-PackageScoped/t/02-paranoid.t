use strict;
use warnings;

use Test::More tests => 9;

use Sig::PackageScoped::Paranoid;

{
    package Foo;

    # dying in package Foo now prepends 'Foo: ' to message
    Sig::PackageScoped::set_sig( __DIE__ => sub { die "Foo: $_[0]" } );

    eval { die "bar\n" };

    chomp $@;
    ::is( $@, 'Foo: bar',
          q{$@ should be 'Foo: bar'} );

    {
	# dying in package Foo now prepends 'Foo2: ' to message.  This
	# should reset to just 'Foo: ' when the local var goes out of
	# scope
	local $SIG{__DIE__} = sub { die "Foo2: $_[0]" };

	eval { die "bar\n" };

	chomp $@;
        ::is( $@, 'Foo2: bar',
              q{$@ should be 'Foo: bar'} );

	package Bar;

	# now that we're in Bar it should be a regular die
	eval { die "bar\n"; };

	chomp $@;
        ::is( $@, 'bar',
              q{$@ should be 'bar'} );
    }

    # back in package Foo with previous handler restored
    eval { die "bar\n" };

    chomp $@;
    ::is( $@, 'Foo: bar',
          q{$@ should be 'Foo: bar'} );

    package Bar;

    # in bar, no handler should be set
    eval { die "bar\n"; };

    chomp $@;
    ::is( $@, 'bar',
          q{$@ should be 'bar'} );

    package Foo;

    {
	# resets package Foo entirely
	$SIG{__DIE__} = sub { die "Foo2: $_[0]" };

	eval { die "bar\n" };

	chomp $@;
        ::is( $@, 'Foo2: bar',
              q{$@ should be 'Foo: bar'} );
    }

    eval { die "bar\n"; };

    chomp $@;
    ::is( $@, 'Foo2: bar',
          q{$@ should be 'Foo: bar'} );

    package Bar;

    # in bar, _still_ no handler should be set
    eval { die "bar\n"; };

    chomp $@;
    ::is( $@, 'bar',
          q{$@ should be 'bar'} );

    package Foo;

    # remove our handler(s)
    Sig::PackageScoped::unset_sig( __DIE__ => 1, __WARN__ => 1 );

    eval { die "bar\n"; };

    chomp $@;
    ::is( $@, 'bar',
          q{$@ should be 'bar' after unsetting signal handler} );

}
