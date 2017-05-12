package Test::Chimps::Smoker;

use warnings;
use strict;

use Config;
use File::Basename;
use File::Path;
use File::Temp qw/tempdir/;
use Params::Validate qw/:all/;
use Test::Chimps::Client;
use Test::TAP::Model::Visual;
use YAML::Syck;

=head1 NAME

Test::Chimps::Smoker - Poll a set of SVN repositories and run tests when they change

=head1 SYNOPSIS

This module gives you everything you need to make your own build
slave.  You give it a configuration file describing all of your
projects and how to test them, and it will monitor the SVN
repositories, check the projects out (and their dependencies), test
them, and submit the report to a server.

    use Test::Chimps::Smoker;

    my $poller = Test::Chimps::Smoker->new(
      server      => 'http://www.example.com/cgi-bin/chimps-server.pl',
      config_file => '/path/to/configfile.yml'


    $poller->poll();

=head1 METHODS

=head2 new ARGS

Creates a new Client object.  ARGS is a hash whose valid keys are:

=over 4

=item * config_file

Mandatory.  The configuration file describing which repositories to
monitor.  The format of the configuration is described in
L</"CONFIGURATION FILE">.

=item * server

Mandatory.  The URI of the server script to upload the reports to.

=item * simulate

Don't actually submit the smoke reports, just run the tests.  This
I<does>, however, increment the revision numbers in the config
file.

=back

=cut

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/server config_file simulate/);
__PACKAGE__->mk_accessors(
  qw/_added_to_inc _env_stack _checkout_paths _config projects iterations/);

# add a signal handler so destructor gets run
$SIG{INT} = sub {print "caught sigint.  cleaning up...\n"; exit(1)};

sub new {
  my $class = shift;
  my $obj = bless {}, $class;
  $obj->_init(@_);
  return $obj;
}

sub _init {
  my $self = shift;
  my %args = validate_with(
    params => \@_,
    spec   => {
      server      => 1,
      config_file => 1,
      simulate    => 0,
      iterations  => {
        optional => 1,
        default  => 'inf'
      },
      projects => {
        optional => 1,
        default  => 'all'
      }
    },
    called => 'The Test::Chimps::Smoker constructor'
  );

  foreach my $key (keys %args) {
    $self->{$key} = $args{$key};
  }
  $self->_added_to_inc([]);
  $self->_env_stack([]);
  $self->_checkout_paths([]);

  $self->_config(LoadFile($self->config_file));
}

sub DESTROY {
  my $self = shift;
  foreach my $tmpdir (@{$self->_checkout_paths}) {
    _remove_tmpdir($tmpdir);
  }
}

sub _smoke_once {
  my $self = shift;
  my $project = shift;
  my $config = $self->_config;

  return 1 if $config->{$project}->{dependency_only};

  my $info_out = `svn info $config->{$project}->{svn_uri}`;
  $info_out =~ m/^Revision: (\d+)/m;
  my $latest_revision = $1;
  $info_out =~ m/^Last Changed Rev: (\d+)/m;
  my $last_changed_revision = $1;

  my $old_revision = $config->{$project}->{revision};

  return 0 unless $last_changed_revision > $old_revision;

  my @revisions = (($old_revision + 1) .. $latest_revision);
  my $revision;
  while (@revisions) {
    $revision = shift @revisions;
    # only actually do the check out if the revision and last changed revision match for
    # a particular revision
    last if _change_on_revision($config->{$project}->{svn_uri}, $revision);
  }

  $info_out = `svn info -r $revision $config->{$project}->{svn_uri}`;
  $info_out =~ m/^Last Changed Author: (\w+)/m;
  my $committer = $1;

  $config->{$project}->{revision} = $revision;

  $self->_checkout_project($config->{$project}, $revision);

  my $model;
  {
    local $SIG{ALRM} = sub { die "10 minute timeout exceeded" };
    alarm 600;
    print "running tests for $project\n";
    eval {
      $model = Test::TAP::Model::Visual->new_with_tests(glob("t/*.t t/*/t/*.t"));
    };
    alarm 0;                    # cancel alarm
  }

  if ($@) {
    print "Tests aborted: $@\n";
  }

  my $duration = $model->structure->{end_time} - $model->structure->{start_time};

  $self->_unroll_env_stack;

  foreach my $libdir (@{$self->_added_to_inc}) {
    print "removing $libdir from \@INC\n";
    shift @INC;
  }
  $self->_added_to_inc([]);

  chdir(File::Spec->rootdir);

  foreach my $tmpdir (@{$self->_checkout_paths}) {
    _remove_tmpdir($tmpdir);
  }
  $self->_checkout_paths([]);

  my $client = Test::Chimps::Client->new(
    model            => $model,
    report_variables => {
      project   => $project,
      revision  => $revision,
      committer => $committer,
      duration  => $duration,
      osname    => $Config{osname},
      osvers    => $Config{osvers},
      archname  => $Config{archname}
    },
    server => $self->server
  );

  my ($status, $msg);
  if ($self->simulate) {
    $status = 1;
  } else {
    ($status, $msg) = $client->send;
  }

  if ($status) {
    print "Sumbitted smoke report for $project revision $revision\n";
    DumpFile($self->config_file, $config);
    return 1;
  } else {
    print "Error: the server responded: $msg\n";
    return 0;
  }
}

