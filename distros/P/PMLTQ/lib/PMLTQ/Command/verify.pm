package PMLTQ::Command::verify;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::verify::VERSION = '1.3.1';
# ABSTRACT: Check if database exists and that it contains some data

use PMLTQ::Base 'PMLTQ::Command';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;

  my $db_name = $self->config->{db}->{name};

  my $dbh;
  eval { $dbh = $self->db };

  die "Database " . $db_name . " does not exist!\n" if $@;
  print "Database " . $db_name . " exists\n";

  my @tables = map { s/^public\.//; $_ } grep {m/^public\./} $dbh->tables();
  print "Database contains ", scalar @tables, " tables\n";
  for my $table (@tables) {
    my $sth = $dbh->prepare("SELECT * FROM $table");
    $sth->execute;
    print "Table $table contains " . $sth->rows . " rows\n";
  }
  $dbh->disconnect;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Command::verify - Check if database exists and that it contains some data

=head1 VERSION

version 1.3.1

=head1 SYNOPSIS

  pmltq verify <treebank_config>

=head1 DESCRIPTION

Check if database exists and that it contains some data.

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
