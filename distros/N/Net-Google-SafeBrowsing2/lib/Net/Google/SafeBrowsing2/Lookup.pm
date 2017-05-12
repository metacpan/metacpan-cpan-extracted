package Net::Google::SafeBrowsing2::Lookup;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use URI;
use Text::Trim;

our $VERSION = '0.2';

=head1 NAME

Net::Google::SafeBrowsing2::Lookup - Perl extension for the Google Safe Browsing v2 Lookup API.

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing2::Lookup;

  my $gsb = Net::Google::SafeBrowsing2::Lookup->new(
	key 	=> "my key", 
  );

  my %match = $gsb->lookup(url => 'http://www.gumblar.cn/');
  
  if ($match{'http://www.gumblar.cn/'} eq 'malware') {
	print "http://www.gumblar.cn/ is flagged as a dangerous site\n";
  }

  my %matches = $gsb->lookup(urls => ['http://www.gumblar.cn/', 'http://flahupdate.co.cc']);
  foreach my $url (keys %matches) {
    print $url, " is ", $matches{$url}, "\n";
  }

=head1 DESCRIPTION

Net::Google::SafeBrowsing2::Lookup implements the Google Safe Browsing v2 Lookup API. See the API documentation at L<http://code.google.com/apis/safebrowsing/lookup_guide.html>.

If you need to check more than 10,000 URLs a day, you need to use L<Net::Google::SafeBrowsing2>.

The source code is available on github at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing2>.

=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing2::Lookup object

  my $gsb = Net::Google::SafeBrowsing2::Lookup->new(
	key 	=> "my key", 
	debug	=> 0,
  );

Arguments

=over 4

=item key

Required. Your Google Safe Browsing API key

=item debug

Optional. Set to 1 to enable debugging. 0 (disabled) by default.

The debug output maybe quite large and can slow down significantly the update and lookup functions.

=item errors

Optional. Set to 1 to show errors to STDOUT. 0 (disabled by default).

=item version

Optional. Google Safe Browsing version. 3.0 by default

=item delay

Optional. Delay, in seconds, between 2 requests to the Google server. See the C<lookup> function for more details. 0 (no delay) by default

=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		key			=> '',
		version		=> '3.0',
		debug		=> 0,
		delay		=> 0,
# 		errors		=> 0,
# 		last_error	=> '',

		%args,
	};

	bless $self, $class or croak "Can't bless $class: $!";
    return $self;
}


=head1 PUBLIC FUNCTIONS

=over 4

=back

=head2 lookup()

Lookup a list URLs against the Google Safe Browsing v2 lists.

  my %match = $gsb->lookup(url => 'http://www.gumblar.cn');

Returns a hash C<url> => C<Google match>. The possible list of values for C<Google match> are: "ok" (no match), "malware", "phishing", "malware,phishing" (match both lists) and "error".

Arguments

=over 4

=item url

Optional. Single URL to lookup.

=item urls

Optional. List of URLs to lookup.

The Lookup API allows only 10,000 URL checks a day. if you need more, use the L<Net::Google::SafeBrowsing2> library.

Each requests must contain 500 URLs at most. The lookup() method will split the list of URLS in blocks of 500 URLs if needed.

=item delay

Optional. If more than 500 URLs are checked, wait C<delay> seconds between consecutive requests to avoid rate limiting by Google.

=back

=cut

sub lookup {
	my ($self, %args) 	= @_;
	my $url				= $args{url}		|| '';
	my @inputs			= @{ $args{urls} 	|| []};
	my $delay			= $args{delay}		|| $self->{delay}	|| 0;


	if ($url ne '') {
		push(@inputs, $url);
	}

	# Max is 500 URLs per request
	my %results = ();

	my $count = 0;
	while (scalar @inputs > 0) {
		my @urls = splice(@inputs, 0, 500);

		my $body = scalar(@urls);
		foreach my $input (@urls) {
			my $canonical = $self->canonical_uri($input);
			$body .= "\n$canonical";
			$self->debug("$input => $canonical\n");
		}
		$self->debug("BODY:\n$body\n\n");
	
		my $url = "https://sb-ssl.google.com/safebrowsing/api/lookup?client=perl&apikey=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};
		sleep $delay if ($delay > 0 && $count > 0);
		my $res = $self->ua->post($url, Content =>  $body);
	
		if ($res->code == 400) {
			$self->error("Invalid request");
			%results = ( %results, $self->errors(@urls) );
		}
		elsif ($res->code == 401) {
			$self->error("Invalid API key");
			%results = ( %results, $self->errors(@urls) );
		}
		elsif ($res->code == 503) {
			$self->error("Server error, client may have sent too many requests");
			%results = ( %results, $self->errors(@urls) );
		}
		else {
			%results = ( %results, $self->parse(response => $res, urls => [@urls]) );
		}

		$count++;
	}

	return %results;
}


