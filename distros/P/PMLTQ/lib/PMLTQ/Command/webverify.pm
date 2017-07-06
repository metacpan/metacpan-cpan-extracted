package PMLTQ::Command::webverify;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::webverify::VERSION = '1.4.0';
# ABSTRACT: Check if treebank is setted in web interface

use PMLTQ::Base 'PMLTQ::Command';
use File::Path qw( make_path );

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my $ua = $self->ua;
  $self->login($ua);

  my $json = JSON->new;
  my $treebank = $self->get_treebank($ua);
  if($treebank) {
    print $json->pretty->encode($treebank);
    if (my $test_query = $self->config->{test_query}) {
      if($test_query->{result_dir} && not(-d $test_query->{result_dir})) {
        make_path($test_query->{result_dir}) or die "Unable to create directory ".$test_query->{result_dir}."\n" ;
      }
      my $i=0;
      for my $query (@{$test_query->{queries} // []}) {
        my $text = $query->{query};
        my $filename = File::Spec->catfile($test_query->{result_dir} // '.',  $query->{filename} // $i);
        unless($text) {
          print STDERR "Error in config file: Empty query\n";
          next;
        }
        my $result = $self->evaluate_query($treebank->{id},$text);
        if($result =~ m!</svg>!) {
          print STDERR "There is no text field in SVG result $filename ('$text') => check print server log (wrong styles?)\n" unless $result =~ m!</text>!;
          print STDERR "There is no node field in SVG result $filename ('$text') => check print server log (wrong file path?)\n" unless $result =~ m!<ellipse!;
        }

        open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
        print $fh $result;
        close $fh;
        $i++;
      }
    }
  } else {
    print STDERR "Unknown treebank\n";
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Command::webverify - Check if treebank is setted in web interface

=head1 VERSION

version 1.4.0

=head1 SYNOPSIS

  pmltq webverify <treebank_config>

=head1 DESCRIPTION

Check if treebank is setted in web interface.

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
