
package RayApp::XML;

use strict;
use warnings;

use Encode ();

$RayApp::XML::VERSION = '1.160';

use base 'RayApp::Source';
use XML::LibXSLT ();

sub new {
        my $class = shift;
	my %opts = @_;
	my $rayapp = $opts{rayapp} or return;

	my $data;
	if (exists $opts{content}) {
		$data = $rayapp->load_string( delete $opts{content}, %opts ) or return;
	} else {
		$data = $rayapp->load_uri( delete $opts{uri}, %opts ) or return;
	}
	if ($data->{xmldom}) {
		return $data;
	}

	if (defined $data->redirect_location) {
		return $data;
	}
	if (defined $data->www_authenticate) {
		return $data;
	}

	my $xml_parser = $rayapp->xml_parser or return;
	eval {
		$data->{xmldom} = $xml_parser->parse_string($data->content);
	};
	if ($@) {
		$rayapp->errstr($@);
		return;
	}
	my @pi;
	my $child = $data->{xmldom}->firstChild;


	while (defined $child) {
		if ($child->nodeType == 7	# processing instruction
			and $child->nodeName eq 'xml-stylesheet') {
			my $value = $child->nodeValue;
			my %attributes;

			while ($value =~ /\s*(\S+)=(?:"(.*?)"|'(.*?)')/g) {
				push @{ $attributes{$1} },
					( defined $2 ? $2 : $3 );
			}

			push @pi, {
				value => $value,
				attributes => \%attributes,
			};
		}
		$child = $child->nextSibling();
	}

	$data->{pi_xml_stylesheets} = \@pi;

	if ($data->{xmldom}->encoding) {
		$data->{xmldom}->setEncoding('UTF-8');
	}
	return bless $data, $class;
}
sub xmldom { shift->{xmldom}; }
sub isdsd { shift->{is_dsd}; }

sub parse_as_dsd {
	my $self = shift;

	require RayApp::DSD;
	my $dsd = new RayApp::DSD( $self ) or return;
	$dsd;
}

package RayApp::XML::Sourcer;
sub new {
	my $class = shift;
	my %opts = @_;
	my $new_uri = URI->new_abs($opts{uri}, $opts{stylesheet}->uri);
	# print STDERR "Stylesheet [@{[ $opts{stylesheet}->uri ]}] wants [$new_uri] in pid $$\n";
	my $rayapp = $opts{stylesheet}->rayapp;
	my $source = $rayapp->load_uri($new_uri);
	if (not defined $source) {
		my $errstr = $rayapp->errstr;
		die "Failed to load [$new_uri]: $errstr\n";
	}
	return bless {
		source => $source,
		offset => 0,
		}, $class;

}
sub get_next_chunk {
	my ($self, $length) = @_;
	my $offset = $self->{offset};
	if ($offset >= length($self->{source}->content)) {
		return '';
	}
	my $buffer = substr($self->{source}->content, $offset, $length);
	$self->{offset} += length($buffer);
	return $buffer;
}

package RayApp::XML;

sub match_uri {
        # print STDERR "match_uri [@_]\n";
	if ($_[0] =~ m!^file:/!) {
		return;
	}
	return 1;
}
sub open_uri {
        # print STDERR "open_uri [@_]\n";
	my ($stylesheet, $uri) = @_;
	return new RayApp::XML::Sourcer(
		uri => $uri,
		stylesheet => $stylesheet,
	);
}
sub read_uri {
        # print STDERR "read_uri [@_]\n";
	my ($sourcer, $length) = @_;
	return $sourcer->get_next_chunk($length);
}
sub close_uri {
        # print STDERR "close_uri [@_]\n";
        return;
}


