#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Cwd;
use File::Temp;
use Path::Class;

use Resource::Pack::JSON;

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('json2.js');

    my $resource = Resource::Pack::JSON->new(use_bundled => 1);
    ok(!-e $file, "json doesn't exist yet");
    $resource->install;
    ok(-e $file, "json exists!");
    like($file->slurp, qr/2010-03-20/,
         "got the right json version");
    like($file->slurp, qr/\Qif (!this.JSON) {/,
         "got something that looks like json2.js");
    unlike($file->slurp, qr/Remove this line from json2\.js before deployment/,
           "the alert has been removed");
    chdir $oldcwd;
}

done_testing;
