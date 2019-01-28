package PMLTQ::Commands;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Commands::VERSION = '2.0.3';
# ABSTRACT: PMLTQ command line interface

use PMLTQ::Base -strict;

use Cwd qw/getcwd abs_path/;
use File::Basename 'fileparse';
use File::Spec;
use Getopt::Long ();
use Hash::Merge 'merge';
use List::MoreUtils 'apply';
use PMLTQ::Loader qw/find_modules load_class/;
use YAML::Tiny;

use File::Basename 'dirname';
use File::Spec ();
use File::ShareDir 'dist_dir';
my $local_shared_dir = File::Spec->catdir(dirname(__FILE__), File::Spec->updir, File::Spec->updir, File::Spec->updir, 'share');
my $shared_dir = eval { dist_dir(__PACKAGE__) };

# Assume installation
if (-d $local_shared_dir or !$shared_dir) {
  $shared_dir = $local_shared_dir;
}
sub shared_dir { $shared_dir }

sub DEFAULT_CONFIG {
  my $base_dir = shift || getcwd();
  return {
    data_dir   => File::Spec->catdir( $base_dir, 'data' ),
    output_dir => File::Spec->catdir( $base_dir, 'sql_dump' ),
    resources  => File::Spec->catdir( $base_dir, 'resources' ),
    db         => {
      host => 'localhost',
      port => 5432
    },
    isFree => 'false',
    isAllLogged => 'false',
    isPublic => 'false',
    isFeatured => 'false',
    info => {
      fields => 'name'
    }
  };
}

sub run {
  my ( $self, $name, @args ) = @_;

  if ( $name && $name =~ /^\w+$/ && ( $name ne 'help' || $args[0] ) ) {
    $name = shift @args if my $help = $name eq 'help';

    my $command = _command( "PMLTQ::Command::$name", \@args );
    return $help ? $command->help : $command->run(@args);
  }
  print "Available commands:\n\t", join( "\n\t", sort { $a cmp $b } _available_commands() ), "\n";
}

