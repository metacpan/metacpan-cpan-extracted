#use strict;
#use warnings;

sub catdir
{
    shift;
    join '', map "*$_*", @_;
}

use File::Spec;
use Test::More tests => 5;
use_ok('Module::Replace');

Module::Replace::replace('File::Spec', \'main', qw(catdir));
is(File::Spec->catdir('foo','bar'), '*foo**bar*', 'overridden function');
ok(exists ${File::Spec::}{catdir});

Module::Replace::restore('File::Spec', \'main');
ok(not exists ${File::Spec::}{catdir});
isnt(File::Spec->catdir('foo','bar'), '*foo**bar*', 'restored function');


