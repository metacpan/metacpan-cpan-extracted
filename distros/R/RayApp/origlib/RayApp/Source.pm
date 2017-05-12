
use 5.008001;
use strict;
use warnings;

package RayApp::Source;

$RayApp::Source::VERSION = '1.149';

use Digest::MD5 ();

# Create the RayApp::Source object which retrieves the source
# via URI and holds the content of the response
sub new {
	my $class = shift;
	my %opts = @_;
	my $uri = $opts{uri};
	my $md5_hex;
	if (exists $opts{content}) {
		if (not defined $uri) {
			no warnings 'uninitialized';
			$md5_hex = Digest::MD5::md5_hex($opts{content});
			$uri = "md5:$md5_hex";
			if (defined $opts{rayapp}{uris}{ $uri }) {
				return $opts{rayapp}{uris}{ $uri };
			}
		}
	} else {
		my $rayapp = $opts{rayapp};
		my $ua = $rayapp->ua;
		my $response = $ua->get($uri);

		if ($response->is_error) {
			if (defined $response->{_msg}) {
				$rayapp->errstr($response->{_msg});
			} else {
				$rayapp->errstr($response->error_as_html());
			}
			return;
		}
		$opts{content} = $response->content;
		$opts{mtime} = $response->last_modified;
		$md5_hex = Digest::MD5::md5_hex($opts{content});
	}

	return $opts{rayapp}{uris}{ $uri } = bless {
		uri => $uri,
		content => $opts{content},
		md5_hex => $md5_hex,
		rayapp => $opts{rayapp},
		mtime => $opts{mtime},
		}, $class;
}

sub rayapp {
	shift->{rayapp};
}
sub uri {
	shift->{uri};
}
sub mtime {
	shift->{mtime};
}
sub content {
	shift->{content};
}
sub md5_hex {
	shift->{md5_hex};
}
sub errstr {
	my $self = shift;
	if (@_) {
		$self->{errstr} = shift;
	}
	return $self->{errstr};
}
sub clear_errstr {
	shift->errstr(undef);
	1;
}

package RayApp::XML;

use base 'RayApp::Source';

sub new {
	my ($class, $object) = @_;
	if (not ref $object) {
		$object = new RayApp::Source($object) or return;
	}
	my $rayapp = $object->rayapp;
	my $xml_parser = $rayapp->xml_parser or return;

	$object->{xmldom} = $xml_parser->parse_string($object->content);

	# FIXME: why is this here?
	if ($object->{xmldom}->encoding) {
		$object->{xmldom}->setEncoding('UTF-8');
	}
	return bless $object, $class;
}
sub xmldom {
	my $self = shift;
	return $self->{xmldom};
}

__END__

use URI::file ();
use Digest::MD5 ();
use LWP::UserAgent ();
use Config;
use XML::LibXML ();
use XML::LibXSLT ();
use Encode ();


# The constructor
sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	if (not defined $self->{base}) {
		$self->{base} = URI::file->cwd;
	}
	return $self;
}
sub errstr {
	my $self = shift;
	return ( ref $self ? $self->{errstr} : $RayApp::errstr );
}

# Loading content by URI, using cache
sub load_uri {

}
sub load_user_agent {
	my $self = shift;
	my %uaoptions;
	if (defined $self->{ua_options}) {
		%uaoptions = %{ $self->{ua_options} };
	}
	$self->{ua} = new LWP::UserAgent(%uaoptions) or do {
		$self->{errstr} = 'Error loading user agent';
		return;
	};
	return 1;
}
# Loading of content specified as string
sub load_string {
	my $self = shift;
	my $md5_hex = Digest::MD5::md5_hex($_[0]);
	my $uri = "md5:$md5_hex";
	return $self->{uris}{$uri} = bless {
		uri => $uri,
		content => $_[0],
		md5_hex => $md5_hex,
		rayapp => $self,
		}, 'RayApp::DSD';
}

# Loading content and parsing it as DSD
sub load_dsd {
	my ($self, $uri) = @_;
	my $dsd = $self->load_uri($uri) or return;
	$uri = $dsd->uri;				# absolute URI
	if ($self->{uris}{$uri}{is_dsd}) {
		return $self->{uris}{$uri};		# already parsed as DSD
	}
	eval {
		$self->parse_dsd($dsd);			# try to parse the XML
	};
	if ($@) {
		($self->{errstr} = $@) =~ s/\n+$//;
		return;
	}
	return $dsd;
}
sub load_dsd_string {
	my $self = shift;
	$self->{errstr} = undef;
	my $dsd = $self->load_string(@_);
	eval {
		$self->parse_dsd($dsd);
	};
	if ($@) {
		($self->{errstr} = $@) =~ s/\n+$//;
		return;
	}
	return $dsd;
}
# Loading content that should be XML
sub load_xml {
	my ($self, $uri) = @_;
	my $xml = $self->load_uri($uri);
	if (not defined $self->{parser}) {
		$self->{parser} = new XML::LibXML;
		if (not defined $self->{parser}) {
			die "Error loading the XML::LibXML parser\n";
		}
		$self->{parser}->line_numbers(1);
		# $self->{parser}->keep_blanks(0);
	}
	$xml->{dom} = $self->{parser}->parse_string($xml->{content});
	return $xml;
}
sub load_xml_string {
	my $self = shift;
	my $xml = $self->load_string(@_);
	if (not defined $self->{parser}) {
		$self->{parser} = new XML::LibXML;
		if (not defined $self->{parser}) {
			die "Error loading the XML::LibXML parser\n";
		}
		$self->{parser}->line_numbers(1);
		# $self->{parser}->keep_blanks(0);
	}
	$xml->{dom} = $self->{parser}->parse_string($xml->{content});
	return $xml;
}



