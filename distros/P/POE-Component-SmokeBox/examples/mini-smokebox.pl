  use strict;
  use warnings;
  use POE;
  use POE::Component::SmokeBox;
  use POE::Component::SmokeBox::Smoker;
  use POE::Component::SmokeBox::Job;
  use POE::Component::SmokeBox::Recent;
  use Getopt::Long;

  $|=1;

  my ($perl, $jobs, $recenturl);

  GetOptions( 'perl=s' => \$perl, 'jobs=s' => \$jobs, 'recenturl' => \$recenturl );

  my @pending;
  if ( $jobs ) {
    open my $fh, "<$jobs" or die "$jobs: $!\n";
    while (<$fh>) {
          chomp;
          push @pending, $_;
    }
    close($fh);
  }

  my $smokebox = POE::Component::SmokeBox->spawn();

  POE::Session->create(
        package_states => [
           'main' => [ qw(_start _stop _results _recent) ],
        ],
        heap => { perl => $perl, pending => \@pending },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $smoker = POE::Component::SmokeBox::Smoker->new(
	perl => $perl,
    );

    $smokebox->add_smoker( $smoker );

    if ( @{ $heap->{pending} } ) {
      $smokebox->submit( event => '_results',
			 job => POE::Component::SmokeBox::Job->new( command => 'smoke', module => $_ ) )
        			for @{ $heap->{pending} };
    }
    else {
      POE::Component::SmokeBox::Recent->recent(
          url => $recenturl || 'http://www.cpan.org/',
          event => '_recent',
      );
    }
    undef;
  }

  sub _stop {
    $smokebox->shutdown();
    undef;
  }

  sub _results {
    my $results = $_[ARG0];
    print $_, "\n" for map { @{ $_->{log} } } $results->{result}->results();
    undef;
  }

  sub _recent {
    my ($kernel,$heap,$job) = @_[KERNEL,HEAP,ARG0];
    die $job->{error}, "\n" if $job->{error};
      $smokebox->submit( event => '_results',
			 job => POE::Component::SmokeBox::Job->new( command => 'smoke', module => $_ ) )
        			for @{ $job->{recent} };
    undef;
  }
