use v5.10;
use strict;
use warnings;

use Test::More;
use TPath::Forester::File qw(tff);
use File::Temp ();
use Cwd qw(getcwd);
use FindBin qw($Bin);
use lib "$Bin/lib";
use TreeMachine;

my $dir = getcwd;

my $td = File::Temp::tempdir();
chdir $td;

file_tree(
    {
        name     => 'a',
        children => [
            { name => 'b', binary => 1 },
            {
                name => 'c',
                text => "theße are the times\nthat try men's souls"
            },
            {
                name     => 'd',
                children => [
                    {
                        name     => 'e',
                        children => [ { name => 'h', text => '' } ]
                    },
                    { name => 'f', binary => 1 },
                    {
                        name     => 'g',
                        encoding => 'iso-8859-1',
                        text     => "one çine"
                    }
                ]
            }
        ],
    }
);

my @files;

my $a = tff->wrap('a');

@files = tff->path('//@bin')->select($a);
is @files, 2, 'found right number of binary files';
is join( '', sort map { $_->name } @files ), 'bf', 'found the correct files';

@files = tff->path('//@B')->select($a);
is @files, 6, 'found right number of -B files';
is join( '', sort map { $_->name } @files ), 'abdefh',
  'found the correct files';

@files = tff->path('//@txt')->select($a);
is @files, 3, 'found right number of text files';
is join( '', sort map { $_->name } @files ), 'cgh', 'found the correct files';

@files = tff->path('//@z')->select($a);
is @files, 1, 'found right number of empty files';
is $files[0]->name, 'h', 'found correct empty file';

@files = tff->path('/a/*')->select($a);
is @files, 3, 'found three children of a';
is join( '', map { $_->name } @files ), 'bcd', 'found the correct children';

@files = tff->path('//@f')->select($a);
is @files, 5, 'found correct number of file files';
is join( '', sort map { $_->name } @files ), 'bcfgh', 'found the correct files';

@files = tff->path('//@d')->select($a);
is @files, 3, 'found correct number of directories';
is join( '', sort map { $_->name } @files ), 'ade',
  'found the correct directories';

@files = tff->path('//*[@lines = 2]')->select($a);
is @files, 1, 'found right number of two-line files';
is $files[0]->name, 'c', 'found correct two-line file';

TODO: {
    local $TODO = 'encoding detection needs more work';

    @files = tff->path('//*[@text =|= "theße"]')->select($a);
    is @files, 1, 'found right number of files containing a ß';
    is @files && $files[0]->name, 'c', 'found correct file containing ß';

    @files = tff->path('//*[@text =|= "çine"]')->select($a);
    is @files, 1, 'found right number of files containing a ç';
    is @files && $files[0]->name, 'g', 'found correct file containing ç';
}

@files = tff->path( '//*[@oid = ' . $< . ']' )->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@oid works';

my $gid = ( split / /, $( )[0];
@files = tff->path( '//*[@gid = ' . $gid . ']' )->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@gid works';

@files =
  tff->path( '//*[@user = "' . getpwuid($<) . '"]' )->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@user works';

my $group = getgrgid $gid;
@files = tff->path( '//*[@group = "' . $group . '"]' )->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@group works';

@files = tff->path('//*[@oid = @me]')->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@me works';

@files = tff->path('//*[@name =~ "[aeiou]"]')->select($a);
is join( '', sort map { $_->name } @files ), 'ae', '@name works';

@files = tff->path('//@r')->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@r works';

@files = tff->path('//@w')->select($a);
is join( '', sort map { $_->name } @files ), 'abcdefgh', '@w works';

@files = tff->path('//@x')->select($a);
is join( '', sort map { $_->name } @files ), 'ade', '@x works';

@files = tff->path('//*[@s = 0]')->select($a);
is join( '', sort map { $_->name } @files ), 'h', '@s works';

file_tree(
    {
        name     => 'b',
        children => [
            {
                name => 'c.txt',
                text => "foo bar baz"
            },
            {
                name     => 'd',
                children => [
                    {
                        name => 'e.txt',
                        text => "foo bar baz"
                    },
                    { name => 'ftxt', binary => 1 },
                    {
                        name => 'g',
                        text => "foo bar baz"
                    }
                ]
            }
        ],
    }
);

tff->clean;
my $b = tff->wrap('b');

@files = tff->path('//@ext("txt")')->select($b);
is @files, 2, 'found right number of files with the @txt("txt")';
is join( ' ', sort map { $_->name } @files ), 'c.txt e.txt', 'found the correct files';

chdir $dir;
rmtree($td);

done_testing();
