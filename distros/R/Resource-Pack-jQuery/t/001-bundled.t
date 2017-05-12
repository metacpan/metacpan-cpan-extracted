#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Cwd;
use File::Temp;
use Path::Class;

use Resource::Pack::jQuery;

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('jquery-1.4.2.min.js');

    my $resource = Resource::Pack::jQuery->new(use_bundled => 1);
    ok(!-e $file, "jquery doesn't exist yet");
    $resource->install;
    ok(-e $file, "jquery exists!");
    like($file->slurp, qr/jQuery JavaScript Library v1\.4\.2/,
         "got the right jquery version");
    like($file->slurp, qr/\Q(function(A,w){function ma(){/,
         "got the minified jquery");
    chdir $oldcwd;
}

done_testing;