sub _smoke_n_times {
  my $self = shift;
  my $n = shift;
  my $projects = shift;

  if ($n <= 0) {
    die "Can not smoke projects a negative number of times";
  } elsif ($n eq 'inf') {
    while (1) {
      $self->_smoke_projects($projects);
      sleep 60;
    }
  } else {
    for (my $i = 0; $i < $n;) {
      $i++ if $self->_smoke_projects($projects);
      sleep 60;
    }
  }
}

sub _smoke_projects {
  my $self = shift;
  my $projects = shift;
  my $config = $self->_config;

  foreach my $project (@$projects) {
    $self->_smoke_once($project);
  }
}

=head2 smoke PARAMS

Calling smoke will cause the C<Smoker> object to continually poll
repositories for changes in revision numbers.  If an (actual)
change is detected, the repository will be checked out (with
dependencies), built, and tested, and the resulting report will be
submitted to the server.  This method may not return.  Valid
options to smoke are:

=over 4

=item * iterations

Specifies the number of iterations to run.  This is the number of
smoke reports to generate per project.  A value of 'inf' means to
continue smoking forever.  Defaults to 'inf'.

=item * projects

An array reference specifying which projects to smoke.  If the
string 'all' is provided instead of an array reference, all
projects will be smoked.  Defaults to 'all'.

=back

=cut

sub smoke {
  my $self = shift;
  my $config = $self->_config;

  my %args = validate_with(
    params => \@_,
    spec   => {
      iterations => {
        optional => 1,
        type     => SCALAR,
        regex    => qr/^(inf|\d+)$/,
        default  => 'inf'
      },
      projects => {
        optional => 1,
        type     => ARRAYREF | SCALAR,
        default  => 'all'
      }
    },
    called => 'Test::Chimps::Smoker->smoke'
  );

  my $projects = $args{projects};
  my $iterations = $args{iterations};
  $self->_validate_projects_opt($projects);

  if ($projects eq 'all') {
    $projects = [keys %$config];
  }

  $self->_smoke_n_times($iterations, $projects);

}

sub _validate_projects_opt {
  my ($self, $projects) = @_;
  return if $projects eq 'all';

  foreach my $project (@$projects) {
    die "no such project: '$project'"
      unless exists $self->_config->{$project};
  }
}

sub _checkout_project {
  my $self = shift;
  my $project = shift;
  my $revision = shift;

  my $tmpdir = tempdir("chimps-svn-XXXXXXX", TMPDIR => 1);
  unshift @{$self->_checkout_paths}, $tmpdir;

  system("svn", "co", "-r", $revision, $project->{svn_uri}, $tmpdir);

  $self->_push_onto_env_stack($project->{env});

  my $projectdir = File::Spec->catdir($tmpdir, $project->{root_dir});

  if (defined $project->{dependencies}) {
    foreach my $dep (@{$project->{dependencies}}) {
      print "processing dependency $dep\n";
      $self->_checkout_project($self->_config->{$dep}, 'HEAD');
    }
  }

  chdir($projectdir);

  my $old_perl5lib = $ENV{PERL5LIB};
  $ENV{PERL5LIB} = join($Config{path_sep}, @{$self->_added_to_inc}) .
    ':' . $ENV{PERL5LIB};
  if (defined $project->{configure_cmd}) {
    system($project->{configure_cmd});
  }
  $ENV{PERL5LIB} = $old_perl5lib;

  for my $libloc (qw{blib/lib}) {
    my $libdir = File::Spec->catdir($tmpdir,
                                    $project->{root_dir},
                                    $libloc);
    print "adding $libdir to \@INC\n";
    unshift @{$self->_added_to_inc}, $libdir;
    unshift @INC, $libdir;
  }


  return $projectdir;
}

