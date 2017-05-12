package Test::DBIC::Schema::Connector;
our $AUTHORITY = 'cpan:GETTY';
$Test::DBIC::Schema::Connector::VERSION = '0.003';
# ABSTRACT: Generate an instance of a DBIx::Class::Schema as test database
use Exporter::Lite;

@EXPORT = qw( test_dbic_schema_connect );

use strict;
use warnings;
use File::Temp qw/tempdir/;

use Data::Dumper;

sub test_dbic_schema_connect {
	my ( $schema_package, $options ) = @_;
	$options = {} if !$options;
	my $env_prefix;
	$env_prefix = $options->{env_prefix} if defined $options->{env_prefix};
	if (!$env_prefix) {
		$env_prefix = uc($schema_package);
		$env_prefix =~ s/::/_/g;
	}
	my $env_user = defined $options->{env_user} ? $options->{env_user} : $env_prefix.'_USER';
	my $env_pass = defined $options->{env_pass} ? $options->{env_pass} : $env_prefix.'_PASS';
	my $env_dsn = defined $options->{env_dsn} ? $options->{env_dsn} : $env_prefix.'_DSN';
	my $user = defined $options->{user} ? $options->{user} : defined $ENV{$env_user} ? $ENV{$env_user} : '';
	my $pass = defined $options->{pass} ? $options->{pass} : defined $ENV{$env_pass} ? $ENV{$env_pass} : '';
	my $dsn = defined $options->{dsn} ? $options->{dsn} : defined $ENV{$env_dsn} ? $ENV{$env_dsn} : undef;
	my $tmpdir;
	if (!$dsn) {
		$tmpdir = tempdir;
		$dsn = 'dbi:SQLite:dbname='.$tmpdir.'/database.sqlite';
	}

	my $schema = $schema_package->connect($dsn,$user,$pass);
	$schema->{tmpdir_storage_for_test_dbic_schema_connector} = $tmpdir if $tmpdir;
	$schema->deploy if !$options->{no_deploy};
	
	my ( $file ) = $dsn =~ m/(\/tmp\/\w+\/.+)$/g;
	
	return $schema;
}

1;

__END__

=pod

=head1 NAME

Test::DBIC::Schema::Connector - Generate an instance of a DBIx::Class::Schema as test database

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Test::DBIC::Schema::Connector;

  my $schema = test_dbic_schema_connect('MySchema');
  
  # MYSCHEMA_DSN will be used as DSN if given
  # MYSCHEMA_USER will be used as username if given
  # MYSCHEMA_PASS will be used as password if given

  my $schema = test_dbic_schema_connect('MySchema',{
    env_prefix => 'I_LOVE',
    user => 'peter',
    env_pass => 'I_HATE_PASS',
  });
  
  # I_LOVE_DSN will be used as DSN if given
  # The user is fixed to be peter
  # I_HATE_PASS will be used as password if given

=head1 DESCRIPTION

This distribution connects a schema to a test database, given by ENV variables, or if not given, by deploying a SQLite version of the database.

=head1 FUNCTIONS

=head2 test_dbic_schema_connect($schema_package,\%options)

This function returns the connectd schema, or throws an error if not possible. The following keys for the options are possible:

=head3 env_prefix

Prefix for the ENV variables used, by default it will UPPERCASE the given schema name and replace B<::> with B<_>.

=head3 user

Setting the user to the given value, ignoring the ENV variable.

=head3 pass

Setting the password to the given value, ignoring the ENV variable.

=head3 dsn

Setting the dsn to the given value, ignoring the ENV variable.

=head3 env_user

ENV variable used for the username of the connection. Defaults to I<env_prefix> + B<_USER>.

=head3 env_pass

ENV variable used for the password of the connection. Defaults to I<env_prefix> + B<_PASS>.

=head3 env_dsn

ENV variable used for the dsn of the connection. Defaults to I<env_prefix> + B<_DSN>.

=head3 no_deploy

Do not try to deploy the database.

=head3 autoupgrade B<TODO>

Do not deploy the database, instead try to autoupgrade the existing one. If there is no content, it will get generated in this process.

=head1 SUPPORT

IRC

  Join #dbix-class on irc.perl.org and ask for Getty.

Repository

  http://github.com/Getty/p5-test-dbic-schema-connector
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-test-dbic-schema-connector/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<http://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<http://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Raudssus Social Software.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
