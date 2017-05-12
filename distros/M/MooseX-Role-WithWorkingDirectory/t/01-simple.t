use strict;
use warnings;

use Cwd;
use File::Spec;
use File::Temp qw(tempdir);
use Test::Builder;
use Test::Exception;
use Test::More tests => 12;
use autodie qw(chdir mkdir);

{
    package MyObject;

    use Cwd ();

    use Moose;
    with 'MooseX::Role::WithWorkingDirectory';

    sub test_method {
        my ( $self, $directory ) = @_;

        my $builder = Test::Builder->new;
        my $ok = $self->isa('MyObject') && $directory eq Cwd::getcwd();
        $builder->ok($ok);

        if(wantarray) {
            return ( 2 );
        } else {
            return 1;
        }
    }

    sub fail {
        die "hahahaha";
    }
}

my $orig_wd = getcwd();
my $tempdir = tempdir(CLEANUP => 1);
chdir($tempdir);

mkdir 'good';

my $object = MyObject->new;
can_ok($object, 'with_wd');

is(getcwd(), $tempdir, 'Verifying current directory');
$object->test_method($tempdir);
$object->with_wd('good')->test_method(File::Spec->catdir($tempdir, 'good'));
is(getcwd(), $tempdir, 'Verifying current directory');
dies_ok {
    $object->with_wd('bad')->test_method(File::Spec->catdir($tempdir, 'bad'));
};
dies_ok {
    $object->with_wd('good')->fail;
};
is(getcwd(), $tempdir, 'Verifying current directory');

my $result = $object->with_wd('good')->test_method(File::Spec->catdir($tempdir, 'good'));
is $result, 1, 'Verify that context works properly';

my @result = $object->with_wd('good')->test_method(File::Spec->catdir($tempdir, 'good'));
is_deeply [2], \@result, 'Verify that context works properly';

rmdir 'good';
chdir $orig_wd;
