use Test::More tests => 2;

use strict;
use warnings;

use Path::Class::Iterator;

my $root = '.';

sub debug
{
    diag(@_) if $ENV{PERL_TEST};
}

ok(my $walker = Path::Class::Iterator->new(root => $root), "new object");

my $count = 0;
until ($walker->done)
{
    my $f = $walker->next;

    $count++;
    if (-l $f)
    {
        debug "$f is a symlink";
    }
    elsif (-d $f)
    {
        debug "$f is a dir";
    }
    elsif (-f $f)
    {
        debug "$f is a file";
    }
    else
    {
        debug "no idea what $f is";
    }

}

ok($count > 1, "found some files");
