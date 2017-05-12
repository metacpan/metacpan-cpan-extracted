use strict;
use warnings;

use Test::More tests => 4;

use Sig::PackageScoped;

{
    package Foo;

    # dying in package Foo now prepends 'Foo: ' to message
    Sig::PackageScoped::set_sig( __DIE__ => sub { die "Foo: $_[0]" } );

    eval { die "bar\n" };

    chomp $@;
    ::is( $@, 'Foo: bar',
          q{$@ should be 'Foo: bar'} );

    {
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

    package Foo;

    # remove our handler(s)
    Sig::PackageScoped::unset_sig( __DIE__ => 1, __WARN__ => 1 );

    eval { die "bar\n"; };

    chomp $@;
    ::is( $@, 'bar',
          q{After removing signal handler $@ should be 'bar'} );

}
