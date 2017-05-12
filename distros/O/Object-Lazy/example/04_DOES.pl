#!perl ## no critic (TidyCode)

use strict;
use warnings;

use 5.010;

our $VERSION = 0;

use Object::Lazy;

my $object = Object::Lazy->new({
    # how to create the real object
    build  => sub {
        return RealClass->new;
    },
    # do not build at method DOES
    # inheritance
    isa    => 'RealClass', # array reference allowed too
    # roles
    DOES   => 'Role',      # array reference allowed too
    # tell me when
    logger => sub {
        my $at_stack = shift;
        () = print "RealClass $at_stack";
    },
});

{
    my $ok = $object->DOES('RealClass');
    () = print "$ok = \$object->DOES('RealClass');\n";
}
{
    my $ok = $object->DOES('RealClass');
    () = print "$ok = \$object->DOES('Role');\n";
}

# build the real object and call method output
$object->output;

# $Id$

package RealClass;

sub new {
    return bless {}, shift;
}

sub output {
    () = print "# Method output called!\n";

    return;
}

__END__

output:

1 = $object->DOES('RealClass');
1 = $object->DOES('Role');
RealClass object built at ../lib/Object/Lazy.pm line 35.
    Object::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
    eval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
    Try::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
    Object::Lazy::BUILD_OBJECT(RealClass=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
    Object::Lazy::AUTOLOAD(RealClass=HASH(...)) called at 04_DOES.pl line 39
# Method output called!
