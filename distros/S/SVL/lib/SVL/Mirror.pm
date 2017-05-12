package SVL::Mirror;
use strict;
use warnings;
use base qw(SVL);
use Carp;
use SVN::Mirror;
__PACKAGE__->mk_accessors(qw(depotname mirror));

sub url {
  my $self = shift;
  return $self->mirror->{rsource};
}

sub find_by_uuid {
  my $class  = shift;
  my %args   = @_;
  my $xd     = $args{xd} || confess "No xd!";
  my $uuid   = $args{uuid} || confess "No uuid!";
  my @depots =
    exists($args{depots}) ? @{ $args{depots} } : sort keys %{ $xd->{depotmap} };

  my @mirrors;

  foreach my $depot (@depots) {

    # XXX FIX THIS JUST REMOVING ALL SLASHES IS NOT GOOD
    $depot =~ s{/}{}g;

    # XXX IGNORING THE $@ OF AN EVAL {} IS BAD IT MIGHT DIE FOR ANY REASON
    # AND THEN WE ARE HIDING THE ERROR AND MAKING IT HARDER TO FIND THE BUG
    # WHICH IS ANNOYING IN THE LONG RUN -- sky

    my (undef, undef, $repos) = eval { $xd->find_repos("/$depot/", 1) };
    next unless $repos;

    foreach my $path (SVN::Mirror::list_mirror($repos)) {
      my $m = eval {
        my $mirror = SVN::Mirror->new(
          target_path => $path,
          repos       => $repos,
          get_source  => 1,
        );
        $mirror->init;
        $mirror;
      } or next;
      next unless $m->{source_uuid} eq $uuid;
      push @mirrors, SVL::Mirror->new->depotname($depot)->mirror($m);
    }
  }
  return @mirrors;
}

1;