# Style the DOM data (either result of DSD data serialization or plain
# XML input), using list of stylesheets, deriving relative URIs from
# this resource's URI
sub style_dom {
	my ($self, $dom, $opts) = (shift, shift, shift);

	my $rayapp = $self->rayapp;
	my $dsd_uri = $self->uri;

	my @style_params;
	if (defined $opts->{'style_params'}
		and ref $opts->{'style_params'}) {
		if (ref $opts->{'style_params'} eq 'HASH') {
			@style_params = XML::LibXSLT::xpath_to_string(
				%{ $opts->{style_params} }
			);
		} elsif (ref $opts->{'style_params'} eq 'ARRAY') {
			@style_params = XML::LibXSLT::xpath_to_string(
				@{ $opts->{style_params} }
			);
		}
		delete $opts->{'style_params'};
	}

	my $outdom = $dom;
	my $style;
	for my $st (@_) {
		my $st_uri = URI->new_abs($st,
			(defined $dsd_uri) ? $dsd_uri : $rayapp->base_uri
			);
		my $stylesheet = $rayapp->load_xml($st_uri);
		if (not defined $stylesheet) {
			$self->errstr("Failed to load XML [$st_uri]: " . $rayapp->errstr);
			return;
		}
		$style = $stylesheet->{xslt_dom};
		if (not defined $style) {
			my $xslt_parser = $rayapp->{xslt_parser};
			if (not defined $xslt_parser) {
				$xslt_parser = $rayapp->{xslt_parser} = new XML::LibXSLT;
			}
			$xslt_parser->callbacks(
				\&match_uri,
				sub { open_uri($stylesheet, @_) },
				\&read_uri,
				\&close_uri
			);
			# local $SIG{__WARN__} = sub {};
			$style = $stylesheet->{xslt_dom} = eval {
				$xslt_parser->parse_stylesheet($stylesheet->xmldom)
			};
			if ($@ or not defined $style) {
				$self->errstr("Failed to parse stylesheet [$st_uri]: $@");
				return;
			}
		}
		{
			local $XML::LibXML::match_cb = \&match_uri;
			local $XML::LibXML::open_cb = sub { open_uri($stylesheet, @_) };
			local $XML::LibXML::read_cb = \&read_uri;
			local $XML::LibXML::close_cb = \&close_uri;
			$outdom = eval { $style->transform($outdom, @style_params) };
		}
		if ($@) {
			$self->errstr("Stylesheet [$st_uri] $@");
			return;
		}
		if (not defined $outdom) {
			$self->errstr("Stylesheet [$stylesheet] returned empty result");
			return;
		}
	}
	if (defined $style) {
		if (defined $opts->{as_string}
			and $opts->{as_string}) {
			my $string = $style->output_string($outdom);
			if (${^UNICODE}) {
				if (wantarray) {
					return Encode::decode('utf8', $string,
							Encode::FB_DEFAULT),
						$style->media_type,
						$style->output_encoding;
				} else {
					return Encode::decode('utf8', $string,	
							Encode::FB_DEFAULT);
				}
			} else {
				if (wantarray) {
					return $string, $style->media_type,
						$style->output_encoding;
				} else {
					return $string;
				}
			}
		} else {
			if (wantarray) {
				return ($outdom, $style->media_type, $style->output_encoding);
			} else {
				return $outdom;
			}
		}
	} else {
		if ($outdom->encoding) {
			$outdom->setEncoding('UTF-8');
		}
		if (defined $opts->{as_string}
			and $opts->{as_string}) {
			my $string = $outdom->toString(0);
			if (${^UNICODE}) {
				if (wantarray) {
					return Encode::decode('utf8', $string,
							Encode::FB_DEFAULT),
						'text/xml',
						$outdom->encoding;
				} else {
					return Encode::decode('utf8', $string,	
							Encode::FB_DEFAULT);
				}
			} else {
				if (wantarray) {
					return $string, 'text/xml',
						$outdom->encoding;
				} else {
					return $string;
				}
			}
		} else {
			if (wantarray) {
				return ($outdom, 'text/xml', $outdom->encoding);
			} else {
				return $outdom;
			}
		}
	}
}
sub style_string {
	my ($self, $dom, $opts) = (shift, shift, shift);
	$opts->{as_string} = 1;
	return $self->style_dom($dom, $opts, @_);
}

sub find_stylesheets {
	my ($self, $type) = @_;
	return if not defined $type or $type eq 'xml';
	my @exts;

	my @pi = grep { defined $_->{attributes}{href}
		and (not defined $_->{attributes}{type}
			or $_->{attributes}{type} =~ m!^text/(xml|application|xslt?)(\s*;|$)!) }
		@{ $self->{pi_xml_stylesheets} };

	if ($type eq 'html') {
		my @match = (grep {
			not defined $_->{attributes}{media}
			or grep { $_ eq 'screen' } @{ $_->{attributes}{media} }
			} @pi);
		if (@match) {
			return $match[0]->{attributes}{href}[0];
		}
		@exts = ('.xsl', '.xslt', '.html.xsl', '.html.xslt');
	} elsif ($type eq 'txt') {
		@exts = ('.txt.xsl', '.txt.xslt');
	} elsif ($type eq 'pdf' or $type eq 'fo') {
		my @match = (grep {
			not defined $_->{attributes}{media}
			or grep { $_ eq 'print' } @{ $_->{attributes}{media} }
			} @pi);
		if (@match) {
			return $match[0]->{attributes}{href}[0];
		}
		@exts = ('.fo.xsl', '.fo.xslt');
	}

	my $uri = $self->uri;
	if ($uri =~ m!^/|file:/!) {
		$uri =~ s!^file:(//)?/!/!;
		$uri =~ s!\.[^./]+$!!;
		for my $ext (@exts) {
			if (-f $uri . $ext) {
				return $uri . $ext;
			}
		}
	} else {
		$uri =~ s/\.[^.]+$// and return $uri . $exts[0];
	}
	return;
}




1;
