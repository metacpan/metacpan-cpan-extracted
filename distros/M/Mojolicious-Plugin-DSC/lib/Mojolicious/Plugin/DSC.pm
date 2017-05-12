package Mojolicious::Plugin::DSC;
use Mojo::Base 'Mojolicious::Plugin';
use DBIx::Simple::Class;
use Mojo::Util qw(camelize);
use Carp;

our $VERSION = '1.006';

#some known good defaults
my $COMMON_ATTRIBUTES = {
  RaiseError => 1,
  AutoCommit => 1,
};

has config => sub { {} };

sub register {
  my ($self, $app, $config) = @_;

  # This stuff is executed, when the plugin is loaded
  # Config
  $config                   //= {};
  $config->{load_classes}   //= [];
  $config->{DEBUG}          //= ($app->mode =~ m|^dev|);
  $config->{dbh_attributes} //= {};
  $config->{database}       //= '';
  croak('"load_classes" configuration directive '
      . 'must be an ARRAY reference containing a list of classes to load.')
    unless (ref($config->{load_classes}) eq 'ARRAY');
  croak('"dbh_attributes" configuration directive '
      . 'must be a HASH reference. See DBI/Database_Handle_Attributes.')
    unless (ref($config->{dbh_attributes}) eq 'HASH');

  #prepared Data Source Name?
  if (!$config->{dsn}) {
    $config->{driver}
      || croak('Please choose and set a database driver like "mysql","SQLite","Pg"!..');
    croak('Please set "database"!') unless $config->{database} =~ m/\w+/x;
    $config->{host} ||= 'localhost';
    $config->{dsn} = 'dbi:'
      . $config->{driver}
      . ':database='
      . $config->{database}
      . ';host='
      . $config->{host}
      . ($config->{port} ? ';port=' . $config->{port} : '');

    if ($config->{database} =~ m/(\w+)/x) {
      $config->{namespace} = camelize($1) unless $config->{namespace};
    }
  }
  else {
    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) =
      DBI->parse_dsn($config->{dsn})
      || croak("Can't parse DBI DSN! dsn=>'$config->{dsn}'");
    $config->{driver} = $driver;

    $scheme =~ m/(database|dbname)=\W?(\w+)/x and do {
      $config->{namespace} ||= camelize($2);
    };
    $config->{dbh_attributes} =
      {%{$config->{dbh_attributes}}, ($attr_hash ? %$attr_hash : ())};
  }

  $config->{onconnect_do} ||= [];

  #Postpone connecting to the database till the first helper call.
  my $helper_builder = sub {

    #ready... Go!
    my $dbix = DBIx::Simple->connect(
      $config->{dsn},
      $config->{user}     || '',
      $config->{password} || '',
      {%$COMMON_ATTRIBUTES, %{$config->{dbh_attributes}}}
    );
    if (!ref($config->{onconnect_do})) {
      $config->{onconnect_do} = [$config->{onconnect_do}];
    }
    for my $sql (@{$config->{onconnect_do}}) {
      next unless $sql;
      if (ref($sql) eq 'CODE') { $sql->($dbix); next; }
      $dbix->dbh->do($sql);
    }
    my $DSCS   = $config->{namespace};
    my $schema = Mojo::Util::class_to_path($DSCS);
    if (eval { require $schema; }) {
      $DSCS->DEBUG($config->{DEBUG});
      $DSCS->dbix($dbix);
    }
    else {
      Carp::carp("($@) Trying to continue without $schema...");
      DBIx::Simple::Class->DEBUG($config->{DEBUG});
      DBIx::Simple::Class->dbix($dbix);
    }
    $self->_load_classes($app, $config);
    return $dbix;
  };

  #Add $dbix as attribute and helper where needed
  my $dbix_helper = $config->{dbix_helper} ||= 'dbix';
  $app->helper($dbix_helper, $helper_builder);
  $self->config({%$config});    #copy
  $app->$dbix_helper() if (!$config->{postpone_connect});
  return $self;
}    #end register


sub _load_classes {
  my ($self, $app, $config) = @_;
  state $load_error = <<"ERR";
You may need to create it first using the dsc_dump_schema.pl script.'
Try: dsc_dump_schema.pl --help'
ERR

  if (scalar @{$config->{load_classes}}) {
    my @classes   = @{$config->{load_classes}};
    my $namespace = $config->{namespace};
    $namespace .= '::' unless $namespace =~ /:{2}$/;
    foreach my $class (@classes) {
      if ($class =~ /^$namespace/) {
        my $e = Mojo::Loader::load_class($class);
        Carp::confess(ref $e ? "Exception: $e" : "$class not found: ($load_error)")
          if $e;
        next;
      }
      my $e = Mojo::Loader::load_class($namespace . $class);
      if (ref $e) {
        Carp::confess("Exception: $e");
      }
      elsif ($e) {
        my $e2 = Mojo::Loader::load_class($class);
        Carp::confess(ref $e2 ? "Exception: $e2" : "$class not found: ($load_error)")
          if $e2;
      }
    }
  }
  else {    #no load_classes
    my @classes = Mojo::Loader::find_modules($config->{namespace});
    foreach my $class (@classes) {
      my $e = Mojo::Loader::load_class($class);
      croak($e) if $e;
    }
  }
  return;
}

1;

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DSC - use DBIx::Simple::Class in your application.

=head1 SYNOPSIS

  #load
  # Mojolicious
  $self->plugin('DSC', $config);

  # Mojolicious::Lite
  plugin 'DSC', $config;
  
  my $user = My::User->find(1234);
  #or
  my $user = My::User->query('SELECT * FROM users WHERE user=?','ivan');
  #or if SQL::Abstract is isnstalled
  my $user = My::User->select(user=>'ivan');
  
  
