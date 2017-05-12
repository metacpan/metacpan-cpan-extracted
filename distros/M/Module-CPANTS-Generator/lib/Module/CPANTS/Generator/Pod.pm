package Module::CPANTS::Generator::Pod;
use strict;
use Clone qw(clone);
use File::Find::Rule;
use Module::CPANTS::Generator;
use Pod::Simple::Checker;
use Pod::Simple::TextContent;
use base 'Module::CPANTS::Generator';

sub generate {
  my $self = shift;

  my $cpants = $self->grab_cpants;

  foreach my $dist (sort grep { -d } <*>) {
    next if $dist =~ /^\./;

   if (not exists $cpants->{$dist}->{lines}) {
      print "* $dist\n";
      my ($lines, $pod, $with_comments, $pod_errors) = (0, 0, 0, 0);
      for my $file (find( file => name => '*.{pod,pm}', in => $dist )) {

	# Count the number of POD errors
	my $parser = Pod::Simple::Checker->new;
	my $errata;
	$parser->output_string(\$errata);
	$parser->parse_file($file);
        my $errors = () = $errata =~ /Around line /g;
	$pod_errors += $errors;

	# Count the number of lines of POD
	$parser = Pod::Simple::TextContent->new;
	my $podtext;
	$parser->output_string(\$podtext);
	$parser->parse_file($file);
        $pod += (split /\n/, $podtext);

	# Count comments & total lines of code
	open my $fh, "$file" or next;
	# worlds stupidest pod parser - incorrect but quick
	my $inpod = 0;
	while (<$fh>) {
          s/\r$//g;
	  /^=/     and $inpod = 1;
	  /^=cut$/ and $inpod = 0;
#	  $pod++           if $inpod;
	  $with_comments++ if (not $inpod)
	    && /#/ && (not /(\b([ysmq]|q[qrxw]|tr))#/);
          $lines++;
	}
      }
      $cpants->{$dist}{lines} = {
        total         => $lines,
        with_comments => $with_comments,
        pod           => $pod,
        pod_errors    => $pod_errors,
        nonpod        => $lines - $pod,
      };
      print "  $pod_errors pod errors\n" if $pod_errors;
    }
    $cpants->{cpants}->{$dist}->{lines} = clone($cpants->{$dist}->{lines});
  }
  $self->save_cpants($cpants);
}

1;

