package Net::DiffBot;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::XS;
use URI::Escape qw(uri_escape);
use HTTP::Request;

my $endpoint_url = 'http://www.diffbot.com/api/article';

=head1 NAME

Net::DiffBot - Interface to the diffbot.com API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module is just an interface for www.diffbot.com API.

    use Net::DiffBot;

    my $d = Net::DiffBot->new('token' => 'diffbottoken');
	my $page_data = $d->get_data_from_url($url)
    ...



=head1 SUBROUTINES/METHODS

=head2 new

Constructor method, you need to pass the diffbot token 
	
    my $d = Net::DiffBot->new('token' => 'diffbottoken');

=cut

sub new {
  my ($p, %args) = @_;

  die "No token provided" if (!exists $args{'token'});
  $p = ref($p) || $p;

  my $self = bless {
    %args
  }, $p;

  return $self
}

=head2 get_data_from_url

Fetch diffbot data based on the url , along with the url you can set other options

	my $page_data = $d->get_data_from_url($url, 'tags' => 1, summary => 1)

	Valid flags are: callback, html, dontStripAds, tags, comments, summary
	You can see the use of theses flags at www.diffbot.com

	Returns the page data as an hashref.

=cut

=head2 get_data_from_content

Fetch diffbot data based on sent content , you also need to send the url and the content type  ('text/plain', 'text/html'). You can also set other options as with get_data_from_url.

	my $page_data = my $d->get_data_from_content($url, $content, $content_type, 'tags' => 1, summary => 1)

	Valid flags are: callback, html, dontStripAds, tags, comments, summary
	You can see the use of theses flags at www.diffbot.com

	Returns the page data as an hashref.

=cut


sub get_data_from_content {
	my ($self, $url, $content, $content_type, %args) = @_;
	if (($content_type ne 'text/plain') and ($content_type ne 'text/html') ) {
		warn "Invalid content type, possible values are 'text/plain' or 'text/html'";
		return undef;
	}
	if (!$url) {
		warn "No url provided";
		return undef;
	}

	my $request_args = $self->get_request_args($url, %args);
    my $request_url = $self->build_request_url(%{$request_args});
    my $ua = LWP::UserAgent->new();

	my $content_length = length($content);
	my $headers = HTTP::Headers->new();
	$headers->header('Content-type' => $content_type);
	$headers->header('Content-length' => $content_length);
	my $http_request = HTTP::Request->new('POST', $request_url, $headers, $content);
	my $response = $ua->request($http_request);
    if (!$response->is_success) {
        warn "ERROR with request " . $request_url . " HTTP response" . $response->status_line;
        return undef;
    } else {
        my $data;
        eval {
            $data = decode_json($response->content);
        };
        if ($@) {
            warn "ERROR decoding JSON response";
            return undef;
        }
        return $data;
    }




}

sub get_request_args {
	my ($self, $url, %args) = @_;
	my @possible_args = qw(callback html dontStripAds tags comments summary);

    my %request_args = (
        'url' => $url,
    );
    for my $arg (@possible_args) {
        if ((exists $args{$arg}) and ($args{$arg}) ) {
            $request_args{$arg} = 'true';
        }
    }

	return \%request_args;
	

}
sub get_data_from_url {
    my ($self, $url, %args) = @_;
	if (!$url) {
		warn "No url provided";
		return undef;
	}


	my $request_args = $self->get_request_args($url, %args);
    my $request_url = $self->build_request_url(%{$request_args});
    my $ua = LWP::UserAgent->new();

    my $response = $ua->get($request_url);
    if (!$response->is_success) {
        warn "ERROR with request " . $request_url . " HTTP response" . $response->status_line;
        return undef;
    } else {
        my $data;
        eval {
            $data = decode_json($response->content);
        };
        if ($@) {
            warn "ERROR decoding JSON response";
            return undef;
        }
        return $data;
    }
}


sub build_request_url {
    my ($self, %args) = @_;
    $args{'token'} = $self->{'token'};

    my @keys = sort( grep { defined $args{$_} } keys(%args) );

    if (%args) {
        return  "$endpoint_url?" . join( '&', map { uri_escape($_,$self->{'uri_unsafe'}) . '=' . uri_escape( $args{$_} ) } @keys );
    } else {
        return $endpoint_url;
    }


}

=head1 AUTHOR

Bruno Martins, C<< <bscmartins at gmail.com> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DiffBot

Github repo https://github.com/bmartins/Net-DiffBot

=item * Search CPAN

L<http://search.cpan.org/dist/Net-DiffBot/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Bruno Martins.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::DiffBot