sub parse {
	my ($self, %args) 	= @_;
	my $response		= $args{response}	|| croak "Missing response\n";;
	my @urls			= @{ $args{urls}	|| []};


	if ($response->code == 204) {
		$self->debug("No match\n");
		return map { $_ => 'ok' } @urls;
	}

	my %results = ();
	my @lines = split /\n/, $response->content;

	if (scalar @urls != scalar @lines) {
		$self->error("Number of URLs in the reponse does not match the number of URLs in the request");
		$self->error( scalar(@urls) . "/" . scalar(@lines));
		$self->error($response->content);
		return $self->errors(@urls);
	}

	for(my $i = 0; $i < scalar(@urls); $i++) {
		$results{$urls[$i]} = $lines[$i];
	}

	return %results;
}

sub errors {
	my ($self, @urls) = @_;

	return map { $_ => 'error' } @urls;
}


sub ua {
	my ($self, %args) = @_;

	if (! exists $self->{ua}) {
		my $ua = LWP::UserAgent->new;
  		$ua->timeout(60);

		$self->{ua} = $ua;
	}

	return $self->{ua};
}


sub debug {
	my ($self, $message) = @_;

	print $message if ($self->{debug} > 0);
}


sub error {
	my ($self, $message) = @_;

	print "ERROR - ", $message, "\n" if ($self->{debug} > 0 || $self->{errors} > 0);
	$self->{last_error} = $message;
}

sub canonical_uri {
	my ($self, $url) = @_;

	$url = trim $url;

	# Special case for \t \r \n
	while ($url =~ s/^([^?]+)[\r\t\n]/$1/sgi) { } 

	my $uri = URI->new($url)->canonical; # does not deal with directory traversing

# 	$self->debug("0. $url => " . $uri->as_string . "\n");

	
	if (! $uri->scheme() || $uri->scheme() eq '') {
		$uri = URI->new("http://$url")->canonical;
	}

	$uri->fragment('');

	my $escape = $uri->as_string;

	# Reduce double // to single / in path
	while ($escape =~ s/^([a-z]+:\/\/[^?]+)\/\//$1\//sgi) { }


	# Remove empty fragment
	$escape =~ s/#$//;

	# canonial does not handle ../ 
# 	$self->debug("\t$escape\n");
	while($escape =~ s/([^\/])\/([^\/]+)\/\.\.([\/?].*)?$/$1$3/gi) {  }

	# May have removed ending /
# 	$self->debug("\t$escape\n");
	$escape .= "/" if ($escape =~ /^[a-z]+:\/\/[^\/\?]+$/);
	$escape =~ s/^([a-z]+:\/\/[^\/]+)(\?.*)$/$1\/$2/gi;
# 	$self->debug("\t$escape\n");

	# other weird case if domain = digits only, try to translte it to IP address
	if ((my $domain = URI->new($escape)->host) =~/^\d+$/) {
		my $ip = num2ip($domain);

		if (validaddr($ip)) {
			$uri = URI->new($escape);
			$uri->host($ip);

			$escape = $uri->as_string;
		}
	}

# 	$self->debug("1. $url => $escape\n");

	# Try to escape the path again
	$url = $escape;
	while (($escape = URI::Escape::uri_unescape($url)) ne $escape) { # wrong for %23 -> #
		$url = $escape;
	}
# 	while (($escape = URI->new($url)->canonical->as_string) ne $escape) { # breask more unit tests than previous
# 		$url = $escape;
# 	}

	# Fix for %23 -> #
	while($escape =~ s/#/%23/sgi) { }

# 	$self->debug("2. $url => $escape\n");

	# Fix over escaping
	while($escape =~ s/^([^?]+)%%(%.*)?$/$1%25%25$2/sgi) { }

	# URI has issues with % in domains, it gets the host wrong

		# 1. fix the host
# 	$self->debug("Domain: " . URI->new($escape)->host . "\n");
	my $exception = 0;
	while ($escape =~ /^[a-z]+:\/\/[^\/]*([^a-z0-9%_.-\/:])[^\/]*(\/.*)$/) {
		my $source = $1;
		my $target = sprintf("%02x", ord($source));

		$escape =~ s/^([a-z]+:\/\/[^\/]*)\Q$source\E/$1%\Q$target\E/;

		$exception = 1;
	}

		# 2. need to parse the path again
	if ($exception && $escape =~ /^[a-z]+:\/\/[^\/]+\/(.+)/) {
		my $source = $1;
		my $target = URI::Escape::uri_unescape($source);

# 		print "Source: $source\n";
		while ($target ne URI::Escape::uri_unescape($target)) {
			$target = URI::Escape::uri_unescape($target);
		}

		
		$escape =~ s/\/\Q$source\E/\/$target/;

		while ($escape =~ s/#/%23/sgi) { } # fragement has been removed earlier
		while ($escape =~ s/^([a-z]+:\/\/[^\/]+\/.*)%5e/$1\&/sgi) { } # not in the host name
# 		while ($escape =~ s/%5e/&/sgi) { } 

		while ($escape =~ s/%([^0-9a-f]|.[^0-9a-f])/%25$1/sgi) { }
	}

# 	$self->debug("$url => $escape\n");
# 	$self->debug(URI->new($escape)->as_string . "\n");

	return URI->new($escape);
}


=head1 CHANGELOG

=over 4

=item 0.2

Documentation update.

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for the implementation of Google Safe Browsing v2 API.

=head1 AUTHOR

Julien Sobrier, E<lt>jsobrier@zscaler.comE<gt> or E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
