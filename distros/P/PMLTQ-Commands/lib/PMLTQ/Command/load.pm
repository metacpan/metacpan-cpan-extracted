package PMLTQ::Command::load;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::load::VERSION = '2.0.3';
# ABSTRACT: Load treebank to database

use PMLTQ::Base 'PMLTQ::Command';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;

  my $config     = $self->config;
  my $output_dir = $self->config->{output_dir};

  unless ( -d $output_dir ) {
    die <<"MSG";
Output directory $output_dir does not exist.

Maybe you need to run 'pmltq convert' first.

MSG
  }

  my $dbh;
  eval { $dbh = $self->db };
  if ( $@ ) {
    die <<"MSG";
$@
Maybe you need to run 'pmltq initdb' first.

MSG
  }

  for my $layer ( @{ $config->{layers} } ) {
    my $listfile = File::Spec->catfile( $output_dir, "$layer->{name}__init.list" );
    open my $fh, '<', $listfile or die "Can't open $listfile: $!";
    for my $file (<$fh>) {
      $file =~ s/\n$//;
      next unless $file;
      $self->run_sql_from_file( $file, $output_dir, $dbh );
    }
    ###$dbh->do($sql);
  }
  $dbh->disconnect;
}

=encoding utf8

=head1 SYNOPSIS

  pmltq load <treebank_config> <sql_dir>

=head1 DESCRIPTION

Load treebank to database

=head1 OPTIONS

=head1 PARAMS

=over 5

=item B<treebank_config>

Path to configuration file. If a treebank_config is --, config is readed from STDIN.

Path to input directory.

=back

=cut

1;
