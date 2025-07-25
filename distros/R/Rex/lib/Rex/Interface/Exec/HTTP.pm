#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Interface::Exec::HTTP;

use v5.14.4;
use warnings;
use Rex::Commands;

our $VERSION = '1.16.1'; # VERSION

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  return $self;
}

sub exec {
  my ( $self, $cmd, $path, $option ) = @_;

  Rex::Logger::debug("Executing: $cmd");

  if ( exists $option->{path} ) {
    $path = $option->{path};
  }

  if ($path) { $path = "PATH=$path" }
  $path ||= "";

  # let the other side descide if LC_ALL=C should be used
  # for example, this will not work on windows
  #$cmd = "LC_ALL=C $path " . $cmd;

  Rex::Commands::profiler()->start("exec: $cmd");

  my $new_cmd = $cmd;
  if ( Rex::Config->get_source_global_profile ) {
    $new_cmd = ". /etc/profile >/dev/null 2>&1; $new_cmd";
  }

  my $resp =
    connection->post( "/execute", { exec => $new_cmd, options => $option } );
  Rex::Commands::profiler()->end("exec: $cmd");

  if ( $resp->{ok} ) {
    $? = $resp->{retval};
    my ( $out, $err ) = ( $resp->{output}, "" );

    Rex::Logger::debug($out);

    if ($err) {
      Rex::Logger::debug("========= ERR ============");
      Rex::Logger::debug($err);
      Rex::Logger::debug("========= ERR ============");
    }

    if (wantarray) { return ( $out, $err ); }

    return $out;
  }
  else {
    $? = 1;
  }

}

1;
