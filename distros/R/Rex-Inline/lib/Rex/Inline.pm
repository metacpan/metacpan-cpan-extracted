#
# (c) Johnny Wang <johnnywang1991@msn.com>
#
# vim: set ts=2
# vim: set sw=2
# vim: set tw=0
# vim: set expandtab

=encoding UTF-8

=head1 NAME

Rex::Inline - write Rex in perl

=head1 DESCRIPTION

Rex::Inline is an API of I<Rex> module write with Moose.

when you want use rex in your perl program, and do not want to use the B<rex> command line, you can try to use this module.

=head1 GETTING HELP
 
=over 4
 
=item * Bug Tracker: L<https://github.com/johnnywang1991/RexInline/issues>
 
=back

=head1 SYNOPSIS

  use Rex::Inline;
  use Rex::Inline::Test;

  my $rex_inline = Rex::Inline->new(
    use_debug => 0
    # now you can set default authentication
    user => $user,              # optional
    password => $password,      # optional
    public_key => $public_key,  # optional
    private_key => $private_key,# optional
  );

  # add default authentication 
  # if you didn't provide authentication in your task, Rex::Inline will use this as default one
  # or if your authentication is failed, Rex::Inline will use this retry the ssh connection
  $rex_inline->add_auth({
    user => $user,
    password => $password,
    sudo => TRUE,
  });
  $rex_inline->add_auth({
    user => $user,
    public_key => $public_key,
    private_key => $private_key,
  });

  # data reference like this
  $rex_inline->add_task(
    {
      name => 'something_uniq_string',  # name is required when add data_reference task
      func => sub {                     # func is required when add data_reference task
        ...
      },
      user => $user,
      server => [@server],
      # if need password
      password => $password,
      # optional
      public_key => $public_key,
      private_key => $private_key,
    }
  );

  # or Rex::Inline::Test is based on Rex::Inline::Base module
  # See Rex::Inline::Base Documents
  $rex_inline->add_task(
    Rex::Inline::Test->new(
      user => $user,
      server => [@server],
      # if need password
      password => $password,
      # optional
      public_key => $public_key,
      private_key => $private_key,
      # input param, in any format you want
      input => $input,
    )
  );

  $rex_inline->execute;

  # get rex task reports
  $rex_inline->reports;

=cut
package Rex::Inline;

use strict;
use warnings;

use utf8;
use FindBin;
use POSIX 'strftime';

our $VERSION = '0.0.8'; # VERSION

use Moose;
use MooseX::AttributeShortcuts;

use File::Temp 'mkdtemp';
use File::Path::Tiny;
use File::Spec::Functions;

use YAML::XS qw(LoadFile Dump);
use JSON;
use Parallel::ForkManager;

use Rex -feature => 0.31;
use Rex::Config;
use Rex::Group;
use Rex::TaskList;

# custom module
use Rex::Inline::Test;

use namespace::autoclean;

use Moose::Util::TypeConstraints;
subtype 'TaskType'
  => as 'ArrayRef[Object]';
coerce 'TaskType'
  => from 'ArrayRef',
  => via { [ map { (ref $_ eq 'HASH') ? Rex::Inline::Test->new($_) : $_ } @$_ ] };
no Moose::Util::TypeConstraints;

=head1 ATTRIBUTES

=over 4

=item user

set default ssh connection user

=item password

set default ssh connection password

=item private_key

set default private_key filename

=item public_key

set default public_key filename

=cut

has [qw(user password private_key public_key)] => (is => 'ro', predicate => 1);

=item use_debug

set/get debug option (Bool)

Print or not debug level log 

see B<rex -d> option

default is 0 (disabled)
=cut
has use_debug => (is => 'rw', default => 0);

=item use_cache

set/get use_cache option (Bool)

Use or not B<rex -c> option

default is 1 (enable)
=cut
has use_cache => (is => 'rw', default => 1);

=item use_report

set/get use_report option (Bool)

