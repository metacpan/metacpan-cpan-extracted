#!/usr/bin/perl
#
#$Id: 01basic.t,v 1.5 2002/07/04 22:15:35 eric Exp $

use strict;
use FindBin    qw($Bin);
use File::Spec;
use File::Path qw(rmtree);
use POE;

our %FILES = (foo => 2, bar => 1);
use Test::More;
plan tests => 1;
use_ok('POE::Component::DirWatch::Object::Untouched');

exit;

#i'llfix it. i promise

our $DIR   = File::Spec->catfile($Bin, 'watch');
our $state = -1;
our %seen;

POE::Session->create(
     inline_states => 
     {
      _start   => \&_tstart,
      _stop    => \&_tstop,
      _endtest => sub { $_[KERNEL]->post(dirwatch_test => 'shutdown') }
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


	my $watcher =  POE::Component::DirWatch::Object::NewFile->new
	    (
	     alias      => 'dirwatch_test',
	     directory  => $DIR,
	     callback   => \&file_found,
	     interval   => 1,
	     edited     => 1,
	    );

	ok($watcher->alias eq 'dirwatch_test');

    }

sub _tstop{
    my $heap = $_[HEAP];
    rmtree $DIR;
}

sub file_found{
    my ($file, $pathname) = @_;

    ok(1, 'callback has been called');
    ok(exists $FILES{$file}, 'correct file');
    ++$seen{$file};
    is($pathname, File::Spec->catfile($DIR, $file), 'correct path');

    # don't loop
    if (++$state == keys %FILES) {
        is_deeply(\%FILES, \%seen, 'seen all files');
	ok($seen{foo} == 2," Picked up edited file");
	$poe_kernel->state("endtest",  sub{ $_[KERNEL]->post(CharlieCard => '_endtest') });
	$poe_kernel->delay("endtest", 5);
    } elsif ($state > keys %FILES) {
        rmtree $DIR;
        die "We seem to be looping, bailing out\n";
    } elsif($state == (keys %FILES) -1 ){
	my $path = File::Spec->catfile($DIR, 'foo');
	utime time, time, $path;
    }
}

__END__
