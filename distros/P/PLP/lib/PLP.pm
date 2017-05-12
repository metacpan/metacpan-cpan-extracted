package PLP;

use 5.006;

use PLP::Functions ();
use PLP::Fields;
use PLP::Tie::Headers;
use PLP::Tie::Delay;
use PLP::Tie::Print;

use File::Basename ();
use File::Spec;

use strict;
use warnings;

our $VERSION = '3.23';

# Subs in this package:
#  _default_error($plain, $html)    Default error handler
#  clean                            Reset variables
#  error($error, $type)             Handle errors
#  everything                       Do everything: CGI
#  handler($r)                      Do everything: mod_perl
#  sendheaders                      Send headers
#  source($path, $level, $linespec) Read and parse .plp files
#  start                            Start the initialized PLP script

# The _init subs do the following:
#  Set $PLP::code to the initial code
#  Set $ENV{PLP_*} and make PATH_INFO if needed
#  Change the CWD

# This gets referenced as the initial $PLP::ERROR
sub _default_error {
	my ($plain, $html) = @_; 
	print qq{<table border=1 class="PLPerror"><tr><td>},
	      qq{<b>Debug information:</b><br>$html</td></tr></table>};
}

# This cleans up from previous requests, and sets the default $PLP::DEBUG
sub clean {
	@PLP::END = ();
	$PLP::code = '';
	$PLP::sentheaders = 0;
	$PLP::DEBUG = 1;
	$PLP::print = '';
	delete @ENV{ grep /^PLP_/, keys %ENV };
}

# Handles errors, uses subref $PLP::ERROR (default: \&_default_error)
sub error {
	my ($error, $type) = @_;
	if (not defined $type or $type < 100) {
		return undef unless $PLP::DEBUG & 1;
		my $plain = $error;
		(my $html = $plain) =~ s/([<&>])/'&#' . ord($1) . ';'/ge;
		PLP::sendheaders() unless $PLP::sentheaders;
		$PLP::ERROR->($plain, $html);
	} else {
		select STDOUT;
		my ($short, $long) = @{
			+{
				404 => [
					'Not Found',
					"The requested URL $ENV{REQUEST_URI} was not found " .
					"on this server."
				],
				403 => [
					'Forbidden',
					"You don't have permission to access $ENV{REQUEST_URI} " .
					"on this server."
				],
			}->{$type}
		};
		print "Status: $type\nContent-Type: text/html\n\n",
			qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n<html>},
			"<head>\n<title>$type $short</title>\n</head></body>\n<h1>$short",
			"</h1>\n$long<p>\n<hr>\n";
		print $ENV{SERVER_SIGNATURE} if $ENV{SERVER_SIGNATURE};
		print "</body></html>";
	}
}

# Wrap old request handlers.
sub everything {
	require PLP::Backend::CGI;
	PLP::Backend::CGI->everything();
}
sub handler {
	require PLP::Backend::Apache;
	PLP::Backend::Apache::handler(@_);
}

# Sends the headers waiting in %PLP::Script::header
sub sendheaders () {
	local $\;  # reset print behaviour if triggered by say()
	$PLP::sentheaders ||= [ caller 1 ? (caller 1)[1, 2] : (caller)[1, 2] ];
	print STDOUT "Content-Type: text/plain\n\n" if $PLP::DEBUG & 2;
	while (my ($header, $values) = each %PLP::Script::header) {
		print STDOUT "$header: $_\n" for split /\n/, $values;
	}
	print STDOUT "\n";
}