show rex report result

default is 1 (enable)
=cut
has use_report => (is => 'rw', default => 1);

=item use_report_log

set/get use_report_log option (Bool)

report to log

default is 0 (false)
=cut
has use_report_log => (is => 'rw', default => 0);


=item log_dir

set/get log dir (String)

default is C<"./rexlogs/">
=cut
has log_dir => (is => 'rw', default => './rexlogs/');

=item parallelism

set/get parallelism nums (Int)

see B<rex -t> option

default is 5
=cut
has parallelism => (is => 'rw', default => 5);

=item log_paths

get log paths (ArrayRef)

format is 

  [{task_id => log_path}, ...]

I<readonly>
=cut
has log_paths => (
  is => 'ro',
  default => sub{[]},
  traits => ['Array'],
  handles => {add_log_paths => 'push'},
);
=item reports

get rex process reports (ArrayRef)

format is:

  [{report => $report_ref, task_id => $task_id, date => $date, hostname => $hostname}, ...]

I<readonly>
=cut
has reports => (
  is => 'ro',
  default => sub{[]},
  traits => ['Array'],
  handles => { 
    add_reports => 'push',
    map_reports => 'map'
  }
);

=back
=cut

has date => (is => 'ro', lazy => 1, builder => 1); # date: format is YYmmdd
has prefix => (is => 'ro', lazy => 1, builder => 1); # log prefix dir
has tasklist => (is => 'ro', lazy => 1, builder => 1); # rex tasklist base object, use private
has pm => (is => 'ro', lazy => 1, builder => 1); # parallel forkmanager object, use private

=head1 METHODS

=over 4

=item add_task

add B<Rex::Inline::Base> Object to TaskList

or Add Data reference to TaskList 

  my $rex_inline = Rex::Inline->new;

  $rex_inline->add_task({
      name => 'something_uniq_string', # required when add data_reference task
      func => sub { # required when add data_reference task
        ...
      },
      user => $user2,
      server => [@server2],
      # if need password
      password => $password2,
      # optional
      public_key => $public_key2,
      private_key => $private_key2,
  });

  ...

=cut

has task => (
  is => 'ro',
  isa => 'TaskType',
  coerce => 1,
  default => sub{[]},
  traits => ['Array'],
  handles => {add_task => 'push'},
);

=item add_auth

Add an authentication fallback

This is the default authentication

If all you provide authentications is failed, B<Rex::Inline> will try to use this one

  $rex_inline->add_auth({
    user => $user,
    password => $password,
    sudo => TRUE,
  });
  $rex_inline->add_auth({
    user => $user,
    public_key => $public_key,
    private_key => $private_key,
  });

=cut

has auth => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  default => sub{[]},
  traits => ['Array'],
  handles => {add_auth => 'push'},
  predicate => 1
);

=item execute

Execute all loaded Task in parallel

  $rex_inline->execute;

=cut
sub execute {
  my $self = shift;

  ### setup parallel forkmanager
  $self->pm->run_on_finish(sub {
    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $results) = @_;
    # retrieve data structure from child
    if ($results) {  # children are not forced to send anything
      my @reports = @{$results->{reports}};
      $self->add_reports(@reports) if @reports;

      my @log_paths = @{$results->{log_paths}};
      $self->add_log_paths(@log_paths) if @log_paths;
    }
  });

  ### run task list
  for my $task_in_list ($self->tasklist->get_tasks) {
    $self->pm->start and next;

    my @reports;
    my @log_paths;
    if ( $self->tasklist->is_task($task_in_list) ) {
      my $task_id = $self->tasklist->get_task($task_in_list)->desc;
      ### set logging path
      my $log_path = catfile( $self->prefix, "${task_id}.log" );
      logging to_file => $log_path;
      push @log_paths, $log_path;
      ### set report path
      my $report_path = mkdtemp( sprintf("%s/reports_XXXXXX", $self->prefix) );
      set report_path => $report_path;
      ### run
      $self->tasklist->run($task_in_list);
      ### fetch reports
      push @reports, $self->_fetch_reports($task_in_list, $report_path, $task_id) if $self->use_report;
    }

    $self->pm->finish(0, {reports => [@reports], log_paths => [@log_paths]});
  }

  ### wait parallel task
  $self->pm->wait_all_children;
}

