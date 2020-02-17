##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Application - a class representing a single mountable application

=head1 SYNOPSIS

   use PApp::Application;

   # you don't normally use this class directly

=head1 DESCRIPTION

This class is the base class for all mountable PApp applications.

=over 4

=cut

package PApp::Application;

use PApp::Config qw(DBH);
use PApp::Util;
use PApp::SQL;
use PApp::Exception;
use PApp::I18n ();

use Convert::Scalar ();

use common::sense;

our $VERSION = 2.2;

=item $papp = new PApp::Application args...

=cut

sub new {
   my $class = shift;

   bless { @_ }, $class;
}

=item $ppkg->preprocess

Parse the package (including all subpackages) and store the configuration
and code data in the PApp Package Cache(tm) for use by load_config and
load_code.

=item $papp->mount

Do necessary bookkeeping to mount an application.

=cut

sub load_config { }
sub load_code { }
sub mount { }

sub unload {
   my $self = shift;

   # this is most important
   sql_exec DBH, "delete from pkg where id = ? and ctime = ?", $self->{path}, $self->{ctime};

   delete $self->{cb_src};
   delete $self->{cb};

   delete $self->{ctime};
   delete $self->{compiled};
   delete $self->{translate};
   delete $self->{file};
   delete $self->{root}; # this might trigger a lot of memory freeing!
}

=item $papp->upgrade

Called to upgrade an applicaiton.

=cut

sub upgrade {
   # nop
}

=item $papp->event("event")

Distributes the event to all subpackages/submodules.

=cut

sub event($$) {
   my $self = shift;
   my $event = shift;
   if ($self->{cb}{$event}) {
      $self->{cb}{$event}();
      delete $self->{cb}{$event} if $event eq "init";
   }
}

=item $papp->load

Make sure the application is loaded (i.e. in-memory)

=cut

sub load {
   my $self = shift;

   $self->load_code;
}

=item $papp->surl(surl-args)

=item $papp->slink(slink-args)

Just like PApp::surl and PApp::slink, except that it also jumps into the
application (i.e. it switches applications).  C<surl> will act as if you
were in the main module of the application.

=cut

sub surl {
   my $self = shift;

   push @_, "/papp_appid" => $self->{appid};
   &PApp::surl;
}

sub slink {
   my $content = splice @_, 1,1;
   PApp::alink($content, &surl);
}

=item $changed = $papp->check_deps

Check dependencies and unload application if any dependencies have
changed.

=cut

sub check_deps($) {
   my $self = shift;
   my $reload;

   while (my ($path, $v) = each %{$self->{file}}) {
      $reload++ if (stat $path)[9] != $v->{mtime};
   }

   $self->reload if $reload;
   $reload;
}

sub reload {
   my $self = shift;
   my $code = $self->{compiled};
   warn "reloading application $self->{name}";
   $self->unload;
   $self->load_config;
   $self->load_code if $code;
}

=item register_file($name, %attrs)

Register an additional file (for dependency tracking and i18n
scanning). There should never be a need to use this function. Example:

  $papp->register_file("/etc/issue", lang => "en", domain => "mydomain");

=cut

sub register_file {
   my $self = shift;
   my $name = shift;
   my %attr = @_;
   $attr{lang} = PApp::I18n::normalize_langid $attr{lang};
   $self->{file}{$name} = \%attr;
}

=item $papp->run

"Run" the application, i.e. find the current package & module and execute it.

=item $papp->uncaught_exception ($exception, $callback)

This method is called when a surl callback dies ($callback true) or
another exception is caught by papp ($callback false).This method is free
to call C<abort_to> or other functions. If it returns, the exception will
be ignored.

The default implementation just rethrows.

=cut

sub uncaught_exception {
   PApp::handle_error ($_[1]);
}

package PApp::Application::Agni;

=back

=head2 PApp::Application::Agni

There is another Application type, Agni, which allows you to directly mount a specific
agni object. To do this, you have to specify the application path like this:

  PApp::Application::<obj_by_name_spec>

e.g., to mount the admin application in root/agni/, use one of these

  PApp::Application::Agni/root/agni/4295054263
  PApp::Application::Agni/root/agni/GID/4295054263
  PApp::Application::Agni/root/agni/agni/application::admin

=cut

use Carp 'croak';

use base "PApp::Application";

sub for_all_packages($&;$$) {
   my $self = shift;
   my $cb   = shift;
   my $path = shift || "";

   #$self->{root}->for_all_packages($cb, $path, $self->{root}{name});
}

sub new {
   my ($class, %arg) = @_;

   require Agni;

   &Agni::agni_exec (sub {
      my $obj = Agni::obj_by_name ($arg{path})
         or croak "unable to mount object $arg{path}";

      $class->SUPER::new (%arg, obj => $obj);
   });
}

sub run {
   local $PApp::papp    = shift;

   local $PApp::SQL::Database = $PApp::Config::Database;
   local $PApp::SQL::DBH      = $PApp::Config::DBH;

   $PApp::papp->{obj}->show;
}

sub upgrade {
   my $papp = shift;

   Agni::agni_exec (sub {
      $papp->{obj}->upgrade;
   });
}

=over 4

=item $papp->uncaught_exception

The Agni-specific version of this method calls the C<uncaught_exception>
method of the mounted application.

=cut

sub uncaught_exception {
   local $PApp::papp = shift;

   local $PApp::SQL::Database = $PApp::Config::Database;
   local $PApp::SQL::DBH      = $PApp::Config::DBH;

   $PApp::papp->{obj}->uncaught_exception ($_[0], $_[1]);
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

