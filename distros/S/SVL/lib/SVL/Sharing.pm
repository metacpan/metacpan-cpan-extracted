package SVL::Sharing;
use strict;
use warnings;
use base qw(Class::Accessor::Chained::Fast);
use Cwd 'realpath';
use File::Path;
use Path::Class;
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use SVK;
use Text::Tags::Parser;
__PACKAGE__->mk_accessors(qw(base svk xd));

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->base($_[0]);
  $self->xd($_[1]);
  $self->svk(SVK->new(xd => $self->xd));
  return $self;
}

sub fakesvkcmd {
  my ($self, $path) = @_;
  my $fakecmd = bless { xd => $self->xd }, 'SVK::Command';
  $fakecmd->arg_co_maybe($path, 1);
}

sub map_path_to_depot {
  my ($self, $path, $name) = @_;
  my $target = $self->fakesvkcmd($path);
  my $depot  = $target->depotname;
  die "Cannot find depot '$path'"
    unless (exists($self->xd->{depotmap}->{$depot}));
  $name = $depot unless ($name);
  return (
    file($self->base, $depot || '_default_'),
    $self->xd->{depotmap}->{$depot},
    $depot, $target
  );
}

sub set_tags {
  my ($self, $target, $path, @tags) = @_;
  my $tags = join "\n", @tags;
  $self->svk->ps(
    -m         => "tags for share $target->{depotpath} by svl",
    'svl:tags' => $tags,
    $path,
  );
}

sub get_tags {
  my ($self, $target, $path, $depot) = @_;
  my $tags = $self->xd->do_proplist($target->new(path => $path))->{'svl:tags'}
    || '';
  return Text::Tags::Parser->new->parse_tags(join " ", split "\n", $tags);
}

sub add {
  my ($self, $inpath, @tags) = @_;
  my ($share_path, $path, $depot, $target) =
    $self->map_path_to_depot($inpath, @tags);
  die "$target->{depotpath} doesn't exist.\n"
    unless $target->root->check_path($target->path);
  mkpath([ $self->base ]) unless -d $self->base;

  $self->set_tags($target, $inpath, @tags);

  my @prop =
    split(/\n/,
    $self->xd->do_proplist($target->new(path => '/'))->{'svl:share'} || '');
    lstat $share_path;

  die "$share_path already exists\n" if -e _ && @prop == 0;
  symlink $path => $share_path;
  print "Depot '$depot' is now shared\n";
  push @prop, $target->path;
  $self->svk->ps(
    -m => "share $target->{depotpath} by svl",
    'svl:share' => join("\n", @prop),
    "/$depot/"
  );
}

sub delete {
  my $self = shift;
  my ($share_path, $path, $depot, $target) = $self->map_path_to_depot(@_);

  my @prop =
    split(/\n/,
    $self->xd->do_proplist($target->new(path => '/'))->{'svl:share'} || '');
  @prop = grep { $_ ne $target->path } @prop;
  $self->svk->ps(
    -m => "unshare $target->{depotpath} by svl",
    'svl:share' => join("\n", @prop),
    "/$depot/"
  );

  print "Directory '" . $target->path . "' is now unshared\n";
  unless (@prop) {
    lstat $share_path;
    die "'$depot' isn't shared\n" unless -e _;
    unlink($share_path);
    print "Depot '$depot' is now unshared\n";
  }
}

sub list {
  my $self = shift;
  my $base = $self->base;
  my @shares;
  my $pool = SVN::Pool->new_default;
  for my $link (<$base/*>) {
    my $path = $link;
    my $depot = file($link)->basename;
    my $depotname = $self->resolve_depot_from_path($path);
    next unless defined $depotname;
    my $target = $self->fakesvkcmd("/$depotname/");
    my @prop   =
      split(/\n/, $self->xd->do_proplist($target)->{'svl:share'} || '');

    #    warn "$base $path $depotname : @prop";
    foreach my $prop (@prop) {
      my @tags = $self->get_tags($target, $prop, $depotname);
      push @shares,
        SVL::Share->new({
          depot => $depot,
          path => $prop,
          tags => \@tags,
          uuid => $target->{repos}->fs->get_uuid,
        });
    }
  }
  return @shares;
}

sub resolve_depot_from_path {
  my ($self, $path) = @_;
  $path = realpath($path);
  for (keys %{ $self->xd->{depotmap} }) {
    if ($self->xd->{depotmap}{$_} eq $path) {
      return $_;
    }
  }
  return;
}

sub mirrored {
  my($self, $share) = @_;
  my @paths;
  for my $mirror (
     SVL::Mirror->find_by_uuid(
       xd   => $self->xd,
       uuid => $share->uuid,
     )
     )
   {
     next unless $share->path eq $mirror->mirror->{rsource_path};
    push @paths, $mirror;
  }
  return @paths;
}

# return repos from given depot name or svl::share::depot object;
sub repos {
  my ($self, $path) = @_;
  if (ref($path)) {
    $path = file($self->base, $path->name);
  }
  return SVN::Repos::open($path);
}

1;
