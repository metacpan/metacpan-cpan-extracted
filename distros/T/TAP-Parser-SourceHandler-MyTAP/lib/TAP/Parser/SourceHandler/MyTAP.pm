package TAP::Parser::SourceHandler::MyTAP;

use strict;
use vars qw($VERSION @ISA);

use TAP::Parser::IteratorFactory   ();
use TAP::Parser::Iterator::Process ();

@ISA = qw(TAP::Parser::SourceHandler);
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

our $VERSION = '3.27';

=head1 Name

TAP::Parser::SourceHandler::MyTAP - Stream TAP from MyTAP test scripts

=head1 Synopsis

In F<Build.PL> for your application with MyTAP tests in F<t/*.my>:

  Module::Build->new(
      module_name        => 'MyApp',
      test_file_exts     => [qw(.t .my)],
      use_tap_harness    => 1,
      tap_harness_args   => {
          sources => {
              Perl  => undef,
              MyTAP => {
                  database => 'try',
                  user     => 'root',
                  suffix   => '.my',
              },
          }
      },
      build_requires     => {
          'Module::Build'                     => '0.30',
          'TAP::Parser::SourceHandler::MyTAP' => '3.22',
      },
  )->create_build_script;

If you're using L<C<prove>|prove>:

  prove --source Perl \
        --ext .t --ext .my \
        --source MyTAP --mytap-option database=try \
                       --mytap-option user=root \
                       --mytap-option suffix=.my

If you have only MyTAP tests, just use C<my_prove>:

  my_prove --database try --user root

Direct use:

  use TAP::Parser::Source;
  use TAP::Parser::SourceHandler::MyTAP;

  my $source = TAP::Parser::Source->new->raw(\'mytest.my');
  $source->config({ MyTAP => {
      database => 'testing',
      user     => 'root',
      suffix   => '.my',
  }});
  $source->assemble_meta;

  my $class = 'TAP::Parser::SourceHandler::MyTAP';
  my $vote  = $class->can_handle( $source );
  my $iter  = $class->make_iterator( $source );

=head1 Description

This source handler executes MyTAP MySQL tests. It does two things:

=over

=item 1.

Looks at the L<TAP::Parser::Source> passed to it to determine whether or not
the source in question is in fact a MyTAP test (L</can_handle>).

=item 2.

Creates an iterator that will call C<mysql> to run the MyTAP tests
(L</make_iterator>).

=back

Unless you're writing a plugin or subclassing L<TAP::Parser>, you probably
won't need to use this module directly.

=head2 Testing with MyTAP

If you just want to write tests with L<MyTAP|https://github.org/theory/mytap/>,
here's how:

=over

=item *

Download L<MyTAP|https://github.org/theory/mytap/> and install it into your
MySQL server:

  mysql -u root < mytap.sql

=item *

Write your tests in files ending in F<.my> in the F<t> directory, right
alongside your normal Perl F<.t> tests. Here's a simple MyTAP test to get you
started:

  BEGIN;

  SELECT tap.plan(1);

  SELECT tap.pass('This should pass!');

  CALL tap.finish();
  ROLLBACK;

Note how the MyTAP functions are being called from the C<tap> database.

=begin comment

Add this if a MyTAP site comes up with docs.

Consult the extensive L<MyTAP
documentation|http://mytap.org/documentation.html> for a comprehensive list of
test functions.

=end comment

=item *

Run your tests with C<my_prove> like so:

  my_prove --database try --user root t/

Or, if you have Perl F<.t> and MyTAP F<.my> tests, run them all together with
C<prove>:

        --ext .t --ext .my \
        --source MyTAP --mytap-option database=try \
                       --mytap-option user=root \
                       --mytap-option suffix=.my
=item *

Once you're sure that you've got the MyTAP tests working, modify your
F<Build.PL> script to allow F<./Build test> to run both the Perl and the MyTAP
tests, like so:

  Module::Build->new(
      module_name        => 'MyApp',
      test_file_exts     => [qw(.t .my)],
      use_tap_harness    => 1,
      configure_requires => { 'Module::Build' => '0.30', },
      tap_harness_args   => {
          sources => {
              Perl  => undef,
              MyTAP => {
                  database => 'try',
                  user     => 'root',
                  suffix   => '.my',
              },
          }
      },
      build_requires     => {
          'Module::Build'                     => '0.30',
          'TAP::Parser::SourceHandler::MyTAP' => '3.22',
      },
  )->create_build_script;

The C<use_tap_harness> parameter is optional, since it's implicitly set by the
use of the C<tap_harness_args> parameter. All the other parameters are
required as you see here. See the documentation for C<make_iterator()> for a
complete list of options to the C<MyTAP> key under C<sources>.

And that's it. Now get testing!

=back

=head1 Methods

=head2 Class Methods

=head3 C<can_handle>

  my $vote = $class->can_handle( $source );

Looks at the source to determine whether or not it's a MyTAP test file and
returns a score for how likely it is in fact a MyTAP test file. The scores are
as follows:

  1    if it has a suffix equal to that in a "suffix" config
  1    if its suffix is ".my"
  0.8  if its suffix is ".sql"
  0.75 if its suffix is ".s"

The latter two scores are subject to change, so try to name your MyTAP tests
ending in ".my" or specify a suffix in the configuration to be sure.

=cut

sub can_handle {
    my ( $class, $source ) = @_;
    my $meta = $source->meta;

    return 0 unless $meta->{is_file};

    my $suf = $meta->{file}{lc_ext};

    # If the config specifies a suffix, it's required.
    if ( my $config = $source->config_for('MyTAP') ) {
        if ( my $suffix = $config->{suffix} ) {
            if (ref $suffix) {
                return (grep { $suf eq $_ } @{ $suffix }) ? 1 : 0;
            }
            return $suf eq $config->{suffix} ? 1 : 0;
        }
    }

    # Otherwise, return a score for our supported suffixes.
    my %score_for = (
        '.my'  => 0.9,
        '.sql' => 0.8,
        '.s'   => 0.75,
    );
    return $score_for{$suf} || 0;
}

=head3 C<make_iterator>

  my $iterator = $class->make_iterator( $source );

Returns a new L<TAP::Parser::Iterator::Process> for the source.
C<< $source->raw >> must be either a file name or a scalar reference to the
file name.

The MyTAP tests are run by executing C<mysql>, the MySQL command-line utility.
A number of arguments are passed to it, many of which you can affect by
setting up the source source configuration. The configuration must be a hash
reference, and supports the following keys:

=over

=item C<mysql>

The path to the C<mysql> command. Defaults to simply "mysql", which should work
well enough if it's in your path.

=item C<database>

The database to which to connect to run the tests. Defaults to the system
username.

=item C<user>

The MySQL user to use to connect to MySQL. If not specified, no user will be
used, in which case C<mysql> will fall back on the system username.

=item C<password>

The password to use to connect to MySQL. If not specified, no password will be
used.

=item C<host>

Specifies the host name of the machine to which to connect to the MySQL
server. Defaults to the local host.

=item C<port>

Specifies the TCP port or the local Unix-domain socket file extension on which
the server is listening for connections. Defaults to the port specified at the
time C<mysql> was compiled, usually 3306.

=back

=cut

sub make_iterator {
    my ( $class, $source ) = @_;
    my $config = $source->config_for('MyTAP');

    my @command = ( $config->{mysql} || 'mysql' );
    push @command, qw(
      --disable-pager
      --batch
      --raw
      --skip-column-names
      --unbuffered
    );

    for (qw(user host port database)) {
        push @command, "--$_" => $config->{$_} if defined $config->{$_};
    }

    # Special-case --password, which requires = before the value. O_o
    if (my $pw = $config->{password}) {
        push @command, "--password=$pw";
    }

    my $fn = ref $source->raw ? ${ $source->raw } : $source->raw;
    $class->_croak(
        'No such file or directory: ' . ( defined $fn ? $fn : '' ) )
      unless $fn && -e $fn;

    push @command, '--execute', "source $fn";

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

=item * L<TAP::Parser::SourceHandler::pgTAP>

=item * L<TAP::Parser::SourceHandler::File>

=item * L<TAP::Parser::SourceHandler::Handle>

=item * L<TAP::Parser::SourceHandler::RawTAP>

=back

=head1 Support

This module is managed in an open
L<GitHub repository|https://github.com/theory/tap-parser-sourcehandler-mytap/>.
Feel free to fork and contribute, or to clone
C<git://github.com/theory/tap-parser-sourcehandler-mytap.git> and send
patches!

Found a bug? Please
L<post|https://github.com/theory/tap-parser-sourcehandler-mytap/issues> or
L<email|mailto:bug-tap-parser-sourcehandler-mytap@rt.cpan.org> a report!

=head1 Author

David E. Wheeler <dwheeler@cpan.org>

=head1 Copyright and License

Copyright (c) 2010-2016 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
