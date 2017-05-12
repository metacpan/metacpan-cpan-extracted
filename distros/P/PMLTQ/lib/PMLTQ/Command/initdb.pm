package PMLTQ::Command::initdb;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::initdb::VERSION = '1.3.1';
# ABSTRACT: Initialize empty database

use PMLTQ::Base 'PMLTQ::Command';
use PMLTQ;

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;

  my $config = $self->config;
  my $dbh    = $self->sys_db;

  $dbh->do("CREATE DATABASE \"$config->{db}->{name}\";") or die $dbh->errstr;
  $dbh->disconnect;

  $dbh = $self->db;
  $self->run_sql_from_file( 'init.sql', File::Spec->catfile( PMLTQ->shared_dir, 'sql' ), $dbh );
  $dbh->disconnect;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Command::initdb - Initialize empty database

=head1 VERSION

version 1.3.1

=head1 SYNOPSIS

  pmltq initdb <treebank_config>

=head1 DESCRIPTION

Initialize empty database.

=head1 OPTIONS

=head1 PARAMS

=over 5

=item B<treebank_config>

Path to configuration file. If a treebank_config is --, config is readed from STDIN.

=back

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