sub execute_application_cgi {
	my ($self, $application, @params) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		require $application;
		return &handler(@params);
	};
	if ($@) {
		print STDERR $@;
		my $errstr = $@;
		$errstr =~ s/\n$//;
		$self->{errstr} = $errstr;
		return 500;
	}
	return $ret;
}

sub execute_application_handler {
	my ($self, $application, @params) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		local *FILE;
		open FILE, $application or die "Error reading `$application': $!\n";
		local $/ = undef;
		my $content = <FILE>;
		close FILE or die "Error reading `$application' during close: $!\n";
		if (${^TAINT}) {
			$content =~ /^(.*)$/s and $content = $1;
		}
		my $max_num = $self->{max_handler_num};
		if (not defined $max_num) {
			$max_num = 0;
		}
		$self->{max_handler_num} = ++$max_num;
		eval "package RayApp::Root::pkg$max_num; " . $content
			or die "Compiling `$application' did not return true value\n";
		my $handler = 'RayApp::Root::pkg' . $max_num . '::handler';
		$self->{handlers}{$application} = {
			handler => $handler,
		};
		no strict;
		return &{ $handler }(@params);
	};
	if ($@) {
		print STDERR $@;
		my $errstr = $@;
		$errstr =~ s/\n$//;
		$self->{errstr} = $errstr;
		return 500;
	}
	return $ret;
}

sub execute_application_handler_reuse {
	my ($self, $application, @params) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		my $handler;
		my $mtime = (stat $application)[9];
		if (defined $self->{handlers}{$application}
			and defined $self->{handlers}{$application}{mtime}
			and $self->{handlers}{$application}{mtime} == $mtime) {
			# print STDERR "Not loading\n";
			$handler = $self->{handlers}{$application}{handler};
		} else {        
			$handler = $application;
			$handler =~ s!([^a-zA-Z0-9])! ($1 eq '/') ? '::' : sprintf("_%02x", ord $1) !ge;
			my $package = 'RayApp::Root::pkn' . $handler;
			$handler = $package . '::handler';
			### print STDERR "Loading\n";

			local *FILE;
			open FILE, $application or die "Error reading `$application': $!\n";
			local $/ = undef;
			my $content = <FILE>;
			close FILE or die "Error reading `$application' during close: $!\n";
			if (${^TAINT}) {
				$content =~ /^(.*)$/s and $content = $1;
			}
			my $max_num = $self->{max_handler_num};
			if (not defined $max_num) {
				$max_num = 0;
			}
			## $content =~ s/(.*)/$1/s;
			$max_num++;
			eval "package $package; " . $content
				or die "Compiling `$application' did not return true value\n";
			$self->{handlers}{$application} = {
				handler => $handler,
				mtime => $mtime,
			};
		}
		no strict;
		return &{ $handler }(@params);
	};
	if ($@) {
		print STDERR $@;
		my $errstr = $@;
		$errstr =~ s/\n$//;
		$self->{errstr} = $errstr;
		return 500;
	}
	return $ret;
}

sub execute_application_process_storable {
	my ($self, $application, $dsd_uri) = @_;
	$self->{errstr} = undef;
	if (ref $application) {
		$dsd_uri = $application->{'uri'};
		$application = $application->application_name;
	}       
	my $ret = eval {
		if (not defined $application) {
			die "Application name was not defined\n";
		}
		require Storable;
		my $inc = join ' ', map "-I$_", @INC;   

		local $ENV{'PATH'};
		delete $ENV{'PATH'};
		local $ENV{'BASH_ENV'};
		delete $ENV{'BASH_ENV'};
		my $value = `$Config{'perlpath'} $inc -MRayApp::CGIStorable $application $dsd_uri`;
		if ($value =~ s!^Content-Type: application/x-perl-storable.*\n\n!!s) {
			my $data = Storable::thaw($value);
			return $data;
		}
		return $value;
	};
	if ($@) {
		print STDERR $@;
		my $errstr = $@;
		$errstr =~ s/\n$//;
		$self->{errstr} = $errstr;
		return 500;
	}
	return $ret;
}

sub find_stylesheet {
	my ($self, $uri, $type) = @_;
	return if not defined $type;
	my @exts = ('.xsl', '.xslt', '.html.xsl', '.html.xslt');
	if ($type eq 'txt') {
		@exts = ('.txtxsl', '.txtxslt', '.txt.xsl', '.txt.xslt');
	} elsif ($type eq 'pdf' or $type eq 'fo') {
		@exts = ('.foxsl', '.foxslt', '.fo.xsl', '.fo.xslt');
	}
	for my $ext (@exts) {
		if (-f $uri . $ext) {
			return $uri . $ext;
		}
	}
        if ($type eq 'html'
                and defined $ENV{'RAYAPP_HTML_STYLESHEETS'}) {
		return split /:/, $ENV{'RAYAPP_HTML_STYLESHEETS'};
        } elsif ($type eq 'txt'
                and defined $ENV{'RAYAPP_TXT_STYLESHEETS'}) {
		return split /:/, $ENV{'RAYAPP_TXT_STYLESHEETS'};
        } elsif (($type eq 'pdf' or $type eq 'fo')
                and defined $ENV{'RAYAPP_FO_STYLESHEETS'}) {
		return split /:/, $ENV{'RAYAPP_FO_STYLESHEETS'};
        }
	return;
}


package RayApp::DSD;


sub clone_node {
	my $node = shift;
	my $new = $node->cloneNode(0);
	$new->setNodeName($node->nodeName);
	my $child = $node->firstChild;
	while (defined $child) {
		my $new_child = clone_node($child);
		$new->addChild($new_child);
		$child = $child->nextSibling;
	}
	for my $a ($node->attributes) {
		next if not defined $a;
		$new->setAttribute($a->nodeName, $a->getValue);
	}
	return $new;
}


