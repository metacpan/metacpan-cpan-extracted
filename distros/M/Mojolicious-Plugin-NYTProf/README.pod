package Mojolicious::Plugin::NYTProf;

=head1 NAME

Mojolicious::Plugin::NYTProf - Auto handling of Devel::NYTProf in your Mojolicious app

=for html
<a href='https://travis-ci.org/Humanstate/mojolicious-plugin-nytprof?branch=master'><img src='https://travis-ci.org/Humanstate/mojolicious-plugin-nytprof.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/mojolicious-plugin-nytprof?branch=master'><img src='https://coveralls.io/repos/Humanstate/mojolicious-plugin-nytprof/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.23

=head1 DESCRIPTION

This plugin enables L<Mojolicious> to automatically generate Devel::NYTProf
profiles and routes for your app, it has been inspired by
L<Dancer::Plugin::NYTProf>

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin NYTProf => {
    nytprof => {
      ... # see CONFIGURATION
    },
  };

  app->start;

Or

  use Mojo::Base 'Mojolicious';

  ...

  sub startup {
    my $self = shift;

    ...

    my $mojo_config = $self->plugin('Config');
    $self->plugin(NYTProf => $mojo_config);
  }

Then run your app - you should start your app with the env variables:

  PERL5OPT='-d:NYTProf'
  NYTPROF=start=no

without this, things go a bit haywire (most obviously manifested as broken links
in the report) because otherwise any code compiled before the C<plugin> call
cannot be covered, as described in the docs:
L<https://metacpan.org/pod/Devel::NYTProf#RUN-TIME-CONTROL-OF-PROFILING>

Profiles generated can be seen by visting /nytprof and reports
will be generated on the fly when you click on a specific profile.

=cut

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Time::HiRes 'gettimeofday';
use File::Temp;
use File::Which;
use File::Spec::Functions qw/catfile catdir/;

our $VERSION = '0.23';

=head1 METHODS

=head2 register

Registers the plugin with your app - this will only do something if the nytprof
key exists in your config hash

  $self->register($app, \%config);

=head1 HOOKS AND Devel::NYTProf

The plugin adds hooks to control the level of profiling, Devel::NYTProf profiling
is started using a before_routes hook and the stopped with an around_dispatch hook.

The consequence of this is that you should see profiling only for your routes and
rendering code and will not see most of the actual Mojolicious framework detail.

The caveat with the use of hooks is that some hooks can fire out of order, and when
asynchronous code is used in your controllers you may see incomplete/odd profiling
behaviour - you can play around with the hook configuration to try to fix this.

You can override the hooks used to control when the profiling runs, see the
CONFIGURATION section below.

=head1 CONFIGURATION

Here's what you can control in myapp.conf:

  {
    # Devel::NYTProf will only be loaded, and profiling enabled, if the nytprof
    # key is present in your config file, so either remove it or comment it out
    # to completely disable profiling.
    nytprof => {

      # path to your nytprofhtml script (installed as part of Devel::NYTProf
      # distribution). the plugin will do its best to try to find this so this
      # is optional, just set if you have a none standard path
      nytprofhtml_path => '/path/to/nytprofhtml',

      # path to store Devel::NYTProf output profiles and generated html pages.
      # options, defaults to "/path/to/your/app/root/dir/nytprof"
      profiles_dir => '/path/to/nytprof/profiles/'

      # set this to true to allow the plugin to run when in production mode
      # the default value is 0 so you can deploy your app to prod without
      # having to make any changes to config/plugin register
      allow_production => 0,

      # Devel::NYTProf environment options, see the documentation at
      # https://metacpan.org/pod/Devel::NYTProf#NYTPROF-ENVIRONMENT-VARIABLE
      # for a complete list. N.B. you can't supply start or file as these
      # are used internally in the plugin so will be ignored if passed
      env => {
        trace => 1,
        log   => "/path/to/foo/",
        ....
      },

      # when to enable Devel::NYTProf profiling - the pre_hook will run
      # to enable_profile and the post_hook will run to disable_profile
      # and finish_profile. the values show here are the defaults so you
      # do not need to provide these options
      #
      # bear in mind the caveats in the Mojolicious docs regarding hooks
      # and that they may not fire in the order you expect - this can
      # affect the NYTProf output and cause some things not to appear
      # (or appear in the wrong order). the defaults below should be 
      # sufficient for profiling your code, however you can change these
      #
      # N.B. there is nothing stopping you reversing the order of the
      # hooks, which would cause the Mojolicious framework code to be
      # profiled, or providing hooks that are the same or even invalid. these
      # config options should probably be used with some care
      pre_hook  => 'before_routes',
      post_hook => 'around_dispatch',
    },
  }

=head1 nytprofhtml LOCATION

