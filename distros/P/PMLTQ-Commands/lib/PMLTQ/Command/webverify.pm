package PMLTQ::Command::webverify;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::webverify::VERSION = '2.0.2';
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

=cut

1;