sub errstr {
	return shift->{errstr};
}
sub uri {
	return shift->{uri};
}
sub content {
	return shift->{content};
}
sub dom {
	return shift->{dom};
}
sub md5_hex {
	return shift->{md5_hex};
}
sub rayapp {
	return shift->{rayapp};
}


sub application_name {
	my $self = shift;
	if (not defined $self->{application}) {
		return;
	}
	my $uri = URI->new_abs($self->{application}, $self->{uri});
	if (not $uri =~ s/^file://) {
		return;
	}
	return $uri;
}


sub bind_data {
	my ($self, $dom, $node, $pointer, $data, $showname, $inmulti) = @_;
	my $spec = $self->{'placeholders'}{$pointer};
	if (not defined $data) {
		if ($spec->{'mandatory'} eq 'yes') {
			$self->{errstr} .= "No value of $showname for mandatory data element defined at line $spec->{'ln'}\n";
		}
		RayApp::removeChildNodeNicely($node->parentNode, $node);
		return 0;
	} elsif ($spec->{'multiple'} eq 'listelement'
			or $spec->{'multiple'} eq 'hashelement') {
		my $i = 0;
		for my $child ($node->childNodes) {
			if ($child->nodeType == 1) {
				$self->bind_data($dom, $child, "$pointer:$i",
					$data, $showname, 0);
			}
			$i++;
		}
	} elsif ($inmulti == 0 and $spec->{'multiple'} eq 'list') {
		if (not ref $data or ref $data ne 'ARRAY') {
			$self->{errstr} .= "Data '@{[ ref $data || $data ]}' found where array reference expected for $showname at line $spec->{'ln'}\n";
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		}
		my $parent = $node->parentNode;
		my $prev = $node->previousSibling;
		my $indent;
		if (defined $prev and $prev->nodeType == 3) {
			my $v = $prev->nodeValue;
			if (defined $v and $v =~ /(\n[ \t]+)/) {
				$indent = $1;
			}
		}
		if (@{$data} == 0) {
			RayApp::removeChildNodeNicely($parent, $node);
		}
		for (my $i = 0; $i < @{$data}; $i++) {
			my $work = $node;
			if ($i < $#{$data}) {
				# $work = $node->cloneNode(1);
				$work = clone_node($node);
				$parent->insertBefore($work, $node);
				if (defined $indent) {
					$parent->insertBefore(
						$dom->createTextNode($indent),
						$node);
				}
			}
			$self->bind_data($dom, $work, $pointer,
				$data->[$i], $showname . "[$i]", 1);
		}
	} elsif ($inmulti == 0 and $spec->{'multiple'} eq 'hash') {
		if (not ref $data or ref $data ne 'HASH') {
			$self->{errstr} .= "Data '@{[ ref $data || $data ]}' found where hash reference expected for $showname at line $spec->{'ln'}\n";
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		}
		my $parent = $node->parentNode;
		my $prev = $node->previousSibling;
		my $indent;
		if (defined $prev and $prev->nodeType == 3) {
			my $v = $prev->nodeValue;
			if (defined $v and $v =~ /(\n[ \t]+)/) {
				$indent = $1;
			}
		}
		my $numkeys = keys %$data;
		if ($numkeys == 0) {
			RayApp::removeChildNodeNicely($parent, $node);
		}
		my $i = 0;
		for my $key (sort {
			my $r = 0;
			if ($spec->{'hashorder'} eq 'num') {
				local $^W = 0;
				$r = $a <=> $b;
			}
			if ($r == 0 and $spec->{'hashorder'} eq 'string') {
				$r = $a cmp $b;
			}
			return $r;
			} keys %$data) {

			my $work = $node;
			if ($i < $numkeys - 1) {
				# $work = $node->cloneNode(1);
				$work = clone_node($node);
				$parent->insertBefore($work, $node);
				if (defined $indent) {
					$parent->insertBefore(
						$dom->createTextNode($indent),
						$node);
				}
			}
			$i++;
			$work->setAttribute($spec->{'idattr'}, $key);
			$self->bind_data($dom, $work, $pointer,
				$data->{$key}, $showname . "{$key}", 1);
		}
	} elsif ($spec->{'type'} ne 'hash') {
		if (ref $data) {
			$self->{errstr} .= "Scalar expected for $showname defined at line $spec->{'ln'}, got @{[ ref $data ]}\n";
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		} elsif ($spec->{'type'} eq 'int'
			and not $data =~ /^[+-]?\d+$/) {
			$self->{errstr} .= "Value '$data' of $showname is not integer for data element defined at line $spec->{'ln'}\n";
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		} elsif ($spec->{'type'} eq 'num'
			and not $data =~ /^[+-]?\d*\.?\d+$/) {
			$self->{errstr} .= "Value '$data' of $showname is not numeric for data element defined at line $spec->{'ln'}\n";
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		}
		if ($spec->{'cdata'} eq 'yes') {
			while ($data =~ s/^(.*\])(?=\]>)//sg) {
				$node->appendChild($dom->createCDATASection($1));
			}
			$node->appendChild($dom->createCDATASection($data));
		} else {
			$node->appendText($data);
		}
		return 1;
	} elsif ($spec->{'type'} eq 'hash') {
		if (not ref $data) {
			$self->{errstr} .= "Scalar data '$data' found where structure expected for $showname at line $spec->{'ln'}\n";
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		}
		my %done = ();
		my $total = 0;
		my $i = 0;
		my $arrayi = 0;
		for my $child ($node->childNodes) {
			my $newpointer = "$pointer:$i";
			$i++;
			next if not defined $self->{'placeholders'}{$newpointer};
			if (ref $data eq 'ARRAY') {
				$total += $self->bind_data($dom, $child,
					$newpointer, $data->[ $arrayi ],
					$showname . "[$arrayi]", 0);
				$arrayi++;
			} else {
				my $newname = $self->{'placeholders'}{$newpointer}{'name'};
				$total += $self->bind_data($dom, $child,
					$newpointer, $data->{ $newname },
					$showname . "{$newname}", 0);
				$done{$newname} = 1;
			}
		}
		if (ref $data eq 'HASH') {
			for my $k (sort keys %$data) {
				if (not exists $done{$k}) {
					$self->{errstr} .= "Data $showname\{$k} does not match data structure description\n";
				}
			}
		} elsif (ref $data eq 'ARRAY') {
			if ($arrayi <= $#$data) {
				my $view = $arrayi;
				if ($arrayi < $#$data) {
					$view .= "..$#$data";
				}
				$self->{errstr} .= "Data $showname\[$view] does not match data structure description\n";
			}
		} else {
			die "We shouldn't have got here";
		}
		if ($total or $inmulti) {
			return 1;
		} else {
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return 0;
		}
	} else {
		die "We shouldn't have got here, " . $node->toString;
	}
	return 1;
}

