package SVL::Command::Pull;
use strict;
use warnings;
use base qw( SVL::Command );
use constant options => ('C|check-only' => 'checkonly');
use SVK::Util qw(find_local_mirror);
use Path::Class;

sub run {
  my ($self, $path) = @_;
  my $target = $self->svkcmd->arg_co_maybe($path, 1);
  my $minfo =
    SVK::Merge->new(xd => $self->xd)->find_merge_sources($target, 1, 1);

  my ($ancestor_data)  = $target->copy_ancestors;

  #This is a work around because find_merge_sources doesn't find sources unless you have merged
  $minfo->{join(":", SVK::Util::find_svm_source($target->{repos}, $ancestor_data->[0], $ancestor_data->[1] ) )}++;

  my %shares;
  foreach my $share (SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd)->list) {
      $shares{$share->uuid}++;
  }

  
  

  my $source;
  for (sort keys %$minfo) {
    my ($uuid, $path) = split /:/;
    $source->{$uuid}->{$path}++;
  }

  my $bonjour = SVL::Bonjour->new;
  $bonjour->discover();

  foreach my $peer (@{ $bonjour->peers }) {
    my $host_port = $peer->address . ':' . $peer->svnport;
    foreach my $share (@{ $peer->shares }) {
      my $top_uuid  = $share->uuid;
      my $url       = $share->url;
      my $string    = `svn pg svk:merge --strict $url`;

      $string .= "\n".$share->uuid.":".$share->path .":0"; 
 
#      warn "$url => \n$string\n";
      my $peer_data = SVK::Merge::Info->new($string);
      foreach my $remote (values %$peer_data) {
        my $uuid = $remote->{uuid};
	next if(exists $shares{$share->uuid});
        next unless exists $source->{$uuid}->{$remote->{path}};
        $self->do_pull($peer, $target, $share->uuid, $share->path);
        last;
      }
    }
  }
}

sub do_pull {
  my ($self, $peer, $target, $uuid, $source) = @_;
  my ($path) = find_local_mirror($target->{repos}, $uuid, $source);

  # TODO: NO LOCAL MIRROR, WE SHOULD WARN
  unless($path) {
      warn "We have a remote repository relation but we don't have a local mirror please link\n";
      warn "$target->{repos}, $uuid, $source";
      return;
  }

  print "merge from " . $peer->name . "\n";

  # TODO: --remoterev and proper --host as well
  $self->svk->sm(
    '--sync', '-lm',
    "merge from " . $peer->name . " by svl:",
    "/" . $target->depotname . $path => $target->{depotpath}
  );

  $self->svk->up($target->{report})
    if exists $target->{copath};
}

1;

__END__

=head1 NAME

SVL::Command::Pull - Pull from repositories

=head1 SYNOPSIS

  svl pull
  svl pull --check-only

=head1 OPTIONS

---check-only # do not pull, check only

