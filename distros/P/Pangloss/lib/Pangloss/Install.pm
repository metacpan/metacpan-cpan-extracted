package Pangloss::Install;

# exists only for the namespace so the front page doesn't get clobbered on
# search.cpan.org...

1;

=pod

=head1 NAME

Pangloss::Install - how to install Pangloss

=head1 SYNOPSIS

  % perl Build.PL
  % ./Build test
  % ./Build install

  # follow on-screen instructions

=head1 INSTALLATION

In general, the following should work:

	% perl Build.PL
	% ./Build test
	% ./Build install

If you want to install Pangloss somewhere other than /usr/local/pangloss, add
a 'install_base=/path/to/install' to the first line, for example:

	% perl Build.PL install_base=~/pangloss

Follow the on-screen instructions after installing Pangloss.

=head1 CONFIGURATION

You can use the Pangloss admin tool found in the 'bin' directory to do most of
the initial setup:

	% $PG_HOME/bin/pg_admin --help

First off, you must setup a Pixie store for Pangloss to use (see the Pixie
documentation for stores types available and for more details on Pixie).  If
you are setting up a DBI store, you can do it with the Pangloss admin tool,
for example:

	pangloss> create store, 'dbi:mysql:dbname=test'
	pangloss> connect 'dbi:mysql:dbname=test'

Next, you need an admin user:

	pangloss> create admin

Once that's done you're ready to load the pangloss webserver (you can use the
website to create other users and such).

Most Pangloss configuration can be done with environment variables.  Read the
L<Pangloss::Config> documentation to see what parameters are available:

	% man Pangloss::Config
		- or -
	% perldoc Pangloss::Config

Pangloss requires a 'controller' configuration file, which can be tailored
to suit your needs.  The defaults live in the C<$PG_HOME/conf> directory, and
should be sensible enough for most installations.

=head1 STANDALONE TEST SERVER

There is a standalone server available in the 'bin' directory:

	% $PG_HOME/bin/pg_test_server --help

This is useful as a smoke test to make sure you have set all the right
environment variables and that there are no problems.  It's also handy if you
don't have Apache or mod_perl installed but would like to try out Pangloss
anyway.

=head1 APACHE CONFIGURATION

Pangloss has been built to run under Apache/mod_perl.  A sample configuration
file is included:

	$PG_HOME/conf/sample-httpd.conf

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Config>

=cut