sub serialize_data_node {
	my ($self, $dom, $data, $opts, $node, $pointer) = @_;
	if (defined(my $spec = $self->{'placeholders'}{$pointer})) {
		$self->bind_data($dom, $node, $pointer,
			$data->{$spec->{'name'}}, "{$spec->{'name'}}", 0);
		return;
	} elsif (exists $self->{'ifs'}{$pointer}) {
		if ($self->{'ifs'}{$pointer}[0] eq 'if') {
			if (not defined $data->{$self->{'ifs'}{$pointer}[1]}) {
				RayApp::removeChildNodeNicely($node->parentNode, $node);
				return;
			}
			if (not ref $data->{$self->{'ifs'}{$pointer}[1]}
				and not $data->{$self->{'ifs'}{$pointer}[1]}) {
				RayApp::removeChildNodeNicely($node->parentNode, $node);
				return;
			}
			if (ref $data->{$self->{'ifs'}{$pointer}[1]} eq 'ARRAY'
				and not @{ $data->{$self->{'ifs'}{$pointer}[1]} }) {
				RayApp::removeChildNodeNicely($node->parentNode, $node);
				return;
			}
			if (ref $data->{$self->{'ifs'}{$pointer}[1]} eq 'HASH'
				and not keys %{ $data->{$self->{'ifs'}{$pointer}[1]} }) {
				RayApp::removeChildNodeNicely($node->parentNode, $node);
				return;
			}
		} elsif ($self->{'ifs'}{$pointer}[0] eq 'ifdef'
			and not defined $data->{$self->{'ifs'}{$pointer}[1]}) {
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return;
		} elsif ($self->{'ifs'}{$pointer}[0] eq 'ifnot'
			and $data->{$self->{'ifs'}{$pointer}[1]}) {
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return;
		} elsif ($self->{'ifs'}{$pointer}[0] eq 'ifnotdef'
			and defined $data->{$self->{'ifs'}{$pointer}[1]}) {
			RayApp::removeChildNodeNicely($node->parentNode, $node);
			return;
		}
	}

	my $i = 0;
	for my $child ($node->childNodes) {
		$self->serialize_data_node($dom, $data,
			$opts, $child, "$pointer:$i");
		$i++;
	}
	return;
}

sub serialize_style_dom {
	my ($self, $data, $opts) = ( shift, shift, shift );

	my $outdom = eval {
		$self->serialize_data_dom($data, $opts) ;
	};
	if ($@) {
		return;
	}

	return $self->style_dom($outdom, $opts, @_);
}

sub serialize_style {
	my ($self, $data, $opts) = ( shift, shift, shift );
	my $outdom = eval {
		$self->serialize_data_dom($data, $opts) ;
	};
	if ($@) {
		return;
	}
	return $self->style_string($outdom, $opts, @_);
}

sub validate_parameters {
	my $self = shift;
	$self->{errstr} = '';
	my %params;

	if (defined $_[0] and ref $_[0]) {
		if (eval { $_[0]->can("param") } and not $@) {
			for my $name ($_[0]->param) {
				$params{$name} = [ $_[0]->param($name) ];
			}
		} else {
			%params = %{ $_[0] };
		}
	} else {
		while (@_) {
			my ($k, $v) = (shift, shift);
			push @{ $params{$k} }, $v;
		}
	}

	for my $k (sort keys %params) {
		my $check = $self->{param}{$k};
		if (not defined $check) {
			my @prefixes;
			for my $i ( 1 .. length($k) ) {
				push @prefixes, substr $k, 0, $i;	
			}
			for my $pfx (reverse @prefixes) {
				if (defined $self->{paramprefix}{$pfx}) {
					$check = $self->{paramprefix}{$pfx};
					last if defined $check;
				}
			}
		}
		my $showname = 'undef';
		if (defined $params{$k}) {
			if (@{ $params{$k} } > 1) {
				$showname = '['
					. join(', ', map {
						defined $_
						? "'$_'"
						: 'undef' } @{ $params{$k} })
					. ']';
			} else {
				$showname = ( defined $params{$k}[0]
						? "'$params{$k}[0]'"
						: 'undef' );
			}
		}
		if (not defined $check) {
			$self->{errstr} .= "Unknown parameter '$k'=$showname\n";
		} elsif (@{ $params{$k} } > 1 and $check->{'multiple'} ne 'yes') {
			$self->{errstr} .= "Parameter '$k' has multiple values $showname\n";
		} elsif (defined $params{$k} and @{ $params{$k} }) {
			if ($check->{'type'} eq 'int') {
				my @bad = grep {
					defined $_ and not /^[+-]?\d+$/
					} @{ $params{$k} };
				if (@bad) {
					my $showname = '['
						. join(', ', map "'$_'", @bad)
						. ']';
					$self->{errstr} .= "Parameter '$k' has non-integer value $showname\n";
				}
			} elsif ($check->{'type'} eq 'num') {
				my @bad = grep {
					defined $_ and not /^[+-]?\d*\.\d+$/
					} @{ $params{$k} };
				if (@bad) {
					my $showname = '['
						. join(', ', map "'$_'", @bad)
						. ']';
					$self->{errstr} .= "Parameter '$k' has non-numeric value $showname\n";
				}
			}
		}
	}
	if ($self->{errstr} eq '') {
		$self->{errstr} = undef;
		return 1;
	}
	if (not $self->{errstr} =~ /\n./) {
		$self->{errstr} =~ s/\n$//;
	}
	return;
}

