#!/usr/bin/perl
#
#$Id: 01basic.t,v 1.5 2002/07/04 22:15:35 eric Exp $

use strict;
use FindBin    qw($Bin);
use File::Spec;
use File::Path qw(rmtree);
use POE;
use Time::HiRes;

our %FILES = map { $_ =>  1 } qw(foo);
use Test::More;
plan tests => 7;
use_ok('POE::Component::DirWatch::Object');

our $DIR   = File::Spec->catfile($Bin, 'watch');
our $state = 0;
our %seen;

POE::Session->create(
     inline_states =>
     {
      _start       => \&_tstart,
      _stop        => \&_tstop,
     },
    );


$poe_kernel->run();
ok(1, 'Proper shutdown detected');

exit 0;

sub _tstart {
        my ($kernel, $heap) = @_[KERNEL, HEAP];

        $kernel->alias_set("CharlieCard");

        # create a test directory with some test files
        rmtree $DIR;
        mkdir($DIR, 0755) or die "can't create $DIR: $!\n";
        for my $file (keys %FILES) {
            my $path = File::Spec->catfile($DIR, $file);
            open FH, ">$path" or die "can't create $path: $!\n";
            close FH;
        }

        my $watcher =  POE::Component::DirWatch::Object->new
            (
             alias      => 'dirwatch_test',
             directory  => $DIR,
             callback   => \&file_found,
             interval   => 1,
            );

        ok($watcher->alias eq 'dirwatch_test');
    }

sub _tstop{
    my $heap = $_[HEAP];
    ok(rmtree $DIR, 'Proper cleanup detected');
}

my $time;
sub file_found{
    my ( $file, $pathname) = @_;

    if(++$state == 1){
        $time = time + 5;
        $poe_kernel->post(dirwatch_test => '_pause', $time);
    } elsif($state == 2){
        ok($time <= time, "Pause Until Works");
        $time = time + 5;
        $poe_kernel->post(dirwatch_test => '_pause');
        $poe_kernel->post(dirwatch_test => '_resume',$time);
    } elsif($state == 3){
        ok($time <= time, "Pause - Resume When Works");
        $time = time + 5;
        $poe_kernel->post(dirwatch_test => '_pause');
        $poe_kernel->post(dirwatch_test => '_resume',$time);
    } elsif($state == 4){
        ok($time <= time, "Resume When Works");
        $poe_kernel->post(dirwatch_test => 'shutdown');
    } else {
        rmtree $DIR;
        die "Something is wrong, bailing out!\n";
    }
}

__END__