sub _available_commands {
  apply {s/^PMLTQ::Command:://} find_modules('PMLTQ::Command');
}

sub _command {
  my ( $module, $args ) = @_;

  die qq{Unknown command "$module", maybe you need to install it?\n} unless load_class($module);
  die qq{Command doesn't inherit from PMLTQ::Command} unless $module->isa('PMLTQ::Command');

  my $config = _parse_args($args);
  return $module->new( config => $config );
}

sub _parse_args {
  my $args        = shift;
  my $p           = Getopt::Long::Parser->new( config => [qw/pass_through no_ignore_case no_auto_abbrev/] );
  my $config_file = '';
  my $config      = {};

  my $command_line_config = {};
  my @unprocessed_args    = ();

  $p->getoptionsfromarray(
    $args,
    'c|config=s' => \$config_file,
    '<>'         => sub {
      my $arg = shift;
      my ( $path, $value ) = $arg =~ m/^--([a-z0-9-_]+)=(.*)$/;
      unless ($path) {
        push @unprocessed_args, $arg;    # push back to args
        return;
      }

      my @path = split /-/, $path;
      my $name = pop @path;
      my $ref  = $command_line_config;
      while ( my $part = shift @path ) {
        $ref->{$part} = {} unless defined $ref->{$part};
        $ref = $ref->{$part};
      }
      $ref->{$name} = $value;
    }
  );

  if ( $config_file ne '--' ) {
    if ($config_file) {
      die "Configuration file '$config_file' does not exists or is not readable" unless -r $config_file;
    } else {
      $config_file = File::Spec->catfile( getcwd(), 'pmltq.yml' );
      $config_file = undef unless -r $config_file;
    }
  }

  push @$args, @unprocessed_args if @unprocessed_args > 0;

  $config = _load_config($config_file) if $config_file;

  return merge( $command_line_config, merge( $config, DEFAULT_CONFIG ) );
}

sub _load_config {
  my $config_file = shift;
  my $data;
  my $yaml_str;
  if ( $config_file eq '--' ) {
    $yaml_str = do {
      local $/;
      <STDIN>;
    };
    eval { $data = YAML::Tiny->read_string($yaml_str) };
  } else {
    eval { $data = YAML::Tiny->read($config_file) };
  }
  if ( $@ && $@ =~ m/YAML_LOAD_ERR/ ) {
    die "Unable to load config file '$config_file'\n";
  } elsif ( $@ && $@ =~ m/YAML_PARSE_ERR/ ) {
    $@ =~ s/\n.*//g;
    die "Unable to parse config file '$config_file'\n\t$@\n";
  } elsif ( $config_file eq '--' && !$data ) {
    die "Unable to parse config from STDIN:\n$yaml_str\n";
  } elsif ( !$data ) {
    die "Unable to open config file '$config_file'\n";
  }

  my $config = $data->[0];

  my $base_dir = $config->{base_dir};
  unless ($base_dir) {
    ( undef, $base_dir, undef ) = fileparse($config_file);
    $base_dir = abs_path($base_dir);
  }

  $config->{db} = {} unless $config->{db};
  $config->{db}->{name} = $config->{treebank_id} if ( $config->{treebank_id} && !$config->{db}->{name} );

  for ( grep { $config->{$_} } qw/data_dir resources output_dir/ ) {
    $config->{$_} = abs_path( File::Spec->rel2abs( $config->{$_}, $base_dir ) );
  }

  if ( $config->{layers} ) {
    for my $lr ( @{ $config->{layers} } ) {
      $lr->{'related-schema'} =
        [ map { abs_path( File::Spec->rel2abs( $_, $config->{resources} ) ) } @{ $lr->{'related-schema'} } ]
        if $lr->{'related-schema'};
      $lr->{filelist} = abs_path( File::Spec->rel2abs( $lr->{filelist}, $base_dir ) )
        if $lr->{filelist} && !File::Spec->file_name_is_absolute( $lr->{filelist} );
    }
  }

  return merge( $config, DEFAULT_CONFIG($base_dir) );
}

1;

=encoding utf8

=head1 SYNOPSIS

  Usage: pmltq COMMAND [OPTIONS]

    pmltq version
    pmltq configuration
    pmltq init schema1.xml schema2.xml
    pmltq convert
    pmltq load
    pmltq initdb
    pmltq delete
    pmltq webload
    pmltq webdelete
    pmltq webtreebank
    pmltq webverify

  Options (for all commands):
    -c, --config      Config file, by default commands will look
                      for config file called C<pmltq.yml> in the
                      current directory.

=head1 COMMANDS

These commands are available by default.

=head2 configuration

  $ pmltq convert

Uses L<PMLTQ::Command::configuration> to to get current configuration


=head2 convert

  $ pmltq convert

Uses L<PMLTQ::Command::convert> to convert data in the C<data_dir> based on
layers configuration

=head2 delete

  $ pmltq delete

Uses L<PMLTQ::Command::delete> to delete the database for current treebank

=head2 init

  $ pmltq init resources/schema1.xml resources/schema2.xml

Uses L<PMLTQ::Command::init> to generate initial configuration file skeleton
based on given schemas. This command can help you quickly bootstrap the layers
configuration

=head2 initdb

  $ pmltq initdb

Uses L<PMLTQ::Command::initdb> to create and initialize new database for given
treebank

=head2 load

  $ pmltq load

Uses L<PMLTQ::Command::load> to load the data generated by C<convert> command

=head2 query

Uses L<PMLTQ::Command::query> to run a query on given treebank.

=head2 verify

Uses L<PMLTQ::Command::verify> to check if database exists and contains some
data. For now the checking is very simple

=head2 version

Uses L<PMLTQ::Command::version> to display current PMLTQ version

=head2 webdelete

Uses L<PMLTQ::Command::webdelete> to delete treebank from web interface

=head2 webload

Uses L<PMLTQ::Command::webload> to load treebank to web interface

=head2 webtreebank

Uses L<PMLTQ::Command::webtreebank> to get list of treebanks or single treebank info

=head2 webverify

Uses L<PMLTQ::Command::webverify> to verify treebank visibility in web interface

=head1 CONFIG FILE

=head2 Options

=over 2

=item C<treebank_id>

ID of the treebank. Can contain only [a-zA-Z0-9_]. It will be default for the
database name and treebank name in web interface.

=item C<data_dir>

Directory where the data are (this is also base directory for data layers)

Defaults: B<data>

=item C<resources>

Base directory for PML schemas

Defaults: B<resources>

=item C<output_dir>

Directory for all sql dump files. The files generated by C<convert> and used by C<load> command

Defaults: B<sql_dump>

=item C<db>

=over 4

=item C<name>

Database name

Defaults: B<C<treebank_id>> if defined

=item C<host>

Database server hostname or IP address

Defaults: B<localhost>

=item C<port>

Database port

Defaults: B<5432>

=item C<user>, C<password>

Database credentials

=back

=item C<sys_db>

Name of the 'system database' used for administration commands such as
C<CREATE> and C<DROP>.

=item C<layers>

The configuration of treebank's layers and references for each layer.

=over 4

=item C<name>

Schema root name

=item C<data>

A C<glob> path name matching pattern relative to C<data_dir>

=item C<path>

A path name matching pattern relative to PML-TQ server data directory

=item C<related-schema>

List of related schemas that contain node types required in this layer's
reference configuration

=item C<references>

This is key-value hash where key is path to the member of the node structure
and value is node type or '-' (dash) if you intend to ignore that particular
reference. If the node type is not in the current layer schema you have to
prefix node type with the schema name and the appropriate schema have to be
listed in C<related-schema> list.

Examples:

  references:
    path/attr1: '-' #--> ignore this reference
    path/attr2: ref-node #--> reference node type 'ref-node'
    path/attr3: schema:other-node #--> reference node type 'other-node' in schema 'schema'

=back

=item C<title>

Treebank title visible at the web.

=item C<homepage>

Treebank homepage url.

=item C<description>

Treebank description visible at the web.

=item C<isFree>

Boolean value (C<true>, C<false>) sets if the logging in is not required for querying treebank.

Defaults: B<false>

=item C<isAllLogged>

Boolean value (C<true>, C<false>) sets if treebank is queryable for all logged in users.

Defaults: B<false>

=item C<isPublic>

Boolean value (C<true>, C<false>) sets if the treebank is visible for not logged users.

Defaults: B<false>

=item C<isFeatured>

Boolean value (C<true>, C<false>) sets if the treebank is featured.

Defaults: B<false>

=item C<web_api>

=over 4

=item C<dbserver>

Name of database server setted in web interface.

=item C<url>

Link to PML-TQ web service.

=item C<user>, C<password>

Web API credentials of user with admin privileges.

=back

=item C<manuals>

List of manuals

=over 4

=item C<title>, C<url>

Title and link to manual

=back

=item C<tags>

List of tags

=item C<language>

Language code

=item C<test_query>

=over 4

=item C<result_dir>

Directory where should be saved results of test queries (SVG and text files)

=item C<queries>

=over 4

=item C<filename>

Name of the file where the results should be saved

=item C<query>

PML-TQ query

=back

=back

=back

=head2 Change values using CLI

You can use command line parameters to modify any configuration options.

For example you can use

  pmltq load --output_dir='/some/path' --data_dir='some/other/path' --db-name='abc'

Dash C<-> in the parameter's name means dive into the hash, so C<--db-name='abc'> is
going to change C<db: name: 'abc'> while C<--db_name='abc'> would just set configuration
option C<db_name: 'abc'>.

=head2 Commands and options

Following table shows which options are used in commands.

=over 4

=item B<*> required

=item B<+> optional (defaults or nothing is used)

=item B<-> not used

=back

=begin html

<table>
<tr><td></td><th>convert</th><th>delete</th><th>init</th><th>initdb</th><th>load</th><th>verify</th><th>webdelete</th><th>webload</th><th>webverify</th></tr>
<tr><td>treebank_id</td><th>*</th><th>*</th><th>-</th><th>*</th><th>*</th><th>*</th><th>*</th><th>*</th><th>*</th></tr>
<tr><td>data_dir</td><th>+</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>resources</td><th>+</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>output_dir</td><th>+</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>db-name</td><th>-</th><th>+</th><th>-</th><th>+</th><th>+</th><th>+</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>db-host</td><th>-</th><th>+</th><th>-</th><th>+</th><th>+</th><th>+</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>db-port</td><th>-</th><th>+</th><th>-</th><th>+</th><th>+</th><th>+</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>db-user</td><th>-</th><th>-</th><th>-</th><th>*</th><th>*</th><th>*</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>db-password</td><th>-</th><th>-</th><th>-</th><th>*</th><th>*</th><th>*</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>sys_db</td><th>-</th><th>*</th><th>-</th><th>*</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th></tr>
<tr><td>layers</td><th>*</th><th>-</th><th>-</th><th>-</th><th>*</th><th>-</th><th>-</th><th>*</th><th>-</th></tr>
<tr><td>title</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>*</th><th>-</th></tr>
<tr><td>homepage</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>description</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>isFree</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>isPublic</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>isFeatured</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>web_api-dbserver</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>*</th><th>-</th></tr>
<tr><td>web_api-url</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>*</th><th>*</th><th>*</th></tr>
<tr><td>web_api-user</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>*</th><th>*</th><th>*</th></tr>
<tr><td>web_api-password</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>*</th><th>*</th><th>*</th></tr>
<tr><td>manuals</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>tags</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>language</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th><th>-</th></tr>
<tr><td>test_query-result_dir</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th></tr>
<tr><td>test_query-queries</td><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>-</th><th>+</th></tr>
</table>

=end html

=head2 Example:

  data_dir: /pmltq/data/dir/ # directory where the data are (this is also base directory for data layers)
  resources: /pmltq/resources/ # main directory with PML schemas

  treebank_id: tbid

  db: # typical DB auth stuff
    name: treebank_db_name
    host: localhost
    port: 5432
    user: pmltq
    password: pwd

  layers: # description of all data layers
    - name: adata
      data: ./relative/to/data_dir/**/*.a.gz
      related-schema:
        - adata_schema.xml
      references:
        t-node/val_frame.rf: '-'
        t-a/aux.rf: 'adata:a-node'
        t-node/coref_gram.rf: t-node
    - name: tdata
      data: **/*.t.gz

  web_api:
    user: webuser
    password: pwd
    url: 'https://serviceurl.com/'
    dbserver: myserver

  title: 'Treebank name'
  description: 'Short trebank descrioprion'
  language: cs
  tags:
    - mytag1
    - mytag2

=cut