sub _remove_tmpdir {
  my $tmpdir = shift;
  print "removing temporary directory $tmpdir\n";
  rmtree($tmpdir, 0, 0);
}

sub _change_on_revision {
  my $uri = shift;
  my $revision = shift;

  my $info_out = `svn info -r $revision $uri`;
  $info_out =~ m/^Revision: (\d+)/m;
  my $latest_revision = $1;
  $info_out =~ m/^Last Changed Rev: (\d+)/m;
  my $last_changed_revision = $1;

  return $latest_revision == $last_changed_revision;
}

sub _push_onto_env_stack {
  my $self = shift;
  my $vars = shift;

  my $frame = {};
  foreach my $var (keys %$vars) {
    if (exists $ENV{$var}) {
      $frame->{$var} = $ENV{$var};
    } else {
      $frame->{$var} = undef;
    }
    my $value = $vars->{$var};
    # old value substitution
    $value =~ s/\$$var/$ENV{$var}/g;

    print "setting environment variable $var to $value\n";
    $ENV{$var} = $value;
  }
  push @{$self->_env_stack}, $frame;
}

sub _unroll_env_stack {
  my $self = shift;

  while (scalar @{$self->_env_stack}) {
    my $frame = pop @{$self->_env_stack};
    foreach my $var (keys %$frame) {
      if (defined $frame->{$var}) {
        print "reverting environment variable $var to $frame->{$var}\n";
        $ENV{$var} = $frame->{$var};
      } else {
        print "unsetting environment variable $var\n";
        delete $ENV{$var};
      }
    }
  }
}

=head1 ACCESSORS

There are read-only accessors for server, config_file, and simulate.

=head1 CONFIGURATION FILE

The configuration file is YAML dump of a hash.  The keys at the top
level of the hash are project names.  Their values are hashes that
comprise the configuration options for that project.

Perhaps an example is best.  A typical configuration file might
look like this:

    ---
    Some-jifty-project:
      configure_cmd: perl Makefile.PL --skipdeps && make
      dependencies:
        - Jifty
      revision: 555
      root_dir: trunk/foo
      svn_uri: svn+ssh://svn.example.com/svn/foo
    Jifty:
      configure_cmd: perl Makefile.PL --skipdeps && make
      dependencies:
        - Jifty-DBI
      revision: 1332
      root_dir: trunk
      svn_uri: svn+ssh://svn.jifty.org/svn/jifty.org/jifty
    Jifty-DBI:
      configure_cmd: perl Makefile.PL --skipdeps && make
      env:
        JDBI_TEST_MYSQL: jiftydbitestdb
        JDBI_TEST_MYSQL_PASS: ''
        JDBI_TEST_MYSQL_USER: jiftydbitest
        JDBI_TEST_PG: jiftydbitestdb
        JDBI_TEST_PG_USER: jiftydbitest
      revision: 1358
      root_dir: trunk
      svn_uri: svn+ssh://svn.jifty.org/svn/jifty.org/Jifty-DBI

The supported project options are as follows:

=over 4

=item * configure_cmd

The command to configure the project after checkout, but before
running tests.

=item * revision

This is the last revision known for a given project.  When started,
the poller will attempt to checkout and test all revisions (besides
ones on which the directory did not change) between this one and
HEAD.  When a test has been successfully uploaded, the revision
number is updated and the configuration file is re-written.

=item * root_dir

The subdirectory inside the repository where configuration and
testing commands should be run.

=item * svn_uri

The subversion URI of the project.

=item * env

A hash of environment variable names and values that are set before
configuration, and reverted to their previous values after the
tests have been run.  In addition, if environment variable FOO's
new value contains the string "$FOO", then the old value of FOO
will be substituted in when setting the environment variable.

=item * dependencies

A list of project names that are dependencies for the given
project.  All dependencies are checked out at HEAD, have their
configuration commands run, and all dependencys' $root_dir/blib/lib
directories are added to @INC before the configuration command for
the project is run.

=item * dependency_only

Indicates that this project should not be tested.  It is only
present to serve as a dependency for another project.

=back

=head1 REPORT VARIABLES

This module assumes the use of the following report variables:

    project
    revision
    committer
    duration
    osname
    osvers
    archname

=head1 AUTHOR

Zev Benjamin, C<< <zev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-chimps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Chimps-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Chimps::Smoker

You can also look for information at:

=over 4

=item * Mailing list

Chimps has a mailman mailing list at
L<chimps@bestpractical.com>.  You can subscribe via the web
interface at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/chimps>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Chimps-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Chimps-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Chimps-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Chimps-Client>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
