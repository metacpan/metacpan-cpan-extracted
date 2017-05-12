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

use Resource::Pack::jQuery;

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('jquery-1.4.2.min.js');

    my $resource = Resource::Pack::jQuery->new(
        version => '1.4.2',
    );
    ok(!-e $file, "jquery doesn't exist yet");
    $resource->install;
    ok(-e $file, "jquery exists!");
    like($file->slurp, qr/jQuery JavaScript Library v1\.4\.2/,
         "got the right jquery version");
    like($file->slurp, qr/\Q(function(A,w){function ma(){/,
         "got the minified jquery");
    chdir $oldcwd;
}

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('jquery-1.4.2.js');

    my $resource = Resource::Pack::jQuery->new(
        version  => '1.4.2',
        minified => 0,
    );
    ok(!-e $file, "jquery doesn't exist yet");
    $resource->install;
    ok(-e $file, "jquery exists!");
    like($file->slurp, qr/jQuery JavaScript Library v1\.4\.2/,
         "got the right jquery version");
    like($file->slurp, qr:\Qvar jQuery = function(:,
         "got the non-minified jquery");
    chdir $oldcwd;
}

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('jquery-1.3.2.min.js');

    my $resource = Resource::Pack::jQuery->new(
        version => '1.3.2',
    );
    ok(!-e $file, "jquery doesn't exist yet");
    $resource->install;
    ok(-e $file, "jquery exists!");
    like($file->slurp, qr/jQuery JavaScript Library v1\.3\.2/,
         "got the right jquery version");
    like($file->slurp, qr/\Q(function(){var l/,
         "got the minified jquery");
    chdir $oldcwd;
}

{
    my $oldcwd = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;
    my $file = file('jquery-1.3.2.js');

    my $resource = Resource::Pack::jQuery->new(
        version  => '1.3.2',
        minified => 0,
    );
    ok(!-e $file, "jquery doesn't exist yet");
    $resource->install;
    ok(-e $file, "jquery exists!");
    like($file->slurp, qr/jQuery JavaScript Library v1\.3\.2/,
         "got the right jquery version");
    like($file->slurp, qr:\QjQuery.fn = jQuery.prototype = {:,
         "got the non-minified jquery");
    chdir $oldcwd;
}

done_testing;
