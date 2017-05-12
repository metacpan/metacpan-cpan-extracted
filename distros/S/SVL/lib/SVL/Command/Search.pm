package SVL::Command::Search;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command);
use constant subcommands => (qw(fix));

sub run {
  my ($self, $target) = @_;
  $target ||= "";
  
  my $sharing = SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);

  my @shares;
  my %local;
  my $bonjour = SVL::Bonjour->new;
  $bonjour->discover;
  foreach my $peer (@{ $bonjour->peers }) {
    foreach my $share (@{ $peer->shares }) {
      next if $target && !grep { $target eq $_ } @{ $share->tags };
      push @shares, $share;
      $local{ $share->uuid } = 1;
    }
  }

  my $opendht;
  eval { $opendht = SVL::OpenDHT->new };
  if ($target && $opendht) {
    foreach my $share ($opendht->show($target)) {
      next if $local{ $share->uuid };
      push @shares, $share;
    }
  }

  my $stale = 0;
  foreach my $share (sort { $a->url cmp $b->url } @shares) {
    print $share->url . " (" . $share->tags_as_string . ")\n";
    my @mirrored = $sharing->mirrored($share);
    foreach my $mirror (@mirrored) {
      print "  mirrored at /" . $mirror->mirror->{target_path} . "\n";
      if ($share->url ne $mirror->url) {
        $stale++;
        if ($self->fix) {
          SVN::Mirror->new(
            target_path => $mirror->mirror->{target_path},
            source      => $share->url,
            repospath   => $mirror->mirror->{repospath},
            repos       => $mirror->mirror->{repos},
            config      => $mirror->mirror->{config},
          )->relocate;
          print "  fixed stale mirror " . $mirror->url . "\n";
        } else {
          print "  stale mirror " . $mirror->url . "\n";
        }
      }
    }
  }
  if ($stale && !$self->fix) {
    print "svl: you have stale mirrors, run svl search --fix $target \n";
  }
}

sub fix {
  0;
}

package SVL::Command::Search::fix;
use base qw(SVL::Command::Search);

sub fix {
  1;
}

1;

__END__

=head1 NAME

SVL::Command::Search - Show shares matching a tag

=head1 SYNOPSIS

  svl search            # show all local shares
  svl search cpan       # show all local/remote shares that match cpan
  svl search --fix      # fix stale mirrors
  svl search --fix cpan # fix stale mirrors

=head1 OPTIONS

None.
