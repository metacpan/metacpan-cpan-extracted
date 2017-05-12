
package RayApp::CGI;

use strict;
use warnings;

use RayApp ();
use IO::ScalarArray ();

sub handler {
	my ($filename, $uri);
	# print STDERR "request_uri [$ENV{REQUEST_URI}]\n";
	# print STDERR "script_name [$ENV{SCRIPT_NAME}]\n";
	# print STDERR "path_info [$ENV{PATH_INFO}]\n";
	# print STDERR "path_translated [$ENV{PATH_TRANSLATED}]\n";

	# The URI can come as an argument on command line ...
	if (@ARGV) {
		$filename = shift @ARGV;
		$uri = "file:$filename";
	}

	# ... in PATH_INFO in CGI / rayapp_cgi_wrapper ScriptAlias
	# environment; here RAYAPP_DIRECTORY is needed to correctly
	# map the request to filesystem
	elsif (defined $ENV{RAYAPP_DIRECTORY}) {
		$filename = $ENV{RAYAPP_DIRECTORY};
		$filename .= $ENV{PATH_INFO} if defined $ENV{PATH_INFO};
		# $ENV{SCRIPT_NAME} = $ENV{REQUEST_URI};
		$uri = $ENV{REQUEST_URI};
		delete $ENV{PATH_INFO};
		$ENV{PATH_TRANSLATED} = $filename;

		# If we got to directory but the request was not for
		# directory, redirect
		if (-d $filename
			and $ENV{REQUEST_URI} =~ m!(.*?(.))(\?|$)(.*)!
			and $2 ne '/') {
			# print STDERR "301 Location: [$1/$3$4]\n";
			print "Status: 301\nLocation: $1/$3$4\n\n";
			exit;
		}
	}

	# ... maybe even PATH_TRANSLATED would work
	elsif (defined $ENV{PATH_TRANSLATED}) {
		$filename = $ENV{PATH_TRANSLATED};
		$uri = "file:$filename";
	}

	# ... or the URI is specified as $0, by running the .pl script
	else {
		$filename = $0;
		$uri = "file:$filename";
	}

	local $0 = "$0 uri [$uri] filename [$filename]";

	# print STDERR "Filename [$filename]\n";

	# If the URI is a directory, we shall use RAYAPP_DIRECTORY_INDEX
	# to find the application
        if ($filename =~ m!/$! and defined $ENV{RAYAPP_DIRECTORY_INDEX}) {
                $filename .= $ENV{RAYAPP_DIRECTORY_INDEX};
        }


	if (-f $filename) {
		# If the file exists on the filesystem, we just return
		# it
		local *FILE;
		open FILE, $filename or do {
			print "Status: 403\nContent-Type: text/plain\n\n";
			print "Failed to load data for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] error $!\n";
			exit;
		};
		# print STDERR "RayApp::CGI: serving local file [$filename]\n";
		local $/ = undef;
		print "Status: 200\n";
		if ($filename =~ /\.html$/) {
			print "Content-Type: text/html\n\n";
		} elsif ($filename =~ /\.xml$/) {
			print "Content-Type: text/xml\n\n";
		} else {
			print "\n";
		}
		print <FILE>;
		close FILE;
		exit;
	}

	my $rayapp = new RayApp;

	my $stripped_filename = $filename;
	my $ext;
	$stripped_filename =~ s!\.([^./]+)$!! and $ext = $1;

	my ($xml, $dom, $dsd_filename, $application, @params, @stylesheets);
	if (-f $stripped_filename . '.xml') {

		$filename = $stripped_filename . '.xml';
		$xml = $rayapp->load_xml($filename) or do {
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed to load data for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] error ", $rayapp->errstr, "\n";
                        exit;
                };
		$dom = $xml->xmldom;
		@stylesheets = $xml->find_stylesheets($ext);
	} else {

		if (defined $ext) {
			$dsd_filename = $stripped_filename . '.dsd';
		} else {
			$dsd_filename = $filename . '.dsd';
		}
		if (not -f $dsd_filename) {
			print "Status: 404\nContent-Type: text/plain\n\n";
			# print "Failed to load output specification for [$uri]\n";
			print "The requested URL was not found on this server.\n";
			print STDERR "RayApp::CGI: filename [$filename] no DSD found\n";
                        exit;
		}

		$xml = $rayapp->load_dsd($dsd_filename);
		if (not defined $xml) {
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed to load output specification for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] error ", $rayapp->errstr, "\n";
                        exit;
		}

		$application = $xml->application_name;
		if (not defined $application) {
			for ('.mpl', '.pl') {
				if (-f $stripped_filename . $_) {
					$application = $stripped_filename . $_;
					last;
				}
			}
			if (not defined $application) {
				print "Status: 404\nContent-Type: text/plain\n\n";
				print "Failed to load output specification for [$uri]\n";
				print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] no application found\n";
				exit;
			}
		}
	}
	if (defined $application
		or (@stylesheets and $ENV{'RAYAPP_STYLE_STATIC_PARAMS'})) {
		my $input_module = $ENV{'RAYAPP_INPUT_MODULE'};
		if (defined $input_module) {
			my $package = __PACKAGE__;
			my $line = __LINE__;
			$line += 2;
			eval qq!#line $line "$package"\nuse $input_module;!;
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\n";
				print "Failed to load input module for [$uri]\n";
				$@ =~ s/\n+$//; $@ =~ s/(^|\n)/$1  /g;
				print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] failed to load input module [$input_module]:\n$@\n";
				exit;
			}

			my $handler = "${input_module}::handler";
			{
				no strict;
				eval { @params = &{ $handler }(
					( defined $application ? $xml : () )
				); };
			}
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\n";
				print "Failed to run input module for [$uri]\n";
				$@ =~ s/\n+$//; $@ =~ s/(^|\n)/$1  /g;
				print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] failed to run input module [$input_module]:\n$@\n";
				exit;	
			}
		}
	}
	if ($application) {
		my @stdout_data;
		my $err;
		my $data;

		{
			local *STDOUT;
			# binmode STDOUT, ':bytes';
			tie *STDOUT, 'IO::ScalarArray', \@stdout_data;
			eval {
				$data = $rayapp->execute_application_cgi($application, @params)
			};
			$err = $@ if $@;
			untie *STDOUT;
		}

                for (@params) {
                        if (defined $_
				and ref $_
				and $_->can('rollback')) {
                                eval { $_->rollback; };
                        }
                }

		if (defined $err) {
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed to run application for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] application [$application]\n$err\n";
			exit;
		}

		if (not defined $data) {
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed to run application for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] application [$application] returned undef\n";
			exit;
		}

		if (not ref $data) {
			if ($data eq '500') {
				print "Status: 500\nContent-Type: text/plain\n\n";
				print "Failed to run application for [$uri]\n";
				print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] application [$application] returned 500: ", $rayapp->errstr, "\n";
				exit;	
			}

			print "Status: $data\n";
			print @stdout_data;
			exit;
		}

		$dom = $xml->serialize_data_dom($data,
			{
				RaiseError => 0,
			},
		);
		if (not defined $dom
			or defined $xml->errstr) {
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed serialize output data for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] DSD [$dsd_filename] ", $xml->errstr, "\n";
			exit;	
		}
		@stylesheets = $xml->find_stylesheets($ext);
	}

	my %stylesheets_params;
	if (@stylesheets
		or defined $ENV{'HTTP_X_RAYAPP_FRONTEND_URI'}) {
		my $style_param_module = $ENV{'RAYAPP_STYLE_PARAM_MODULE'};
		if (defined $style_param_module) {
			my $package = __PACKAGE__;
			my $line = __LINE__;
			$line += 2;
			eval qq!#line $line "$package"\nuse $style_param_module;!;
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\n";
				print "Failed to load style param module for [$uri]\n";
				$@ =~ s/\n+$//; $@ =~ s/(^|\n)/$1  /g;
				print STDERR "RayApp::CGI: filename [$filename] failed to load style param module [$style_param_module]:\n$@\n";
				exit;	
			}

			my $handler = "${style_param_module}::handler";
			{
				no strict;
				eval {
					%stylesheets_params = &{ $handler }($xml, @params);
				};
			}
			if ($@) {
				print "Status: 500\nContent-Type: text/plain\n\n";
				print "Failed to run style param module for [$uri]\n";
				$@ =~ s/\n+$//; $@ =~ s/(^|\n)/$1  /g;
				print STDERR "RayApp::CGI: filename [$filename] failed to run style param module [$style_param_module]:\n$@\n";
				exit;	
			}
		}
	}
	for (@params) {
		if (defined $_
			and ref $_
			and $_->can('disconnect')) {
			eval { $_->disconnect; };
		}
	}

	my ($output, $media, $charset, @headers_out);
	if (@stylesheets) {
		($output, $media, $charset) = $xml->style_string($dom,
			{
				style_params => \%stylesheets_params,
				RaiseError => 0,
			},
			@stylesheets,
		);
		if (not defined $output) {
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed to style output for [$uri]\n";
			my $error = $xml->errstr;
			$error =~ s/\n+$//;
			print STDERR "RayApp::CGI: filename [$filename] style error:\n$error\n";
			exit;	
		}
	} else {
		my $i = 1;
		for my $k (keys %stylesheets_params) {
			next if not defined $stylesheets_params{$k};
			my $data = "$k:$stylesheets_params{$k}";
			$data =~ s/([^a-zA-Z0-9])/ sprintf "&#x%x;", ord $1 /ge;
			push @headers_out, "X-RayApp-Style-Param-$i: $data\n";
			$i++;
		}
                if (defined $dom) {
                        $output = $dom->toString;
                        $media = 'text/xml';
                        $charset = $dom->encoding;
                } else {
                        $output = $xml->content;
                        $media = $xml->content_type;
                }

	}

	if ($ext eq 'pdf') {
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
			print "Status: 500\nContent-Type: text/plain\n\n";
			print "Failed to generate PDF for [$uri]\n";
			print STDERR "RayApp::CGI: filename [$filename] processor [$processor] should have both %IN and %OUT\n";
			exit;	
		}

		print { $in } $output;
		$in->close();
		print STDERR "RayApp::CGI: Calling [$processor]\n";
		system($processor);
		local $/ = undef;
		$output = '';
		while ($out->sysread($output, 4096, length($output))) {}
		$media = 'application/pdf';
		$charset = undef;
	}
	if (defined $media) {
		print "Pragma: no-cache\nCache-control: no-cache\n"
			if $ext ne 'pdf';
		if (defined $charset
			and ($media ne 'text/xml'
				or not $charset =~ /^utf-?8$/i)) {
			$media .= "; charset=$charset";
		}
		print "Status: 200\n";
		print "Content-Type: $media\n";
	} else {
		print "Status: 200\n";
	}
	no warnings 'utf8';
	print @headers_out;
	print "\n", $output;
	exit;
}

1;

