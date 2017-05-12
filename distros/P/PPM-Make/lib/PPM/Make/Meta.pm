package PPM::Make::Meta;
use strict;
use warnings;
use PPM::Make::Util qw(:all);
use File::Find;
use Safe;
use CPAN::Meta::YAML qw(LoadFile);

our $VERSION = '0.9904';

sub new {
  my ($class, %opts) = @_;
  my $cwd = $opts{dir};
  die qq{Please supply the name of the directory} unless $cwd;
  die qq{The supplied directory "$cwd" doesn't exist} unless -d $cwd;
  my $search = $opts{search};
  die qq{Please supply a PPM::Make::Search object}
    unless (defined $search and (ref($search) eq 'PPM::Make::Search'));
  my $self = {info => {}, cwd => $cwd, search => $search};
  bless $self, $class;
}

sub meta {
  my $self = shift;
  chdir $self->{cwd} or die qq{Cannot chdir to "$self->{cwd}": $!};
  my $mb = -e 'Build.PL';
  $self->{mb} = $mb;
  $self->parse_yaml if (-e 'META.yml');
  if ($mb and -d '_build') {
    $self->parse_build();
  }
  elsif (!$mb) { # ignore Module::Build::Tiny
    $self->parse_make();
  }
  $self->abstract();
  $self->author();
  $self->{info}->{VERSION} = (defined $self->{info}->{VERSION_FROM}) ?
    parse_version($self->{info}->{VERSION_FROM}) :
      $self->{info}->{VERSION};
  $self->bundle() if ($self->{info}->{NAME} =~ /^(Bundle|Task)/i);
  return 1;
}


sub parse_build {
  my $self = shift;
  my $bp = '_build/build_params';
#  open(my $fh, '<', $bp) or die "Couldn't open $bp: $!";
#  my @lines = <$fh>;
#  close $fh;
#  my $content = join "\n", @lines;
#  my $c = new Safe();
#  my $r = $c->reval($content);
#  if ($@) {
#    warn "Eval of $bp failed: $@";
#    return;
#  }
  my $file = $self->{cwd} . '/_build/build_params';
  my $r;
  unless ($r = do $file) {
    die "Can't parse $file: $@" if $@;
    die "Can't do $file: $!" unless defined $r;
    die "Can't run $file" unless $r;
  }

  my $props = $r->[2];
  my %r = ( NAME => $props->{module_name},
            DISTNAME => $props->{dist_name},
            VERSION => $props->{dist_version},
            VERSION_FROM => $props->{dist_version_from},
            PREREQ_PM => $props->{requires},
            AUTHOR => $props->{dist_author},
            ABSTRACT => $props->{dist_abstract},
          );
  foreach (keys %r) {
      next unless $r{$_};
      $self->{info}->{$_} ||= $r{$_};
  }
  return 1;
}

sub parse_yaml {
  my $self = shift;
  my $props;
  eval {$props = LoadFile('META.yml')};
  return if $@;
  my $author = ($props->{author} and ref($props->{author}) eq 'ARRAY') ?
    $props->{author}->[0] : $props->{author};
  my %r = ( NAME => $props->{name},
            DISTNAME => $props->{distname},
            VERSION => $props->{version},
            VERSION_FROM => $props->{version_from},
            PREREQ_PM => $props->{requires},
            AUTHOR => $author,
            ABSTRACT => $props->{abstract},
          );
  foreach (keys %r) {
    next unless $r{$_};
    $self->{info}->{$_} ||= $r{$_};
  }
  return 1;
}

sub parse_make {
  my $self = shift;
  my $flag = 0;
  my @wanted = qw(NAME DISTNAME ABSTRACT ABSTRACT_FROM AUTHOR 
                  VERSION VERSION_FROM PREREQ_PM);
  my $re = join '|', @wanted;
  my @lines;
  open(my $fh, '<', 'Makefile') or die "Couldn't open Makefile: $!";
  while (<$fh>) {
    if (not $flag and /MakeMaker Parameters/) {
      $flag = 1;
      next;
    }
    next unless $flag;
    last if /MakeMaker post_initialize/;
    next unless /$re/;
    # Skip MAN3PODS that can appear here if some words from @wanted found
    next if /^#\s+MAN3PODS => /;
    chomp;
    s/^#*\s+// or next;
    next unless /^(?:$re)\s*\=\>/o;
    push @lines, $_;
  }
  close($fh);
  my $make = join ',', @lines;
  $make = '(' . $make . ')';
  my $c = new Safe();
  my %r = $c->reval($make);
  die "Eval of Makefile failed: $@" if ($@);
  unless ($r{NAME}) {
    if ($r{NAME} = $r{DISTNAME}) {
      $r{NAME} =~ s/-/::/gx;
      warn 'Cannot determine NAME, using DISTNAME instead';
    } 
    else {
      die 'Cannot determine NAME and DISTNAME in Makefile';
    }
  }
  for (@wanted) {
    next unless $r{$_};
    $self->{info}->{$_} ||= $r{$_};
  }
  return 1;
}

sub abstract {
  my $self = shift;
  my $info = $self->{info};
  unless ($info->{ABSTRACT}) {
    if (my $abstract = $self->guess_abstract()) {
      warn "Setting ABSTRACT to '$abstract'\n";
      $self->{info}->{ABSTRACT} = $abstract;
    }
    else {
      warn "Please check ABSTRACT in the ppd file\n";
    }
  }
}

sub guess_abstract {
  my $self = shift;
  my $info = $self->{info};
  my $cwd = $self->{cwd};
  my $search = $self->{search};
  my $result;
  for my $guess(qw(ABSTRACT_FROM VERSION_FROM)) {
    if (my $file = $info->{$guess}) {
      print "Trying to get ABSTRACT from $file ...\n";
      $result = parse_abstract($info->{NAME}, $file);
      return $result if $result;
    }
  }
  my ($hit, $guess);
  for my $ext (qw(pm pod)) {
    if ($info->{NAME} =~ /-|:/) {
      ($guess = $info->{NAME}) =~ s!.*[-:](.*)!$1.$ext!;
    }
    else {
      $guess = $info->{NAME} . ".$ext";
    }
    finddepth(sub{$_ eq $guess && ($hit = $File::Find::name) 
                    && ($hit !~ m!blib/!)}, $cwd);
    next unless ($hit and -f $hit);
    print "Trying to get ABSTRACT from $hit ...\n";
    $result = parse_abstract($info->{NAME}, $hit);
    return $result if $result;
  }
  if (my $try = $info->{NAME} || $info->{DISTNAME}) {
    $try =~ s{-}{::}g;
    my $mod_results = $search->{mod_results};
    if (defined $mod_results and defined $mod_results->{$try}) {
      return $mod_results->{$try}->{mod_abs}
               if defined $mod_results->{$try}->{mod_abs};
    }
    if ($search->search($try, mode => 'mod')) {
      $mod_results = $search->{mod_results};
      if (defined $mod_results and defined $mod_results->{$try}) {
        return $mod_results->{$try}->{mod_abs}
                if defined $mod_results->{$try}->{mod_abs};
      }
    }
    else {
      $search->search_error();
    }
  }
  if (my $try = $info->{NAME} || $info->{DISTNAME}) {
    $try =~ s{::}{-}g;
    my $dist_results = $search->{dist_results};
    if (defined $dist_results and defined $dist_results->{$try}) {
      return $dist_results->{$try}->{dist_abs}
            if defined $dist_results->{$try}->{dist_abs};
    }
    if ($search->search($try, mode => 'dist')) {
      $dist_results = $search->{dist_results};
      if (defined $dist_results and defined $dist_results->{$try}) {
            return $dist_results->{$try}->{dist_abs}
              if defined $dist_results->{$try}->{dist_abs};
      }
    }
    else {
      $search->search_error();
    }
  }
  return;
}

sub bundle {
  my $self = shift;
  my $info = $self->{info};
  my $result = $self->guess_bundle();
  if ($result and ref($result) eq 'ARRAY') {
    warn "Extracting Bundle/Task info ...\n";
    foreach my $mod(@$result) {
      $info->{PREREQ_PM}->{$mod} = 0;
    }
  }
  else {
    warn "Please check prerequisites in the ppd file\n";
  }
}

sub guess_bundle {
  my $self = shift;
  my $info = $self->{info};
  my $cwd = $self->{cwd};
  my $result;
  for my $guess(qw(ABSTRACT_FROM VERSION_FROM)) {
    if (my $file = $info->{$guess}) {
      print "Trying to get Bundle/Task info from $file ...\n";
      $result = parse_bundle($file);
      return $result if $result;
    }
  }
  my ($hit, $guess);
  for my $ext (qw(pm pod)) {
    if ($info->{NAME} =~ /-|:/) {
      ($guess = $info->{NAME}) =~ s!.*[-:](.*)!$1.$ext!;
    }
    else {
      $guess = $info->{NAME} . ".$ext";
    }
    finddepth(sub{$_ eq $guess && ($hit !~ m!blib/!)
                    && ($hit = $File::Find::name) }, $cwd);
    next unless (-f $hit);
    print "Trying to get Bundle/Task info from $hit ...\n";
    $result = parse_bundle($hit);
    return $result if $result;
  }
  return;
}

sub parse_bundle {
  my ($file) = @_;
  my @result;
  local $/ = "\n";
  my $in_cont = 0;
  open(my $fh, '<', $file) or die "Couldn't open $file: $!";
  while (<$fh>) {
    $in_cont = m/^=(?!head1\s+CONTENTS)/ ? 0 :
      m/^=head1\s+CONTENTS/ ? 1 : $in_cont;
    next unless $in_cont;
    next if /^=/;
    s/\#.*//;
    next if /^\s+$/;
    chomp;
    my $result = (split " ", $_, 2)[0];
    $result =~ s/^L<(.*?)>/$1/;
    push @result, $result;
  }
  close $fh;
  return (scalar(@result) > 0) ? \@result : undef;
}

sub author {
  my $self = shift;
  my $info = $self->{info};
  unless ($info->{AUTHOR}) {
    if (my $author = $self->guess_author()) {
      $self->{info}->{AUTHOR} = $author;
      warn qq{Setting AUTHOR to "$author"\n};
    }
    else {
      warn "Please check AUTHOR in the ppd file\n";
    }
  }
}

sub guess_author {
  my $self = shift;
  my $info = $self->{info};
  my $search = $self->{search};
  my $results;
  if (my $try = $info->{NAME} || $info->{DISTNAME}) {
    $try =~ s{-}{::}g;
    my $mod_results = $search->{mod_results};
    if (defined $mod_results and defined $mod_results->{$try}) {
      return $mod_results->{$try}->{author}
        if defined $mod_results->{$try}->{author};
    }
    if ($search->search($try, mode => 'mod')) {
      $mod_results = $search->{mod_results};
      if (defined $mod_results and defined $mod_results->{$try}) {
        return $mod_results->{$try}->{author}
          if defined $mod_results->{$try}->{author};
      }
    }
    else {
      $search->search_error();
    }
  }
  if (my $try = $info->{DISTNAME} || $info->{NAME}) {
    $try =~ s{::}{-}g;
    my $dist_results = $search->{dist_results};
    if (defined $dist_results and defined $dist_results->{$try}) {
      return $dist_results->{$try}->{author}
        if defined $dist_results->{$try}->{author};
    }
    if ($search->search($try, mode => 'dist')) {
      $dist_results = $search->{dist_results};
      if (defined $dist_results and defined $dist_results->{$try}) {
        return $dist_results->{$try}->{author}
          if defined $dist_results->{$try}->{author};
      }
    }
    else {
      $search->search_error();
    }
  }
  return;
}

1;

__END__

=head1 NAME

PPM::Make::Meta - Obtain meta information for a ppm package

=head1 SYNOPSIS

  my $meta = PPM::Make::Meta->new(dir => $some_dir);
  $meta->meta();
  foreach my $key (keys %{$meta->{info}}) {
    print "$key has value $meta->{info}->{$key}\n";
  }

=head1 DESCRIPTION

This module attempts to obtain meta-information from the
sources of a CPAN distribution that is needed to make a ppm
package. One first creates the object as

 my $meta = PPM::Make::Meta->new(dir => $some_dir);

with the required option C<dir =E<gt> $some_dir> specifying
the name of the directory containing the source of the
CPAN distribution. A call to

  $meta->meta();

will then return available meta information as a
hash reference C<$meta-E<gt>{info}>, where the keys
are as follows.

=over

=item NAME - the name of the distribution

=item DISTNAME - the distribution name

=item VERSION - the distribution's version

=item VERSION_FROM - a file where the VERSION can be obtained

=item ABSTRACT - the distribution's abstract

=item ABSTRACT_FROM - a file where the ABSTRACT can be obtained

=item AUTHOR - the distribution's author

=item PREREQ_PM - a hash reference listing the prerequisites

=back

=head1 COPYRIGHT

This program is copyright, 2006 
by Randy Kobes E<gt>r.kobes@uwinnipeg.caE<lt>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM::Make>

=cut

