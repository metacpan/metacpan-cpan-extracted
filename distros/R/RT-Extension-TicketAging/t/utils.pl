#!/usr/bin/perl

use strict;
use warnings;


BEGIN {
### after:     push @INC, qw(@RT_LIB_PATH@);
    push @INC, qw(/opt/rt3/local/lib /opt/rt3/lib);
}

use RT;
RT::LoadConfig();

use IPC::Open3 qw(open3);
use File::Temp qw(tempfile);

our $exec = 'sbin/rt-aging';
die "Couldn't find programm '$exec'" unless -f $exec;
die "'$exec' is not executable" unless -x _;

sub run_exec {
    my %args = @_;
    my $cmd = "$^X -Mblib $exec";
    while ( my ($k,$v) = each %args ) {
        $cmd .= " --$k '$v'";
    }
    local $SIG{'PIPE'} = sub { die "bad" };

    my ($fh_out, $fh_in);
    my $fh_err = tempfile() or die "Couldn't open tmp file: $!";

    my $pid = open3($fh_in, $fh_out, $fh_err, $cmd);
    close $fh_in; waitpid $pid, 0;
    my $result = do { local $/; <$fh_out> };
    my $error = do { $fh_err->flush; seek $fh_err, 0, 0; local $/; <$fh_err> };

    DBIx::SearchBuilder::Record::Cachable->FlushCache;

    return ($result, $error);
}


sub run_exec_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag $err;
}


sub filter_log {
    my $msg = shift;
    $msg =~ s/^\[[^\]]+\]\s*\[(?:debug|info|warning)\]:.*?$//gms;
    $msg =~ s/^\s+|\s+$//g;
    return $msg;
}


sub verbose {
    return unless $ENV{TEST_VERBOSE};

    my $msg = shift;
    return diag($msg);
}
