package MojoX::Logite;

use strict;
use warnings;

use Carp 'croak';

use base 'Mojo::Log';

use Mojo::Util qw (camelize);

our $VERSION = '0.01';

our $LOG_TABLE = 'LogiteTable';
our $LOG_IDX1 = $LOG_TABLE.'Idx1';
our $LOG_IDX2 = $LOG_TABLE.'Idx2';
our $LOG_SCHEMA = <<SCHEMA;
CREATE TABLE $LOG_TABLE (
                      l_id          INTEGER UNIQUE PRIMARY KEY AUTOINCREMENT,
                      l_who_app     TEXT DEFAULT NULL,
                      l_who_mod     TEXT DEFAULT NULL,
                      l_who_pos     TEXT DEFAULT NULL,
                      l_who_id      TEXT DEFAULT NULL,
                      l_what        TEXT DEFAULT NULL,
                      l_when        INTEGER NOT NULL,
                      l_level       CHAR(10) DEFAULT NULL
                      );
CREATE INDEX IF NOT EXISTS $LOG_IDX1 ON $LOG_TABLE (l_when);
CREATE INDEX IF NOT EXISTS $LOG_IDX2 ON $LOG_TABLE (l_level,l_who_app,l_who_mod);
SCHEMA

# some ORLite attributes
__PACKAGE__->attr('package' => 'MojoX::Logite');
__PACKAGE__->attr('prune' => 0);
__PACKAGE__->attr('user_version');
__PACKAGE__->attr('cache');
__PACKAGE__->attr('readonly');

__PACKAGE__->attr('app');

__PACKAGE__->attr('context_stack' => sub { [] });
__PACKAGE__->attr('context_map' => sub { {} });

sub new
{
  my $class = shift;

  my $self = $class->SUPER::new(@_);
  bless $self, $class;

  # ORLite dynamic stuff
  require ORLite;
  my %orlite_options = (
    file    => $self->path,
    package => $self->package,
    cleanup => 'VACUUM',
    create  => sub {
      my $dbh = shift;
      $dbh->do($LOG_SCHEMA);
      },
    tables => [ $LOG_TABLE ],
    prune  => $self->prune,
  );

  if ($self->user_version)
    {
      $orlite_options{ user_version } = $self->user_version;
      my $pkg = $self->package;
      no strict 'refs';
      ${"$pkg\::VERSION"} = $self->user_version;
    }
  $orlite_options{ cache } = $self->cache
    if ($self->cache);

  ORLite->import( \%orlite_options );

  return $self;
}

sub package_table
{
  my ($self) = @_;

  return $self->package.'::'.camelize($LOG_TABLE);
}

sub schema
{
  my ($self) = @_;

  return $LOG_SCHEMA;
}

# override log method
sub log
{
  my ($self, $level, @msgs) = @_;

  # Check log level
  $level = lc $level;
  return $self unless $level && $self->is_level($level);

  my $timestamp = time; # time in milliseconds
  my $msgs = join "\n",
    map { utf8::decode $_ unless utf8::is_utf8 $_;
          $self->_placeholders($_); } @msgs;

  # Caller
  my ($pkg, $line) = (caller())[0, 2];
  ($pkg, $line) = (caller(1))[0, 2] if $pkg eq ref $self or $pkg =~ m/Mojo::Log/;

  my %log_message = (
    'l_who_mod'  => $pkg,
    'l_who_pos'  => $line,
    'l_who_id'   => $$,
    'l_what'     => $msgs,
    'l_when'     => int($timestamp),
    'l_level'    => $level
    );

  $log_message{ 'l_who_app' } = $self->app
    if ($self->app);

  # Write
  $self->package_table->create( %log_message );

  return $self;
}

sub clear
{
  my ($self, $numdays) = @_;

  croak qq/Not a valid number of days $numdays/
    unless ($numdays =~ m/^\d+$/ && $numdays >= 0);

  my $package = $self->package_table;

  # Delete
  if ($numdays == 0)
    {
      $self->package_table->truncate;
    }
  else
    {
      $self->package_table->delete('WHERE t_when ts < strftime("%s","now", "-? day"); ', $numdays);
    }

  return $self;
}

sub _placeholders
{
  my ($self, $msg) = @_;
  
  $msg =~ s/%([xX])(?:{(.*?)})*/_replace($self, $1, $2);/gex;

  return $msg;
}

