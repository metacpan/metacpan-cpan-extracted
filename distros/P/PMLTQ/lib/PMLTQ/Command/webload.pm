package PMLTQ::Command::webload;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::webload::VERSION = '1.3.1';
# ABSTRACT: Register treebank in web interface

use PMLTQ::Base 'PMLTQ::Command';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my $ua = $self->ua;
  $self->login($ua);
  
  my $json = JSON->new;
  my $treebank = $self->get_treebank($ua);
  my $treebank_param = $self->create_treebank_param();
  if($treebank) { # EDITING EXISTING TREEBANK
    $self->request_treebank($treebank,$ua,'PUT',{%$treebank_param,id => $treebank->{id}}); 
  } else { # CREATING NEW TREEBANK
    my $url = URI::WithBase->new('/',$self->config->{web_api}->{url});
    $url->path_segments('api', 'admin', 'treebanks');
    my $data;
    (undef,$data) = $self->request($ua, 'POST', $url->abs->as_string, $treebank_param); 
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Command::webload - Register treebank in web interface

=head1 VERSION

version 1.3.1

=head1 SYNOPSIS

  pmltq webload <treebank_config>

=head1 DESCRIPTION

Register treebank in web interface.

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