=head1 DESCRIPTION

Mojolicious::Plugin::DSC is a L<Mojolicious> plugin that helps you
use L<DBIx::Simple::Class> in your application.
It also adds an app attribute (C<$app-E<gt>dbix>) and controller helper (C<$c-E<gt>dbix>) 
which is a L<DBIx::Simple> instance.

=head1 CONFIGURATION

The configuration is pretty flexible:

  # in Mojolicious startup()
  $self->plugin('DSC', {
    dsn => 'dbi:SQLite:database=:memory:;host=localhost'
  });
  #or
  $self->plugin('DSC', {
    driver => 'mysqlPP',
    database => 'mydbname',
    host => '127.0.0.1',
    user => 'myself',
    password => 'secret',
    onconnect_do => [
      'SET NAMES UTF8',
      'SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO"'
      sub{my $dbix = shift; do_something_complicated($dbix)}
    ],
    dbh_attributes => {AutoCommit=>0},
    namespace => 'My',
    
    #will load My::User, My::Content, My::Pages
    load_classes =>['User', 'Content', 'My::Pages'],
    
    #now you can use $app->DBIX instead of $app->dbix
    dbix_helper => 'DBIX' 
  });

The following parameters can be provided:

=head2 load_classes

An ARRAYREF of classes to be loaded. If not provided, 
all classes under L<namespace> will be loaded.
Classes are expected to be already dumped as files using 
C<dsc_dump_schema.pl> from an existing database.

  #all classes under My::Schema::Class
  $app->plugin('DSC', {
    namespace => My::Schema::Class,
  });
  #only My::Schema::Class::Groups and My::Schema::Class::Users
  $app->plugin('DSC', {
    namespace => My::Schema::Class,
    load_classes => ['Groups', 'Users']
  });

=head2 DEBUG

Boolean. When the current L<Mojolicious/mode> is C<development> this value
is 1.

  $app->plugin('DSC', {
    DEBUG => 1,
    namespace => My::Schema::Class,
    load_classes => ['Groups', 'Users']
  });

=head2 dbh_attributes

HASHREF. Attributes passed to L<DBIx::Simple/connect>.
Default values are:

  {
    RaiseError => 1,
    AutoCommit => 1,
  };

They can be overriden:

  $app->plugin('DSC', {
    namespace => My::Schema::Class,
    dbh_attributes =>{ AutoCommit => 0, sqlite_unicode => 1 }
  });

=head2 dsn

Connection string parsed using L<DBI/parse_dsn> and passed to L<DBIx::Simple/connect>.

From this string we guess the L</driver>, L</database>, L<host>, L<port>
and the L<namespace> which ends up as camelised form of 
the L</database> name.

If L</dsn> is not passed most of the configuration values above must 
be provided so a valid connection string can be constructed.
If L</dsn> is provided it will be preferred over the above parameters
(excluding namespace) because the developer should know better how 
exactly to connect to the database.

  $app->plugin('DSC', {
    namespace => My::Schema::Class,
    dbh_attributes => {sqlite_unicode => 1},
    dsn => 'dbi:SQLite:database=myfile.sqlite'
  });

=head2 driver

String. One of "mysql","SQLite","Pg" etc...
This string is prepended with "dbi:". No default value.

  $app->plugin('DSC', {
    driver => 'mysql',
    dbh_attributes => {sqlite_unicode => 1},
    dsn => 'dbi:SQLite:database=myfile.sqlite'
  });

=head2 database

String - the database name. No default value.

  $app->plugin('DSC', {
    database       => app->home->rel_file('etc/ado.sqlite'),
    dbh_attributes => {sqlite_unicode => 1},
    driver         => 'SQLite',
    namespace      => 'Ado::Model',
  });

=head2 host

String. defaults to C<localhost>.

=head2 port

String. Not added to the connection string if not provided.

=head2 namespace

The class name of your schema class. If not provided the value will be guessed
from the L<database> or L<dsn>. It is recommended to provide your 
schema class name.

  $app->plugin('DSC', {
    database       => app->home->rel_file('etc/ado.sqlite'),
    dbh_attributes => {sqlite_unicode => 1},
    driver         => 'SQLite',
    namespace      => 'My::Model',
  });


=head2 user

String. Username used to connect to the database.

=head2 password

String. Password used to connect to the database.

=head2 onconnect_do

ARRAYREF of SQL statements and callbacks which will be executed right after
establiching the connection.

  $app->plugin('DSC', {
    database       => app->home->rel_file('etc/ado.sqlite'),
    dbh_attributes => {sqlite_unicode => 1},
    driver         => 'SQLite',
    namespace      => 'Ado::Model',
    onconnect_do   => [
        'PRAGMA encoding = "UTF-8"',
        'PRAGMA foreign_keys = ON',
        'PRAGMA temp_store = 2',    #MEMORY
        'VACUUM',
        sub{
          shift->dbh->sqlite_create_function( 'now', 0, sub { return time } );
        }
    ],
  });


=head2 postpone_connect

Boolean. If set, establishing the connection to the database will
be postponed for the first call of C<$app-E<gt>dbix> or the method
name you provided for the L</dbix_helper>.

=head2 dbix_helper

String. The name of the helper method that can be created to invoke/use
directly the L<DBIx::Simple> instance on your controller or application.
Defaults to C<dbix>.

=head1 METHODS

L<Mojolicious::Plugin::DSC> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head2 config

This plugin own configuration. Returns a HASHref.

  #debug
  $app->log->debug($app->dumper($plugin->config));

=head1 SEE ALSO

L<DBIx::Simple::Class>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Красимир Беров (Krasimir Berov).

This program is free software, you can redistribute it and/or
modify it under the terms of the Artistic License version 2.0.

See http://dev.perl.org/licenses/ for more information.

=cut
