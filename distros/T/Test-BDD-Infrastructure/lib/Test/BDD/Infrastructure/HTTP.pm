package Test::BDD::Infrastructure::HTTP;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for http based checks
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE convert_interval
	lookup_config );

use LWP::UserAgent;
use URI;
use HTTP::Request;


Given qr/the http URL (.*)/, sub {
	S->{'uri'} = URI->new( lookup_config($1) );
	S->{'request'} = HTTP::Request->new(
		method => 'GET',
	);
	S->{'agent'} = LWP::UserAgent->new;
};

Given qr/the http URL path is (.*)/, sub {
	S->{'uri'}->path( lookup_config($1) );
};

Given qr/the http user agent is (\S+)/, sub {
	S->{'agent'}->agent( $1 );
};
Given qr/the http proxy for (\S+) is (.*)/, sub {
	S->{'agent'}->proxy( $1 => $2 );
};
Given qr/the http ssl option (\S+) is (.*)/, sub {
	S->{'agent'}->ssl_opts( $1 => $2 );
};
Given qr/the http request method is (\S+)/, sub {
	S->{'request'}->method( $1 );
};

Given qr/the http request header (\S+) is set to (.*)/, sub {
	S->{'request'}->header( $1 => $2 );
};

Given qr/the http timeout is set to (\d+) seconds/, sub {
	S->{'agent'}->timeout( $1 );
};

When qr/the http request is (?:sent|executed)/, sub {
	S->{'request'}->uri( S->{'uri'}->as_string );
	my $response = S->{'agent'}->request( S->{'request'} );
	S->{'response'} = $response;
};


Then qr/the http response must be (?:a )?(successfull|error|failure|redirect|info(?:rmational)?)/, sub {
	my $check = $1;
	diag('response code is '.S->{'response'}->status_line );
	if( $check eq 'successfull' ) {
		ok( S->{'response'}->is_success , 'successfull http response');
	} elsif( $check =~ /(error|failure)/ ) {
		ok( S->{'response'}->is_error , 'error http response');
	} elsif( $check eq 'redirect' ) {
		ok( S->{'response'}->is_redirect , 'redirect http response');
	} elsif( $check =~ /^info/ ) {
		ok( S->{'response'}->is_info , 'info http response');
	}
};

Then qr/the http response status code must be (\d+)/, sub {
	my $code = $1;
	cmp_ok( S->{'response'}->code, '==', $code, "the status code must be $code");
};
Then qr/the http response status message must be like (.*)/, sub {
	my $regex = $1;
	like( S->{'response'}->message, qr/$regex/, "the status message must be like $regex");
};
Then qr/the http response header (\S+) must be like (.*)/, sub {
	my $header = $1;
	my $regex = $2;
	my $value = S->{'response'}->header($header);
	if( ! defined $value ) {
		fail("header $header is not set in response");
		return;
	}
	like( $value, qr/$regex/, "the header $header must be like $regex");
};

Then qr/the http response content must be unlike (.*)/, sub {
	my $regex = $1;
	unlike( S->{'response'}->content, qr/$regex/, "the content must be unlike $regex");
};
Then qr/the http response content must be like (.*)/, sub {
	my $regex = $1;
	like( S->{'response'}->content, qr/$regex/, "the content must be like $regex");
};

Then qr/the http response content size must be $CMP_OPERATOR_RE (\d+) (\S+)/, sub {
	my $op = convert_cmp_operator( $1 );
	my $size = convert_unit( $2, $3 );
	cmp_ok( length S->{'response'}->content, $op, $size, "content must be $op $size" );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::HTTP - cucumber step definitions for http based checks

=head1 VERSION

version 1.005

=head1 Synopsis

  Scenario: A URL must be reachable
    Given the http URL https://markusbenning.de/
    When the http request is sent
    Then the http response must be a redirect
    And the http response status code must be 302
    And the http response status message must be like ^Found
    And the http response header Location must be like ^https://markusbenning.de/blog/
    And the http response header Content-Type must be like text/html
    And the http response content must be like The document has moved
    And the http response content size must be at least 200 byte

=head1 Step definitions

The test must start with

  Given the URL <url>

followed by additional parameters.

Then the request is sent with:

  When the http request is sent

After the request has been sent the response could be examined with
response checks:

  Then the http response ...

=head2 Additional request parameters

  Given the http user agent is <agentstring>
  Given the http proxy for <protocol> is <url>
  Given the http ssl option <option> is <value>
  Given the http request method is <method>
  Given the http request header <header> is set to <value>
  Given the http timeout is set to <timeout> seconds

=head2 Response checks

  Then the http response must be (a )<successfull|error|failure|redirect|info>
  Then the http response status code must be <code>
  Then the http response status message must be like <regex>
  Then the http response header <header> must be like <regex>
  Then the http response content must be unlike <regex>
  Then the http response content must be like <regex>
  Then the http response content size must be <compare> <count> <unit>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
