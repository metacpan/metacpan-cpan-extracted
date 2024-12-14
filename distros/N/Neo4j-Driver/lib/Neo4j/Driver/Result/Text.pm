use v5.12;
use warnings;

package Neo4j::Driver::Result::Text 1.02;
# ABSTRACT: Fallback handler for result errors


# This package is not part of the public Neo4j::Driver API.


use parent 'Neo4j::Driver::Result';

our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);

use Neo4j::Error;


#our $ACCEPT_HEADER = "text/*; q=0.1";


sub new {
	# uncoverable pod (private method)
	my ($class, $params) = @_;
	
	my $header = $params->{http_header};
	my $error = 'Neo4j::Error';
	
	if (! $header->{success} && ! $header->{status}) {
		# Response generated internally by the networking module
		$error = $error->append_new( Network => sprintf("HTTP error: %s", $params->{http_agent}->http_reason) );
	}
	elsif (! $header->{success}) {
		$error = $error->append_new( Network => {
			code => $header->{status},
			as_string => sprintf("HTTP error: %s %s on %s to %s", $header->{status}, $params->{http_agent}->http_reason, $params->{http_method}, $params->{http_path}),
		});
	}
	
	my ($content_type) = $header->{content_type} =~ m/^\s*([^\s;]*)/;
	if (lc $content_type eq 'text/plain') {
		$error = $error->append_new( Internal => {
			as_string => $params->{http_agent}->fetch_all,
		});
	}
	elsif ($content_type =~ m{^text/html\b|^application/xhtml\b}i) {
		my $raw = $params->{http_agent}->fetch_all;
		my ($title) = $raw =~ m{<title>([^<]*)</title>}i;
		$error = $error->append_new( Internal => {
			as_string => sprintf("Received HTML content%s from server (Is this a Neo4j server?)", $title ? " \"$title\"" : ""),
			raw => $raw,
		});
	}
	elsif ($content_type || $header->{status}) {
		$error = $error->append_new( Internal => {
			as_string => sprintf("Received %s content from database server; skipping result parsing", $content_type || "empty"),
			raw => $params->{http_agent}->fetch_all,
		});
	}
	
	return bless { _error => $error }, $class;
}


sub _info { shift }


sub _results { () }  # no actual results provided here


# sub _accept_header { () }
# 
# 
# sub _acceptable {
# 	my ($class, $content_type) = @_;
# 	
# 	return $_[1] =~ m|^text/|i;
# }


1;
