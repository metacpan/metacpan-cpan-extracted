use strict;
use warnings;

use Config;
BEGIN {
    if ($] < 5.008009) {
        print("1..0 # Skip Needs Perl 5.8.9 or later\n");
        exit(0);
    }
    if (! $Config{useithreads}) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}

use threads;
use threads::shared;

BEGIN {
    if ($threads::shared::VERSION lt '1.15') {
        print("1..0 # Skip Needs threads::shared 1.15 or later\n");
        exit(0);
    }
}

use Test::More 'tests' => 29;

package Container; {
    use Object::InsideOut qw(:SHARED);

    my @contents :Field;

    sub store
    {
        my ($self, $item) = @_;
        if (exists($contents[$$self])) {
            push(@{$contents[$$self]}, $item);
        } else {
            $self->set(\@contents, [ $item ]);
        }
        return $contents[$$self][-1];
    }

    sub peek
    {
        my $self = shift;
        return $contents[$$self][-1];
    }

    sub fetch
    {
        my $self = shift;
        pop(@{$contents[$$self]});
    }
}

package Jar; {
    use Object::InsideOut qw(Container :SHARED);
}

package Baggie; {
    use Object::InsideOut qw(Container :SHARED);
}

# Foreign hash-based class
package Foo; {
    sub new
    {
        my $class = shift;
        threads::shared::share(my %self);
        return (bless(\%self, $class));
    }

    sub set_foo
    {
        my ($self, $key, $value) = @_;
        $self->{$key} = $value;
    }

    sub get_foo
    {
        my ($self, $data) = @_;
        return ($self->{$data});
    }
}

package Cookie; {
    use Object::InsideOut qw(Foo :SHARED);

    my @kind :Field :All(kind);

    sub init :Init
    {
        my ($self, $args) = @_;

        $self->inherit(Foo->new());
    }
}


package main;

MAIN:
{
    my $C1 = 'chocolate chip';
    my $C2 = 'oatmeal raisin';
    my $C3 = 'vanilla wafer';

    my $cookie = Cookie->new('kind' => $C1);
    ok($cookie->kind() eq $C1, 'Have cookie');

    my $jar = Jar->new();
    $jar->store($cookie);

    ok($cookie->kind()      eq $C1, 'Still have cookie');
    ok($jar->peek()->kind() eq $C1, 'Still have cookie');
    ok($cookie->kind()      eq $C1, 'Still have cookie');

    threads->create(sub {
        ok($cookie->kind()      eq $C1, 'Have cookie in thread');
        ok($jar->peek()->kind() eq $C1, 'Still have cookie in thread');
        ok($cookie->kind()      eq $C1, 'Still have cookie in thread');

        $jar->store(Cookie->new('kind' => $C2));
        ok($jar->peek()->kind() eq $C2, 'Added cookie in thread');
    })->join();

    ok($cookie->kind()      eq $C1, 'Still have original cookie after thread');
    ok($jar->peek()->kind() eq $C2, 'Still have added cookie after thread');

    $cookie = $jar->fetch();
    ok($cookie->kind()      eq $C2, 'Fetched cookie from jar');
    ok($jar->peek()->kind() eq $C1, 'Cookie still in jar');

    $cookie = $jar->fetch();
    ok($cookie->kind()      eq $C1, 'Fetched cookie from jar');
    undef($cookie);

    share($cookie);
    $cookie = $jar->store(Cookie->new('kind' => $C3));
    ok($jar->peek()->kind() eq $C3, 'New cookie in jar');
    ok($cookie->kind()      eq $C3, 'Have cookie');

    threads->create(sub {
        ok($cookie->kind()      eq $C3, 'Have cookie in thread');
        $cookie = Cookie->new('kind' => $C1);
        ok($cookie->kind()      eq $C1, 'Change cookie in thread');
        ok($jar->peek()->kind() eq $C3, 'Still have cookie in jar');
    })->join();

    ok($cookie->kind()      eq $C1, 'Have changed cookie after thread');
    ok($jar->peek()->kind() eq $C3, 'Still have cookie in jar');
    undef($cookie);
    ok($jar->peek()->kind() eq $C3, 'Still have cookie in jar');
    $cookie = $jar->fetch();
    ok($cookie->kind()      eq $C3, 'Fetched cookie from jar');

    # Multiple levels of shared objects
    my $baggie = Baggie->new();
    $baggie->store($cookie);
    $jar->store($baggie);
    ok($jar->peek()->peek()->kind() eq $C3, 'Cookie in baggie in jar');

    # Inheritance with shared objects
    $cookie->set_foo('bar' => 99);
    threads->create(sub {
        ok($jar->peek()->peek()->get_foo('bar') == 99, 'Cookie foo in thread');
        $cookie->set_foo('insider' => Cookie->new('kind' => $C2));
        # New cookie
        $cookie = Cookie->new('kind' => $C1);
        # Old cookie in jar
        ok($jar->peek()->peek()->kind() eq $C3, 'Cookie in baggie in jar');
        ok($jar->peek()->peek()->get_foo('bar') == 99, 'Cookie foo in thread');
    })->join();

    ok($jar->peek()->peek()->get_foo('bar') == 99, 'Cookie foo in thread');
    ok($cookie->kind()      eq $C1, 'Have changed cookie after thread');
    ok($jar->peek()->peek()->get_foo('insider')->kind() eq $C2, 'Wow');
}

exit(0);

# EOF