The plugin does its best to find the path to your nytprofhtml executable, if
it cannot find it then it will die with an error. This also affects testing,
and any tests will be skipped if they cannot find nytprofhtml allowing you to
install the plugin - you will then need to make sure to set the path in your
config using nytprofhtml_path

=cut

sub register {
  my ($self, $app, $config) = @_;

  if (my $nytprof = $config->{nytprof}) {

    return if $app->mode eq 'production' and ! $nytprof->{allow_production};

    my $nytprofhtml_path;

    if ( $nytprofhtml_path = $nytprof->{nytprofhtml_path} ) {
      # no sanity checking here, if a path is configured we use it
      # and don't fall through to defaults
    } else {
      $nytprofhtml_path = _find_nytprofhtml();
    }

    $nytprofhtml_path && -e $nytprofhtml_path
      or die "Could not find nytprofhtml script. Ensure it's in your path, "
      . "or set the nytprofhtml_path option in your config.";

    # Devel::NYTProf will create an nytprof.out file immediately so
    # we need to assign a tmp file and disable profiling from start
    my $prof_dir = $nytprof->{profiles_dir} || 'nytprof';

    foreach my $dir ($prof_dir,catfile($prof_dir,'profiles')) {
      if (! -d $dir) {
        mkdir $dir
          or die "$dir does not exist and cannot create - $!";
      }
    }

    # disable config option is undocumented, it allows testing where we
    # don't actually load or run Devel::NYTProf
    if (!$nytprof->{disable}) {
      # https://metacpan.org/pod/Devel::NYTProf#NYTPROF-ENVIRONMENT-VARIABLE
      # options for Devel::NYTProf - any can be passed but will always set
      # the start and file options here
      $nytprof->{env}{start} = 'no';
      s/([:=])/\\$1/g for grep{ defined() } values %{ $nytprof->{env} };

      $ENV{NYTPROF} = join( ':',
        map { "$_=" . $nytprof->{env}{$_} }
          keys %{ $nytprof->{env} }
      );

      require Devel::NYTProf;
    }

    $self->_add_hooks($app, $config, $nytprofhtml_path);
  }
}

sub _find_nytprofhtml {
  # fall back, assume nytprofhtml_path in same dir as perl
  my $nytprofhtml_path = $^X;
  $nytprofhtml_path =~ s/w?perl[\d\.]*(?:\.exe)?$/nytprofhtml/;

  if ( ! -e $nytprofhtml_path ) {
    # last ditch attempt to find nytprofhtml, use File::Which
    # (last ditch in that it may return a different nytprofhtml
    # that is using a differently configured perl, e.g. system,
    # this may die with incompat config errorrs but at least try)
    $nytprofhtml_path = File::Which::which('nytprofhtml');
  }

  return $nytprofhtml_path && -e $nytprofhtml_path
    ? $nytprofhtml_path : undef;
}

sub _add_hooks {
  my ($self, $app, $config, $nytprofhtml_path) = @_;

  my $nytprof   = $config->{nytprof};
  my $prof_dir  = $nytprof->{profiles_dir} || 'nytprof';
  my $pre_hook  = $nytprof->{pre_hook}     || 'before_routes';
  my $post_hook = $nytprof->{post_hook}    || 'around_dispatch';
  my $disable   = $nytprof->{disable}      || 0;
  my $log       = $app->log;

  # add the nytprof/html directory to the static paths
  # so we can serve these without having to add routes
  push @{$app->static->paths},catfile($prof_dir,'html');

  # put the actual profile files into a profiles sub directory
  # to avoid confusion with the *dirs* in nytprof/html
  my $prof_sub_dir = catfile( $prof_dir,'profiles' );

  $app->hook($pre_hook => sub {

    # figure args based on what the hook is
    my ($tx, $app, $next, $c, $path);

    if ($pre_hook eq 'after_build_tx') {
      ($tx, $app) = @_[0,1];
      $path = $pre_hook; # TODO - need better identifier for this?
    } elsif ($pre_hook =~ /around/) {
      ($next, $c) = @_[0,1];
    } else {
      $c = $_[0];
      $path = $c->req->url->to_string;
      return if $c->stash->{'mojo.static'}; # static files
    }

    return if $path =~ m{^/nytprof}; # viewing profiles
    $path =~ s!^/!!g;
    $path =~ s!/!-!g;
    $path =~ s![:?]!-!g if $^O eq 'MSWin32';
    $path =~ s!\?.*$!!g; # remove URL query params

    my ($sec, $usec) = gettimeofday;
    my $profile = catfile($prof_sub_dir,"nytprof_out_${sec}_${usec}_${path}_$$");
    if($^O eq 'MSWin32' && length($profile)>259){
      my $overflow = length($profile) - 259;
      $path = substr($path, 0,length($path) - $overflow -1);
      $profile = catfile($prof_sub_dir,"nytprof_out_${sec}_${usec}_${path}_$$");
    }
    $log->debug( 'starting NYTProf' );
    # note that we are passing a custom file to enable_profile, this results in
    # a timing bug causing multiple calls to this plugin (in the order of 10^5)
    # to gradually slow down. see GH #5
    DB::enable_profile( $profile ) if ! $disable;
    return $next->() if $pre_hook =~ /around/;
  });

  $app->hook($post_hook => sub {
    # first arg is $next if the hook matches around
    shift->() if $post_hook =~ /around/;
    DB::finish_profile() if ! $disable;
    $log->debug( 'finished NYTProf' );
  });

  $app->routes->get('/nytprof/profiles/:file'
    => [file => qr/nytprof_out_\d+_\d+.*/]
    => sub {
      $log->debug( "generating profile for $nytprofhtml_path" );
      _generate_profile(@_,$prof_dir,$nytprofhtml_path)
    }
  );

  $app->routes->get('/nytprof' => sub { _list_profiles(@_,$prof_sub_dir) });
}