sub get_dtd {
	my $self = shift;
	return $self->{dtd} if defined $self->{dtd};
	my $data = { elements => {}, attributes => {} };
	$self->get_dtd_node($self->{'dom'}, 0, $data);

	my $out = '';
	for my $element (keys %{ $data->{elements} }) {

		my %contents;
		for my $val ( @{ $data->{elements}{$element} } ) {
			if (@$val == 1 and $val->[0] eq '#PCDATA') {
				$contents{'#PCDATA'} = 1;
			} else {
				my $txt = join ', ', @$val;
				if (@$val > 1) {
					$txt = "($txt)";
				}
				$contents{$txt} = 1;
			}
		}

		$out .= "<!ELEMENT $element ("
			. join '|', grep({ $_ eq '#PCDATA' } keys %contents),
			grep({ $_ ne '#PCDATA' } keys %contents);
		if (defined $contents{'#PCDATA'}) {
			$out .= ")*>\n";
		} else {
			$out .= ")>\n";
		}
		if (defined $data->{attributes}{$element}) {
			$out .= "<!ATTLIST $element ";
			my $i = 0;
			for my $v (keys %{ $data->{attributes}{$element} }) {
				if ($i++) {
					$out .= "\n\t";
				}
				$out .= "$v CDATA #REQUIRED";
			}
			$out .= ">\n";
		}
	}
	return $self->{dtd} = $out;
}

