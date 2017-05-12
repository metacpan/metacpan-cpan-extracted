
package RayApp::mod_perl;

use strict;
use warnings FATAL => 'all';

use Apache2::Const qw( OK SERVER_ERROR DECLINED NOT_FOUND :log );
use Apache2::Log ();
use APR::Const    -compile => qw(:error SUCCESS);
use Apache2::RequestIO ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use APR::Table ();
use Apache2::Response ();
use Apache2::URI ();

use RayApp ();
use IO::ScalarArray;
use URI ();

	# #############################################################
	# All the RayApp's actions are driven by the extension
	# (suffix). Supported outputs include:
	#
	#	.xml		Runs application, serializes output
	#	.html		Runs application and then does XSLT
	#			transformation using .xsl (.html.xsl,
	#			.xslt, .html.xslt) stylesheet
	#	.txt		Runs applications and then does XSLT
	#			transformation using .txt.xsl
	#			stylesheet
	#	.fo		Runs applications and then does XSLT
	#			transformation using .fo.xsl
	#	.pdf, .ps	Same as .fo but executes external
	#			command (fop) to get the desired
	#			output
	#
	# Running the application requires finding a .dsd, loading it,
	# running input module which sets environment for the
	# application code, then finding the .mpl (.pl) application
	# file which is supposed to have a handler() function, running
	# it with parameters returned by the input module, and
	# serializing the output of the application (Perl hash) to the
	# DSD forming XML.
	#
	# If however a .xml file is found, it is used instead of
	# fiddling with .dsd and running the .mpl.
	# #############################################################

