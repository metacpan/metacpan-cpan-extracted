package SVL::Command::Share;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command);
use constant subcommands => qw(list);

sub run {
  my ($self, $target, @tags) = @_;
  die "No target" unless $target;
  my $share =
    SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);
  $share->add($target, @tags);
}

package SVL::Command::Share::list;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command::Share);

sub run {
  my $self    = shift;
  my $sharing =
    SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);
  my @shares = $sharing->list;
  foreach my $share (sort { $a->path cmp $b->path } @shares) {
    my $depot = $share->depot;
    $depot = '' if $depot eq '_default_';
    print '/' . $depot . $share->path . " (" . $share->tags_as_string . ")\n";
  }
}
1;

__END__

=head1 NAME

SVL::Command::Share - Share a local repository

=head1 SYNOPSIS

  svl share //trunk/Acme-Colour/ tags
  svl share --list

=head1 OPTIONS

--list # show shared path
