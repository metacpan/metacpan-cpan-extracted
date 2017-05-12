package SVL::Command::Unshare;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command);

sub run {
  my($self, $target) = @_;
  die "No target" unless $target;
  my $share = SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);
  $share->delete($target);
}

1;

=head1 NAME

SVL::Command::Unshare - Stop sharing a path

=head1 SYNOPSIS

  svl unshare //trunk/Acme-Colour/

=head1 OPTIONS

None.