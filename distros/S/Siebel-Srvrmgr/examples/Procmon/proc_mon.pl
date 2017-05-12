#!/usr/bin/env perl
use warnings;
use strict;
use feature 'say';
use Getopt::Std;
use File::Spec;
use Siebel::Srvrmgr::OS::Unix;
use DateTime;
use File::HomeDir;
use Readonly;
use Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias;
use lib '.';
use Archive;

Readonly my $MY_DBM =>
  File::Spec->catfile( File::HomeDir->my_home(), 'proc_mon.db' );

my %opts;

getopts( 'i:', \%opts );

die "the -i option requires a instance name as value"
  unless ( ( exists( $opts{i} ) ) and ( defined( $opts{i} ) ) );

my $enterprise_log = File::Spec->catfile(
    '',             lc( $opts{i} ),
    'siebel',       '81',
    'siebsrvr',     'enterprises',
    lc( $opts{i} ), $ENV{HOSTNAME},
    'log',          lc( $opts{i} ) . '.' . $ENV{HOSTNAME} . '.log'
);

my $siebel_path = File::Spec->catdir( '', lc( $opts{i} ), 'siebel' );

my $procs = Siebel::Srvrmgr::OS::Unix->new(
    {
        comps_source =>
          Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias->new(
            {
                process_regex => 'Created\s(multithreaded)?\sserver\sprocess', 
                log_path => $enterprise_log,
                archive  => Archive->new( { dbm_path => $MY_DBM } )
            }
          ),
        cmd_regex => $siebel_path,
    }
);

my $now = DateTime->now();
my $timestamp =
    $now->day() . '/'
  . $now->month() . '/'
  . $now->year() . ' '
  . $now->hour() . ':'
  . $now->minute();

my $procs_ref = $procs->get_procs();

my $output = 'output.csv';
open( my $out, '>>', $output ) or die "failed to write to $output: $!";

foreach my $pid ( keys( %{$procs_ref} ) ) {

    print $out join( '|',
        $timestamp,                     $pid,
        $procs_ref->{$pid}->get_pctcpu, $procs_ref->{$pid}->get_fname,
        $procs_ref->{$pid}->get_pctmem, $procs_ref->{$pid}->get_rss,
        $procs_ref->{$pid}->get_vsz,    $procs_ref->{$pid}->get_comp_alias ),
      "\n";

    my $comp_alias = $procs_ref->{$pid}->get_comp_alias();

}

close($out);
