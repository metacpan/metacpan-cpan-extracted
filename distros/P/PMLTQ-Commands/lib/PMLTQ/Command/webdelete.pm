package PMLTQ::Command::webdelete;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::webdelete::VERSION = '2.0.2';
# ABSTRACT: Remove treebank from web interface

use PMLTQ::Base 'PMLTQ::Command';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my $ua = $self->ua;
  $self->login($ua);
  my $json = JSON->new;
  my $treebank = $self->get_treebank($ua);
  if($treebank) {
    $self->request_treebank($treebank,$ua,'DELETE');
  } else {
    print STDERR "Treebank '".$self->config->{title}."' is not at ".$self->config->{web_api}->{url}.".\n"
  }
}

=head1 SYNOPSIS

  pmltq webdelete <treebank_config>

=head1 DESCRIPTION

Remove treebank from web interface.

=head1 OPTIONS

=head1 PARAMS

=over 5

=item B<treebank_config>

Path to configuration file. If a treebank_config is --, config is readed from STDIN.

=back

=cut

1;
