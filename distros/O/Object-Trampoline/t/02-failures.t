use v5.24;

use lib qw( t );

use Object::Trampoline;
use Test::More;

use Symbol      qw( qualify_to_ref );

my $ref = qualify_to_ref 'Carp::croak';

undef &{ *$ref };

my $found   = '';
my $expect  = '';

*$ref
= sub
{
    my $found    = shift;

    ok ! ( index $found, $expect ), "Found '$expect' ($found)";

    # break out of the AUTOLOAD.

    die "Test\n"
};

# found false names?

$expect = q{Object::Trampoline: false prototype.};
eval { Object::Trampoline->frobnicate( '' ) };
ok $@ eq "Test\n", 'Test croak called';

$expect = q{Object::Trampoline::Use: false prototype.};
eval { Object::Trampoline::Use->frobnicate( '' ) };
ok $@ eq "Test\n", 'Test croak called';

$expect = q{Object::Trampoline: false prototype.};
eval { Object::Trampoline->frobnicate( undef ) };
ok $@ eq "Test\n", 'Test croak called';

$expect = q{Object::Trampoline::Use: false prototype.};
eval { Object::Trampoline::Use->frobnicate( undef ) };
ok $@ eq "Test\n", 'Test croak called';

$expect = q{Object::Trampoline: false prototype.};
eval { Object::Trampoline->frobnicate() };
ok $@ eq "Test\n", 'Test croak called';

$expect = q{Object::Trampoline::Use: false prototype.};
eval { Object::Trampoline::Use->frobnicate() };
ok $@ eq "Test\n", 'Test croak called';

# found bogus names (not valid packages):

$expect     = q{Failed:};
my $tramp   = Object::Trampoline::Use->frobnicate( 'Broken' );

eval { $tramp->breaks_here };
ok $@ eq "Test\n", 'Test croak called';

done_testing;

__END__
