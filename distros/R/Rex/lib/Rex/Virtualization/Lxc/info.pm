#
# (c) Oleg Hardt <litwol@litwol.com>
#

package Rex::Virtualization::Lxc::info;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Logger;
use Rex::Helper::Run;

sub execute {
  my ( $class, $arg1 ) = @_;
  my @dominfo;

  if ( !$arg1 ) {
    die('Must define container ID');
  }

  Rex::Logger::debug("Getting lxc-info");

  my @container_info = i_run "lxc-info -n $arg1", fail_ok => 1;
  if ( $? != 0 ) {
    die("Error running lxc-info");
  }

  my %ret;
  for my $line (@container_info) {
    my ( $column, $value ) = split( ':', $line );

    # Trim white spaces.
    $column =~ s/^\s+|\s+$//g;
    $value  =~ s/^\s+|\s+$//g;

    $ret{$column} = $value;
  }

  return \%ret;
}

1;
