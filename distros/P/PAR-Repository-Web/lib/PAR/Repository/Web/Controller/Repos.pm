package PAR::Repository::Web::Controller::Repos;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

PAR::Repository::Web::Controller::Repos - Catalyst Controller for repository viewing

=head1 SYNOPSIS

See L<PAR::Repository::Web>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 repos

Implements C</repos>, the repository list.

=cut

sub repos : Path('/repos') {
  my ( $self, $c ) = @_;

  my $repos = $c->model($c->config->{model})->get_repository_configuration();

  my $rows = [];
  foreach my $repo_alias (keys %$repos) {
    push @$rows, {alias => $repo_alias, name => $repos->{$repo_alias}{name}};
  }

  $c->stash->{rows} = $rows;
  $c->stash->{template} = 'repos.tt';
}

=head2 show_repository

Implements C</repos/ALIAS>, the main page for a repository.

=cut

sub show_repository : Regex('^repos/(\w+)$') {
  my ( $self, $c ) = @_;
  my $alias = $c->req->snippets->[0];

  $c->stash->{reponame} = $c->model($c->config->{model})->get_repository_configuration()->{$alias}{name};
  $c->stash->{alias} = $alias;
  $c->stash->{template} = 'repository.tt';
}

=head2 show_dist

Implements C</repos/ALIAS/dist>, the list of distributions in a repository.

=cut

sub show_dist : Regex('^repos/(\w+)/dist$') {
  my ( $self, $c ) = @_;
  my $reponame = $c->req->snippets->[0];

  # get the dist name and arch parameters
  my $nameregex         = $c->req->param('name');
  my $archregex         = $c->req->param('arch');
  my $excludeAnyArch    = $c->req->param('noanyarch') || 0;
  $nameregex = '.' if not defined $nameregex or $nameregex eq '';
  $nameregex = '.' if not(eval {qr/$nameregex/}) or $@;
  if (
    not defined($archregex) or $archregex eq '' or $archregex eq '.'
    or not(eval {qr/$archregex/}) or $@
  ) {
    $archregex = undef
  }
  
#  require Time::HiRes;
#  my $time = Time::HiRes::time();
  my $res = $c->model($c->config->{model})->query_dist(
    $reponame, regex => $nameregex,
    (defined($archregex) ? (arch => $archregex) : ()),
  );
#  warn "QUERY took " . (Time::HiRes::time()-$time) . "s\n";

  $c->forward('/repos') if not defined $res;

  my $rows = [];
  foreach my $dist (@$res) {
    next if ref $dist;
    my ($name, $version, $arch, $pver) = PAR::Dist::parse_dist_name($dist);
    next if $excludeAnyArch and $arch eq 'any_arch';
    push @$rows, {
      distname => $name, version  => $version,
      platform => $arch, pversion => $pver,
    };
  }

  my $stash = $c->stash;
  $stash->{rows} = $rows;
  $stash->{alias} = $reponame;

  # set the selection parameters as default
  $stash->{noanyarch} = $excludeAnyArch;
  $stash->{nameregexp} = $nameregex;
  $stash->{archregexp} = $archregex;

  $stash->{template} = 'dists.tt';
}

=head2 show_module

Implements C</repos/ALIAS/module>, the list of modules in a repository.

=cut

sub show_module: Regex('^repos/(\w+)/module$') {
  my ( $self, $c ) = @_;
  my $reponame = $c->req->snippets->[0];

  # get the dist name and arch parameters
  my $nameregex         = $c->req->param('name');
  my $archregex         = $c->req->param('arch');
  my $excludeAnyArch    = $c->req->param('noanyarch') || 0;
  $nameregex = '.' if not defined $nameregex or $nameregex eq '';
  $nameregex = '.' if not(eval {qr/$nameregex/}) or $@;
  if (
    not defined($archregex) or $archregex eq '' or $archregex eq '.'
    or not(eval {qr/$archregex/}) or $@
  ) {
    $archregex = undef
  }

#  require Time::HiRes;
#  my $time = Time::HiRes::time();
  my $res = $c->model($c->config->{model})->query_dist(
    $reponame, regex => $nameregex,
    (defined($archregex) ? (arch => $archregex) : ()),
  );
#  warn "QUERY took " . (Time::HiRes::time()-$time) . "s\n";

  $c->forward('/repos') if not defined $res;

  my %seenMod;
  use version;
  for (my $i=0; $i < @$res; $i += 2) {
    my $distname = $res->[$i];
    my $modules  = $res->[$i+1];
    if ($excludeAnyArch) {
      (undef, undef, my $arch, undef) = PAR::Dist::parse_dist_name($distname);
      next if $arch eq 'any_arch';
    }

    foreach my $module (keys %$modules) {
      $seenMod{$module} = {
        name => $module,
        dist => $distname,
        version => $modules->{$module},
      } if not exists $seenMod{$module} or version->new($seenMod{$module}{version}) < version->new($modules->{$module});
    }
  }

  my $stash = $c->stash;
  $stash->{rows} = [map {$seenMod{$_}} sort keys %seenMod];
  $stash->{alias} = $reponame;
  
  # set the selection parameters as default
  $stash->{noanyarch} = $excludeAnyArch;
  $stash->{nameregexp} = $nameregex;
  $stash->{archregexp} = $archregex;

  $stash->{template} = 'modules.tt';
}

=head2 show_script

Implements C</repos/ALIAS/script>, the list of script in a repository.

=cut


sub show_script: Regex('^repos/(\w+)/script$') {
  my ( $self, $c ) = @_;
  my $reponame = $c->req->snippets->[0];
#    my $name = $c->req->param('name');

  # get the script name and arch parameters
  my $nameregex         = $c->req->param('name');
  my $archregex         = $c->req->param('arch');
  my $excludeAnyArch    = $c->req->param('noanyarch') || 0;
  $nameregex = '.' if not defined $nameregex or $nameregex eq '';
  $nameregex = '.' if not(eval {qr/$nameregex/}) or $@;
  if (
    not defined($archregex) or $archregex eq '' or $archregex eq '.'
    or not(eval {qr/$archregex/}) or $@
  ) {
    $archregex = undef
  }


#  require Time::HiRes;
#  my $time = Time::HiRes::time();
  my $scripthash = $c->model($c->config->{model})->query_script_hash(
    $reponame, regex => $nameregex,
    (defined($archregex) ? (arch => $archregex) : ()),
  );
  $c->forward('/repos') if not defined $scripthash;

  my @rows;
  use version;
  SCRIPT: while (my ($script, $dists) = each(%$scripthash)) {
    my $maxv;
    my $maxd;
    while (my ($dist, $version) = each(%$dists)) {
      if ($excludeAnyArch) {
        (undef, undef, my $arch, undef) = PAR::Dist::parse_dist_name($dist);
        next SCRIPT if $arch eq 'any_arch';
      }
 
      if (not defined $maxv or (defined $version and version->new($maxv) < version->new($version))) {
        $maxv = $version;
        $maxd = $dist;
      }
    }
    push @rows, {name => $script, version=>$maxv, dist=>$maxd};
  }

#  warn "QUERY took " . (Time::HiRes::time()-$time) . "s\n";
  @rows = sort {$a->{name} cmp $b->{name}} @rows;


  my $stash = $c->stash;
  $stash->{rows} = \@rows;
  $stash->{alias} = $reponame;
  
  # set the selection parameters as default
  $stash->{noanyarch} = $excludeAnyArch;
  $stash->{nameregexp} = $nameregex;
  $stash->{archregexp} = $archregex;

  $stash->{template} = 'scripts.tt';
}


=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Steffen Mueller E<lt>smueller@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