{
	my %cached; # Conceal cached sources: ( path => [ [ deps ], source, -M ] )
	
	# Given a filename and optional level (level should be 0 if the caller isn't
	# source() itself), and optional linespec (used by PLP::Functions::Include),
	# this function parses a PLP file and returns Perl code, ready to be eval'ed
	sub source {
		my ($file, $level, $linespec, $path) = @_;
		our $use_cache;

		# $file is displayed, $path is used. $path is constructed from $file if
		# not given.

		$level = 0      unless defined $level;
		$linespec = '1' unless defined $linespec;
		
		if ($level > 128) {
			%cached = ();
			return $level
				? qq{\cQ; die qq[Include recursion detected]; print q\cQ}
				: qq{\n#line $linespec\ndie qq[Include recursion detected];};
		}

		my $in_block = 0;   # 1 => "<:", 2 => "<:="
		
		$path ||= File::Spec->rel2abs($file);
		
		my $source_start = $level
			? qq/\cQ;\n#line 1 "$file"\n$PLP::print q\cQ/
			: qq/\n#line 1 "$file"\n$PLP::print q\cQ/;
		
		if ($use_cache and exists $cached{$path}) {
			BREAKOUT: {
				my @checkstack = ($path);
				my $item;
				my %checked;
				while (defined(my $item = shift @checkstack)) {
					next if $checked{$item};
					last BREAKOUT if $cached{$item}[2] > -M $item;
					$checked{$item} = 1;
					push @checkstack, @{ $cached{$item}[0] }
						if @{ $cached{$item}[0] };
				}
				return $level
					? $source_start . $cached{$path}[1]
					: $source_start . $cached{$path}[1] . "\cQ";
			}
		}

		$cached{$path} = [ [ ], undef, undef ] if $use_cache;
		
		my $linenr = 0;
		my $source = '';

		local *SOURCE;
		open SOURCE, '<', $path or return $level
			? qq{\cQ; die qq[Can't open "\Q$path\E" (\Q$!\E)]; print q\cQ}
			: qq{\n#line $linespec\ndie qq[Can't open "\Q$path\E" (\Q$!\E)];};
		
		LINE:
		while (defined (my $line = <SOURCE>)) {
			$linenr++;
			for (;;) {
				$line =~ /
					\G                  # Begin where left off
					( \z                # End
					| <:=? | :>         # PLP tags     <:= ... :> <: ... :>
					| <\([^)]*\)>       # Include tags <(...)>
					| <[^:(][^<:]*      # Normal text
					| :[^>][^<:]*       # Normal text
					| [^<:]*            # Normal text
					)
				/gxs;
				next LINE unless length $1;
				my $part = $1;
				if ($part eq '<:=' and not $in_block) {
					$in_block = 2;
					$source .= "\cQ, (";
				} elsif ($part eq '<:' and not $in_block) {
					$in_block = 1;
					$source .= "\cQ; ";
				} elsif ($part eq ':>' and $in_block) {
					$source .= (
						$in_block == 2
							? "), q\cQ"              # 2
							: "; $PLP::print q\cQ"   # 1
					);
					$in_block = 0;
				} elsif ($part =~ /^<\((.*?)\)>\z/ and not $in_block) {
					my $ipath = File::Spec->rel2abs(
						$1, File::Basename::dirname($path)
					);
					$source .= source($1, $level + 1, undef, $ipath) .
					           qq/\cQ, \n#line $linenr "$file"\nq\cQ/;
					push @{ $cached{$path}[0] }, $ipath;
				} else {
					$part =~ s/\\/\\\\/ unless $in_block;
					$source .= $part;
				}
			}
		}
		
		if ($in_block) {
			$source .= (
				$in_block == 2
					? "), q\cQ"              # 2
					: "; $PLP::print q\cQ"   # 1
			);
		}

		if ($use_cache) {
			$cached{$path}[1] = $source;
			$cached{$path}[2] = -M $path;
		}

		return $level
			? $source_start . $source
			: $source_start . $source . "\cQ";
	}
}


# Let the games begin! No lexicals may exist at this point.
sub start {
	no strict;
	tie *PLPOUT, 'PLP::Tie::Print';
	select PLPOUT;
	$PLP::ERROR = \&_default_error;

	PLP::Fields::doit();
	{
		package PLP::Script;
		use vars qw(%headers %header %cookies %cookie %get %post %fields);
		*headers = \%header;
		*cookies = \%cookie;
		PLP::Functions->import();

		# No lexicals may exist at this point.
		
		eval qq{ package PLP::Script; no warnings; $PLP::code; };
		PLP::error($@, 1) if $@ and $@ !~ /\cS\cT\cO\cP/;

		eval   { package PLP::Script; no warnings; $_->() for reverse @PLP::END };
		PLP::error($@, 1) if $@ and $@ !~ /\cS\cT\cO\cP/;
	}
	PLP::sendheaders() unless $PLP::sentheaders;
	select STDOUT;
	undef *{"PLP::Script::$_"} for keys %PLP::Script::;
	# Symbol::delete_package('PLP::Script');
	# The above does not work. TODO - find out why not.
}

1;

=head1 NAME

PLP - Perl in HTML pages

=head1 SYNOPSIS

=head2 Lighttpd installation

F<lighttpd.conf> configuration using L<mod_fastcgi|PLP::Backend::FastCGI>:

    server.modules += ("mod_fastcgi")
    fastcgi.server += (".plp" => ((
        "bin-path" => "/usr/bin/perl -MPLP::Backend::FastCGI",
        "socket"   => "/tmp/fcgi-plp.socket",
    )))

=head2 Apache installation

F<httpd.conf> for a L<mod_perl|PLP::Backend::Apache> setup:

    <Files *.plp>
        SetHandler perl-script
        PerlHandler PLP::Backend::Apache
        PerlSendHeader On
    </Files>

=head2 Test script (test.plp)

    <html><body>
    <:
        print "Hurrah, it works!<br>" for 1..10;
    :>
    </body></html>

=head1 DESCRIPTION

PLP is yet another Perl embedder, primarily for HTML documents. Unlike with
other Perl embedders, there is no need to learn a meta-syntax or object
model: one can just use the normal Perl constructs. PLP runs under
L<FastCGI|PLP::Backend::FastCGI> and L<mod_perl|PLP::Backend::Apache>
for speeds comparable to those of PHP, but can also be run as a standard
L<CGI|PLP::Backend::CGI> script.

=head2 Setup

See either
L<CGI|PLP::Backend::CGI>,
L<FastCGI|PLP::Backend::FastCGI> (recommended)
or L<Apache|PLP::Backend::Apache>.
At least the following servers are supported:

=over 10

=item Lighttpd

With L<mod_fastcgi|PLP::Backend::FastCGI> or L<mod_cgi|PLP::Backend::CGI>.

=item Apache

Either version 1 or 2. Using
L<mod_fcgid, mod_fastcgi|PLP::Backend::FastCGI>,
L<mod_perl|PLP::Backend::Apache>,
or L<mod_action|PLP::Backend::CGI>.

=back

=head2 PLP Syntax

=over 22

=item C<< <: perl_code(); :> >>

With C<< <: >> and C<< :> >>, you can add Perl code to your document. This is
what PLP is all about. All code outside of these tags is printed. It is
possible to mix perl language constructs with normal HTML parts of the document:

    <: unless ($ENV{REMOTE_USER}) { :>
        You are not logged in.
    <: } :>

C<< :> >> always stops a code block, even when it is found in a string literal.

=item C<< <:= $expression :> >>

Includes a dynamic expression in your document. The expression is evaluated in
list context. Please note that the expression should not end a statement: avoid
semi-colons. No whitespace may be between C<< <: >> and the equal sign.

C<< foo <:= $bar :> $baz >> is like C<< <: print 'foo ', $bar, ' $baz'; :> >>.

=item C<< <(filename)> >>

Includes another file before the PLP code is executed. The file is included
literally, so it shares lexical variables. Because this is a compile-time tag,
it's fast, but you can't use a variable as the filename. You can create
recursive includes, so beware! (PLP will catch simple recursion: the maximum
depth is 128.) Whitespace in the filename is not ignored so C<< <( foo.txt)> >>
includes the file named C< foo.txt>, including the space in its name. A
compile-time alternative is include(), which is described in L<PLP::Functions>.

=back

=head2 PLP Functions

These are described in L<PLP::Functions>.

=head2 PLP Variables

=over 22

=item $ENV{SCRIPT_NAME}

The URI of the PLP document, without the query string. (Example: C</foo.plp>)

Used to be renamed to C<$ENV{PLP_NAME}>, which is still provided but deprecated.

=item $ENV{SCRIPT_FILENAME}

The filename of the PLP document. (Example: C</var/www/index.plp>)

C<$ENV{PLP_SCRIPT}> also still provided but deprecated.

=item $PLP::VERSION

The version of PLP.

=item $PLP::DEBUG

Controls debugging output, and should be treated as a bitmask. The least
significant bit (1) controls if run-time error messages are reported to the
browser, the second bit (2) controls if headers are sent twice, so they get
displayed in the browser. A value of 3 means both features are enabled. The
default value is 1.

=item $PLP::ERROR

Contains a reference to the code that is used to report run-time errors. You
can override this to have it in your own design, and you could even make it
report errors by e-mail. The sub reference gets two arguments: the error message
as plain text and the error message with special characters encoded with HTML 
entities.

=item %header, %cookie, %get, %post, %fields

These are described in L<PLP::Fields>.

=back

=head2 Things that you should know about

Not only syntax is important, you should also be aware of some other important
features. Your script runs inside the package C<PLP::Script> and shouldn't
leave it. This is because when your script ends, all global variables in the
C<PLP::Script> package are destroyed, which is very important if you run a
persistent backend (they would retain their values if they weren't explicitly
destroyed).

Until your first output, you are printing to a tied filehandle C<PLPOUT>. On
first output, headers are sent to the browser and C<STDOUT> is selected for
efficiency. To set headers, you must assign to C<$header{ $header_name}> before
any output. This means the opening C<< <: >> have to be the first characters in
your document, without any whitespace in front of them. If you start output and
try to set headers later, an error message will appear telling you on which
line your output started. An alternative way of setting headers is using Perl's
BEGIN blocks. BEGIN blocks are executed as soon as possible, before anything
else.

Unless you're running as CGI, the interpreter won't exit after processing a page,
so C<END { }> blocks won't work properly.  You should use C<PLP_END { };> instead.
Note that this is a not a built-in construct, so it needs proper termination
with a semi-colon (as do C<eval> and C<do>).

When run persistently, modules are loaded only once. A good modular design can
improve performance because of this, but you will have to B<reload> the modules
yourself when there are newer versions. 

The special hashes are tied hashes and do not always behave the way you expect,
especially when mixed with modules that expect normal CGI environments, like
CGI.pm. Read L<PLP::Fields> for information more about this.

=head1 FAQ and HowTo

A lot of questions are asked often, so before asking yours, please read the 
FAQ at L<PLP::FAQ>. Some examples can be found at L<PLP::HowTo>.

=head1 AUTHORS

Currently maintained by Mischa POSLAWSKY <perl@shiar.org>

Originally by Juerd Waalboer <juerd@cpan.org>

=head1 LICENSE

Copyright (c) 2000-2002 Juerd Waalboer, 2005-2008 Mischa POSLAWSKY.
All rights reserved.

This software is free software;
you can redistribute and/or modify it under the terms of the MIT/X11 license.

=head1 SEE ALSO

L<PLP::Functions>, L<PLP::Fields>, L<PLP::FAQ>, L<PLP::HowTo>

=cut

### Garbage bin

# About the #S lines:
# I wanted to implement Safe.pm so that scripts were run inside a
# configurable compartment. This needed for XS modules to be pre-loaded,
# hence the PLPsafe_* Apache directives. However, $safe->reval() lets
# Apache segfault. End of fun. The lines are still here so that I can
# s/^#S //g to re-implement them whenever this has been fixed.

#S # For PLPsafe scripts
#S sub safe_eval {
#S     my ($r, $code) = @_;
#S     $r->send_http_header('text/plain');
#S     require Safe;
#S     unless ($PLP::safe) {
#S 	$PLP::safe = Safe->new('PLP::Script');
#S 	for ( map split, $r->dir_config->get('PLPsafe_module') ) {
#S 	    $PLP::safe->share('*' . $_ . '::');
#S 	    s!::!/!g;
#S 	    require $_ . '.pm';
#S 	}
#S 	$PLP::safe->permit(Opcode::full_opset());
#S 	$PLP::safe->deny(Opcode::opset(':dangerous'));
#S     }
#S     $PLP::safe->reval($code);
#S }
#S  my ($r) = @_;

# start()
#S 	if ($PLP::use_safe) {
#S 	    PLP::safe_eval($r, $PLP::code);
#S 	} else {
#	    eval qq{ package PLP::Script; $PLP::code; };
#S 	}
#	PLP::error($@, 1) if $@ and $@ !~ /\cS\cT\cO\cP/;
#S 	if ($PLP::use_safe) {
#S 	    PLP::safe_eval($r, '$_->() for reverse @PLP::END');
#S 	} else {
#	    eval   { package PLP::Script; $_->() for reverse @PLP::END };
#S 	}
#	PLP::error($@, 1) if $@ and $@ !~ /\cS\cT\cO\cP/;

###