=item report_as_yaml

  my $yaml_report = $rex_inline->report_as_yaml;

=item report_as_json

  my $json_report = $rex_inline->report_as_json;

=cut

sub report_as_yaml { Dump( [ shift->map_reports(sub { Dump($_) }) ] ) }
sub report_as_json { encode_json( [shift->map_reports(sub { encode_json($_) })] ) }

=item print_as_yaml

  $rex_inline->print_as_yaml;

=item print_as_json

  $rex_inline->print_as_json;

=cut

sub print_as_yaml { print join("\n", shift->map_reports(sub { Dump($_) })), "\n" }
sub print_as_json { print join("\n", shift->map_reports(sub { encode_json($_) })), "\n" }

=back
=cut

sub _fetch_reports {
  my $self = shift;
  my ($task_name, $report_path, $task_id) = @_;

  my @reports;

  ### read report path
  for my $server ( @{ $self->tasklist->get_task($task_name)->server } ) {
    my $report;

    for my $report_file ( glob catfile( $report_path, $server, '*.yml' ) ) {
      my $report_content = eval { LoadFile($report_file) };
      $report = {
        report => $report_content,
        group => $task_id,
        date => $self->date,
        host => $server->name
      };
    }
    rmdir catdir( $report_path, $server );

    unless ($report) {
      ### log failed
      $report = {
        report => {
          task => {
            failed => '1',
            message => sprintf(
              'Wrong username/password or wrong key on %s. Or root is not permitted to login over SSH.',
              $server->name
            )
          }
        },
        group => $task_id,
        date => $self->date,
        host => $server->name
      };
    }

    ### push report
    push @reports, $report;
  }
  rmdir $report_path;

  Rex::Logger::info( join("\n", map { Dump($_) } @reports) ) if $self->use_report_log;
  return @reports;
}

sub _build_tasklist {
  my $self = shift;
  
  ### set log debug level
  if ($self->use_debug) {
    $Rex::Logger::debug = $self->debug_bool;
    $Rex::Logger::silent = 0;
  }

  ### force use ssh instead openssh
  set connection => "SSH";
  ### set parallelism
  parallelism($self->parallelism);
  ### set use cache
  Rex::Config->set_use_cache($self->use_cache);
  ### set report
  Rex::Config->set_do_reporting($self->use_report);
  Rex::Config->set_report_type('YAML');

  ### initial task list
  for my $task (@{$self->task}) {
    ### setup new connection group
    group $task->id => @{$task->server};
    ### setup auth for group
    auth for => $task->id => %{$task->task_auth};
    ### initial task
    desc $task->id;
    ### last param overwrite the caller module name Rex Commands line 284-286
    task $task->name, group => $task->id, $task->func, { class => "Rex::CLI" };
  }

  ### default auth
  my @default_auth;
  if ($self->{user}) {
    @default_auth = ( user => $self->{user} );
    for (qw(password public_key private_key)) {
      push @default_auth, $_ => $self->{$_} if $self->{$_};
    }
  }
  $self->add_auth({@default_auth}) if @default_auth;

  ### add auth fallback
  auth fallback => @{ $self->auth } if $self->has_auth;

  return Rex::TaskList->create;
}

sub _build_date { strftime "%Y%m%d", localtime(time) }
sub _build_prefix {
  my $self = shift;
  my $prefix = catdir($self->log_dir, $self->date);

  File::Path::Tiny::mk($prefix) unless -d $prefix;

  return $prefix;
}
sub _build_pm { Parallel::ForkManager->new(10) }

__PACKAGE__->meta->make_immutable;
