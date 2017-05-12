package Parse::WWWAuthenticate;

# ABSTRACT: Parse the WWW-Authenticate HTTP header

use strict;
use warnings;

use base 'Exporter';

use Carp qw(croak);
use HTTP::Headers::Util qw(_split_header_words);

our $VERSION = 0.03;

our @EXPORT_OK = qw(parse_wwwa);

sub parse_wwwa {
   my ($string) = @_;

   my @parts = split_header_words( $string);

   my $challenge;
   my @challenges;

   PART:
   for my $part ( @parts ) {
      my ($maybe_challenge, $challenge_check) = @{$part};

      if ( !defined $challenge_check ) {
         $challenge = ucfirst lc $maybe_challenge;
         push @challenges, { name => $challenge, params => {} };
      }

      my ($key, $value) = ($part->[-2], $part->[-1]);
      if ( !defined $value ) {
         next PART;
      }

      my $lc_key = lc $key;
      if ( $challenge eq 'Basic' &&
         $lc_key eq 'realm' &&
         exists $challenges[-1]->{params}->{$lc_key}
      ) {
         croak 'only one realm is allowed';
      }

      $challenges[-1]->{params}->{lc $key} = $value;
   }

   for my $challenge ( @challenges ) {
       if ( $challenge->{name} eq 'Basic' && !exists $challenge->{params}->{realm} ) {
          croak 'realm parameter is missing';
       }
   }

   return @challenges;
}

sub split_header_words {
    my @res = &_split_header_words;
    for my $arr (@res) {
      for (my $i = @$arr - 2; $i >= 0; $i -= 2) {
          $arr->[$i] = $arr->[$i];
      }
    }
    return @res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::WWWAuthenticate - Parse the WWW-Authenticate HTTP header

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Parse::WWWAuthenticate qw(parse_wwwa);
  
  my $header = 'Basic realm="test"';
  my @challenges = parse_wwwa( $header );
  for my $challenge ( @challenges ) {
      print "Server accepts: " . $challenge->{name};
  }

kinda more real life:

  use LWP::UserAgent;
  use Parse::WWWAuthenticate qw(parse_wwwa);
  
  my $ua       = LWP::UserAgent->new;
  my $response = $ua->get('http://some.domain.example');
  my $header   = $response->header('WWW-Authenticate');
  
  my @challenges = parse_wwwa( $header );
  for my $challenge ( @challenges ) {
      print "Try to use $challenge->{name}...\n";
  }

=head1 FUNCTIONS

=head2 parse_wwwa

parses the content of the I<WWW-Authenticate> header and returns a hash of all the challenges and their data.

  my $header = 'Basic realm="test"';
  my @challenges = parse_wwwa( $header );
  for my $challenge ( @challenges ) {
      print "Try to use $challenge->{name}...\n";
  }

=head2 split_header_words

=head1 ACKNOWLEDGEMENTS

The testcases were generated with the httpauth.xml file from L<https://greenbyte.de/tech/tc/httpauth>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
