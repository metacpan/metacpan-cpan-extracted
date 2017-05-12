
package RayApp::mod_perl_Storable;

use RayApp ();
use Apache::Response ();
use Apache::RequestRec ();
use Apache::Const -compile => qw(OK SERVER_ERROR DECLINED NOT_FOUND);
use APR::Table ();
use Apache::RequestIO ();

use Config;
use Storable ();
use Apache::SubProcess ();
use strict;
                                                                                
sub print_errors (@) {
	my $err_in_browser = pop;
	if ($err_in_browser) {
		print @_;
	}
	print STDERR @_;
}

my $rayapp;
sub handler {
	my $r = shift;

	my $uri;
        if (defined $ENV{RAYAPP_DIRECTORY}) {
                $uri = $ENV{RAYAPP_DIRECTORY};
                $uri .= $ENV{PATH_INFO} if defined $ENV{PATH_INFO};
                $ENV{SCRIPT_NAME} = $ENV{REQUEST_URI};
                delete $ENV{PATH_INFO};
                $ENV{PATH_TRANSLATED} = $uri;
        } else {
		$uri = $r->filename();
	}

	if (($uri =~ m!/$!
		or -d $uri) and defined $ENV{'RAYAPP_DIRECTORY_INDEX'}) {
		$uri .= '/' unless $uri =~ m!/$!;
		$uri .= $ENV{'RAYAPP_DIRECTORY_INDEX'};
	}

        if ($uri =~ /\.html$/ and -f $uri) {
                $r->filename($uri);
                return Apache::DECLINED;
        }

	my $err_in_browser = ( defined $ENV{'RAYAPP_ERRORS_IN_BROWSER'}
		and $ENV{'RAYAPP_ERRORS_IN_BROWSER'} );

	$rayapp = new RayApp( 'cache' => 1 ) if not defined $rayapp;

	my ($type, $dsd, $data, @stylesheets, @style_params);
	my $stripped_uri = $uri;
	$stripped_uri =~ s/\.(xml|html|txt|pdf|fo)$// and $type = $1;

	if ($type eq 'html'
		and defined $ENV{'RAYAPP_HTML_STYLESHEETS'}) {
		@stylesheets = split /:/, $ENV{'RAYAPP_HTML_STYLESHEETS'};
	} elsif ($type eq 'txt'
		and defined $ENV{'RAYAPP_TXT_STYLESHEETS'}) {
		@stylesheets = split /:/, $ENV{'RAYAPP_TXT_STYLESHEETS'};
	} elsif (($type eq 'pdf' or $type eq 'fo')
		and defined $ENV{'RAYAPP_FO_STYLESHEETS'}) {
		@stylesheets = split /:/, $ENV{'RAYAPP_FO_STYLESHEETS'};
	}
	if ($type ne 'xml' and not @stylesheets) {
		my $styleuri = $uri;
		$styleuri =~ s/\.[^\.]+$//;
		@stylesheets = RayApp::find_stylesheet($styleuri, $type);
	}

        if (-f $stripped_uri . '.xml') {
		$uri = $stripped_uri . '.xml';
                $r->filename($uri);
                $dsd = $rayapp->load_xml($uri) or do {
                        $r->content_type('text/plain');
                        $r->print("Broken RayApp setup, XML not available, sorry.\n");
                        print_errors "Reading XML [$uri] failed: ",
                                $rayapp->errstr, "\n", $err_in_browser;
                        return Apache::SERVER_ERROR;
                };
		if ($type ne 'xml') {
			bless $dsd, 'RayApp::DSD';
		}
	} else {
		if ($uri =~ s/\.(xml|html|txt|pdf|fo)$//) {
			$type = $1;
			for my $ext ('.dsd') {
				if (-f $uri . $ext) {
					$uri .= $ext;
					last;
				}
			}
			
		}

		$dsd = $rayapp->load_dsd($uri);
		if (not defined $dsd) {
			if (not -f $uri) {
				return Apache::NOT_FOUND;
			}
			$r->content_type('text/plain');
			$r->print("Broken RayApp setup, failed to load DSD, sorry.\n");
			print_errors "Loading DSD [$uri] failed: ",
				$rayapp->errstr, "\n", $err_in_browser;
			return Apache::SERVER_ERROR;
		}
		my $application = $dsd->application_name;
		if (not defined $application) {
			my $appuri = $uri;
			$appuri =~ s/\.[^\.]+$//;
			my $ok = 0;
			for my $ext ('.pl', '.mpl', '.xpl') {
				if (-f $appuri . $ext) {
					$application = $appuri . $ext;
					$ok = 1;
					last;
				}
			}
			if (not $ok) {
				$r->content_type('text/plain');
				print "Broken RayApp setup, failed to find application, sorry.\n";
				return Apache::SERVER_ERROR;
			}
		}

		eval {
			my $in_data = '';
			my $tmp;
			while ($r->read($tmp, 1024)) {
				$in_data .= $tmp;
			}
			my ($in_fh, $out_fh, $err_fh) = $r->spawn_proc_prog($Config{perlpath}, [ '-MRayApp::CGIStorable', $application, $dsd->{uri} ]);
			my $headers_in = $r->headers_in;
			my $content_type_in = $headers_in->{'Content-Type'};
			if (defined $content_type_in
				and ($content_type_in =~ m!^application/x-www-form-urlencoded!
					or $content_type_in =~ m!^multipart/form-data!)) {
				$ENV{CONTENT_TYPE} = $content_type_in;
			}
			$ENV{CONTENT_LENGTH} = $headers_in->{'Content-Length'};
			$ENV{REQUEST_METHOD} = $r->method;
			print $in_fh $in_data;
			close $in_fh;
			my ($value, $err_value);

			if ( $Config{useperlio} ) {
				$value = join '', <$out_fh>;
				$err_value = join '', <$err_fh>;
			} else {
				my $its_err = 0;
				while ( IO::Select->new($out_fh)->can_read(10)
					or ((($its_err = 1) == 1)
						and IO::Select->new($err_fh)->can_read(10) ) ) {
					if ($its_err) {
						$err_value .= <$err_fh>;
					} else {
						$value .= <$out_fh>;
					}
					$its_err = 0;
				}
			}
			close $out_fh;
			close $err_fh;
			print STDERR "Error: ", $err_value if defined $err_value and $err_value ne '';
			if ($value =~ s!^Content-Type: application/x-perl-storable.*\n\n!!s) {
				$data = Storable::thaw($value);
			} else {
				$data = $value;
			}
		};
		# eval { $data = $rayapp->execute_application_process_storable($application, $dsd->{'uri'}) };
		if ($@) {
			$r->content_type('text/plain');
			print "Broken RayApp setup, failed to run the application, sorry.\n";
			print_errors "Error executing [$application]\n",
				$@, $err_in_browser;
			return Apache::SERVER_ERROR;
		}

		if (not ref $data and $data eq '500') {
			$r->content_type('text/plain');
			print "Broken RayApp setup, failed to run the application, sorry.\n";
			print_errors "Error executing [$application]\n",
				$rayapp->errstr, $err_in_browser;
			return Apache::SERVER_ERROR;
		}

		if (not ref $data) {
			# handler already sent the response itself
			$r->send_cgi_header($data);
			return Apache::OK;
		}

		if (ref $data eq 'ARRAY') {
			@style_params = [ @{ $data }[ 1 .. $#$data ] ];
			$data = $data->[0];
		}
	}

	if (not @stylesheets) {
		my $output;
		if (ref $dsd eq 'HASH') {
			$output = $dsd->{content};
		} else {
 			$output = $dsd->serialize_data($data, { RaiseError => 0 });
			if ($dsd->errstr) {
				$r->content_type('text/plain');
				print "Broken RayApp setup, data serialization failed, sorry.\n";
				print_errors "Serialization failed for [$0]: ",
					$dsd->errstr, "\n", $err_in_browser;
				return Apache::SERVER_ERROR;
			}
                        $r->headers_out->{'Pragma'} = 'no-cache';
                        $r->headers_out->{'Cache-control'} = 'no-cache';
		}
		$r->content_type('text/xml');

		$r->print($output) unless $r->header_only;
		return Apache::OK;
	} else {
		my ($output, $media, $charset) = $dsd->serialize_style($data,
			{
				'rayapp' => $rayapp,
				( scalar(@style_params)
					? ( style_params => \@style_params )
					: () ),
				RaiseError => 0,
			},
			@stylesheets);

		if ($dsd->errstr or not defined $output) {
			$r->content_type('text/plain');
			print "Broken RayApp setup, failed to serialize and style your data, sorry.\n";
			print_errors
				"Serialization and styling failed for [$0]: ",
				$dsd->errstr, "\n", $err_in_browser;
			return Apache::SERVER_ERROR;
		}
		if (defined $media) {
			if (defined $charset) {
				$media .= "; charset=$charset";
			}
			$r->content_type($media);
		}
		print $output;
		return Apache::OK;
	}
	return Apache::SERVER_ERROR;
}

1;

