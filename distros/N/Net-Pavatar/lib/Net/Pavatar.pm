package Net::Pavatar;

use warnings;
use strict;
use LWPx::ParanoidAgent;
use Carp;
use URI;
use GD;
use Regexp::Common qw /URI/;

=head1 NAME

Net::Pavatar - Pavatar client

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

    use Net::Pavatar;

    my ($hash, $file_type) = Net::Pavatar->fetch( 'http://someblog.com/', { size => [32, 48] } );

    if ($file_type) {
        open FILE, ">avatar.$file_type";
        print FILE $hash->{'48'};
        close FILE;
    }

=cut

sub _browser_get {
	my $url = shift;
	my $browser = shift;

	my ($i, $resp) = (0, undef);
	do {
		if ($i++) { sleep(1); }
		$resp = $browser->get($url);
	} until ($i >= 3 or $resp->code <= 499);
	return wantarray ? ($resp, $resp->is_success) : $resp;
}


=head1 DESCRIPTION

Fetches a pavatar image from a given URL and gives it to you in the sizes you specify. Uses LWPx::ParanoidAgent to protect your servers from attacks.

This module fully conforms to Pavatar spec 0.3.0 (L<http://pavatar.com/spec/pavatar-0.3.0>), which is the latest one on Apr 25th, 2007.

=head1 METHODS

=cut

sub _discover {
	my $class = shift;
	my $url = shift;
	my $params = shift || {};

	my $ua = $params->{'ua'} || LWPx::ParanoidAgent->new( timeout => 15, parse_head => 0 );
	my ($resp, $ok) = &_browser_get($url, $ua);
	if (! $ok) { return }
	my $base = $resp->base();

	# STEP 3.a of spec
	my ($answer) = $resp->header('X-Pavatar');
	if (defined $answer) {
		if ($answer eq 'none' or $answer !~ /$RE{'URI'}{'HTTP'}/) { return }
		return $answer;
	}

	# STEP 3.b of spec
	my $page = $resp->content;
	if ($resp->content_type =~ /\b(x?html|xml)\b/) {
		($answer) = $page =~ /<link rel="pavatar" href="([^"]+)" ?\/?>/gi;
		if (defined $answer) {
			if ($answer eq 'none' or $answer !~ /$RE{'URI'}{'HTTP'}/) { return }
			return $answer;
		}
	}

	# STEP 3.c of spec
	my $uri = URI->new($url);
	#my $uri = $resp->request->uri;
	if ($uri->scheme ne 'http') { return; }
	$uri = 'http://'.$uri->host_port.($uri->path || '/');
	my $pavuri = URI->new_abs('pavatar.png', $uri);

	my $max_size = $ua->max_size;
	$ua->max_size(51200);

	($resp, $ok) = &_browser_get( $pavuri->as_string, $ua );
	if ($ok) { $ua->max_size($max_size); return wantarray ? ($pavuri, $resp) : $pavuri; }

	my $did_pavuri = $pavuri->as_string;
	$pavuri->path('/pavatar.png');

	if ($pavuri->as_string ne $did_pavuri) {
		($resp, $ok) = &_browser_get( $pavuri, $ua );
		if ($ok) { $ua->max_size($max_size); return wantarray ? ($pavuri, $resp) : $pavuri; }
	}

	$ua->max_size($max_size);

	return;
}



=head2 my ($hashref, $type) = Net::Pavatar->fetch( $url, \%opts )

Returns a hashref and a string, as a 2-list. The hash contains the image sizes as keys, and the image data for each size as values. The string contains the image type and can either be 'jpeg', 'png' or 'gif'. If a pavatar does not exist, or is not valid for any reason, returns null.

The \%opts hashref is optional, and accepts the following keys:

C<size> : the sizes that you want the pavatar image returned in - defaults to 80

C<timeout> : the total time that UserAgent is allowed to retrieve each page or image - defaults to 15

e.g. C<< Net::Pavatar->fetch( $url, { size => [32, 48], timeout => 25 } ) >>

=cut

sub fetch {
	my $class = shift;
	my $url = shift;
	my $params = shift || {};

	my $ua = $params->{'ua'} || LWPx::ParanoidAgent->new( timeout => 15, parse_head => 0 );
	($url, my $resp) = $class->_discover($url, { ua => $ua });
	if (! $url) { return; }

	my $max_size = $ua->max_size;
	$ua->max_size(51200);
	my $ok;
	if (! $resp) {
		($resp, $ok) = &_browser_get($url, $ua);
	} else {
		$ok = 1;
	}
	$ua->max_size($max_size);
	if (! $ok) { return; }

	my $type = $resp->content_type;
	($type) = $type =~ /^image\/(.+)$/g;

	my $img;
	if ($type eq 'jpeg') {
		$img = GD::Image->newFromJpegData($resp->content, 1);
	} elsif ($type eq 'gif') {
		$img = GD::Image->newFromGifData($resp->content, 1);
	} elsif ($type eq 'png') {
		$img = GD::Image->newFromPngData($resp->content, 1);
	} else {
		return;
	}
	if (! $img) { return; }

	my ($width, $height) = $img->getBounds();
	if ($width != 80 or $height != 80) { return; }
	my @sizes;
	my $size = $params->{'size'};
	if (! defined $size) {
		@sizes = (80);
	} elsif (ref $size eq 'ARRAY') {
		@sizes = grep { /^\d+$/ } @$size;
	} elsif (! ref $size) {
		@sizes = int($size);
	} else {
		confess "Error: sizes parameter needs to be a number or an arrayref";
	}

	my $return = { };
	foreach my $size (@sizes) {
		if ($size == 80) {
			$return->{'80'} = $resp->content();
		} elsif ($size > 0 and $size < 80) {
			my $newimage = GD::Image->new($size, $size, 1);
			$newimage->copyResampled($img, 0, 0, 0, 0, $size, $size, 80, 80);
			my $data = $newimage->$type();
			$return->{$size} = $data;
		} else {
			confess "Error: problem with size = '$size' (needs to be an integer between 1 and 80 inclusive)";
		}
	}
	if (! keys %$return) { return; }

	return ($return, $type);
}

=head1 AUTHOR

Alexander Karelas, C<< <karjala at karjala.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-pavatar at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Pavatar>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Pavatar

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Pavatar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Pavatar>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Pavatar>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Pavatar>

=item * Module's RSS feed

L<http://myperl.eu/permodule/Net-Pavatar>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Alexander Karelas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::Pavatar
