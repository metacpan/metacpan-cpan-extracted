
package RayApp::mod_perl;

use RayApp ();
use Apache::Response ();
use Apache::RequestRec ();
use Apache::Const -compile => qw(OK SERVER_ERROR DECLINED NOT_FOUND);
use APR::Table ();
use Apache::RequestIO ();

use IO::ScalarArray ();
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

	my $uri = $r->filename();

	if ($uri =~ m!/$! and defined $ENV{'RAYAPP_DIRECTORY_INDEX'}) {
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
				$r->print("Broken RayApp setup, failed to find application, sorry.\n");
				return Apache::SERVER_ERROR;
			}
		}
		my @params;
		if (defined $ENV{'RAYAPP_INPUT_MODULE'}) {
			eval "use $ENV{'RAYAPP_INPUT_MODULE'};";
			if ($@) {
				$r->content_type('text/plain');
				$r->print("Broken RayApp setup, failed to load input module, sorry.\n");
				print_errors "Error loading [$ENV{'RAYAPP_INPUT_MODULE'}]\n",
					$@, $err_in_browser;
				return Apache::SERVER_ERROR;
			}

			my $handler = "$ENV{'RAYAPP_INPUT_MODULE'}::handler";
			{
			no strict;
			eval { @params = &{ $handler }($dsd, $r); };
			}
			if ($@) {
				$r->content_type('text/plain');
				$r->print("Broken RayApp setup, failed to run input module, sorry.\n");
				print_errors "Error executing [$ENV{'RAYAPP_INPUT_MODULE'}]\n",
					$@, $err_in_browser;
				return Apache::SERVER_ERROR;
			}
		}
		if (defined $ENV{'RAYAPP_STYLE_PARAMS_MODULE'}) {
			eval "use $ENV{'RAYAPP_STYLE_PARAMS_MODULE'};";
			if ($@) {
				$r->content_type('text/plain');
				$r->print("Broken RayApp setup, failed to load style params module, sorry.\n");
				print_errors "Error loading [$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}]\n",
					$@, $err_in_browser;
				return Apache::SERVER_ERROR;
			}

			my $handler = "$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}::handler";
			{
			no strict;
			eval { @style_params = &{ $handler }($dsd, @params); };
			}
			if ($@) {
				$r->content_type('text/plain');
				$r->print("Broken RayApp setup, failed to run style params module, sorry.\n");
				print_errors "Error executing [$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}]\n",
					$@, $err_in_browser;
				return Apache::SERVER_ERROR;
			}
		}

		my $tied = tied *STDOUT;
		my @stdout_data;
		my $err;

		{
			local *STDOUT;
			binmode STDOUT, ':bytes';
			tie *STDOUT, 'IO::ScalarArray', \@stdout_data;

			eval { $data = $rayapp->execute_application_handler_reuse($application, @params) };
			$err = $@;
			if ($tied) {
				tie *STDOUT, $tied;
			} else {
				untie *STDOUT;
			}
		}
		for (@params) {
			if (defined $_ and ref $_ and $_->can('disconnect')) {
				eval { $_->rollback; };
				eval { $_->disconnect; };
			}
		}
		if ($err) {
			$r->content_type('text/plain');
			$r->print("Broken RayApp setup, failed to run the application, sorry.\n");
			print_errors "Error executing [$application]\n",
				$err, $err_in_browser;
			return Apache::SERVER_ERROR;
		}

		if (not ref $data and $data eq '500') {
			$r->content_type('text/plain');
			$r->print("Broken RayApp setup, failed to run the application, sorry.\n");
			print_errors "Error executing [$application]\n",
				$rayapp->errstr, $err_in_browser;
			return Apache::SERVER_ERROR;
		}

		if (not ref $data) {
			# handler already sent the response itself, we've got it
			# in @stdout_data
			$r->status($data);
			$r->send_cgi_header(join '', @stdout_data);
			return Apache::OK;
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
				$r->print("Broken RayApp setup, data serialization failed, sorry.\n");
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
			$r->print("Broken RayApp setup, failed to serialize and style your data, sorry.\n");
			print_errors
				"Serialization and styling failed for [$0]: ",
				$dsd->errstr, "\n", $err_in_browser;
			return Apache::SERVER_ERROR;
		}
		if ($type eq 'pdf') {
			require File::Temp;
			my $processor = $ENV{'RAYAPP_FO_PROCESSOR'};
			if (not defined $processor) {
				$processor = 'fop %IN -pdf %OUT';
			}
			my $in = new File::Temp(
				TEMPLATE => 'rayappXXXXXX',
				SUFFIX => '.fo',
				DIR => '/tmp',
				);
			my $out = new File::Temp(
				TEMPLATE => 'rayappXXXXXX',
				SUFFIX => '.pdf',
				DIR => '/tmp',
				);
			unless ($processor =~ s/%IN/ $in->filename() /ge
				and $processor =~ s/%OUT/ $out->filename() /ge) {
				$r->content_type('text/plain');
				$r->print("Broken RayApp setup, PDF generation failed, sorry.\n");
				print_errors "Processor line [$processor] has to have both %IN and %OUT\n", $err_in_browser;
				return Apache::SERVER_ERROR;
			}
			print { $in } $output;
			$in->close();
			print STDERR "Calling [$processor]\n";
			system($processor);
			local $/ = undef;
			$output = < $out >;
			$media = 'application/pdf';
			$charset = undef;
		} else {
			$r->headers_out->{'Pragma'} = 'no-cache';
			$r->headers_out->{'Cache-control'} = 'no-cache';
		}
		if (defined $media) {
			if (defined $charset) {
				$media .= "; charset=$charset";
			}

			if ($r->headers_out->{'Content-Type'} ne $media) {
				$r->content_type($media);
			}
		}
		$r->print($output) unless $r->header_only;
		return Apache::OK;
	}
	return Apache::SERVER_ERROR;
}

1;

