#!/usr/bin/perl -w

use strict;
use feature qw( switch );

use blib;

use IO::Async::Loop 0.16;
use Net::Async::FTP;

use Getopt::Long qw(:config no_ignore_case );

my $loop = IO::Async::Loop->new;

my $ftp = Net::Async::FTP->new;
$loop->add( $ftp );

my $port;

my $host;
my $user;
my $pass;

my $verbose = 0;

GetOptions(
   'port|p=i' => \$port,
   'host|h=s' => \$host,
   'user|u=s' => \$user,
   'pass|w=s' => \$pass,
   'P' => sub {
      print "Password: ";
      $pass = `bash -c 'read -s PASSWORD; echo \$PASSWORD'`; chomp $pass;
      print "\n";
   },
   'verbose|v+' => \$verbose,
) or exit(1);

defined $host or die "Need host\n";
defined $user or die "Need user\n";
defined $pass or die "Need a password\n";

my $mode = shift @ARGV or die "Need a mode\n";

my $connected = 0;

$ftp->connect(
   host    => $host,
   service => $port,

   on_connected => sub {
      print "Connected\n" if $verbose;

      $ftp->login(
         user => $user,
         pass => $pass,

         on_login => sub {
            $connected = 1;
         },

         on_error => sub { die "Failed - $_[0]\n" },
      );
   },

   on_error => sub { die "Failed - $_[0]\n" },
);

$loop->loop_once until $connected;

given( $mode ) {
   when( "list" ) {
      $ftp->list_parsed(
         path => $ARGV[0],
         on_list => sub {
            my @files = @_;
            print "name                                     type mode   size       mtime\n";
            printf "%- 40s %s    %06o %- 10s %s\n", 
               $_->{name}, $_->{type}, $_->{mode}, $_->{size}||0, scalar localtime($_->{mtime}) for @files;
            $loop->loop_stop;
         },
      );
   }
   when( "namelist" ) {
      $ftp->namelist(
         path => $ARGV[0],
         on_names => sub {
            my @names = @_;
            print "NAME: $_\n" for @names;
            $loop->loop_stop;
         },
      );
   }
   when( "retr" ) {
      $ftp->retr(
         path => $ARGV[0],
         on_data => sub {
            my ( $data ) = @_;
            print $data;
            $loop->loop_stop;
         },
      );
   }
   when( "stor" ) {
      my $data = do { local $/, <STDIN> };
      $ftp->stor(
         path => $ARGV[0],
         data => $data,
         on_stored => sub {
            $loop->loop_stop;
         },
      );
   }
   when( "dele" ) {
      $ftp->dele(
         path => $ARGV[0],
         on_done => sub {
            $loop->loop_stop;
         },
      );
   }
   when( "rename" ) {
      $ftp->rename(
         oldpath => $ARGV[0],
         newpath => $ARGV[1],
         on_done => sub {
            $loop->loop_stop;
         },
      );
   }
   when( "stat" ) {
      $ftp->stat(
         path => $ARGV[0],
         on_stat => sub {
            my @lines = @_;
            print "$_\n" for @lines;
            $loop->loop_stop;
         },
      );
   }
   when( "statp" ) {
      $ftp->stat_parsed(
         path => $ARGV[0],
         on_stat => sub {
            my %stat = @_;
            print "  {$_} => $stat{$_}\n" for keys %stat;
            $loop->loop_stop;
         },
      );
   }
   when( "readdatacmd" ) {
      my $command = $ARGV[0];
      my $data;
      my $on_error = sub { die "Error $_[0] ($_[1]) during $command" };

      $ftp->do_command( 
         join( " ", @ARGV ),
         start => sub { $ftp->_collect_dataconn( $data, $on_error ) },
         ok    => sub { 
            print $data;
            $loop->loop_stop;
         },
         err   => $on_error,
      );
   }
   when( "cmd" ) {
      $ftp->do_command(
         join( " ", @ARGV ),
         ok    => sub { 
            my ( $num, $message, @extralines ) = @_;
            print "$num: $message\n";
            print "  $_\n" for @extralines;
            $loop->loop_stop
         },
         'err' => sub { die "Error $_[0] ($_[1]) during $mode" },
      );
   }
   default {
      die "Unrecognised mode $mode\n";
   }
}

$loop->loop_forever;
