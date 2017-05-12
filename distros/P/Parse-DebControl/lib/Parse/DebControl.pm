package Parse::DebControl;

###########################################################
#       Parse::DebControl - Parse debian-style control
#		files (and other colon key-value fields)
#
#       Copyright 2003 - Jay Bonci <jaybonci@cpan.org>
#       Licensed under the same terms as perl itself
#
###########################################################

use strict;
use IO::Scalar;
use Compress::Zlib;
use LWP::UserAgent;

use vars qw($VERSION);
$VERSION = '2.005';

sub new {
	my ($class, $debug) = @_;
	my $this = {};

	my $obj = bless $this, $class;
	if($debug)
	{
		$obj->DEBUG();
	}
	return $obj;
};

sub parse_file {
	my ($this, $filename, $options) = @_;
	unless($filename)
	{
		$this->_dowarn("parse_file failed because no filename parameter was given");
		return;
	}	

	my $fh;
	unless(open($fh,"$filename"))
	{
		$this->_dowarn("parse_file failed because $filename could not be opened for reading");
		return;
	}
	
	return $this->_parseDataHandle($fh, $options);
};

sub parse_mem {
	my ($this, $data, $options) = @_;

	unless($data)
	{
		$this->_dowarn("parse_mem failed because no data was given");
		return;
	}

	my $IOS = new IO::Scalar \$data;

	unless($IOS)
	{
		$this->_dowarn("parse_mem failed because IO::Scalar creation failed.");
		return;
	}

	return $this->_parseDataHandle($IOS, $options);

};

sub parse_web {
	my ($this, $url, $options) = @_;

	unless($url)
	{
		$this->_dowarn("No url given, thus no data to parse");
		return;
	}

	my $ua = LWP::UserAgent->new;

	my $request = HTTP::Request->new(GET => $url);

	unless($request)
	{
		$this->_dowarn("Failed to instantiate HTTP Request object");
		return;
	}

	my $response = $ua->request($request);

	if ($response->is_success) {
		return $this->parse_mem($response->content(), $options);
	} else {
		$this->_dowarn("Failed to fetch $url from the web");
		return;
	}
}

sub write_file {
	my ($this, $filenameorhandle, $dataorarrayref, $options) = @_;

	unless($filenameorhandle)
	{
		$this->_dowarn("write_file failed because no filename or filehandle was given");
		return;
	}

	unless($dataorarrayref)
	{
		$this->_dowarn("write_file failed because no data was given");
		return;
	}

	my $handle = $this->_getValidHandle($filenameorhandle, $options);

	unless($handle)
	{
		$this->_dowarn("write_file failed because we couldn't negotiate a valid handle");
		return;
	}

	my $string = $this->write_mem($dataorarrayref, $options);
	$string ||= "";
	
	print $handle $string;
	close $handle;

	return length($string);
}

sub write_mem {
	my ($this, $dataorarrayref, $options) = @_;

	unless($dataorarrayref)
	{
		$this->_dowarn("write_mem failed because no data was given");
		return;
	}

	my $arrayref = $this->_makeArrayref($dataorarrayref);

	my $string = $this->_makeControl($arrayref);

	$string .= "\n" if $options->{addNewline};

	$string = Compress::Zlib::memGzip($string) if $options->{gzip};

	return $string;
}

sub DEBUG
{
        my($this, $verbose) = @_;
        $verbose = 1 unless(defined($verbose) and int($verbose) == 0);
        $this->{_verbose} = $verbose;
        return;

}

sub _getValidHandle {
	my($this, $filenameorhandle, $options) = @_;

	if(ref $filenameorhandle eq "GLOB")
	{
		unless($filenameorhandle->opened())
		{
			$this->_dowarn("Can't get a valid filehandle to write to, because that is closed");
			return;
		}

		return $filenameorhandle;
	}else
	{
		my $openmode = ">>";
		$openmode=">" if $options->{clobberFile};
		$openmode=">>" if $options->{appendFile};

		my $handle;

		unless(open $handle,"$openmode$filenameorhandle")
		{
			$this->_dowarn("Couldn't open file: $openmode$filenameorhandle for writing");
			return;
		}

		return $handle;
	}
}

sub _makeArrayref {
	my ($this, $dataorarrayref) = @_;

        if(ref $dataorarrayref eq "ARRAY")
        {
		return $dataorarrayref;
        }else{
		return [$dataorarrayref];
	}
}

