package PMLTQ::Command::delete;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::delete::VERSION = '2.0.3';
# ABSTRACT: Deletes the treebank from database

use PMLTQ::Base 'PMLTQ::Command';

has usage => sub { shift->extract_usage };

sub run {
  my $self   = shift;
  my $config = $self->config;

  my $dbh = $self->sys_db;
  $dbh->do("SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$config->{db}->{name}' AND pid <> pg_backend_pid();"); # disconnect all connections to deleted database
  $dbh->do("DROP DATABASE \"$config->{db}->{name}\";");
  my $error = $dbh->errstr;
  $dbh->disconnect;
  die $error if $error;
}

=head1 SYNOPSIS

  pmltq delete <treebank_config>

=head1 DESCRIPTION

Delete the treebank from database.

=head1 OPTIONS

=head1 PARAMS

=over 5

=item B<treebank_config>

Path to configuration file. If a treebank_config is --, config is readed from STDIN.

=back

=cut

1;