sub get_dtd_node {
	my ($self, $node, $pointer, $data) = @_;

	my $name;
	if ($node->nodeType == 1) {
		$name = $node->nodeName;
	}
	my @eltxt;
	my $more = 0;
	my $i = 0;
	for my $child ($node->childNodes) {
		my $newpointer = "$pointer:$i";
		$i++;
		$self->get_dtd_node($child, $newpointer, $data);
		next if $child->nodeType != 1;
		my $childname = $child->nodeName;
		push @eltxt, $childname;
		if (not defined $self->{placeholders}
			or not defined $self->{placeholders}{$newpointer}) {
			if (exists $self->{ifs}{$newpointer}) {
				$eltxt[$#eltxt] .= '?';
			}
			next;
		}
		if ($self->{placeholders}{$newpointer}{multiple} eq 'hash') {
			$data->{attributes}{$childname}{
				$self->{placeholders}{$newpointer}{idattr}
				} = 1;
		}

		if ($self->{placeholders}{$newpointer}{multiple} eq 'list'
			or $self->{placeholders}{$newpointer}{multiple} eq 'hash') {
			if (defined $self->{placeholders}{$newpointer}{mandatory}
				and $self->{placeholders}{$newpointer}{mandatory} eq 'yes') {
				$eltxt[$#eltxt] .= '+';
			} else {
				$eltxt[$#eltxt] .= '*';
			}
		} elsif ($self->{placeholders}{$newpointer}{mandatory} ne 'yes') {
			$eltxt[$#eltxt] .= '?';
		}
	}
	if (defined $name) {
		if (not @eltxt) {
			@eltxt = '#PCDATA';
		}
		push @{$data->{elements}{$name}}, \@eltxt;

		for my $attr ($node->attributes) {
			$data->{attributes}{$name}{ $attr->nodeName } = 1;
		}
	}
}

# Style the DOM data (either result of DSD data serialization or plain
# XML input), using list of stylesheets, deriving relative URIs from
# DSD's URI
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
		$style = $stylesheet->{xslt_dom};
		if (not defined $style) {
			my $xslt_parser = $rayapp->{xslt_parser};
			if (not defined $xslt_parser) {
				$xslt_parser = $rayapp->{xslt_parser} = new XML::LibXSLT;
			}
			$style = $stylesheet->{xslt_dom} = eval {
				$xslt_parser->parse_stylesheet($stylesheet->dom)
				};
			if ($@ or not defined $style) {
				$self->{errstr} = $@;
				return;
			}
		}
		$outdom = eval { $style->transform($outdom, @style_params) };
		if ($@) {
			$self->{'errstr'} = $@;
			return;
		}
		if (not defined $outdom) {
			$self->{'errstr'} = "Stylesheet [$stylesheet] returned empty result\n";
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
	}
	return;
}
sub style_string {
	my ($self, $dom, $opts) = (shift, shift, shift);
	$opts->{as_string} = 1;
	return $self->style_dom($dom, $opts, @_);
}

1;

=head1 NAME

RayApp - Framework for data-centric Web applications

=head1 SYNOPSIS

	use RayApp;
	my $rayapp = new RayApp;
	my $dsd = $rayapp->load_dsd('structure.xml');
	print $dsd->serialize_data( $data );

=head1 INTRODUCTION

The B<RayApp> provides a framework for data-centric Web applications.
Instead of writing Perl code that prints HTML, or embedding the code
inside of HTML markup, the Web applications only process and return
Perl data. No markup handling is done in the code of individual
application, inside of the business logic. This reduces the
presentation noise in individual applications, increases
maintainability and speeds development.

The data returned by the application is then serialized to XML and
postprocessed by XSLT to desired output format, which may be HTML,
XHTML, WML or anything else.
In order to provide all parties involved (analysts, application
programmers, Web designers, ...) with a common specification of the
data format, data structure description (DSD) file is a mandatory part
of the applications. The data returned by the Perl code is fitted into
the data structure, creating XML file with agreed-on elements.

This way, application programmers know what data is expected from
their applications and Web designers know what XMLs the
prostprocessing stage will be dealing with, in advance. In addition,
application code can be tested separately from the presentation part,
and tests for both application and presentation part can be written
independently, in parallel.

Of course, the data structure description can change if necessary, it
is not written in stone. Both application programmer and Web designer
can use the old DSD file and regression tests to easily migrate to the
new structure. This change in DSD leads to change in the DOCTYPE of
the resulting XML and is thus easily detected by the external parties.
The system will never produce unexpected data output, since the data
output is based on DSD which is known.

=head1 CONFIGURATION

Most of the use of RayApp approach is expected in the Web context.
This section summarizes configuration steps needed for the Apache
HTTP server.

Assume you have a Web application that should reside on URL

	http://server/sub/app.html

The application consists of three files:

	/cont/www/app.dsd
	/cont/www/app.pl
	/cont/www/app.xsl

Whenever a request for /sub/appl.html comes, the DSD
/cont/www/app.dsd is to be loaded, app.pl executes and the output
serialized to HTML with app.xsl. You will need to configure Apache to
do these steps for you and generate the HTML on the fly.

=head2 Pure mod_perl approach

If you have a mod_perl support in your Apache and want to use it to
run you B<RayApp>-based applications, the following setup will give
you the correct result:

	Alias /sub/ /cont/www/
	<LocationMatch /sub/.*\.(html|xml)$/>
		SetHandler perl-script
		PerlResponseHandler RayApp::mod_perl
	</LocationMatch>

The Alias directive ensures that the DSD and Perl code will be
correctly found in the /cont/www/ directory. The same result can be
achieved by setting B<RAYAPP_DIRECTORY> environment variable without
specifying Alias:

	<LocationMatch /sub/.*\.(html|xml)$/>
		SetEnv RAYAPP_DIRECTORY /cont/www
		SetHandler perl-script
		PerlResponseHandler RayApp::mod_perl
	</LocationMatch>

Make sure that in this case you include all necessary directives here
in the LocationMatch section. Without the Alias, no potential

	<Directory /cont/www/>
	...
	</Directory>

sections will be taken into account.

There are some more environment variables that are recognized by
B<RayApp>:

=over 4

=item RAYAPP_INPUT_MODULE

Specifies name of module whose B<handler> function will be invoked
for each request. It can be used to do any initial setup which is
reasonable to do outside of the code of individual Web applications,
like checking permitted parameters or connecting to database sources. 
The array of return values of this handler will be passed to the
application's B<handler>. That way, the applications can be sure they
will always get their $q, $r, $dbh values populated and ready.

=item RAYAPP_STYLE_PARAMS_MODULE

Specifies name of module whose B<handler> function should return hash
of parameters that will be passed to the XSLT transformations.

=item RAYAPP_ERRORS_IN_BROWSER

When set to true (default is false), any internal parsing, execution
or styling error will be shown in the output page, besides going
to error_log.

=back

=head2 CGI approach

You may not have mod_perl installed on your machine. Or you do not
want to use it in you Apache. In that case, B<RayApp> can be invoked
in CGI manner. With the layout mentioned above, the configuration
will be

	ScriptAliasMatch ^/sub/(.+)\.(html|xml)$ /cont/www/$1.pl
	<Location /sub/>
		SetEnv PERL5OPT -MRayApp::CGIWrapper
	</Location>

Essentially, any request for .html or .xml will be mapped to run
the .pl application, with B<RayApp::CGIWrapper> helper module
providing all the transformations behind the scenes. This layout
assumes that the applications are always next to the DSD files
with the .pl extensions. In addition, the applications have to have
the executable bit set and start with correct #! line.

Alternatively, the B<rayapp_cgi_wrapper> script (included in the
B<RayApp> distribution) can be used to run B<RayApp> applications
in CGI mode with the following configuration:

	ScriptAliasMatch ^/sub/(.+\.(html|xml))$	\
			/usr/bin/rayapp_cgi_wrapper/$1
	<Location /sub/>
		SetEnv RAYAPP_DIRECTORY /cont/www
	</Location>

As with he recipe above, the mod_perl B<RAYAPP_DIRECTORY> has to be
specified to correctly resolve the URI -> file translation. In this
case, the applications can be without the x bit and without the #!
line.

=head2 The applications

Having the Web server set up, you can write your first application
in B<RayApp> manner. For start, a simplistic application which only
returns two values will be enough.

First the DSD file, B</cont/www/app.dsd>:

	<?xml version="1.0"?>
	<root>
		<_param name="name"/>
		<name/>
		<time/>
	</root>

The application will accept one parameter, B<name> and will return
hash with two values, B<name> and B<time>. The code can be

	use CGI;
	sub handler {
		my $q = new CGI;
		return {
			name => $q->param('name'),
			time => time,
		};
	}
	1;

The application returns a hash with two elements. A request for

	http://server/sub/app.xml?name=Peter

should return

	<?xml version="1.0"?>
	<root>
		<name>Peter</name>
		<time>1075057209</time>
	</root>

Adding the B</cont/www/app.xsl> file with XSLT templates should be
easy now.

Of course, you can also run the application on the command line, but
you'll have to use the B<RayApp::CGIWrapper> module, since you
application (B<app.pl>) only defined the B<handler> function, nothing
more:

	$ perl -MCGI=-debug -MRayApp::CGIWrapper app.dsd

The B<-MCGI=-debug> is here to force debuggin input on standard input.

As using CGI and calling

	my $q = new CGI;

in each of your applications is a bit boring, you can create an
initialization module, for example CGIInit.pm:

	package CGIInit;
	use CGI;
	sub handler {
		return (new CGI);
	}
	1;

The application code will change to (app.pl):

	sub handler {
		my $q = shift;
		return {
			name => $q->param('name'),
			time => time,
		};
	}
	1;

and setting RAYAPP_INPUT_MODULE=CGIInit on the command line or
SetEnv RAYAPP_INPUT_MODULE CGIInit in the Apache configuration file
will make sure all B<RayApp> applications' handlers will get the
proper parameters. Database handlers are another targets for this
centralized initialization.

=head1 DATA STRUCTURE DESCRIPTION (DSD)

The data structure description file is a XML file. Its elements either
form the skeleton of the output XML and are copied to the output, or
specify placeholders for application data, or input parameters that
the application accepts.

=head2 Parameters

Parameters are denoted by the B<_param> elements. They take the
following attributes:

=over 4

=item name

Name of the parameter. For example,

	<_param name="id"/>

specifies parameter B<id>.

=item prefix

Prefix of the parameter. All parameters with this prefix will be
allowed. Element

	<_param prefix="search-"/>

allows both B<search-23> and B<search-xx> parameters.

=item multiple

By default, only one parameter of each name is allowed. However,
specifying B<multiple="yes"> makes it possible to call the application
with multiple parameters of the same name:

	<_param name="id" multiple="yes"/>
	application.cgi?id=34;id=45

=item type

A simple type checking is possible. Available types are B<int>,
B<integer> for integer values, B<num> and B<number> for numerical
values, and the default B<string> for generic string values.

Note that the type on parameters should only be used for input data
that will never be directly entered by the user, either for
machine-to-machine communication, or for values in HTML forms that
come from menus or checkboxes. If you need to check that the user
specified their age as a number, use the type string and application
code to retrieve the correct data or return with request for more
correct input.

=back

=head2 Typerefs

Any child element with an attribute B<typeref> is replaced by document
fragment specified by this attribute. Absolute or relative URL is
allowed, with possibly fragment information after a B<#> (hash)
character. For example:

	<root>
		<invoice typeref="invoice.dsd#inv"/>
		<adress typeref="address.xml"/>
	</root>

=head2 Data placeholders

Any child element, element with attributes B<type>, B<multiple> or with
name B<_data> are data placeholders that will have the application
data binded to them. The allowed attributes of placeholders are:

=over 4

=item type

Type of the placeholder. Except the scalar types which are the same as
for input parameters, B<hash> or B<struct> values can be used to denote
nested structure.

=item mandatory

By default, no data needs to be returned by the application for the
placeholder. When set to B<yes>, the value will be required.

=item id

An element can be assigned a unique identification which can be then
referenced by B<typeref> from other parts of the same DSD or from
remote DSD's.

=item multiple

When this attribute is specified, the value is expected to be an
aggregate and either the currect DSD element or its child is repeated
for each value.

=over 4

=item list

An array is expected as the value. The placeholder element
will be repeated.

=item listelement

An array is expected, the child of the placeholder will be repeated
for each of the array's element.

=item hash

An associative array is expected and placeholder element will
be repeated for all values of the array. The key of individual values
will be in an attribute B<id> or in an attribute named in DSD with
attribute B<idattr>.

=item hashelement

The same as B<hash>, except that the child of the placeholder will be
repeated.

=back

=item idattr

Specifies the name of attribute which will hold keys of
individual values for multiple values B<hash> and B<hashelement>,
the default is B<id>.

=item hashorder

Order of elements for values binded using multiple values B<hash> or
B<hashelement>. Possible values are B<num>, B<string>, and
(the default) B<natural>.

=item cdata

When set to yes, the scalar content of this element will be
output as a CDATA section.

=back

=head2 Conditions

The non-placeholder elements can have one of the B<if>, B<ifdef>,
B<ifnot> or B<ifnotdef> attributes that specify a top-level value
(from the data hash) that will be checked for presence or its value.
If the condition is not matched, this element with all its children
will be removed from the output stream.

=head2 Attributes

By default, only the special DSD attributes are allowed. However, with
an attribute B<attrs> a list of space separated attribute names can be
specified. These will be preserved on output.

With attribute B<xattrs>, a rename of attributes is possible. The
value is space separated list of space separated pairs of attribute
names.

=head2 Application name

The root element of the DSD can hold an B<application> attribute with
a URL (file name) of the application which should provide the data for
the DSD.

=head1 DESCRIPTION OF INTERNALS

In the previous parts we have seen how to use B<RayApp> to write Web
applications. Changes are that you will want to use B<RayApp>
serializer in other, non-Web projects. This part describes the
internals of the framework.

=head2 RayApp object

To work with B<RayApp> and to have it process data structure description
files, application data, and presentation transformation, you need
a B<RayApp> object first. Use contructor B<new> to create one:

	use RayApp ();
	my $rayapp = new RayApp;

The constructor takes a couple of optional parameters that affect
B<RayApp>'s behaviour:

=over 4

=item base

The base URI, used for all URI resolutions. By default, the current
directory is used.

=item cache

When set to true value, will cache loaded DSD's and stylesheets.
False by default.

=item ua_options

Options that will be send to B<LWP::UserAgent> constructor. See
B<LWP> documentation for exact list.

=back

A constructor call might look like

	my $rayapp = new RayApp (
		base => 'file:///path/sub/',
		cache => 1,
		ua_options => {
			env_proxy => 1,
			timeout => 30,
			},
	);

Should the B<new> call fail, error message can be found in the
B<$RayApp::errstr> variable.

Once you have the B<RayApp> object, use B<load_dsd> or
B<load_dsd_string> methods to load a document structure description
(DSD). Parameters of these methods are as follows.

=over 4

=item load_dsd

The only parameter is URL of the DSD file. If you specify a relative
URL, it will be resolved relative to the base URI of the B<RayApp>
object.

	my $dsd = $rayapp->load_dsd('invoice.dsd');
	my $dsd = $rayapp->load_dsd('file:///path/to/invoice.dsd');

=item load_dsd_string

For B<load_dsd_string>, the DSD is specified as the sole parameter of
the method call:

	my $dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
		<invoice>
			<num type="int"/>
			<data typeref="invoice_data.dsd"/>
		</invoice>
	')

=back

If the B<load_dsd> or B<load_dsd_string> fails for whatever
reason, it returns undef and the error message can be retrieved
using B<errstr> method of B<RayApp>:

	my $dsd = $ra->load_dsd('data.xml')
		or die $ra->errstr;

On success, these methods give you a B<RayApp::DSD> object that
accepts further method calls. 

=head2 RayApp::DSD object

The incoming parameters of the CGI request can be checked
against the B<_param> specification included in the DSD, using the
B<validate_parameters>. It is designed to seamlessly accept hash
(array) of parameters or a B<CGI> / B<Apache::Request> /
B<Apache::RequestRec> -compatible object, and
fetch the parameters from it. The method returns true when all
parameters match the DSD, false otherwise. On error, B<errstr> method
of the B<RayApp::DSD> object gives the reason.

	my $q = new CGI;
	if (not $dsd->validate_parameters($q)) {
		# ... $dsd->errstr
	}
	
	$dsd->validate_parameters('id' => 1, 'id' => 2,
		'name' => 'PC', 'search' => 'Search')
		or # ...

From the DSD, the document type definition (DTD) can be derived,
providing DOCTYPE of the resulting data. Use method B<get_dtd> to
receive DTD as a string.

	my $dtdstring = $dsd->get_dtd;

The most important action that can be done with a B<RayApp::DSD>
object is serialization of data returned by the application,
according to the DSD. Method B<serialize_data> accepts hash with data
as its first argument, and optionally secont argument with options
driving the serialization. The method returns the output XML string.

	my $xml = $dsd->serialize_data({
		id => 14,
		name => 'Peter'
		});

Alternatively, a method B<serialize_data_dom> can be used which
behaves identically, only returning the DOM instead of the string.
That may be benefitial if the result is immediatelly postprocessed
using Perl tools, saving one parse call.

The supported serialization options are:

=over 4

=item RaiseError

By default it is true (1), resulting in an exception whenever
a serialization error occurs. This behavior may be switched off by
setting the parameter to zero. In that case the result is returned
even if the data did not match the DSD exactly (which may lead to the
output XML not matching its DOCTYPE). Use B<errstr> to verify that the
serialization was without errors.

	my $dom = $dsd->serialize_data_dom({
		people => [ { id => 2, name => 'Bob' },
			{ id => 31, name => 'Alice' } ]
		}, { RaiseError => 0 });
	if ($dsd->errstr) { # ...

=item doctype

This value will be used as a SYSTEM identifier of the DOCTYPE.

=item doctype_ext

The SYSTEM identifier will be derived from the URI of the DSD by
changing extension to this string.

	my $xml = $dsd->serialize_data({}, { doctype_ext => '.dtd' });

The DOCTYPE will be included in the resulting XML only if one of the
B<doctype> or B<doctype_ext> options are used.

=item validate

The resulting XML is serialized to XML and parsed back while being
validated against the DTD derived from the DSD. Set this option to
true to enable this extra safe bahaviour.

	my $dom = $dsd->serialize_data_dom({
		numbers => [ 13.4, 3, 45 ],
		rows => $dbh->selectall_arrayref($sth)
		}, { validate => 1 });

=back

Serialized data (the resulting XML) can be immediatelly postprocessed
with B<serialize_style> or B<serialize_style_dom> methods. They take
the same arguments as B<serialize_data>, but each additional argument
is considered to be a URI of a XSLT stylesheet. The stylesheets will
be applied to the output XML in the order in which they are specified.

	my $html = $dsd->serliaze_style({
		found => { 1 => 'x', 45 => 67 }
		}, { RaiseError => 0 },
		'generic.xslt',
		'finetune.xslt',
		);

In scalar context, the result of the transformations is returned.
In an array context, the result is returned as the first element,
followed by the media type (a.k.a. content type) and encoding
(a.k.a. charset) of the output.

=head2 Executing application handlers

The B<RayApp> object, besides access to the B<load_dsd*> methods,
provides methods of executing application handlers, either using the
B<Apache::Registry> style inside of the calling Perl/mod_perl
environment, or using external CGI scripts.

Method B<execute_application_handler> (and its reusing companion
B<execute_application_handler_reuse>) of B<RayApp> object take 
a single parameter with a file/URL of the Perl handler, or
a B<RayApp::DSD> object. The application code is loaded (or reused)
and a method B<handler> is invoked.
The data then can be passed directly to the B<serialize*> methods
of B<RayApp::DSD> object.

	$dsd = $rayapp->load_dsd($uri);
	my $data = $rayapp->execute_application_handler($dsd);
	# my $data = $rayapp->execute_application_handler('script.pm');
	$dsd->serialize_style($data, {}, 'stylesheet.xsl');

When the B<RayApp::DSD> is passed as an argument, the application name
is derived the standard way, from the B<application> attribute of the
root element of the DSD.

Any additional parameters to B<execute_application*> methods are
passed over to the handler methods of the loaded application.

The application can also be invoked in a separate process, using
B<execute_application_process_storable> method. The data of the
application is then stored using B<RayApp::CGIStorable> module and
transferred back to B<RayApp> using application's standard output
handle.

=head1 SEE ALSO

LWP::UserAgent(3), XML::LibXML(3)

=head1 AUTHOR

Copyright (c) Jan Pazdziora 2001--2004

=head1 VERSION

This documentation is believed to describe accurately B<RayApp>
version 1.146.