sub _makeControl
{
	my ($this, $dataorarrayref) = @_;
	
	my $str = "";

	foreach my $stanza(@$dataorarrayref)
	{
		foreach my $key(keys %$stanza)
		{
			$stanza->{$key} ||= "";

			my @lines = split("\n", $stanza->{$key});
			if (@lines) {
				$str.="$key\: ".(shift @lines)."\n";
			} else {
				$str.="$key\:\n";
			}

			foreach(@lines)
			{
				if($_ eq "")
				{
					$str.=" .\n";
				}
				else{
					$str.=" $_\n";
				}
			}

		}

		$str ||= "";
		$str.="\n";
	}

	chomp($str);
	return $str;
	
}

sub _parseDataHandle
{
	my ($this, $handle, $options) = @_;

	my $structs;

	unless($handle)
	{
		$this->_dowarn("_parseDataHandle failed because no handle was given. This is likely a bug in the module");
		return;
	}

	if($options->{tryGzip})
	{
		if(my $gunzipped = $this->_tryGzipInflate($handle))
		{
			$handle = new IO::Scalar \$gunzipped
		}
	}

	my $data = $this->_getReadyHash($options);

	my $linenum = 0;
	my $lastfield = "";

	foreach my $line (<$handle>)
	{
		#Sometimes with IO::Scalar, lines may have a newline at the end

		#$line =~ s/\r??\n??$//; #CRLF fix, but chomp seems to clean it
		chomp $line;
		

		if($options->{stripComments}){
			next if $line =~ /^\s*\#[^\#]/;
			$line =~ s/\#$//;
			$line =~ s/(?<=[^\#])\#[^\#].*//;
			$line =~ s/\#\#/\#/;
		}

		$linenum++;
		if($line =~ /^[^\t\s]/)
		{
			#we have a valid key-value pair
			if($line =~ /(.*?)\s*\:\s*(.*)$/)
			{
				my $key = $1;
				my $value = $2;

				if($options->{discardCase})
				{
					$key = lc($key);
				}

				unless($options->{verbMultiLine})
				{
					$value =~ s/[\s\t]+$//;
				}

				$data->{$key} = $value;


				if ($options->{verbMultiLine} 
					&& (($data->{$lastfield} || "") =~ /\n/o)){
					$data->{$lastfield} .= "\n";
				}

				$lastfield = $key;
			}else{
				$this->_dowarn("Parse error on line $linenum of data; invalid key/value stanza");
				return $structs;
			}

		}elsif($line =~ /^([\t\s])(.*)/)
		{
			#appends to previous line

			unless($lastfield)
			{
				$this->_dowarn("Parse error on line $linenum of data; indented entry without previous line");
				return $structs;
			}
			if($options->{verbMultiLine}){
				$data->{$lastfield}.="\n$1$2";
			}elsif($2 eq "." ){
				$data->{$lastfield}.="\n";
			}else{
				my $val = $2;
				$val =~ s/[\s\t]+$//;
				$data->{$lastfield}.="\n$val";
			}

		}elsif($line =~ /^[\s\t]*$/){
		        if ($options->{verbMultiLine} 
			    && ($data->{$lastfield} =~ /\n/o)) {
			    $data->{$lastfield} .= "\n";
			}
			if(keys %$data > 0){
				push @$structs, $data;
			}
			$data = $this->_getReadyHash($options);
			$lastfield = "";
		}else{
			$this->_dowarn("Parse error on line $linenum of data; unidentified line structure");
			return $structs;
		}

	}

	if(keys %$data > 0)
	{
		push @$structs, $data;
	}

	return $structs;
}

sub _tryGzipInflate
{
	my ($this, $handle) = @_;

	my $buffer;
	{
		local $/ = undef;
		$buffer = <$handle>;
	}
	return Compress::Zlib::memGunzip($buffer) || $buffer;
}

sub _getReadyHash
{
	my ($this, $options) = @_;
	my $data;

	if($options->{useTieIxHash})
	{
		eval("use Tie::IxHash");
		if($@)
		{
			$this->_dowarn("Can't use Tie::IxHash. You need to install it to have this functionality");
			return;
		}
		tie(%$data, "Tie::IxHash");
		return $data;
	}

	return {};
}

sub _dowarn
{
        my ($this, $warning) = @_;

        if($this->{_verbose})
        {
                warn "DEBUG: $warning";
        }

        return;
}


1;

__END__

=head1 NAME

Parse::DebControl - Easy OO parsing of debian control-like files

=head1 SYNOPSIS

	use Parse::DebControl

	$parser = new Parse::DebControl;

	$data = $parser->parse_mem($control_data, $options);
	$data = $parser->parse_file('./debian/control', $options);
	$data = $parser->parse_web($url, $options);

	$writer = new Parse::DebControl;

	$string = $writer->write_mem($singlestanza);
	$string = $writer->write_mem([$stanza1, $stanza2]);

	$writer->write_file($filename, $singlestanza, $options);
	$writer->write_file($filename, [$stanza1, $stanza2], $options);

	$writer->write_file($handle, $singlestanza, $options);
	$writer->write_file($handle, [$stanza1, $stanza2], $options);

	$parser->DEBUG();

=head1 DESCRIPTION

	Parse::DebControl is an easy OO way to parse debian control files and 
	other colon separated key-value pairs. It's specifically designed
	to handle the format used in Debian control files, template files, and
	the cache files used by dpkg.

	For basic format information see:
	http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-controlsyntax

	This module does not actually do any intelligence with the file content
	(because there are a lot of files in this format), but merely handles
	the format. It can handle simple control files, or files hundreds of lines 
	long efficiently and easily.

=head2 Class Methods

=over 4

=item * C<new()>

=item * C<new(I<$debug>)>

Returns a new Parse::DebControl object. If a true parameter I<$debug> is 
passed in, it turns on debugging, similar to a call to C<DEBUG()> (see below);

=back

=over 4

=item * C<parse_file($control_filename,I<$options>)>

Takes a filename as a scalar and an optional hashref of options (see below). 
Will parse as much as it can, warning (if C<DEBUG>ing is turned on) on 
parsing errors. 

Returns an array of hashrefs, containing the data in the control file, split up
by stanza.  Stanzas are deliniated by newlines, and multi-line fields are
expressed as such post-parsing.  Single periods are treated as special extra
newline deliniators, per convention.  Whitespace is also stripped off of lines
as to make it less-easy to make mistakes with hand-written conf files).

The options hashref can take parameters as follows. Setting the string to true
enables the option.

	useTieIxHash - Instead of an array of regular hashrefs, uses Tie::IxHash-
		based hashrefs

	discardCase  - Remove all case items from keys (not values)		

	stripComments - Remove all commented lines in standard #comment format.
		Literal #'s are represented by ##. For instance

		Hello there #this is a comment
		Hello there, I like ##CCCCCC as a grey.

		The first is a comment, the second is a literal "#".

	verbMultiLine - Keep the description AS IS, and no not collapse leading
		spaces or dots as newlines. This also keeps whitespace from being
		stripped off the end of lines.

	tryGzip	- Attempt to expand the data chunk with gzip first. If the text is
		already expanded (ie: plain text), parsing will continue normally. 
		This could optionally be turned on for all items in the future, but
		it is off by default so we don't have to scrub over all the text for
		performance reasons.

=back

=over 4

=item * C<parse_mem($control_data, I<$options>)>

Similar to C<parse_file>, except takes data as a scalar. Returns the same
array of hashrefs as C<parse_file>. The options hashref is the same as 
C<parse_file> as well; see above.

=back

=over 4

=item * C<parse_web($url, I<$options>)>

Similar to the other parse_* functions, this pulls down a control file from
the web and attempts to parse it. For options and return values, see C<parse_file>, 
above

=back

=over 4

=item * C<write_file($filename, $data, I<$options>)>

=item * C<write_file($handle, $data)>

=item * C<write_file($filename, [$data1, $data2, $data3], I<$options>)>

=item * C<write_file($handle, [$data, $data2, $data3])>

This function takes a filename or a handle and writes the data out.  The 
data can be given as a single hashref or as an arrayref of hashrefs. It
will then write it out in a format that it can parse. The order is dependant
on your hash sorting order. If you care, use Tie::IxHash.  Remember for 
reading back in, the module doesn't care.

The I<$options> hashref can contain one of the following two items:

	addNewline - At the end of the last stanza, add an additional newline.
	appendFile  - (default) Write to the end of the file
	clobberFile - Overwrite the file given.
	gzip - Compress the data with gzip before writing

Since you determine the mode of your filehandle, passing it along with an 
options hashref obviously won't do anything; rather, it is ignored.

The I<addNewline> option solves a situation where if you are writing
stanzas to a file in a loop (such as logging with this module), then
the data will be streamed together, and won't parse back in correctly.
It is possible that this is the behavior that you want (if you wanted to write 
one key at a time), so it is optional.

This function returns the number of bytes written to the file, undef 
otherwise.

=back

=over 4

=item * C<write_mem($data)>

=item * C<write_mem([$data1,$data2,$data3])>;

This function works similarly to the C<write_file> method, except it returns
the control structure as a scalar, instead of writing it to a file.  There
is no I<%options> for this file (yet);

=back

=over 4

=item * C<DEBUG()>

Turns on debugging. Calling it with no paramater or a true parameter turns
on verbose C<warn()>ings.  Calling it with a false parameter turns it off.
It is useful for nailing down any format or internal problems.

=back

=head1 CHANGES

B<Version 2.005> - January 13th, 2004

=over 4

=item * More generic test suite fix for earlier versions of Test::More

=item * Updated copyright statement

=back

B<Version 2.004> - January 12th, 2004

=over 4

=item * More documentation formatting and typo fixes

=item * CHANGES file now generated automatically

=item * Fixes for potential test suite failure in Pod::Coverage run

=item * Adds the "addNewline" option to write_file to solve the streaming stanza problem.

=item * Adds tests for the addNewline option

=back

B<Version 2.003> - January 6th, 2004

=over 4

=item * Added optional Test::Pod test

=item * Skips potential Win32 test failure in the module where it wants to write to /tmp.

=item * Added optional Pod::Coverage test

=back

B<Version 2.002> - October 7th, 2003

=over 4

=item * No code changes. Fixes to test suite

=back

B<Version 2.001> - September 11th, 2003

=over 4

=item * Cleaned up more POD errors

=item * Added tests for file writing

=item * Fixed bug where write_file ignored the gzip parameter

=back

B<Version 2.0> - September 5th, 2003

=over 4

=item * Version increase.

=item * Added gzip support (with the tryGzip option), so that compresses control files can be parsed on the fly

=item * Added gzip support for writing of control files

=item * Added parse_web to snag files right off the web. Useful for things such as apt's Sources.gz and Packages.gz

=back

B<Version 1.10b> - September 2nd, 2003

=over 4

=item * Documentation fix for ## vs # in stripComments

=back

B<Version 1.10> - September 2nd, 2003

=over 4

=item * Documentation fixes, as pointed out by pudge

=item * Adds a feature to stripComments where ## will get interpolated as a literal pound sign, as suggested by pudge.

=back

B<Version 1.9> - July 24th, 2003

=over 4

=item * Fix for warning for edge case (uninitialized value in chomp)

=item * Tests for CRLF

=back

B<Version 1.8> - July 11th, 2003

=over 4

=item * By default, we now strip off whitespace unless verbMultiLine is in place.  This makes sense for things like conf files where trailing whitespace has no meaning. Thanks to pudge for reporting this.

=back

B<Version 1.7> - June 25th, 2003

=over 4

=item * POD documentation error noticed again by Frank Lichtenheld

=item * Also by Frank, applied a patch to add a "verbMultiLine" option so that we can hand multiline fields back unparsed.

=item * Slightly expanded test suite to cover new features

=back

B<Version 1.6.1> - June 9th, 2003

=over 4

=item * POD cleanups noticed by Frank Lichtenheld. Thank you, Frank.

=back

B<Version 1.6> - June 2nd, 2003

=over 4

=item * Cleaned up some warnings when you pass in empty hashrefs or arrayrefs

=item * Added stripComments setting

=item * Cleaned up POD errors

=back

B<Version 1.5> - May 8th, 2003

=over 4

=item * Added a line to quash errors with undef hashkeys and writing

=item * Fixed the Makefile.PL to straighten up DebControl.pm being in the wrong dir

=back

B<Version 1.4> - April 30th, 2003

=over 4

=item * Removed exports as they were unnecessary. Many thanks to pudge, who pointed this out.

=back

B<Version 1.3> - April 28th, 2003

=over 4

=item * Fixed a bug where writing blank stanzas would throw a warning.  Fix found and supplied by Nate Oostendorp.

=back

B<Version 1.2b> - April 25th, 2003

Fixed:

=over 4

=item * A bug in the test suite where IxHash was not disabled in 40write.t. Thanks to Jeroen Latour from cpan-testers for the report.

=back

B<Version 1.2> - April 24th, 2003

Fixed:

=over 4

=item * A bug in IxHash support where multiple stanzas might be out of order

=back

B<Version 1.1> - April 23rd, 2003

Added:

=over 4

=item * Writing support

=item * Tie::IxHash support

=item * Case insensitive reading support

=back

B<Version 1.0> - April 23rd, 2003

=over 4

=item * This is the initial public release for CPAN, so everything is new.

=back

=head1 BUGS

The module will let you parse otherwise illegal key-value pairs and pairs with spaces. Badly formed stanzas will do things like overwrite duplicate keys, etc.  This is your problem.

As of 1.10, the module uses advanced regexp's to figure out about comments.  If the tests fail, then stripComments won't work on your earlier perl version (should be fine on 5.6.0+)

=head1 TODO

Change the name over to the Debian:: namespace, probably as Debian::ControlFormat.  This will happen as soon as the project that uses this module reaches stability, and we can do some minor tweaks.

=head1 COPYRIGHT

Parse::DebControl is copyright 2003,2004 Jay Bonci E<lt>jaybonci@cpan.orgE<gt>.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
