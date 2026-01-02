#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use File::Temp qw(tempfile tempdir);

use lib 'lib';
use PAGI::Request::Upload;

subtest 'upload from memory buffer' => sub {
    my $upload = PAGI::Request::Upload->new(
        field_name   => 'avatar',
        filename     => 'photo.jpg',
        content_type => 'image/jpeg',
        data         => 'fake image data here',
    );

    is($upload->field_name, 'avatar', 'field_name');
    is($upload->filename, 'photo.jpg', 'filename');
    is($upload->basename, 'photo.jpg', 'basename');
    is($upload->content_type, 'image/jpeg', 'content_type');
    is($upload->size, 20, 'size');
    ok(!$upload->is_empty, 'not empty');
    ok($upload->is_in_memory, 'is in memory');
    ok(!$upload->is_on_disk, 'not on disk');
    is($upload->slurp, 'fake image data here', 'slurp');
};

subtest 'upload from temp file' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $temp_path) = tempfile(DIR => $dir);
    print $fh "file content here";
    close $fh;

    my $upload = PAGI::Request::Upload->new(
        field_name   => 'document',
        filename     => 'report.pdf',
        content_type => 'application/pdf',
        temp_path    => $temp_path,
        size         => 17,
    );

    ok(!$upload->is_in_memory, 'not in memory');
    ok($upload->is_on_disk, 'is on disk');
    is($upload->temp_path, $temp_path, 'temp_path');
    is($upload->slurp, 'file content here', 'slurp from file');
};

subtest 'basename strips path' => sub {
    my $upload = PAGI::Request::Upload->new(
        field_name   => 'file',
        filename     => 'C:\Users\John\Documents\file.txt',
        content_type => 'text/plain',
        data         => 'x',
    );

    is($upload->basename, 'file.txt', 'Windows path stripped');

    my $upload2 = PAGI::Request::Upload->new(
        field_name   => 'file',
        filename     => '/home/john/photos/vacation.jpg',
        content_type => 'image/jpeg',
        data         => 'x',
    );

    is($upload2->basename, 'vacation.jpg', 'Unix path stripped');
};

subtest 'is_empty' => sub {
    my $empty = PAGI::Request::Upload->new(
        field_name   => 'file',
        filename     => '',
        content_type => 'application/octet-stream',
        data         => '',
    );

    ok($empty->is_empty, 'empty upload detected');
    is($empty->size, 0, 'size is 0');
};

subtest 'move_to from memory' => sub {
    my $upload = PAGI::Request::Upload->new(
        field_name   => 'file',
        filename     => 'test.txt',
        content_type => 'text/plain',
        data         => 'test content 123',
    );

    my $dir = tempdir(CLEANUP => 1);
    my $dest = "$dir/moved.txt";

    $upload->move_to($dest);

    ok(-f $dest, 'file created');
    open my $fh, '<', $dest;
    my $content = do { local $/; <$fh> };
    close $fh;
    is($content, 'test content 123', 'content matches');
};

subtest 'move_to from disk' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $temp_path) = tempfile(DIR => $dir);
    print $fh "moveable content";
    close $fh;

    my $upload = PAGI::Request::Upload->new(
        field_name   => 'file',
        filename     => 'doc.txt',
        content_type => 'text/plain',
        temp_path    => $temp_path,
        size         => 16,
    );

    my $dest = "$dir/moved.txt";
    $upload->move_to($dest);

    ok(-f $dest, 'destination exists');
    ok(!-f $temp_path, 'temp file removed');

    open $fh, '<', $dest;
    my $content = do { local $/; <$fh> };
    close $fh;
    is($content, 'moveable content', 'content correct');
};

subtest 'filehandle access' => sub {
    my $upload = PAGI::Request::Upload->new(
        field_name   => 'file',
        filename     => 'data.txt',
        content_type => 'text/plain',
        data         => "line1\nline2\nline3\n",
    );

    my $fh = $upload->fh;
    my @lines = <$fh>;
    is(scalar(@lines), 3, 'three lines');
    is($lines[0], "line1\n", 'first line');
};

done_testing;
