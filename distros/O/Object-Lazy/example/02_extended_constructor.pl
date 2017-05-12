#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use Object::Lazy;

my $object = Object::Lazy->new({
    # A lazy Data::Dumper object as example
    # will show you use or require late too.
    build  => sub {
        require Data::Dumper;
        return Data::Dumper->new(['data'], ['my_dump']);
    },
    # tell me when
    logger => sub {
        my $at_stack = shift;
        () = print "Data::Dumper $at_stack";
    },
});

sub do_something_with {
    my ($object, $condition) = @_; ## no critic (ReusedNames)

    if ($condition) {
        # the Data::Dumper object will be created
        () = print $object->Dump;
    }
    else {
        # the Data::Dumper object is not created
    }
    () = print
        "condition = $condition\n",
        "object = $object\n";

    return;
}

# do nothing
do_something_with($object, 0);

# build the real object and call method Dump
do_something_with($object, 1);

# $Id$

__END__

output:

condition = 0
object = Object::Lazy=HASH(...)
Data::Dumper object built at ../lib/Object/Lazy.pm line 35.
    Object::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
    eval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
    Try::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
    Object::Lazy::BUILD_OBJECT(Data::Dumper=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
    Object::Lazy::AUTOLOAD(Data::Dumper=HASH(...)) called at 02_extended_constructor.pl line 29
    main::do_something_with(Data::Dumper=HASH(...), 1) called at 02_extended_constructor.pl line 45
$my_dump = 'data';
condition = 1
object = Data::Dumper=HASH(...)