sub _list_profiles {
  my $self = shift;
  my $prof_dir = shift;

  my @profiles = _profiles($prof_dir);
  $self->app->log->debug( scalar( @profiles ) . ' profiles found' );

  # could use epl here, but users might be using a different Template engine
  my $list = @profiles
    ? '<p>Select a profile run output from the list to view the HTML reports as produced by <tt>Devel::NYTProf</tt>.</p><ul>'
    : '<p>No profiles found</p>';

  foreach (@profiles) {
    $list .= qq{
      <li>
        <a href="$_->{url}">$_->{label}</a>
          (PID $_->{pid}, $_->{created}, $_->{duration})
      </li>
    };
  }

  $list .= '</ul>' if $list !~ /No profiles found/;

  my $html = <<"EndOfEp";
<html>
  <head>
    <title>NYTProf profile run list</title>
  </head>
  <body>
    <h1>Profile run list</h1>
      $list
  </body>
</html>
EndOfEp

  $self->render(text => $html);
}

sub _profiles {
  my $prof_dir = shift;

  require Devel::NYTProf::Data;
  opendir my $dirh, $prof_dir
      or die "Unable to open profiles dir $prof_dir - $!";
  my @files = grep { /^nytprof_out/ } readdir $dirh;
  closedir $dirh;

  my @profiles;

  for my $file ( sort {
    (stat catfile($prof_dir,$b))[10] <=> (stat catfile($prof_dir,$a))[10]
  } @files ) {
    my $profile;
    my $filepath = catfile($prof_dir,$file);
    my $label = $file;
    $label =~ s{nytprof_out_(\d+)_(\d+)_}{};
    my ($sec, $usec) = ($1,$2);
    $label =~ s{\.}{/}g;
    $label =~ s{/(\d+)$}{};
    my $pid = $1;

    my ($nytprof,$duration);
    eval { $nytprof = Devel::NYTProf::Data->new({filename => $filepath}); };

    $profile->{duration} = $nytprof && $nytprof->attributes->{profiler_duration}
      ? sprintf('%.4f secs', $nytprof->attributes->{profiler_duration})
      : '??? seconds - corrupt profile data?';

    @{$profile}{qw/file url pid created label/}
      = ($file,"/nytprof/profiles/$file",$pid,scalar localtime($sec),$label);
    push(@profiles,$profile);
  }

  return @profiles;
}

sub _generate_profile {
  my $self = shift;
  my $htmldir = my $prof_dir = shift;
  my $nytprofhtml_path = shift;

  my $file    = $self->stash('file');
  my $profile = catfile($prof_dir,'profiles',$file);
  return $self->reply->not_found if !-f $profile;
  
  foreach my $sub_dir (
    $htmldir,
    catfile($htmldir,'html'),
    catfile($htmldir,'html',$file),
  ) {
    if (! -d $sub_dir) {
      mkdir $sub_dir
        or die "$sub_dir does not exist and cannot create - $!";
    }
  }

  $htmldir = catfile($htmldir,'html',$file);

  if (! -f catfile($htmldir, 'index.html')) {
    system($nytprofhtml_path, "--file=$profile", "--out=$htmldir");

    if ($? == -1) {
      die "'$nytprofhtml_path' failed to execute: $!";
    } elsif ($? & 127) {
      die sprintf "'%s' died with signal %d, %s coredump",
        $nytprofhtml_path,,($? & 127),($? & 128) ? 'with' : 'without';
    } elsif ($? != 0) {
      die sprintf "'%s' exited with value %d", 
        $nytprofhtml_path, $? >> 8;
    }
  }

  $self->redirect_to("/${file}/index.html");
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
please raise an issue / pull request:

    https://github.com/Humanstate/mojolicious-plugin-nytprof

=cut

1;

# vim: ts=2:sw=2:et
