#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Virtualization::LibVirt::option;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Logger;
use Rex::Helper::Run;

my $FUNC_MAP = {
  max_memory => "setmaxmem",
  memory     => "setmem",
};

sub execute {
  my ( $class, $arg1, %opt ) = @_;
  my $virt_settings = Rex::Config->get("virtualization");
  chomp( my $uri =
      ref($virt_settings) ? $virt_settings->{connect} : i_run "virsh uri" );

  unless ($arg1) {
    die("You have to define the vm name!");
  }

  my $dom = $arg1;
  Rex::Logger::debug("setting some options for: $dom");

  for my $opt ( keys %opt ) {
    my $val = $opt{$opt};

    unless ( exists $FUNC_MAP->{$opt} ) {
      Rex::Logger::info("$opt can't be set right now.");
      next;
    }

    my $func = $FUNC_MAP->{$opt};
    i_run "virsh -c $uri $func '$dom' '$val'", fail_ok => 1;
    if ( $? != 0 ) {
      Rex::Logger::info( "Error setting $opt to $val on $dom ($@)", "warn" );
    }

  }

}

1;