my $rayapp;
sub handler {

	# This is run as PerlResponseHandler, so the first argument
	# is Apache2::RequestRec

	my $r = shift;

	$rayapp = new RayApp if not defined $rayapp;
	my $caching = $r->dir_config('RayAppCache');
	if (defined $caching
		and $caching ne 'no'
		and $caching ne 'none') {
		$rayapp->cache($caching);
	}

	my ($ext);

	my $uri = $r->uri();		# we just use uri for logging
	my $filename = $r->filename();
	my ($xml, $dom, @params, @stylesheets);

	my %stylesheets_params;

	my ($translate, $translate_source);
	if ($translate = $r->dir_config('RayAppURIProxy')) {
		$translate_source = $r->uri;
	} elsif ($translate = $r->dir_config('RayAppPathInfoProxy')) {
		$translate_source = $r->path_info;
	}
	if (defined $translate) {
		if ($translate_source =~ m!/$!) {
			my $index = $r->dir_config('RayAppDirectoryIndex');
			if (defined $index) {
				$translate_source .= $index;
			}
		}
		my $path_info = $r->path_info;
		my $uri = $r->uri();
		my $location = $r->location();

		# $r->log_error("Kicking in translate [$translate] uri [$uri] filename [$filename] path info [$path_info] location [$location]");

		my $load_uri;
#		if ($path_info eq '') {
#			my $location = $r->location();
#			my $uri = $r->uri();
#			if ($location ne ''
#				and substr($uri, 0, length($location))
#							eq $location) {
#				$load_uri = substr($uri, length($location));
#				$r->log_error(" * changing path_info");
#			}
#		}

		# $r->log_error(" + will translate [$translate_source]");
		my ($left, $right) = split /\s+/, $translate, 2;
		if (not defined $left or not defined $right) {
			$r->content_type('text/plain');
			$r->print("Failed to proxy to backend for [$uri]\n");
			$r->log_error("RayApp::mod_perl: uri [$uri] proxy [$translate] not valid");
			$r->status(Apache2::Const::SERVER_ERROR());
			return Apache2::Const::OK();
		}
		if ($translate_source =~ m!\.([^./]+)$!) {
			$ext = $1;	# this tells us postprocessing type
		}
		my @parens = ($translate_source =~ /$left/);
		$load_uri = $right;
		$load_uri =~ s/(\\.|\$(\d+))/
			if ($1 eq '\$') {
				'\$';
			} elsif ($1 eq '$0') {
				'$0';
			} else {
				$parens[ $2 - 1 ];
			}
			/ge;
		# $r->log_error("   > got [$load_uri]");

		my $request_uri = $r->construct_url;

		$load_uri = URI->new_abs($load_uri, $r->construct_url);

		my %post_opts;
		my $pass_args = $r->dir_config('RayAppProxyParams');
		if (not defined $pass_args or lc($pass_args) eq 'yes') {
			if ($r->method eq 'POST') {
				my $body = '';
				while ($r->read(my $b, 1024)) {
					$body .= $b;
				}
				$post_opts{post_body} = $body;
				$post_opts{post_content_type} = $r->headers_in->{'Content-Type'};
			} else {
				if ($r->args ne '') {
					$load_uri .= '?' . $r->args;
				}
			}
		}
		# $r->log_error("   > constructed base [$request_uri] loading [$load_uri]");
		$r->log_error("RayApp::mod_perl proxy [$uri] to [$load_uri] in pid $$");
		my $authorization = $r->headers_in->{'Authorization'};

		if (not defined $ext or $ext eq 'xml') {
			$xml = $rayapp->load_uri($load_uri,
					method => $r->method,
					want_404 => 1,
					want_401 => 1,
					authorization_header => $authorization,
					%post_opts,
				) or do {
				$r->print("Failed to proxy to backend for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] proxy [$translate] failed: " . $rayapp->errstr);
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			};
		} else {
			$xml = $rayapp->load_xml($load_uri,
					method => $r->method,
					want_404 => 1,
					want_401 => 1,
					frontend_ext => $ext,
					frontend_uri => $request_uri,
					authorization_header => $authorization,
					%post_opts,
				) or do {
				$r->content_type('text/plain');
				$r->print("Failed to proxy to backend for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] proxy [$translate] failed: " . $rayapp->errstr);
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			};
		}
		if (defined $xml->redirect_location) {
			$r->status($xml->status);
			$r->headers_out->{Location} = $xml->redirect_location;
			$r->content_type($xml->content_type);

			$r->print( $xml->content );
			return Apache2::Const::OK();
		}
		if ($xml->status eq '404') {
			# $r->notes->set('error-notes', "Testing");
			$r->log_error("Returning data backend's 404");
			return Apache2::Const::NOT_FOUND();
		}
		if ($xml->status eq '401') {
			# $r->notes->set('error-notes', "Testing");
			$r->log_error("Need to authenticate");
			$r->status($xml->status);
			$r->headers_out->{'WWW-Authenticate'} = $xml->www_authenticate;
			$r->content_type($xml->content_type);

			$r->print( $xml->content );
			return Apache2::Const::OK();
		}
		if ($xml->stylesheet_params) {
			%stylesheets_params = $xml->stylesheet_params;
		}
		@stylesheets = $xml->find_stylesheets($ext);
	}

	else {

		# If the handler was invoked and Alias is in action, we will
		# get the requested file name here.

		if (not defined $filename) {
			# Otherwise we decline because we do not know where
			# the DSD is expected to be.

			# FIXME: we might have some own resolution mechanism
			# though

			return Apache2::Const::DECLINED();
		}

		if ($filename =~ m!/$!) {
			# If the request is for a directory, let's find
			# the DSD that should handle the directory

			# FIXME: shouldn't we always use DirectoryIndex
			# and let Apache do the lookup for us? Probably not
			# since the resouce we look for will not exist.

			my $index = $r->dir_config('RayAppDirectoryIndex');

			if (not defined $index) {
				# We did not find a way to get decent URI

				$r->log_error("No RayAppDirectoryIndex");
				return Apache2::Const::DECLINED();
			}
			$filename .= $index;
			$r->filename($filename);
		}

		if (-f $filename) {
			# If the file exists on the filesystem, we just return
			# it.

			$r->log_error("RayApp::mod_perl: info: serving local file [$filename] for [$uri] in pid $$");
			$r->filename($filename);
			return Apache2::Const::DECLINED();
		}

		my $stripped_filename = $filename;
		$stripped_filename =~ s!\.([^./]+)$!! and $ext = $1;

		my ($dsd_filename, $application);
		if (-f $stripped_filename . '.xml') {
			# We found XML file -- we will use this static file
			# instead of running the application

			$filename = $stripped_filename . '.xml';
			$r->filename($filename);

			$xml = $rayapp->load_xml($filename);
			if (not defined $xml) {
				$r->content_type('text/plain');
				$r->print("Failed to load data for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] filename [$filename] error " . $rayapp->errstr);
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			};
			@stylesheets = $xml->find_stylesheets($ext);
		} else {
			if (defined $ext) {
				$dsd_filename = $stripped_filename . '.dsd';
			} else {
				$dsd_filename = $filename . '.dsd';
			}
			if (not -f $dsd_filename) {
				$r->log_error("RayApp::mod_perl: uri [$uri] filename [$filename] no DSD [$dsd_filename]");
				return Apache2::Const::NOT_FOUND();
			}

			$xml = $rayapp->load_dsd($dsd_filename);
			if (not defined $xml) {
				$r->content_type('text/plain');
				$r->print("Failed to load output specification for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] error " . $rayapp->errstr);
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
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
					$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] no application found");
					return Apache2::Const::NOT_FOUND();
				}
			}
		}
		if (defined $application
			or (@stylesheets
				and $r->dir_config('RayAppStyleStaticParams'))) {

			my $input_module = $r->dir_config('RayAppInputModule');
			if (defined $input_module) {
				my $package = __PACKAGE__;
				my $line = __LINE__;
				$line += 2;
				eval qq!#line $line "$package"\nuse $input_module!;
				if ($@) {
					$r->content_type('text/plain');
					$r->print("Failed to load input module for [$uri]\n");
					$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] input module [$input_module]\n$@");
					$r->status(Apache2::Const::SERVER_ERROR());
					return Apache2::Const::OK();
				}

				my $handler = "${input_module}::handler";
				{
					no strict;
					eval {
						@params = &{ $handler }( $xml, $r );
					};
				}
				if ($@) {
					$r->content_type('text/plain');
					$r->print("Failed to run input module for [$uri]\n");
					$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] input module [$input_module]\n$@");
					$r->status(Apache2::Const::SERVER_ERROR());
					return Apache2::Const::OK();
				}
			}
		}
		
		if (defined $application) {
			my $tied = tied *STDOUT;
			my @stdout_data;
			my $err;
			my $data;

			{
				local *STDOUT;
				# binmode STDOUT, ':bytes';
				tie *STDOUT, 'IO::ScalarArray', \@stdout_data;

				eval {
					$data = $rayapp->execute_application_handler_reuse($application, @params);
				};
				$err = $@ if $@;
				if (defined $tied) {
					tie *STDOUT, $tied;
				} else {
					untie *STDOUT;
				}
			}

			for (@params) {
				if (defined $_
					and ref $_
					and $_->can('rollback')) {
					eval { $_->rollback; };
					last;
				}
			}

			if (defined $err) {
				$r->content_type('text/plain');
				$r->print("Failed to run application for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] application [$application]\n$err");
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			}

			if (not defined $data) {
				$r->content_type('text/plain');
				$r->print("Failed to run application for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] application [$application] returned undef");
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			}

			if (not ref $data) {
				if ($data eq '500') {
					$r->content_type('text/plain');
					$r->print("Failed to run application for [$uri]\n");
					$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] application [$application] returned 500: " . $rayapp->errstr);
					$r->status(Apache2::Const::SERVER_ERROR());
					return Apache2::Const::OK();
				}

				# Handler already sent the response itself
				# using series of prints, we'va caught it in
				# @stdout_data

				$r->status($data);
				$r->headers_out->{'X-RayApp-Status'} = $data;
				$r->send_cgi_header(
					join '', @stdout_data
				);
				return Apache2::Const::OK();
			}
			$dom = $xml->serialize_data_dom($data,
				{
					RaiseError => 0,
				}
			);
			if (not defined $dom
				or defined $xml->errstr) {
				$r->content_type('text/plain');
				$r->print("Failed to serialize output data for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] DSD [$dsd_filename] " . $xml->errstr);
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			}
		}
		@stylesheets = $xml->find_stylesheets($ext);
	}

	if (defined $filename and @stylesheets) {
		for (@stylesheets) {
			my $new_uri = URI->new_abs($_, $filename);
			if (-f $new_uri) {
				$_ = "file:$new_uri";
			}
		}
		# $r->log_error("Translated stylesheets [@stylesheets] in pid $$");
	}

	if ((@stylesheets or $r->headers_in->{'X-RayApp-Frontend-URI'})
		and not defined $dom) {
		$dom = $xml->xmldom;
	}
	if ((@stylesheets or $r->headers_in->{'X-RayApp-Frontend-URI'})
		and not keys %stylesheets_params) {
		my $style_param_module = $r->dir_config('RayAppStyleParamModule');
		if (defined $style_param_module) {
			my $package = __PACKAGE__;
			my $line = __LINE__;
			$line += 2;
			eval qq!#line $line "$package"\nuse $style_param_module!;
			if ($@) {
				$r->content_type('text/plain');
				$r->print("Failed to load style param module for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] style param module [$style_param_module]\n$@");
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			}

			my $handler = "${style_param_module}::handler";
			{
				no strict;
				eval {
					%stylesheets_params = &{ $handler }( $xml, @params );
				};
			}
			if ($@) {
				$r->content_type('text/plain');
				$r->print("Failed to run style param module for [$uri]\n");
				$r->log_error("RayApp::mod_perl: uri [$uri] style param module [$style_param_module]\n$@");
				$r->status(Apache2::Const::SERVER_ERROR());
				return Apache2::Const::OK();
			}
		}
	}
	for (@params) {
		if (defined $_
			and ref $_
			and $_->can('disconnect')) {
			eval { $_->disconnect; };
			last;
		}
	}

	my ($output, $media, $charset);
	if (@stylesheets) {
		($output, $media, $charset) = $xml->style_string($dom,
			{
			style_params => \%stylesheets_params,
			RaiseError => 0,
			},
			@stylesheets,
		);
		if (not defined $output) {
			$r->content_type('text/plain');
			$r->print("Failed to style output for [$uri]\n");
			$r->log_error("RayApp::mod_perl: uri [$uri] filename [$filename] style error " . $xml->errstr);
			$r->status(Apache2::Const::SERVER_ERROR());
			return Apache2::Const::OK();
		}
	} else {
		my $i = 1;
		for my $k (keys %stylesheets_params) {
			my $data = "$k:$stylesheets_params{$k}";
			$data =~ s/([^a-zA-Z0-9])/ sprintf "&#x%x;", ord $1 /ge;
			$r->headers_out->{"X-RayApp-Style-Param-$i"} = $data;
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

	if (defined $ext and $ext eq 'pdf') {
		require File::Temp;
		my $processor = $r->dir_config('RayAppFOProcessor');
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
			$r->print("Failed to generate PDF for [$uri]\n");
			$r->log_error("RayApp::mod_perl: uri [$uri] processor [$processor] should have both %IN and %OUT");
			$r->status(Apache2::Const::SERVER_ERROR());
			return Apache2::Const::OK();
		}
		print { $in } $output;
		$in->close();
		$r->log_rerror(Apache2::Log::LOG_MARK(), Apache2::Const::LOG_INFO(),
			APR::Const::SUCCESS(), "Calling [$processor]");
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
		if (defined $charset
			and ($media ne 'text/xml'
				or not $charset =~ /^utf-?8$/i)) {
			$media .= "; charset=$charset";
		}
		if (not defined $r->headers_out->{'Content-Type'}
			or $r->headers_out->{'Content-Type'} ne $media) {
			$r->content_type($media);
		}
	}
	$r->print($output) if not $r->header_only;
	my $redirect_location = $xml->redirect_location;
	if (defined $redirect_location) {
		$r->status($xml->status);
		$r->err_headers_out->{Location} = $redirect_location;
	}
	return Apache2::Const::OK();
}

1;

