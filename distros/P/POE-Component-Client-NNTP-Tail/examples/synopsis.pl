#!/usr/bin/env perl
use strict;
use warnings;

#--------------------------------------------------------------------------#
# synopsis follows
#--------------------------------------------------------------------------#

  use POE qw( Component::Client::NNTP::Tail );
  use Email::Simple;

  POE::Component::Client::NNTP::Tail->spawn(
    NNTPServer  => 'nntp.perl.org',
    Group       => 'perl.cpan.testers',
  );

  POE::Session->create(
    package_states => [
      main => [qw(_start new_header got_article)]
    ],
  );

  POE::Kernel->run;

  # register for NNTP tail events
  sub _start {
    $_[KERNEL]->post( 'perl.cpan.testers' => 'register' );
    return;
  }

  # get articles with subject 'FAIL' as 'got_article' events
  sub new_header {
    my ($article_id, $lines) = @_[ARG0, ARG1];
    my $article = Email::Simple->new( join("\r\n", @$lines) );
    if ( $article->header('Subject') =~ /^FAIL/ ) {
      $_[KERNEL]->post( 
        'perl.cpan.testers' => 'get_article' => $article_id 
      );
    }
    return;
  }

  # find and print perl version components to terminal
  sub got_article {
    my ($article_id, $lines) = @_[ARG0, ARG1];
    for my $text ( reverse @$lines ) {
      if ( $text =~ /^Summary of my perl5 \(([^)]+)\)/ ) {
        print "$1\n";
        last;
      }
    }
    return;
  }

