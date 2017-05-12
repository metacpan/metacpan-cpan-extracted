if (!defined $PApp::Apache2::_compiled) { eval do { local $/; <DATA> }; die if $@ } 1;
__DATA__

#line 5 "(PApp/Apache2.pm)"

##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Apache2 - multi-page-state-preserving web applications

=head1 SYNOPSIS

   #   Apache's httpd.conf file
   #   mandatory: activation of PApp
   PerlModule PApp::Apache2

   # configure the perl module
   <Perl>
      search_path PApp "/root/src/Fluffball/macro";
      search_path PApp "/root/src/Fluffball";
      configure PApp (
         cipherkey => "f8da1b96e906bace04c96dbe562af9x31957b44e4c282a1658072f0cbe6ba44d",
         pappdb    => "DBI:mysql:papp",
         checkdeps => 1,
      );

      # mount an application (here: dbedit.papp)
      mount_appset PApp (
         location => "/dbedit",
         src => "dbedit.papp"
      );
      configured PApp; # mandatory
   </Perl>

=head1 DESCRIPTION

This module interfaces PApp to the Apache web browser, version 2.

=over 4

=cut

package PApp::Apache2::Gateway;
use Apache2 ();
use Apache::Log ();
use Apache::RequestIO ();
use Apache::RequestRec ();

our @ISA = Apache::RequestRec::;

sub new {
   bless $_[1], $_[0];
}

sub warn {
   warn $_[1];
}

sub log_reason {
   my $self = shift;
   $self->log_error(@_);
}

sub query_string {
   $ENV{QUERY_STRING}
}

sub header_out {
   my $self = shift;
   if(@_ == 1) {
      $self->headers_out->get(@_);
   } else {
      $self->headers_out->set(@_);
   }
}

sub send_http_header {
    $_[0]->content_type;
}

sub header_in {
   my $self = shift;
   if(@_ == 1) {
      $self->headers_in->get(@_);
   } else {
      $self->headers_in->set(@_);
   }
}

# send_fd is not implemented in Apache 2.0
# we use sendfile as fallback but it's ugly.
use File::Temp qw(tempfile);
use APR::Const    -compile => 'SUCCESS';

sub send_fd {
   my ($self, $fd) = @_;
   my ($dst, $name) = tempfile();

   my $buf;
   while(my $cnt = sysread($fd, $buf, 8192)) {
        syswrite($dst, $buf) == $cnt or die "syswrite on $name failed $!";
   }
   my $rc = $self->sendfile($name);
   unlink $name;
   die "sendfile failed: $rc" unless $rc == APR::SUCCESS;
   return Apache::OK; 
}

use POSIX qw(dup2 open close O_WRONLY);
sub internal_redirect {
   my $self = shift;
   my $fd = POSIX::open("/dev/null", O_WRONLY);
   dup2($fd,1);
   close($fd);
   untie *STDOUT; open STDOUT, ">&1";
   $self->SUPER::internal_redirect(@_);
}

sub content {
   my $self = shift;

   my $len = $self->headers_in->get("Content-Length");
   my $got = 0;
   my $data = "";
   while($got < $len) {
      $got += read STDIN, $data, $len - $got, $got;
      defined $! and last;
   }
   die "error getting post data expected=$len got=$got\n" unless $got == $len;
   $data;
}


# for future debugging only :)
sub DESTROY {
   $self->SUPER::DESTROY
}


package PApp::Apache2;

use Carp;
use Apache2 ();
use Apache::RequestRec ();
use Apache::RequestIO ();
use Apache::Const -compile => qw(OK);
use Apache::SubRequest (); # internal_redirect
use FileHandle ();
use File::Basename qw(dirname);

use PApp;
use PApp::Exception;

BEGIN {
   our @ISA = PApp::Base::;
   unshift @PApp::ISA, __PACKAGE__;
   $VERSION = 2.1;
}

*PApp::OK = sub { OK };

sub config_error {
   my $self = shift;
   my $err = shift;
   warn "$err\nPApp: error during configuration caught, skipping some stages\n";
}

sub ChildInit {
   unless (PApp::configured_p) {
      warn "FATAL: 'configured PApp' was never called, disabling PApp";
   }

   PApp::post_fork_cleanup;

   PApp->event('childinit');
}

sub apache_config_package {
   my $level = 0;
   1 while (caller(++$level))[0] =~ /^PApp/;
   (caller($level))[0];
}

sub interface {
   qw(PApp::Apache2 1.0);
}

sub configure {
   my $self = shift;
   my $cfg = apache_config_package;
   #${"${cfg}::PerlInitHandler"} = "PApp::Apache2::Init";
   ${"${cfg}::PerlChildInitHandler"} = "PApp::Apache2::ChildInit";
   $self->SUPER::configure(@_);
}

sub mount {
   my $self = shift;
}

sub mount {
   my $self = shift;
   my $papp = shift;

   $self->SUPER::mount($papp, @_);

   my $appid = $papp->{appid};

   my $handler = "PApp::Apache2::handler_for_appid".$appid;
   my %papp_handler = (
         SetHandler  => 'perl-script',
         PerlResponseHandler => $handler,
   );
    $handler .= "::handler";
   *$handler = sub {
      package PApp;
      use Apache::RequestRec ();

      $request = new PApp::Apache2::Gateway $_[0];
      $PApp::papp = $papp;

      $location = $request->uri;
      $pathinfo = $request->path_info;
      substr ($location, -length $pathinfo) = "" if $pathinfo;

      _handler;
   };

   my $mountconfig = $papp->{mountconfig};
   if ($mountconfig !~ /%papp_handler/) {
      # INSECURE, should check for empty string instead (TYPOE!)#FIXME#d#
      warn "$papp->{path} [appid=$appid]: mountconfig does not contain '%papp_handler', mounting on '/$papp->{name}'\n";
      $mountconfig = "\$Location{'~ ^/$papp->{name}(/|\$)'} = \\%papp_handler";
   };

   my $package = apache_config_package;

   eval "package $package; $mountconfig";
   $@ and fancydie "error while evaluating mountconfig", "$@",
                   info => [app => "$papp->{path} [appid=$appid]"],
                   info => [mountconfig => $mountconfig];

   $papp;
}

<<'EOF';
#
#   optional Apache::Status information
#
Apache::Status->menu_item(
    'PApp' => 'PApp status',
    sub {
        my ($r, $q) = @_;
        push(@s, "<b>Status Information about PApp</b><br>");
        return \@s;
    }
) if Apache->module('Apache::Status');
EOF

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

 Stefan Traby <oesi@schmorp.de>

=cut


