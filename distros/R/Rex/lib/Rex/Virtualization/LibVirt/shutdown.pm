#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Virtualization::LibVirt::shutdown;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Logger;
use Rex::Helper::Run;

sub execute {
  my ( $class, $arg1, %opt ) = @_;
  my $virt_settings = Rex::Config->get("virtualization");
  chomp( my $uri =
      ref($virt_settings) ? $virt_settings->{connect} : i_run "virsh uri" );

  unless ($arg1) {
    die("You have to define the vm name!");
  }

  my $dom = $arg1;
  Rex::Logger::debug("shutdown domain: $dom");

  unless ($dom) {
    die("VM $dom not found.");
  }

  i_run "virsh -c $uri shutdown '$dom'", fail_ok => 1;
  if ( $? != 0 ) {
    die("Error shutdown vm $dom");
  }

}

1;
