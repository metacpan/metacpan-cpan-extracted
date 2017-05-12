package PApp::SCGI;

##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

use common::sense;
use Errno ();

use EV;
use AnyEvent;

use Agni;
use PApp ();
use PApp::CGI ();

our $VERBOSE;
our $LISTEN;
our $FH;
our $REFRESH;
our $CONTROL = \*STDOUT;
our $APPID;
our %APP; # app cache

sub SCGI_MAX_HEADER() { 16384 - 16 }

sub error($) {
   die shift;
}

sub run_request {
   print $FH <<EOF
Status: 404

nope
EOF
}

sub find_app {
   $APP{"$_[0]$_[1]"} ||= $_[0]->new (path => $_[1])
}

sub request {
   # scgi headerss must be at least 29 octets long
   # we only read 6, to limit header size to 100k

   my $buf;

   do {
      sysread $FH, $buf, 6 - length $buf, length $buf
         or $! == Errno::EINTR
         or error "$! while reading scgi header length";

      if ($buf =~ s/^([0-9]+:)//) {
         my $len = $1 + 1;

         $len <= SCGI_MAX_HEADER
            or error "$len: scgi header too long";

         do {
            sysread $FH, $buf, $len - length $buf, length $buf
               or $! == Errno::EINTR
               or error "$! while reading scgi header data";
         } while $len != length $buf;

         (substr $buf, -2, 2, "") eq "\x00,"
            or error "scgi header tail malformed";

         my %hdr = split /\x00/, $buf;

         warn "[$$] $hdr{REQUEST_METHOD} $hdr{REQUEST_SCHEME}://$hdr{HTTP_HOST}$hdr{REQUEST_URI} $VERBOSE\n"
            if $VERBOSE >= 3;

         use Data::Dump; warn Data::Dump::pp \%hdr;

         $hdr{SCRIPT_FILENAME} =~ /(PApp::Application[^\/]+)(.*)$/
            or error "SCRIPT_FILENAME must match valid papp application";

         local $PApp::papp = find_app $1, $2
            or error "$1$2: unable to resolve PApp application";

         open STDIN , "<&", fileno $FH;
         open STDOUT, ">&", fileno $FH;

         $PApp::request  = new_from PApp::CGI::Request \%hdr;
         $PApp::location = $PApp::request->{name};
         $PApp::pathinfo = $PApp::request->{path_info};

         PApp::_handler;

         close STDIN;
         close STDOUT;

         shutdown $FH, 2; #d# something keeps this alive
         undef $FH;

         return;
      }
   } while 6 != length $buf;

   error "scgi header malformed";
}

sub idle;
sub idle {
   my ($listen, $idle, $control);
   
   syswrite $CONTROL, "i";

   $listen = AE::io $LISTEN, 0, sub {
      accept $FH, $LISTEN
         or return;

      warn "[$$] accept.\n" if $VERBOSE >= 4;

      ($listen, $idle, $control) = ();

      AnyEvent::fh_block $FH;

      syswrite $CONTROL, "b";
      request $FH;
      idle;
   };

   $idle = AE::timer $REFRESH, $REFRESH, sub {
      warn "[$$] refresh.\n";#d#
      Agni::agni_refresh;
   };

   $control = AE::io $CONTROL, 0, sub {
      shutdown $CONTROL, 2;
      exit;
   };
}

sub master_init {
   ($VERBOSE) = @_;

   warn "[$$] master init @_.\n" if $VERBOSE;#d#

   configure PApp;
   configured PApp;
   Agni::agni_refresh; # to set up database &c

   $SIG{CHLD} = 'IGNORE';
}

sub master_refresh {
   warn "[$$] master refresh.\n";#d#
}

sub load_obj {
   my ($spec, $nsname) = @_;

   $spec =~ m%^([^/].*/)([^/]+)$%
      or die "$spec: unable to split into path/obj or path/name parts\n";

   my ($path, $name) = ($1, $2);
   my $pathid = $Agni::pathid{$path}
      or die "$path: path does not exist\n";

   $nsname = "GID" if $name =~ /^[0-9]+$/;  # gid
   $nsname = $1    if $name =~ s/^(.*?)=//; # explicit ns

   my $ns = (Agni::path_obj_by_gid $pathid, $Agni::OID_NAMESPACES)->lookup ($nsname)
      or die "$nsname: no such namespace\n";

   $ns->lookup ($name)
      or die "$name: no such object in namespace $nsname\n"
}

sub master_preload_obj {
   load_obj $_
      for @_;
}

sub master_preload_ns {
   warn "pre ns @_\n";#d#
   for my $spec (@_) {
      my $ns = load_obj $spec, "namespaces";
      for (@{ $ns->contents_gid }) {
         Agni::path_obj_by_gid $ns->{_path}, $_;
      }
   }
   warn "pre ns @_\n";#d#
}

sub run {
   ($CONTROL, $LISTEN, $REFRESH) = @_;

   warn "[$$] worker starting.\n" if $VERBOSE >= 2;

   delete $SIG{CHLD};

   PApp::post_fork_cleanup;
   PApp->event('childinit');

   idle;

   EV::run;
}

1



