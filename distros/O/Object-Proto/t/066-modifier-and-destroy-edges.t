use strict;
use warnings;
use Test::More;
use Object::Proto;

Object::Proto::define('MD', 'a');

for my $kind (qw(before after around)) {
    my $f = \&{"Object::Proto::$kind"};
    eval { $f->('MD::a', 'not code') };
    like($@, qr/Second argument must be a code reference/, "$kind wants a code reference");
    eval { $f->('a', sub { }) };
    like($@, qr/Method name must be fully qualified \(Class::method\)/, "$kind wants a qualified name");
    eval { $f->('Nope::a', sub { }) };
    like($@, qr/Class 'Nope' not defined with Object::Proto::define/, "$kind wants a defined class");
}

my @log;
Object::Proto::before('MD::ghost', sub { push @log, 'before' });
Object::Proto::after('MD::ghost', sub { push @log, 'after' });
my @r = MD->new->ghost;
is_deeply(\@r, [], 'a modified method that never existed returns nothing');
is_deeply(\@log, ['before', 'after'], 'and still runs its modifiers');

package MD::Dies;
sub DEMOLISH { die "boom\n" }
package MD::Own;
our $destroyed = 0;
sub DESTROY { $destroyed++ }
sub DEMOLISH { die "never called\n" }
package main;

Object::Proto::define('MD::Dies', 'a');
my @warned;
{
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    my $d = MD::Dies->new;
    undef $d;
}
like($warned[0], qr/Error in DEMOLISH: boom/, 'an error in DEMOLISH is a warning');

Object::Proto::define('MD::Own', 'a');
{
    my $w = MD::Own->new;
}
is($MD::Own::destroyed, 1, 'a class with its own DESTROY keeps it');

eval { Object::Proto::singleton('Nope') };
like($@, qr/Class 'Nope' not defined with Object::Proto::define/, 'singleton wants a defined class');

my $o = MD->new;
Object::Proto::freeze($o);
eval { Object::Proto::lock($o) };
like($@, qr/Object is frozen/, 'a frozen object cannot be locked');

eval { Object::Proto::import_accessors('Nope') };
like($@, qr/Class 'Nope' not defined with Object::Proto::define/, 'import_accessors wants a defined class');
eval { Object::Proto::import_accessor('Nope', 'a') };
like($@, qr/Class 'Nope' not defined with Object::Proto::define/, 'import_accessor wants a defined class');
eval { Object::Proto::import_accessor('MD', 'nope') };
like($@, qr/Property 'nope' not defined in class 'MD'/, 'and a defined property');
Object::Proto::import_accessor('MD', 'a', 'md_a', 'MD::Elsewhere');
ok(MD::Elsewhere->can('md_a'), 'import_accessor takes the package as its fourth argument');
is(MD::Elsewhere::md_a($o), undef, 'and the accessor works there');

done_testing;
