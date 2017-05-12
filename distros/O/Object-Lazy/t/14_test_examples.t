#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING} or plan(
    skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.'
);

plan(tests => 6);

my @data = (
    {
        test   => '01_short_constructor',
        path   => 'example',
        script => '-I../lib -T 01_short_constructor.pl',
        result => <<'EOT',
condition = 0
object = Object::Lazy=HASH(...)
$my_dump = 'data';
condition = 1
object = Data::Dumper=HASH(...)
EOT
    },
    {
        test   => '02_extended_constructor',
        path   => 'example',
        script => '-I../lib -T 02_extended_constructor.pl',
        result => <<'EOT',
condition = 0
object = Object::Lazy=HASH(...)
Data::Dumper object built at ../lib/Object/Lazy.pm line 35.
\tObject::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
\teval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
\tTry::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
\tObject::Lazy::BUILD_OBJECT(Data::Dumper=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
\tObject::Lazy::AUTOLOAD(Data::Dumper=HASH(...)) called at 02_extended_constructor.pl line 29
\tmain::do_something_with(Data::Dumper=HASH(...), 1) called at 02_extended_constructor.pl line 45
$my_dump = 'data';
condition = 1
object = Data::Dumper=HASH(...)
EOT
    },
    {
        test   => '03_isa',
        path   => 'example',
        script => '-I../lib -T 03_isa.pl',
        result => <<'EOT',
1 = $object->isa('RealClass');
1 = $object->isa('BaseClassOfRealClass');
RealClass object built at ../lib/Object/Lazy.pm line 35.
\tObject::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
\teval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
\tTry::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
\tObject::Lazy::BUILD_OBJECT(RealClass=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
\tObject::Lazy::AUTOLOAD(RealClass=HASH(...)) called at 03_isa.pl line 38
# Method output called!
EOT
    },
    {
        test   => '04_DOES',
        path   => 'example',
        script => '-I../lib -T 04_DOES.pl',
        result => <<'EOT',
1 = $object->DOES('RealClass');
1 = $object->DOES('Role');
RealClass object built at ../lib/Object/Lazy.pm line 35.
\tObject::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
\teval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
\tTry::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
\tObject::Lazy::BUILD_OBJECT(RealClass=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
\tObject::Lazy::AUTOLOAD(RealClass=HASH(...)) called at 04_DOES.pl line 39
# Method output called!
EOT
    },
    {
        test   => '05_VERSION',
        path   => 'example',
        script => '-I../lib -T 05_VERSION.pl',
        result => <<'EOT',
Data::Dumper version 9999 required--this is only version ... at ../lib/Object/Lazy.pm line 124.
11.12.13 = $object_2->VERSION( qv(11.12.13') )
Real object 1 object built at ../lib/Object/Lazy.pm line 35.
\tObject::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
\teval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
\tTry::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
\tObject::Lazy::BUILD_OBJECT(Data::Dumper=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
\tObject::Lazy::AUTOLOAD(Data::Dumper=HASH(...)) called at 05_VERSION.pl line 50
Real object 2 object built at ../lib/Object/Lazy.pm line 35.
\tObject::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
\teval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
\tTry::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
\tObject::Lazy::BUILD_OBJECT(Data::Dumper=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 53
\tObject::Lazy::AUTOLOAD(Data::Dumper=HASH(...)) called at 05_VERSION.pl line 51
EOT
    },
    {
        test   => '06_ref',
        path   => 'example',
        script => '-I../lib -T 06_ref.pl',
        result => <<'EOT',
RealClass = ref $object;
RealClass object built at ../lib/Object/Lazy.pm line 35.
\tObject::Lazy::try {...} () called at D:/Perl/site/lib/Try/Tiny.pm line 81
\teval {...} called at D:/Perl/site/lib/Try/Tiny.pm line 72
\tTry::Tiny::try(CODE(...), Try::Tiny::Catch=REF(...)) called at ../lib/Object/Lazy.pm line 39
\tObject::Lazy::BUILD_OBJECT(RealClass=HASH(...), REF(...)) called at ../lib/Object/Lazy.pm line 110
\tObject::Lazy::can(RealClass=HASH(...), "new") called at 06_ref.pl line 27
CODE(...) = $object->can('new')
EOT
    }
);

for my $data (@data) {
    # run example
    my $dir = getcwd;
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);

    # normalize reference addresses
    $result =~ s{
        ( SCALAR | ARRAY | HASH | CODE | REF )
        \( 0x [0-9a-f]+ \)
    }
    {$1(...)}xmsg;

    # normalize version number
    $result =~ s{
        ( \Qthis is only version\E ) \s+ \S+
    }
    {$1 ...}xms;

    # interpolate tab only
    $data->{result} =~ s{\\t}{\t}xmsg;

    SKIP: {
        if ( UNIVERSAL->can('DOES') ) {
            eq_or_diff(
                $result,
                $data->{result},
                $data->{test},
            );
        }
        else {
            skip('UNIVERSAL 1.04 (Perl 5.10) required for method DOES', 1);
        }
    }
}
