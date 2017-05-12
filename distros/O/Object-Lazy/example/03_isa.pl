#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use Object::Lazy;

my $object = Object::Lazy->new({
    # how to create the real object
    build  => sub {
        return RealClass->new;
    },
    # do not build at method isa
    # isa => 'RealClass',
    # or
    isa    => [qw(RealClass BaseClassOfRealClass)],
    # tell me when
    logger => sub {
        my $at_stack = shift;
        () = print "RealClass $at_stack";
    },
});

{
    my $ok = $object->isa('RealClass');
    () = print "$ok = \$object->isa('RealClass');\n";
}

# ask about inheritage
{
    my $ok = $object->isa('BaseClassOfRealClass');
    () = print "$ok = \$object->isa('BaseClassOfRealClass');\n";
}

# build the real object and call method output
$object->output;

# $Id$

package RealClass;

use parent qw(-norequire BaseClassOfRealClass);


package BaseClassOfRealClass; ## no critic (MultiplePackages)

sub new {
    return bless {}, shift;
}

sub output {
    () = print "# Method output called!\n";

    return;
}

__END__

output:

1 = $object->isa('RealClass');
1 = $object->isa('BaseClassOfRealClass');
RealClass object built at ../lib/Object/Lazy.pm line 35.
    Object::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
    eval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
    Try::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
    Object::Lazy::BUILD_OBJECT(RealClass=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
    Object::Lazy::AUTOLOAD(RealClass=HASH(...)) called at 03_isa.pl line 38
# Method output called!