sub _replace
{
  my ($self, $what, $key) = @_;

  my $ret = "[undef]";

  if ($what eq 'x')
    {
      $ret = join " ", @{$self->context_stack}
        if (defined $self->context_stack->[-1]);
    }
  elsif ($what eq 'X')
    {
      $ret = $self->context_map->{$key}
        if (exists $self->context_map->{$key});
    }

  return $ret;
}

1;

__END__

=head1 NAME

MojoX::Logite - A simple Mojo::Log implementation which logs to an SQLite database

=head1 SYNOPSIS

  use MojoX::Logite;

  # Create a logging object that will log to STDERR by default
  my $logite = MojoX::Logite->new;

  # Customize the logite location and minimum log level
  my $logite = MojoX::Logite->new(
        path  => '/var/log/mojo.db',
        level => 'warn',
        package => 'MyApp::Logite',
    );

  $logite->log(debug => 'This should work');

  $logite->debug("Why isn't this working?");
  $logite->info("FYI: it happened again");
  $logite->warn("This might be a problem");
  $logite->error("Garden variety error");
  $logite->fatal("Boom!");

  # wipe the whole log file
  $logite->clear(0);

  # clear all messages older than 7 days
  $logite->clear(7);

  # ORLite root and table package methods (be careful!)

  my $package = $logite->package;

  my $handle = $package->dbh;

  my %whos = $package->selectall_hashref(
              	'select who from Log where ...'
		);

  my $package_log = $logite->package.'::Log';

  $package_log->iterate( sub {
             print localtime($_->l_when)." ".$_->l_level." ".$_->l_who." [".$_->l_ctx."]: ".$_->l_what."\n";
         } );

  # clean completly the log
  MyApp::Logite::Log->truncate;

=head1 DESCRIPTION

MojoX::Logite is a simple Mojo::Log subclass implementation which logs to an SQLite database.
A Mojolicious::Plugin::Logite plugin is also provided.

The module by default logs to a SQLite database file. The module levergaes
basic ORLite library and methods to do basic searching and bookkeeping
of log information.

By default the module uses 'log/mojo_log.db' as DB log file in the context/application directory. No directories
are created apart the DB file itself.

=head1 ATTRIBUTES

L<MojoX::Logite> inherits all attributes from L<Mojo::Log> and implements
the following new ones.

=head2 C<package>

    my $package = $logite->package;

ORLite root package namespace. By default is set to be 'MojoX::Logite' itself and the there is only one log table defined named LogiteTable. See also package_table method and ORLite documentation.

=head2 C<prune>

    my $prune = $logite->prune(1);

See ORLite documentation.  In some situation, such as during test scripts, an application will
only need the created SQLite database temporarily. In these situations, the "prune" option can
be provided to instruct ORLite to delete the SQLite database when the program ends.

By default, the "prune" option is set to false.

=head2 C<user_version>

    my $user_version = $logite->user_version(1);

Basic support for ORlite schema version-locking. See ORLite documentation. It will require 
PRAGMA user_version = <version_number> to work. It is genrally used with the cache attribute, see below.

=head2 C<cache>

    my $cache = $logite->cache('cache/directory');

Cache ORLite auto-generated package structures. See ORLite documentation.

=head2 C<readonly>

    my $readonly = $logite->readonly(1);

Not very useful, if not to just open log DB for statistics and no log operationas are required. See
ORLite documentation.

=head2 C<app>

    my $app = $logite->app;

If set it is a name or identifier for the application which is logging information. This might be useful
for applications which need to track additional contextual information on a per-application base, in addition
to track the default package, line, log level and process pid information. By default, no additional app
context is set.

=head2 C<context_stack>

    my $context_stack = $logite->context_stack;

    # peek
    my $value = $logite->context_stack->[-1];

    # pop
    my $value = pop @{$logite->context_stack};

    # likewise perl equivalents shift/unshift/slice etc...

    # push
    push @{$logite->context_stack}, $value;

    # clear any state
    $logite->context_stack( [] ); 

The Nested Diagnostic Context (NDC) to use to generate contextual logging information using
the %x placeholder. See C<DIAGNOSTIC CONTEXTS> below.

=head2 C<context_map>

    my $context_map = $logite->context_map;

    my $state = $logite->context_map->{state};

    $logite->context_map->{new_state} = $new_value;

    # clear any state
    $logite->context_map( {} );

The Mapped Diagnostic Context (MDC) to use to generate contextual logging information using
the %X{key} placeholder. See C<DIAGNOSTIC CONTEXTS> below.

=head1 METHODS

