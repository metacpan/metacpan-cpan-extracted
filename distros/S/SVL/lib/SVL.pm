package SVL;
use strict;
use warnings;
use Path::Class;
use SVL::Bonjour;
use SVL::Sharing;
use SVL::Share;
use SVN::Core;
use base qw(Class::Accessor::Chained::Fast);
our $VERSION = "0.29";
our $SVNSERVE_PORT = 48513;
our $SVL_PORT = 48512;

1;

__END__

=head1 NAME

svl - A peer-to-peer version of svk

=head1 SYNOPSIS

  # The following commands are evailable in svl:
  svl help checkout
  svl help pull
  svl help share
  svl help search
  svl help unshare
  svl help tag

=head1 OPTIONS

None.
