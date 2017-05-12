#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use version;
use English qw(-no_match_vars $EVAL_ERROR);
use Data::Dumper;
use Object::Lazy;

my $object_1 = Object::Lazy->new({
    # A lazy Data::Dumper object as example.
    build       => sub {
        return Data::Dumper->new(['data'], ['my_dump_1']);
    },
    # take the version from class Data::Dumper;
    version_from => 'Data::Dumper',
    # tell me when
    logger       => sub {
        my $at_stack = shift;
        () = print "Real object 1 $at_stack";
    },
});

my $object_2 = Object::Lazy->new({
    # A lazy Data::Dumper object as example.
    build  => sub {
        return Data::Dumper->new(['data'], ['my_dump_2']);
    },
    # take the version from scalar;
    VERSION => qv('11.12.13'),
    # tell me when
    logger  => sub {
        my $at_stack = shift;
        () = print "Real object 2 $at_stack";
    },
});


{
    () = eval { $object_1->VERSION('9999') };
    () = print $EVAL_ERROR;
    my $version = $object_2->VERSION;
    () = print "$version = \$object_2->VERSION( qv(11.12.13') )\n"
}

# build the real object and call method output
$object_1->Dump;
$object_2->Dump;

# $Id$

__END__

output:

Data::Dumper version 9999 required--this is only version ... at ../lib/Object/Lazy.pm line 124.
11.12.13 = $object_2->VERSION( qv(11.12.13') )
Real object 1 object built at ../lib/Object/Lazy.pm line 35.
    Object::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
    eval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
    Try::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
    Object::Lazy::BUILD_OBJECT(Data::Dumper=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
    Object::Lazy::AUTOLOAD(Data::Dumper=HASH(...)) called at 05_VERSION.pl line 50
Real object 2 object built at ../lib/Object/Lazy.pm line 35.
    Object::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
    eval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
    Try::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
    Object::Lazy::BUILD_OBJECT(Data::Dumper=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
    Object::Lazy::AUTOLOAD(Data::Dumper=HASH(...)) called at 05_VERSION.pl line 51
