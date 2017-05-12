
package RayApp::CGI;

use strict;

use RayApp ();
use IO::ScalarArray ();

sub print_errors (@) {
	my $err_in_browser = pop;
	if ($err_in_browser) {
		print @_;
	}
	print STDERR @_;
}

sub handler {
	my $uri;

	# The URI can come as an argument on command line ...
	if (@ARGV) {
		$uri = shift @ARGV;
	}

	# ... in PATH_INFO in CGI / rayapp_cgi_wrapper ScriptAlias
	# environment; here RAYAPP_DIRECTORY is needed to do correctly
	# map the request to filesystem
	elsif (defined $ENV{RAYAPP_DIRECTORY}) {
		$uri = $ENV{RAYAPP_DIRECTORY};
		$uri .= $ENV{PATH_INFO} if defined $ENV{PATH_INFO};
		$ENV{SCRIPT_NAME} = $ENV{REQUEST_URI};
		delete $ENV{PATH_INFO};
		$ENV{PATH_TRANSLATED} = $uri;
	}

	# ... maybe even PATH_TRANSLATED would work
	elsif (defined $ENV{PATH_TRANSLATED}) {
		$uri = $ENV{PATH_TRANSLATED};
	}

	# ... or the URI is specified as $0, by running the .pl script
	else {
		$uri = $0;
		if ($uri =~ s/\.(mpl|pl)$//) {
			for my $ext ('.dsd') {
				if (-f $uri . $ext) {
					$uri .= $ext;
					last;
				}
			}
		}
	}

	# If the URI is a directory, we shall use RAYAPP_DIRECTORY_INDEX
	# to find the application
        if ($uri =~ m!/$! and defined $ENV{RAYAPP_DIRECTORY_INDEX}) {
                $uri .= $ENV{RAYAPP_DIRECTORY_INDEX};
        }


	my $err_in_browser = ( defined $ENV{'RAYAPP_ERRORS_IN_BROWSER'}
		and $ENV{'RAYAPP_ERRORS_IN_BROWSER'} );

	if (-f $uri) {
		local *FILE;
		open FILE, $uri or do {
			print "Status: 404\nContent-Type: text/plain\n\n";
			print_errors "Error reading [$uri]: $!\n", $err_in_browser;
			exit;
		};
		local $/ = undef;
		print "Status: 200\n";
		if ($uri =~ /\.html$/) {
			print "Content-Type: text/html\n\n";
		} elsif ($uri =~ /\.xml$/) {
			print "Content-Type: text/xml\n\n";
		}
		print <FILE>;
		close FILE;
		exit;
	}

	my $rayapp = new RayApp;

	my ($type, $dsd, $data, @stylesheets, @style_params);
	my $stripped_uri = $uri;
	$stripped_uri =~ s/\.(xml|html|txt|pdf|fo)$// and $type = $1;

	if ($type ne 'xml') {
		@stylesheets = $rayapp->find_stylesheet($stripped_uri, $type);
	}

	if (-f $stripped_uri . '.xml') {
		$uri = $stripped_uri . '.xml';
		$dsd = $rayapp->load_uri($uri) or do {
			print "Status: 500\nContent-Type: text/plain\n\n";
                        print "Broken RayApp setup, XML not available, sorry.\n";
                        print_errors "Reading XML [$uri] failed: ",
                                $rayapp->errstr, "\n", $err_in_browser;
                        exit;
                };
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
				print "Status: 404\nContent-Type: text/plain\n\n";
				print "The requested URL was not found on this server.\n";
			} else {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to load DSD, sorry.\n";
				print_errors "Loading DSD [$uri] failed: ",
					$rayapp->errstr, "\n", $err_in_browser;
			}
			exit;
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
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to find application, sorry.\n";
				exit;
			}
		}
		my @params;
		if (defined $ENV{'RAYAPP_INPUT_MODULE'}) {
			eval "use $ENV{'RAYAPP_INPUT_MODULE'};";
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to load input module, sorry.\n";
				print_errors "Error loading [$ENV{'RAYAPP_INPUT_MODULE'}]\n",
					$@, $err_in_browser;
				exit;	
			}

			my $handler = "$ENV{'RAYAPP_INPUT_MODULE'}::handler";
			{
			no strict;
			eval { @params = &{ $handler }($dsd); };
			}
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to run input module, sorry.\n";
				print_errors "Error executing [$ENV{'RAYAPP_INPUT_MODULE'}]\n",
					$@, $err_in_browser;
				exit;	
			}
		}
		if (@stylesheets
			and defined $ENV{'RAYAPP_STYLE_PARAMS_MODULE'}) {
			eval "use $ENV{'RAYAPP_STYLE_PARAMS_MODULE'};";
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to load style params module, sorry.\n";
				print_errors "Error loading [$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}]\n",
					$@, $err_in_browser;
				exit;	
			}

			my $handler = "$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}::handler";
			{
			no strict;
			eval { @style_params = &{ $handler }($dsd, @params); };
			}
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to run style params module, sorry.\n";
				print_errors "Error executing [$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}]\n",
					$@, $err_in_browser;
				exit;	
			}
		}

		my @stdout;
		tie *STDOUT, "IO::ScalarArray", \@stdout;
		eval { $data = $rayapp->execute_application_cgi($application, @params) };
		untie *STDOUT;
                for (@params) {
                        if (defined $_ and ref $_ and $_->can('disconnect')) {
                                eval { $_->rollback; };
                                eval { $_->disconnect; };
                        }
                }

		if ($@) {
			print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to run the application, sorry.\n";
			print_errors "Error executing [$application]\n",
				$@, $err_in_browser;
			exit;
		}

		if (not ref $data and $data eq '500') {
			print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to run the application, sorry.\n";
			print_errors "Error executing [$application]\n",
				$rayapp->errstr, $err_in_browser;
			exit;	
		}

		if (not ref $data) {
			print "Status: $data\n";
			print @stdout;
			exit;
		}
	}

	if ($type eq 'xml') {
		my $output;
		if (not defined $data) {
                        $output = $dsd->content;
		} else {
			$output = $dsd->serialize_data($data, { RaiseError => 0 });
			if ($dsd->errstr) {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, data serialization failed, sorry.\n";
				print_errors "Serialization failed for [$0]: ",
					$dsd->errstr, "\n", $err_in_browser;
				exit;
			}
			print "Pragma: no-cache\nCache-control: no-cache\n";
		}
		print "Status: 200\n";
		print "Content-Type: text/xml\n\n", $output;
	} elsif (not @stylesheets) {
		print "Status: 404\n";
		print "Content-Type: text/plain\n\nNot found";
	} else {
		my ($output, $media, $charset) = $dsd->serialize_style($data,
			{
				( scalar(@style_params)
					? ( style_params => \@style_params )
					: () ),
			RaiseError => 0,
			},
			@stylesheets);

		if ($dsd->errstr or not defined $output) {
			print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, failed to serialize and style your data, sorry.\n";
			print_errors
				"Serialization and styling failed for [$0]: ",
				$dsd->errstr, "\n", $err_in_browser;
			exit;
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
				UNLINK => 0,
				);
			my $out = new File::Temp(
				TEMPLATE => 'rayappXXXXXX',
				SUFFIX => '.pdf',
				DIR => '/tmp',
				UNLINK => 0,
				);
			unless ($processor =~ s/%IN/ $in->filename() /ge
				and $processor =~ s/%OUT/ $out->filename() /ge) {
				print "Status: 500\nContent-Type: text/plain\n\nBroken RayApp setup, PDF generation failed, sorry.\n";
				print_errors "Processor line [$processor] has to have both %IN and %OUT\n", $err_in_browser;
				exit;
			}
			print { $in } $output;
			$in->close();
			print STDERR "Calling [$processor]\n";
			system($processor);
			local $/ = undef;
			$output = '';
			while ($out->sysread($output, 4096, length($output))) {}
			$media = 'application/pdf';
			$charset = undef;
		}
		if (defined $media) {
			print "Pragma: no-cache\nCache-control: no-cache\n"
				if $type ne 'pdf';
			if (defined $charset) {
				$media .= "; charset=$charset";
			}
			print "Status: 200\n";
			print "Content-Type: $media\n\n";
		} else {
			print "Status: 200\n";
		}
		print $output;
		exit;
	}
	exit;
}

1;

