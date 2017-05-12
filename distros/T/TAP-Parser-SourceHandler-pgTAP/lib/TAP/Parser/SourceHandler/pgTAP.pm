package TAP::Parser::SourceHandler::pgTAP;

use strict;
use vars qw($VERSION @ISA);

use TAP::Parser::IteratorFactory   ();
use TAP::Parser::Iterator::Process ();

@ISA = qw(TAP::Parser::SourceHandler);
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

our $VERSION = '3.33';

=head1 Name

TAP::Parser::SourceHandler::pgTAP - Stream TAP from pgTAP test scripts

=head1 Synopsis

In F<Build.PL> for your application with pgTAP tests in F<t/*.pg>:

  Module::Build->new(
      module_name        => 'MyApp',
      test_file_exts     => [qw(.t .pg)],
      use_tap_harness    => 1,
      tap_harness_args   => {
          sources => {
              Perl  => undef,
              pgTAP => {
                  dbname   => 'try',
                  username => 'postgres',
                  suffix   => '.pg',
              },
          }
      },
      build_requires     => {
          'Module::Build'                     => '0.30',
          'TAP::Parser::SourceHandler::pgTAP' => '3.19',
      },
  )->create_build_script;

If you're using L<C<prove>|prove>:

  prove --source Perl \
        --ext .t --ext .pg \
        --source pgTAP --pgtap-option dbname=try \
                       --pgtap-option username=postgres \
                       --pgtap-option suffix=.pg

If you have only pgTAP tests, just use C<pg_prove>:

  pg_prove --dbname try --username postgres

Direct use:

  use TAP::Parser::Source;
  use TAP::Parser::SourceHandler::pgTAP;

  my $source = TAP::Parser::Source->new->raw(\'mytest.pg');
  $source->config({ pgTAP => {
      dbname   => 'testing',
      username => 'postgres',
      suffix   => '.pg',
  }});
  $source->assemble_meta;

  my $class = 'TAP::Parser::SourceHandler::pgTAP';
  my $vote  = $class->can_handle( $source );
  my $iter  = $class->make_iterator( $source );

=head1 Description

This source handler executes pgTAP tests. It does two things:

=over

=item 1.

Looks at the L<TAP::Parser::Source> passed to it to determine whether or not
the source in question is in fact a pgTAP test (L</can_handle>).

=item 2.

Creates an iterator that will call C<psql> to run the pgTAP tests
(L</make_iterator>).

=back

Unless you're writing a plugin or subclassing L<TAP::Parser>, you probably
won't need to use this module directly.

=head2 Testing with pgTAP

If you just want to write tests with L<pgTAP|http://pgtap.org/>, here's how:

=over

=item *

Build your test database, including pgTAP. It's best to install it in its own
schema. To build it and install it in the schema "tap", do this (assuming your
database is named "try"):

  make TAPSCHEMA=tap
  make install
  psql -U postgres -d try -f pgtap.sql

=item *

Write your tests in files ending in F<.pg> in the F<t> directory, right
alongside your normal Perl F<.t> tests. Here's a simple pgTAP test to get you
started:

  BEGIN;

  SET search_path = public,tap,pg_catalog;

  SELECT plan(1);

  SELECT pass('This should pass!');

  SELECT * FROM finish();
  ROLLBACK;

Note how C<search_path> has been set so that the pgTAP functions can be found
in the "tap" schema. Consult the extensive L<pgTAP
documentation|http://pgtap.org/documentation.html> for a comprehensive list of
test functions.

=item *

Run your tests with C<prove> like so:

  prove --source Perl \
        --ext .t --ext .pg \
        --source pgTAP --pgtap-option dbname=try \
                       --pgtap-option username=postgres \
                       --pgtap-option suffix=.pg

This will run both your Perl F<.t> tests and your pgTAP F<.pg> tests all
together. You can also use L<pg_prove> to run just the pgTAP tests like so:

  pg_prove -d try -U postgres t/

=item *

Once you're sure that you've got the pgTAP tests working, modify your
F<Build.PL> script to allow F<./Build test> to run both the Perl and the pgTAP
tests, like so:

  Module::Build->new(
      module_name        => 'MyApp',
      test_file_exts     => [qw(.t .pg)],
      use_tap_harness    => 1,
      configure_requires => { 'Module::Build' => '0.30', },
      tap_harness_args   => {
          sources => {
              Perl  => undef,
              pgTAP => {
                  dbname   => 'try',
                  username => 'postgres',
                  suffix   => '.pg',
              },
          }
      },
      build_requires     => {
          'Module::Build'                     => '0.30',
          'TAP::Parser::SourceHandler::pgTAP' => '3.19',
      },
  )->create_build_script;

The C<use_tap_harness> parameter is optional, since it's implicitly set by the
use of the C<tap_harness_args> parameter. All the other parameters are
required as you see here. See the documentation for C<make_iterator()> for a
complete list of options to the C<pgTAP> key under C<sources>.

And that's it. Now get testing!

=back

=head1 METHODS

=head2 Class Methods

=head3 C<can_handle>

  my $vote = $class->can_handle( $source );

Looks at the source to determine whether or not it's a pgTAP test and returns
a score for how likely it is in fact a pgTAP test file. The scores are as
follows:

  1    if it's not a file and starts with "pgsql:".
  1    if it has a suffix equal to that in a "suffix" config
  1    if its suffix is ".pg"
  0.8  if its suffix is ".sql"
  0.75 if its suffix is ".s"

The latter two scores are subject to change, so try to name your pgTAP tests
ending in ".pg" or specify a suffix in the configuration to be sure.

=cut

sub can_handle {
    my ( $class, $source ) = @_;
    my $meta = $source->meta;

    unless ($meta->{is_file}) {
        my $test = ref $source->raw ? ${ $source->raw } : $source->raw;
        return 1 if $test =~ /^pgsql:/;
        return 0;
    }

    my $suf = $meta->{file}{lc_ext};

    # If the config specifies a suffix, it's required.
    if ( my $config = $source->config_for('pgTAP') ) {
        if ( my $suffix = $config->{suffix} ) {
            if (ref $suffix) {
                return (grep { $suf eq $_ } @{ $suffix }) ? 1 : 0;
            }
            return $suf eq $config->{suffix} ? 1 : 0;
        }
    }

    # Otherwise, return a score for our supported suffixes.
    my %score_for = (
        '.pg'  => 0.9,
        '.sql' => 0.8,
        '.s'   => 0.75,
    );
    return $score_for{$suf} || 0;
}

=head3 C<make_iterator>

  my $iterator = $class->make_iterator( $source );

Returns a new L<TAP::Parser::Iterator::Process> for the source.
C<< $source->raw >> must be either a file name or a scalar reference to the
file name -- or a string starting with "pgsql:", in which case the remainder
of the string is assumed to be SQL to be executed inside the database.

The pgTAP tests are run by executing C<psql>, the PostgreSQL command-line
utility. A number of arguments are passed to it, many of which you can affect
by setting up the source source configuration. The configuration must be a
hash reference, and supports the following keys:

=over

=item C<psql>

The path to the C<psql> command. Defaults to simply "psql", which should work
well enough if it's in your path.

=item C<dbname>

The database to which to connect to run the tests. Defaults to the value of
the C<$PGDATABASE> environment variable or, if not set, to the system
username.

=item C<username>

The PostgreSQL username to use to connect to PostgreSQL. If not specified, no
username will be used, in which case C<psql> will fall back on either the
C<$PGUSER> environment variable or, if not set, the system username.

=item C<host>

Specifies the host name of the machine to which to connect to the PostgreSQL
server. If the value begins with a slash, it is used as the directory for the
Unix-domain socket. Defaults to the value of the C<$PGDATABASE> environment
variable or, if not set, the local host.

=item C<port>

Specifies the TCP port or the local Unix-domain socket file extension on which
the server is listening for connections. Defaults to the value of the
C<$PGPORT> environment variable or, if not set, to the port specified at the
time C<psql> was compiled, usually 5432.

=item C<pset>

Specifies a hash of printing options in the style of C<\pset> in the C<psql>
program. See the L<psql
documentation|http://www.postgresql.org/docs/current/static/app-psql.html> for
details on the supported options.

=begin comment

=item C<search_path>

The schema search path to use during the execution of the tests. Useful for
overriding the default search path and you have pgTAP installed in a schema
not included in that search path.

=end comment

=back

=cut

sub make_iterator {
    my ( $class, $source ) = @_;
    my $config = $source->config_for('pgTAP');

    my @command = ( $config->{psql} || 'psql' );
    push @command, qw(
      --no-psqlrc
      --no-align
      --quiet
      --pset pager=off
      --pset tuples_only=true
      --set ON_ERROR_STOP=1
    );

    for (qw(username host port dbname)) {
        push @command, "--$_" => $config->{$_} if defined $config->{$_};
    }

    if (my $pset = $config->{pset}) {
        while (my ($k, $v) = each %{ $pset }) {
            push @command, '--pset', "$k=$v";
        }
    }

    if (my $set = $config->{set}) {
        while (my ($k, $v) = each %{ $set }) {
            push @command, '--set', "$k=$v";
        }
    }

    my $fn = ref $source->raw ? ${ $source->raw } : $source->raw;

    if ($fn && $fn =~ s/^pgsql:\s*//) {
        push @command, '--command', $fn;
    } else {
        $class->_croak(
            'No such file or directory: ' . ( defined $fn ? $fn : '' ) )
            unless $fn && -e $fn;
        push @command, '--file', $fn;
    }

    # XXX I'd like a way to be able to specify environment variables to set when
    # the iterator executes the command...
    # local $ENV{PGOPTIONS} = "--search_path=$config->{search_path}"
    #     if $config->{search_path};

    return TAP::Parser::Iterator::Process->new({
        command => \@command,
        merge   => $source->merge
    });
}

=head1 See Also

=over

=item * L<TAP::Object>

=item * L<TAP::Parser>

=item * L<TAP::Parser::IteratorFactory>

=item * L<TAP::Parser::SourceHandler>

=item * L<TAP::Parser::SourceHandler::Executable>

=item * L<TAP::Parser::SourceHandler::Perl>

=item * L<TAP::Parser::SourceHandler::File>

=item * L<TAP::Parser::SourceHandler::Handle>

=item * L<TAP::Parser::SourceHandler::RawTAP>

=item * L<pgTAP|http://pgtap.org/>

=back

=head1 Support

This module is managed in an open
L<GitHub repository|https://github.com/theory/tap-parser-sourcehandler-pgtap/>.
Feel free to fork and contribute, or to clone
C<git://github.com/theory/tap-parser-sourcehandler-pgtap.git> and send
patches!

Found a bug? Please
L<post|https://github.com/theory/tap-parser-sourcehandler-pgtap/issues> or
L<email|mailto:bug-tap-parser-sourcehandler-pgtap@rt.cpan.org> a report!

=head1 Author

David E. Wheeler <dwheeler@cpan.org>

=head1 Copyright and License

Copyright (c) 2010-2016 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