L<MojoX::Logite> inherits all methods from L<Mojo::Log> and implements the
following new ones.

=head2 C<log>($level, @messages)

  $log = $log->log(debug => 'This should work');

This method simply overrides the default Mojo::Log one and logs information to the underling SQL table.

In addition, diagnostic context information the following I<placeholders> can be used
in the log messages passed to the method:

    %x The topmost NDC (see C<context_stack> attribute above)
    %X{key} The entry 'key' of the MDC ( see C<context_map> attribute above)

NDC and MDC are explained in C<DIAGNOSTIC CONTEXTS> below.

For example using NDC the following:

  push @{$logite->context_stack}, "193.123.45.67";

  $log = $log->log(debug => '[%x] This should work');

Should store into the SQL table a log message like

  "[193.123.45.67] This should work"

Or using MDC instead:

  $log->context_map->{ip} = "193.123.45.67";
  
  $log = $log->log(debug => '[%X{ip}] This should work');

Should generate the same message.

=head2 C<package_table>

Helper function. It returns the fully qualified package name of the underlying SQLite table used for logging.

=head2 C<clear>([NUMDAYS])

Clean the log DB. A mandatory unsigned integer NUMDAYS parameter must specified, to indicate that only messages older than NUMDAYS will be removed.

    $logite->clear(1);

Clear all messages older than yesterday (yesterday messages are left intact).

If NUMDAYS is set to 0 the whole log is cleaned up.

=head2 C<schema>

Read-only helper function. It returns the SQLite schema used for logging. This might be useful for applications willing to
pre-create the tabled into an existing SQLite database, so that MojoX::Logite can then work on its logging table/s
on an existing database.

We note that by default ORLite does not allow to create a table on a existing database (obviously), but sometimes we might want
to maintain one single DB file for the whole application, including logging information.

=head1 ROOT AND TABLE PACKAGE METHODS

The MojoX::Logite package method provides access via the defined package namesapce (default 'MojoX::Logite::ORLite') to the ORLite root packages methods
and the table specific methods via the MojoX::Logite::ORLite::Log package. If differently specified the name of the package can be retrieved with the
package attribute and package_table method respectively.

B<BE CAREFUL IF YOU DO NOT KNOW WHAT YOU ARE DOING!>

B<READ carefully the ORLite module documentation first trying anything, you could corrupt or wipe you log DB files without notice>

=head1 DIAGNOSTIC CONTEXTS

MojoX::Logite allows loggers to maintain common contextual data,
called the Nested Diagnostic Context (NDC) and Mapped Diagnostic Context (MDC).

The concept of diagnostic logging context is described in
Neil Harrison "Patterns for Logging Diagnostic Messages" article, and it is
already implemented into other logging APIs such as Log::Log4perl::MDC.

An MDC is a simple hash table which can be associated to a logger in order to
preserve context between different logging operations. An application can stuff
values under certain keys and retrieve them later via the C<"%X{key}">
placeholder as part of the message/s passed to the MojoX::Logite log method. This
has the benefit to allow to pass a state between different logging operations then
more contextual information can be extracted from the log. See the C<context_map>
attribute above.

In some other cases, at some point the application might decide to push a piece of
data onto the NDC stack, which other parts of the application might
want to reuse. For example, at the beginning of a web request in a server,
the application might decide to push the IP address of the client
onto the stack to provide it for other loggers down the road without
having to pass the data from function to function.

MojoX::Logite provides the C<%x> placeholder which is replaced by a string
which is a blank-separated concatenation of the elements currently on the context stack.
See the C<context_stack> attribute above.

A diagnostic logging context come in handy when users have lots of logs to go through.
For example when diagnosing weird bugs on a production system with interleaving outputs.
Having more contexts gives you way to filter the output or not outputting unneeded logs.

Once an MDC is tied to a logger any log() operation will automatically refer and use the
MDC hash information when referred into output log messages with placeholders. See MojoX::Logite.

MojoX::Logite will automatically replace any %X{key} with the correspoding MDC hash value.

=head1 SEE ALSO

 Mojolicious::Plugin::Logite
 Mojolicious::Plugin::Logite::MDC
 Mojolicious::Plugin::Logite::NDC
 Mojo::Log
 Mojolicious
 ORLite

 "Patterns for Logging Diagnostic Messages" from Neil Harrison

=head1 REPOSITORY

http://github.com/areggiori/MojoX-Logite

=head1 AUTHOR

Alberto Attilio Reggiori, E<lt>areggiori@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Alberto Reggiori

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
