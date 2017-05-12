#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    plan(skip_all => 'network tests disabled for shipped version')
        unless $ENV{RELEASE_TESTING};
}

use Cwd;
use File::Temp;
use Path::Class;

use Resource::Pack::JSON;

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('json2.js');

    my $resource = Resource::Pack::JSON->new;
    ok(!-e $file, "json doesn't exist yet");
    $resource->install;
    ok(-e $file, "json exists!");
    # minimal tests on the contents, since this url isn't versioned
    like($file->slurp, qr+\Qhttp://www.JSON.org/json2.js+,
         "got the json library");
    unlike($file->slurp, qr/\QRemove this line from json2.js before deployment/,
           "the alert has been removed");
    chdir $oldcwd;
}

done_testing;
