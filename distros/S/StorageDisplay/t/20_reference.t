#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use utf8;
use Test2::V0;
use Test::Script;
#use Test::More;
use Test::File::Contents;
use Path::Class;


#file_contents_eq('utf8.txt',   'ååå', { encoding => 'UTF-8' });
#file_contents_eq('latin1.txt', 'ååå', { encoding => 'UTF-8' });

sub load_data {
    my $filename = shift;

    my $contents;
    my $dh;
    open($dh, "<", $filename)
	or die "Cannot open '$filename': $!" ;
    $contents=join('', <$dh>);
    close($dh);
    {
	my $VAR1;
	eval($contents); ## no critic (ProhibitStringyEval)
	#print STDERR "c: $content\n";
	return $VAR1;
    }
}


sub test_reference {
    my $file = shift;
    my $basename = $file->basename;
    my $refdata = file($file->dir, $basename.'.ref.data');
    my $refdot = file($file->dir, $basename.'.ref.dot');
    my $rawcmd = file($file->dir, $basename.'.rawcmd');
    my $data = file($file->dir, $basename.'.data');
    my $dot = file($file->dir, $basename.'.dot');

    my $opts = {
        style    => 'Unified',
        encoding => 'UTF-8',
    };

    ok(-f $rawcmd->stringify, "file ".$rawcmd->stringify." is present");

    unlink $data if -f $data;
    script_runs(['bin/storage2dot',
                 '--replay', $rawcmd->stringify,
                 '-c',
                 '-o', $data->stringify],
        "storage2dot generates ".$data->stringify);
    ok(-f $data, "file ".$data->stringify." was generated");

    my $struct_data_ref = load_data($refdata);
    my $struct_data = load_data($data);

    is($struct_data, $struct_data_ref, "data for $basename are the same as the reference")
	or files_eq_or_diff($refdata, $data, $opts);

    unlink $dot if -f $dot;
    script_runs(['bin/storage2dot',
                 '--data', $data->stringify,
                 '-o', $dot->stringify],
        "storage2dot generates ".$dot->stringify);
    ok(-f $dot, "file ".$dot->stringify." was generated");
    files_eq_or_diff($refdot, $dot, $opts);
}

sub test_reference_dir {
    my $d = shift;
    my $dir = dir($d);

    my $dh = $dir->open or die "Cann't open dir '$dir': $!";
    my @files = grep { /\.rawcmd$/ } readdir($dh);
    close($dh);
    map { s/\.rawcmd$// } @files;
    foreach my $base (sort @files) {
        test_reference(file($dir, $base)); 
    }
}

test_reference_dir('data');

done_testing;   # reached the end safely

