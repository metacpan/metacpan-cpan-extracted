package SVL::Command;
use strict;
use warnings;
use Path::Class;
use SVK;
use base qw(App::CLI Class::Accessor::Chained::Fast App::CLI::Command);
__PACKAGE__->mk_accessors(qw(xd svk svkpath));

sub dispatch {
  my $class = shift;

  # hate!
  $ENV{HOME} ||= ($ENV{HOMEDRIVE} ? dir(@ENV{qw( HOMEDRIVE HOMEPATH )}) : '')
    || (getpwuid($<))[7];
  $ENV{USER} ||= ((defined &Win32::LoginName) ? Win32::LoginName() : '')
    || $ENV{USERNAME}
    || (getpwuid($<))[0];

  my $svkpath = $ENV{SVKROOT} || file($ENV{HOME}, ".svk");

  my $xd = SVK::XD->new(
    giantlock => file($svkpath, 'lock'),
    statefile => file($svkpath, 'config'),
    svkpath   => $svkpath,
  );
  $xd->load();

  $class->SUPER::dispatch(
    xd      => $xd,
    svkpath => $svkpath,
    svk     => SVK->new(xd => $xd)
  );
}

# return the SVK::Command object to use arg_*
sub svkcmd {
  my $self = shift;
  bless { xd => $self->xd }, 'SVK::Command';
}

sub error_cmd {
  "Command not recognized, try $0 help.\n";
}

1;
