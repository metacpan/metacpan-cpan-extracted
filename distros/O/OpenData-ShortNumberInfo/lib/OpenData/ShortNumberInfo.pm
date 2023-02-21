package OpenData::ShortNumberInfo;
# ABSTRACT: Perl interface to OpenData ShortNumberInfo web service


use v5.37.9;
use experimental qw( class builtin try );

class OpenData::ShortNumberInfo {
  use HTTP::Tiny;
  use URI;
  use JSON::PP;

  # @format:off
  field $number :
  param //= 103;
  # @format:on

  method number ( ) {
    return $number;
  }


  method name ( ) {
    # Construct API URL
    my $uri = URI -> new( 'https://api.opendata.az' );
    $uri -> path_segments(
      'v1' ,              # version
      'json' ,            # format
      'nrytn' ,           # organization
      'ShortNumberInfo' , # service
      $number             # parameter
    );

    # Issue HTTP request to get the web page
    my $http = HTTP::Tiny -> new;
    my $response = $http -> get( $uri ); # RV: HR

    # Convert JSON from HTTP response into Perl hash
    my $json = JSON::PP -> new;
    my $content = $json -> decode( $response -> {content} );

    unless ( defined $content -> {StatusMessage} ) {
      return $content -> {Response} -> [0] -> {Name};
    }
    else {
      STDERR -> say( $content -> {StatusMessage} );
      exit 2;

    }
  }


}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenData::ShortNumberInfo - Perl interface to OpenData ShortNumberInfo web service

=head1 VERSION

version 0.230470

=head1 SYNOPSIS

  use OpenData::ShortNumberInfo;

  my $shortnumberinfo =
	  OpenData::ShortNumberInfo -> new( number => 101 );

  say $shortnumberinfo -> name;

=head1 ATTRIBUTES

=head2 number

Returns the three digit phone number the object was constructed with

=head1 METHODS

=head2 name

Takes a 3 digit phone number, and returns the organization name it belongs to.

Prints a message to standard error stream exiting with the status code of 2 if there's no organization found for the number specified.

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
