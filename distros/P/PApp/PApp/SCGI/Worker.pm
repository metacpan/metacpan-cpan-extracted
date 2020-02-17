##########################################################################
## All portions of this code are copyright (c) 2015,2016 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::SCGI::Worker - worker master process management

=head1 SYNOPSIS

   papp-scgid --help

=head1 DESCRIPTION

=cut

package PApp::SCGI::Worker;

use common::sense;
use AnyEvent;
use EV;
use PApp ();
use PApp::SCGI;
use Agni;

# functions dealing with the template process of papp-scgid

our ($VERBOSE, $REFRESH, $MAX_REQUESTS, $LISTEN);

sub init {
   ($VERBOSE, $REFRESH, $MAX_REQUESTS) = @_;

   print "[$$] master init @_.\n" if $VERBOSE;

   ($LISTEN) = AnyEvent::Fork::Serve::run_args;

   configure PApp;
   Agni::agni_refresh; # to set up database &c

   $SIG{CHLD} = 'IGNORE';
}

sub post_init {
   configured PApp;

   defined $AnyEvent::MODEL
      and die "PApp::SCGI::Worker: error: anyevent already initialised\n";

   $IO::AIO::VERSION and IO::AIO::nreqs ()
      and die "PApp::SCGI::Worker: error: IO::AIO busy in template process\n";
}

sub mount {
   my (@apps) = @_;

   while (@apps) {
      my ($pathgid, $location) = splice @apps, 0, 2;
      PApp->mount_agni_app ($pathgid, $location);
   }
}

sub refresh {
   print "[$$] master refresh.\n" if $VERBOSE >= 5;
   agni_refresh; # to set up database &c
}

sub preload_mod {
   for (@_) {
      s%::%/%g;
      print "[$$] preloading mod $_.pm\n" if $VERBOSE >= 1;
      require "$_.pm";
   }
}

sub preload_obj {
   obj_by_name $_
      for @_;
}

sub preload_bag {
   for my $spec (@_) {
      print "[$$] preloading bag $spec\n" if $VERBOSE >= 1;
      my $ns = obj_by_name $spec;
      for (@{ $ns->contents_gid }) {
         path_obj_by_gid $ns->{_path}, $_;
      }
   }
}

our $CONTROL; # control socket
our $CONTROLW;

sub finish {
   print "[$$] worker exiting ($_[0]).\n" if $VERBOSE >= 2;

   exit 0;
}

sub idle;
sub idle {
   my ($acceptor, $idler);

   $acceptor = AE::io $LISTEN, 0, sub {
      if (accept my $fh, $LISTEN) {
         ($acceptor, $idler) = ();
         syswrite $CONTROL, "1";
         PApp::SCGI::handle $fh;
         syswrite $CONTROL, "0";
         idle;

         --$MAX_REQUESTS
            or finish "mr";
      }
   };

   $idler = AE::timer $REFRESH, 0, sub {
      ($acceptor, $idler) = ();
      finish "id";
   };
}

sub run {
   ($CONTROL) = @_;

   print "[$$] worker starting.\n" if $VERBOSE >= 2;

   delete $SIG{CHLD};

   defined $AnyEvent::MODEL
      and die "PApp::SCGI::Worker: error: anyevent already initialised\n";

   AnyEvent::detect;
   AE::now_update;

   $IO::AIO::VERSION
      and IO::AIO::reinit (); # close your eyes and fly blind

   PApp::post_fork_cleanup;
   PApp->event('childinit');

   AnyEvent::fh_block $CONTROL;

   $CONTROLW = AE::io $CONTROL, 0, sub {
      exit 0;
   };

   idle;

   @_ = ();
   goto &EV::run;
}

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

