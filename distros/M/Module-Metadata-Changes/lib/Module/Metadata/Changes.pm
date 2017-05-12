package Module::Metadata::Changes;

use strict;
use warnings;

use Config::IniFiles;

use DateTime::Format::W3CDTF;

use File::Slurper 'read_lines';

use HTML::Entities::Interpolate;
use HTML::Template;

use Moo;

use Try::Tiny;

use Types::Standard qw/Any ArrayRef Bool Str/;

use version;

has changes =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has config =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has convert =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has errstr =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has inFileName =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has module_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has outFileName =>
(
	default  => sub{return 'Changelog.ini'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has pathForHTML =>
(
	default  => sub{return '/dev/run/html/assets/templates/module/metadata/changes'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has release =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has table =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has urlForCSS =>
(
	default  => sub{return '/assets/css/module/metadata/changes/ini.css'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has webPage =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

our $VERSION = '2.12';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	if ($self -> webPage)
	{
		$self -> table(1);
	}

} # End of BUILD.

# ------------------------------------------------

sub get_latest_release
{
	my($self)    = @_;
	my(@release) = $self -> config -> GroupMembers('V');

	my(@output);
	my($release);
	my($version);

	for $release (@release)
	{
		($version = $release) =~ s/^V //;

		push @output, version -> new($version);
	}

	@output = reverse sort{$a cmp $b} @output;

	my($result) = {};

	if ($#output >= 0)
	{
		my($section) = "V $output[0]";

		my($token);

		for $token ($self -> config -> Parameters($section) )
		{
			$$result{$token} = $self -> config -> val($section, $token);
		}
	}

	return $result;

} # End of get_latest_release.

# ------------------------------------------------

sub get_latest_version
{
	my($self)    = @_;
	my(@release) = $self -> config -> GroupMembers('V');

	my(@output);
	my($release);
	my($version);

	for $release (@release)
	{
		($version = $release) =~ s/^V //;

		push @output, version -> new($version);
	}

	@output = reverse sort{$a cmp $b} @output;

	return $#output >= 0 ? $output[0] : '';

} # End of get_latest_version.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;
	$s ||= '';

	if ($self -> verbose)
	{
		print STDERR "$s\n";
	}

} # End of log.

#  -----------------------------------------------

sub parse_datetime
{
	my($self, $candidate) = @_;

	# One of the modules DateTime::Format::HTTP or DateTime::Format::Strptime
	# can return 'No input string', so we use it as well.

	if (length($candidate) == 0)
	{
		return 'No input string';
	}

	my($date) = $self -> parse_datetime_1($candidate);

	if ($date eq 'Could not parse date')
	{
		$date = $self -> parse_datetime_2('%A%n%B%n%d%n%Y', $candidate);

		if ($date eq 'Could not parse date')
		{
			$candidate =~ s/(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\s*//;
			$date      = $self -> parse_datetime_2('%B%n%d%n%Y', $candidate);
		}
	}

	return $@ || $date;

} # End of parse_datetime.

#  -----------------------------------------------

sub parse_datetime_1
{
	my($self, $candidate) = @_;

	my($date);

	require 'DateTime/Format/HTTP.pm';

	try
	{
		$date = DateTime::Format::HTTP -> parse_datetime($candidate);
	}
	catch
	{
		$date = 'Could not parse date';
	};

	return $date;

} # End of parse_datetime_1.

#  -----------------------------------------------

sub parse_datetime_2
{
	my($self, $pattern, $candidate) = @_;
	$candidate =~ s/([0-9]+)(st|nd|rd|th)/$1/; # Zap st from 1st, etc.

	require 'DateTime/Format/Strptime.pm';

	my($parser) = DateTime::Format::Strptime -> new(pattern => $pattern);

	return $parser -> parse_datetime($candidate) || 'Could not parse date';

} # End of parse_datetime_2.

#  -----------------------------------------------

sub read
{
	my($self, $in_file_name) = @_;
	$in_file_name            ||= $self -> inFileName || 'Changelog.ini';

	$self -> config(Config::IniFiles -> new(-file => $in_file_name) );

	# Return object for method chaining.

	return $self -> validate($in_file_name);

} # End of read.

#  -----------------------------------------------

sub reader
{
	my($self, $in_file_name) = @_;
	$in_file_name            ||= $self -> inFileName || (-e 'Changes' ? 'Changes' : 'CHANGES');
	my(@line)                = read_lines $in_file_name;

	$self -> log("Input file: $in_file_name");

	# Get module name from the first line.
	# 1st guess at format: /Revision history for Perl extension Local::Wine./.

	my($line)        = shift @line;
	$line            =~ s/\s+$//;
	$line            =~ s/\s*\.\s*$//;
	my(@field)       = split(/\s+/, $line);
	my($module_name) = $field[$#field];
	my($ok)          = $module_name ? 1 : 0;

	# 2nd guess at format: X::Y somewhere in the first line. This overrides the first guess.

	if (! $ok)
	{
		@field = split(/\s+/, $line);

		my($field);

		for $field (@field)
		{
			if ($field =~ /^.+::.+$/)
			{
				$module_name = $field;

				last;
			}
		}
	}

	$self -> module_name($module_name);
	$self -> log("Module: $module_name");

	# Return object for method chaining.

	return $self -> transform(@line);

} # End of reader.

#  -----------------------------------------------

sub report
{
	my($self)        = @_;
	my($module_name) = $self -> config -> val('Module', 'Name');
	my($width)       = 15;

	my(@output);

	push @output, ['Module', $module_name];
	push @output, ['-' x $width, '-' x $width];

	my($found)   = 0;
	my(@release) = $self -> config -> GroupMembers('V');

	my($date, $deploy_action, $deploy_reason);
	my($release);
	my($version);

	for $release (@release)
	{
		($version = $release) =~ s/^V //;

		next if ($self -> release && ($version ne $self -> release) );

		$date          = $self -> config -> val($release, 'Date');
		$deploy_action = $self -> config -> val($release, 'Deploy.Action');
		$deploy_reason = $self -> config -> val($release, 'Deploy.Reason');
		$found         = 1;

		push @output, ['Version', $version];
		push @output, ['Date', $date];

		if ($deploy_action)
		{
			push @output, ['Deploy.Action', $deploy_action];
			push @output, ['Deploy.Reason', $deploy_reason];
		}

		push @output, ['-' x $width, '-' x $width];
	}

	if (! $found)
	{
		push @output, ['Warning', "V @{[$self -> release]} not found"];
	}

	if ($self -> table)
	{
		$self -> report_as_html(@output);
	}
	else
	{
		# Report as text.

		for (@output)
		{
			printf "%-${width}s %s\n", $$_[0], $$_[1];
		}
	}

} # End of report.

#  -----------------------------------------------

sub report_as_html
{
	my($self, @output) = @_;
	my($template) = HTML::Template -> new(path => $self -> pathForHTML, filename => 'ini.table.tmpl');
	@output       = map
	{
		{
			th => $Entitize{$$_[0]},
			td => $Entitize{$$_[1]},
			td_class => $$_[0] =~ /Deploy/ ? 'ini_deploy' : 'ini_td',
		}
	} @output;

	$template -> param(tr_loop => [@output]);

	my($content) = $template -> output();

	if ($self -> webPage)
	{
		$template = HTML::Template -> new(path => $self -> pathForHTML, filename => 'ini.page.tmpl');

		$template -> param(content => $content);
		$template -> param(url_for_css => $self -> urlForCSS);

		$content = $template -> output();
	}

	print $content;

} # End of report_as_html.

#  -----------------------------------------------

sub run
{
	my($self) = @_;

	# If converting, inFileName is the name of an old-style Changes/CHANGES file,
	# and outFileName is the name of a new-style Changelog.ini file.
	# If reporting on a specific release, inFileName is the name of
	# a new-style Changelog.ini file.

	if ($self -> convert)
	{
		$self -> inFileName('Changes') if (! $self -> inFileName);
		$self -> reader($self -> inFileName) -> writer($self -> outFileName);
	}
	else
	{
		$self -> inFileName('Changelog.ini') if (! $self -> inFileName);
		$self -> read($self -> inFileName);
		$self -> report;
	}

	# Return 0 for success in case someone wants to know.

	return 0;

} # End of run.

#  -----------------------------------------------

sub transform
{
	my($self, @line) = @_;
	my($count)       = 0;

	my($current_version, $current_date, @comment);
	my($date);
	my(@field);
	my($line);
	my($release, @release);
	my($version);

	for $line (@line)
	{
		$count++;

		$line  =~ s/^\s+//;
		$line  =~ s/\s+$//;

		next if (length($line) == 0);
		next if ($line =~ /^#/);

		# Try to get the version number and date.
		# Each release is expected to start with one of:
		# o 1.05  Fri Jan 25 10:08:00 2008
		# o 4.30 - Friday, April 25, 2008
		# o 4.08 - Thursday, March 15th, 2006
		# Squash spaces.

		$line  =~ tr/ / /s;

		# Remove commas (from dates) if the line starts with a digit (which is assumed to be a version #).

		$line  =~ s/,//g if ($line =~ /^v?\d/);
		@field = split(/\s(?:-\s)?/, $line, 2);

		# The "" keeps version happy.

		try
		{
			$version = version -> new("$field[0]");
		};

		$date = defined $field[1] ? $self -> parse_datetime($field[1]) : 'No input string';

		if (! defined $version || ($version eq '0') || ($date eq 'Could not parse date') || ($date =~ /No input string/) )
		{
			# We got an error. So assume it's commentary on the current release.
			# If the line starts with EOT, jam a '-' in front of it to escape it,
			# since Config::IniFiles uses EOT to terminate multi-line comments.

			$line = "-$line" if (substr($line, 0, 3) eq 'EOT');

			push @comment, $line;
		}
		else
		{
			# We got a version and a date. Assume it's a new release.
			# Step 1: Wrap up the last version, if any.

			if ($version && $date)
			{
				$self -> log("Processing: V $version $date");
			}

			if ($current_version)
			{
				$release = {Version => $current_version, Date => $current_date, Comments => [@comment]};

				push @release, $release;
			}

			# Step 2: Start the new version.

			if ($current_version && ($version eq $current_version) )
			{
				$self -> errstr("V $version found with dates $current_date and $date");

				$self -> log($self -> errstr);
			}

			@comment         = ();
			$current_date    = $date;
			$current_version = $version;
		}
	}

	# Step 3: Wrap up the last version, if any.

	if ($current_version)
	{
		$release = {Version => $current_version, Date => $current_date, Comments => [@comment]};

		push @release, $release;
	}

	# Scan the releases looking for security advisories.

	my($security);

	for $release (0 .. $#release)
	{
		$security = 0;

		for $line (@{$release[$release]{'Comments'} })
		{
			if ($line =~ /Security/i)
			{
				$security = 1;

				last;
			}
		}

		if ($security)
		{
			$release[$release]{'Deploy.Action'} = 'Upgrade';
			$release[$release]{'Deploy.Reason'} = 'Security';
		}
	}

	$self -> changes([@release]);

	# Return object for method chaining.

	return $self;

} # End of transform.

#  -----------------------------------------------

sub validate
{
	my($self, $in_file_name) = @_;

	# Validate existence of Module section.

	if (! $self -> config -> SectionExists('Module') )
	{
		die "Error: Section 'Module' is missing from $in_file_name";
	}

	# Validate existence of Name within Module section.

	my($module_name) = $self -> config -> val('Module', 'Name');

	if (! defined $module_name)
	{
		die "Error: Section 'Module' is missing a 'Name' token in $in_file_name";
	}

	# Validate existence of Releases.

	my(@release) = $self -> config -> GroupMembers('V');

	if ($#release < 0)
	{
		die "Error: No releases (sections like [V \$version]) found in $in_file_name";
	}

	my($parser) = DateTime::Format::W3CDTF -> new;

	my($candidate);
	my($date);
	my($release);
	my($version);

	for $release (@release)
	{
		($version = $release) =~ s/^V //;

		# Validate Date within each Release.

		$candidate = $self -> config -> val($release, 'Date');

		try
		{
			$date = $parser -> parse_datetime($candidate);
		}
		catch
		{
			die "Error: Date $candidate is not in W3CDTF format";
		}
	}

	$self -> log("Successful validation of file: $in_file_name");

	# Return object for method chaining.

	return $self;

} # End of validate.

#  -----------------------------------------------

sub writer
{
	my($self, $output_file_name) = @_;
	$output_file_name ||= $self -> outFileName || 'Changelog.ini';

	$self -> config(Config::IniFiles -> new);
	$self -> config -> AddSection('Module');
	$self -> config -> newval('Module', 'Name', $self -> module_name);
	$self -> config -> newval('Module', 'Changelog.Creator', __PACKAGE__ . " V $VERSION");
	$self -> config -> newval('Module', 'Changelog.Parser', "Config::IniFiles V $Config::IniFiles::VERSION");

	# Sort by version number to put the latest version at the top of the file.

	my($section);

	for my $r (reverse sort{$$a{'Version'} cmp $$b{'Version'} } @{$self -> changes})
	{
		$section = "V $$r{'Version'}";

		$self -> config -> AddSection($section);
		$self -> config -> newval($section, 'Date', $$r{'Date'});

		# Put these near the top of this release's notes.

		if ($$r{'Deploy.Action'})
		{
			$self -> config -> newval($section, 'Deploy.Action', $$r{'Deploy.Action'});
			$self -> config -> newval($section, 'Deploy.Reason', $$r{'Deploy.Reason'} || '');
		}

		$self -> config -> newval($section, 'Comments', @{$$r{'Comments'} });
	}

	$self -> config -> WriteConfig($output_file_name);

	$self -> log("Output file: $output_file_name");

	# Return object for method chaining.

	return $self;

} # End of writer.

# -----------------------------------------------

1;

=head1 NAME

Module::Metadata::Changes - Manage machine-readable Changes/CHANGES/Changelog.ini files

=head1 Synopsis

=head2 One-liners

These examples use Changes/CHANGES and Changelog.ini in the 'current' directory.

The command line options (except for -h) correspond to the options documented under L</Constructor and initialization>, below.

	shell>ini.report.pl -h
	shell>ini.report.pl -c
	shell>ini.report.pl -r 1.23
	shell>sudo ini.report.pl -w > /var/www/Changelog.html
	shell>perl -MModule::Metadata::Changes -e 'Module::Metadata::Changes->new(convert => 1)->run'
	shell>perl -MModule::Metadata::Changes -e 'print Module::Metadata::Changes->new->read->get_latest_version'
	shell>perl -MModule::Metadata::Changes -e 'print Module::Metadata::Changes->new->read->report'
	shell>perl -MModule::Metadata::Changes -e 'print Module::Metadata::Changes->new(release=>"2.00")->read->report'

L<Module::Metadata::Changes> ships with C<ini.report.pl> in the bin/ directory. It is installed along with the module.

Also, L<Module::Metadata::Changes> uses L<Config::IniFiles> to read and write Changelog.ini files.

=head2 Reporters

With a script like this:

	#!/usr/bin/env perl

	use feature 'say';
	use strict;
	use warnings;

	use File::chdir; # For magic $CWD.

	use Module::Metadata::Changes;

	# ------------------------------------------------

	my($work) = "$ENV{HOME}/perl.modules";
	my($m)    = Module::Metadata::Changes -> new;

	opendir(INX, $work) || die "Can't opendir($work)";
	my(@name) = sort grep{! /^\.\.?$/} readdir INX;
	closedir INX;

	my($config);
	my($version);

	for my $name (@name)
	{
		$CWD     = "$work/$name"; # Does a chdir.
		$version = $m -> read -> get_latest_version;
		$config  = $m -> config; # Must call read() before config().

		say $config -> val('Module', 'Name'), " V $version ", $config -> val("V $version", 'Date');
	}

you can get a report of the latest version number, from Changelog.ini, for each module in your vast library.

=head1 Description

L<Module::Metadata::Changes> is a pure Perl module.

It allows you to convert old-style Changes/CHANGES files, and to read and write Changelog.ini files.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type L<Module::Metadata::Changes>.

This is the class contructor.

Usage: C<< Module::Metadata::Changes -> new() >>.

This method takes a hash of options. There are no mandatory options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options:

=over 4

=item o convert

This takes the value 0 or 1.

The default is 0.

If the value is 0, calling C<run()> calls C<read()> and C<report()>.

If the value is 1, calling C<run()> calls C<writer(reader() )>.

=item o inFileName

The default is 'Changes' (or, if absent, 'CHANGES') when calling C<reader()>, and
'Changelog.ini' when calling C<read()>.

=item o outFileName

The default is 'Changelog.ini'.

=item o pathForHTML

This is path to the HTML::Template-style templates used by the 'table' and 'webPage' options.

The default is '/dev/shm/html/assets/templates/module/metadata/changes'.

=item o release

The default is ''.

If this option has a non-empty value, the value is assumed to be a release/version number.

In that case, reports (text, HTML) are restricted to only the given version.

The default ('') means reports contain all versions.

'release' was chosen, rather than 'version', in order to avoid a clash with 'verbose',
since all options could then be abbreviated to 1 letter (when running ini.report.pl).

Also, a lot of other software uses -r to refer to release/version.

=item o table

This takes the value 0 or 1.

The default is 0.

This option is only used when C<report()> is called.

If the value is 0, calling C<report()> outputs a text report.

If the value is 1, calling C<report()> outputs a HTML report.

By default, the HTML report will just be a HTML table.

However, if the 'webPage' option is 1, the HTML will be a complete web page.

=item o urlForCSS

The default is '/assets/css/module/metadata/changes/ini.css'.

This is only used if the 'webPage' option is 1.

=item o verbose

This takes the value 0 or 1.

The default is 0.

If the value is 1, write progress reports to STDERR.

=item o webPage

This takes the value 0 or 1.

The default is 0.

A value of 1 automatically sets 'table' to 1.

If the value is 0, the 'table' option outputs just a HTML table.

If the value is 1, the 'table' option outputs a complete web page.

=back

=head1 Methods

=head2 o config()

Returns the L<Config::IniFiles> object, from which you can extract all the data.

This method I<must> be called after calling C<read()>.

See C<scripts/report.names.pl> for sample code.

The names of the sections, [Module] and [V 1.23], and the keys under each, are documented in the FAQ.

=head2 o errstr()

Returns the last error message, or ''.

=head2 o get_latest_release()

Returns an hash ref of details for the latest release.

Returns {} if there is no such release.

The hash keys are (most of) the reserved tokens, as discussed below in the FAQ.

Some reserved tokens, such as EOT, make no sense as hash keys.

=head2 o get_latest_version()

Returns the version number of the latest version.

Returns '' if there is no such version.

=head2 o parse_datetime()

Used by C<transform()>.

=head2 o parse_datetime_1()

Used by C<transform()>.

=head2 o parse_datetime_2()

Used by C<transform()>.

=head2 o read([$input_file_name])

This method reads the given file, using L<Config::IniFiles>.

The $input_file_name is optional. It defaults to 'Changelog.ini'.

See config().

Return value: The object, for method chaining.

=head2 o reader([$input_file_name])

This method parses the given file, assuming it is format is the common-or-garden Changes/CHANGES style.

The $input_file_name is optional. It defaults to 'Changes' (or, if absent, 'CHANGES').

C<reader()> calls C<module_name()> to save the module name for use by other methods.

C<reader()> calls C<transform()>.

Return value: An arrayref of hashrefs, i.e. the return value of C<transform()>.

This value is suitable for passing to C<writer()>.

=head2 o report()

Displays various items for one or all releases.

If the 'release' option to C<new()> was not used, displays items for all releases.

If 'release' was used, restrict the report to just that release/version.

If either the 'table' or 'webPage' options to C<new()> were used, output HTML by calling C<report_as_html()>.

If these latter 2 options were not used, output text.

HTML is escaped using L<HTML::Entities::Interpolate>.

Output is to STDOUT.

Clearly, you should not use -v to get logging output when using text or HTML output.

=head2 o report_as_html()

Displays various items as HTML for one or all releases.

If the 'release' option to C<new()> was not used, displays items for all releases.

If 'release' was used, restrict the report to just that release/version.

Warning: This method must be called via the C<report()> method.

Output is to STDOUT.

=head2 o run()

Use the options passed to C<new()> to determine what to do.

Calling C<< new(convert => 1) >> and then C<run()> will cause C<writer(reader() )> to be called.

If you do not set 'convert' to 1 (i.e. use 0 - the default), C<run()> will call C<read()> and C<report()>.

Return value: 0.

=head2 o transform(@line)

Transform the memory-based version of Changes/CHANGES into an arrayref of hashrefs, where each array element
holds data for 1 version.

Must be called by C<reader()>.

The array is the text read in from Changes/CHANGES.

C<transform()> stores the arrayref of hashrefs in $obj -> changes(), for use by C<writer()>.

Return value: The object, for method chaining.

=head2 o validate($file_name)

This method is used by C<read()> to validate the contents of the file read in.

C<validate()> does not read the file.

C<validate()> calls die when a validation test fails.

The file name is just used for reporting.

Return value: The object, for method chaining.

=head2 o writer([$output_file_name])

This method writes the arrayref stored in $obj -> changes(), using L<Config::IniFiles>, to the given file.

See C<transform()>.

The $output_file_name is optional. It defaults to 'Changelog.ini'.

Return value: The object, for method chaining.

=head1 FAQ

=over 4

=item o Are there any things I should look out for?

=over 4

=item o Invalid dates

Invalid dates in Changes/CHANGES cannot be distinguished from comments. That means that if the output file is
missing one or more versions, it is because of those invalid dates.

=item o Invalid day-of-week (dow)

If Changes/CHANGES includes the dow, it is not cross-checked with the date, so if the dow is wrong,
you will not get an error generated.

=back

=item o How do I display Changelog.ini?

See C<bin/ini.report.pl>. It outputs text or HTML.

=item o What is the format of Changelog.ini?

See also the next question.

See C<scripts/report.names.pl> for sample code.

Here is a sample:

	[Module]
	Name=CGI::Session
	Changelog.Creator=Module::Metadata::Changes V 1.00
	Changelog.Parser=Config::IniFiles V 2.39

	[V 4.30]
	Date=2008-04-25T00:00:00
	Comments= <<EOT
	* FIX: Patch POD for CGI::Session in various places, to emphasize even more that auto-flushing is
	unreliable, and that flush() should always be called explicitly before the program exits.
	The changes are a new section just after SYNOPSIS and DESCRIPTION, and the PODs for flush(),
	and delete(). See RT#17299 and RT#34668
	* NEW: Add t/new_with_undef.t and t/load_with_undef.t to explicitly demonstrate the effects of
	calling new() and load() with various types of undefined or fake parameters. See RT#34668
	EOT

	[V 4.10]
	Date=2006-03-28T00:00:00
	Deploy.Action=Upgrade
	Deploy.Reason=Security
	Comments= <<EOT
	* SECURITY: Hopefully this settles all of the problems with symlinks. Both the file
	and db_file drivers now use O_NOFOLLOW with open when the file should exist and
	O_EXCL|O_CREAT when creating the file. Tests added for symlinks. (Matt LeBlanc)
	* SECURITY: sqlite driver no longer attempts to use /tmp/sessions.sqlt when no
	Handle or DataSource is specified. This was a mistake from a security standpoint
	as anyone on the machine would then be able to create and therefore insert data
	into your sessions. (Matt LeBlanc)
	* NEW: name is now an instance method (RT#17979) (Matt LeBlanc)
	EOT

=item o What are the reserved tokens in this format?

I am using tokens to refer to both things in [] such as Module, and things on the left hand side
of the = signs, such as Date.

And yes, these tokens are case-sensitive.

Under the [Module] section, the tokens are:

=over 4

=item o Changelog.Creator

sample: Changelog.Creator=Module::Metadata::Changes V 2.00

=item o Changelog.Parser

Sample: Changelog.Parser=Config::IniFiles V 2.66

=item o Name

Sample: Name=Manage::Module::Changes

=back

Under each version (section), whose name is like [V 1.23], the token are as follows.

L<Config::IniFiles> calls the V in [V 1.23] a Group Name.

=over 4

=item o Comments

Sample: Comments=- Original version

=item o Date

The datetime of the release, in W3CDTF format.

Sample: Date=2008-05-02T15:15:45

I know the embedded 'T' makes this format a bit harder to read, but the idea is that such files
will normally be processed by a program.

=item o Deploy.Action

The module author makes this recommendation to the end user.

This enables the end user to quickly grep the Changelog.ini, or the output of C<ini.report.pl>,
for things like security fixes and API changes.

Run 'bin/ini.report.pl -h' for help.

Suggestions:

	Deploy.Action=Upgrade
	Deploy.Reason=(Security|Major bug fix)

	Deploy.Action=Upgrade with caution
	Deploy.Reason=(Major|Minor) API change/Development version

Alternately, the classic syslog tokens could perhaps be used:

Debug/Info/Notice/Warning/Error/Critical/Alert/Emergency.

I think the values for these 2 tokens (Deploy.*) should be kept terse, and the Comments section used
for an expanded explanation, if necessary.

Omitting Deploy.Action simply means the module author leaves it up to the end user to
read the comments and make up their own mind.

C<reader()> called directly, or via C<ini.report.pl -c> (i.e. old format to ini format converter),
inserts these 2 tokens if it sees the word /Security/i in the Comments. It is a crude but automatic warning
to end users. The HTML output options (C<-t> and C<-w>) use red text via CSS to highlight these 2 tokens.

Of course security is best handled by the module author explicitly inserting a suitable note.

And, lastly, any such note is purely up to the judgement of the author, which means differences in
opinion are inevitable.

=item o Deploy.Reason

The module author gives this reason for their recommended action.

=item o EOT

Config::IniFiles uses EOT to terminate multi-line comments.

If C<transform()> finds a line beginning with EOT, it jams a '-' in front of it.

=back

=item o Why are there not more reserved tokens?

Various reasons:

=over 4

=item o Any one person, or any group, can standardize on their own tokens

Obviously, it would help if they advertised their choice, firstly so as to get as
many people as possible using the same tokens, and secondly to get agreement on the
interpretation of those choices.

Truely, there is no point in any particular token if it is not given a consistent meaning.

=item o You can simply add your own to your Changelog.ini file

They will then live on as part of the file.

=back

Special processing is normally only relevant when converting an old-style Changes/CHANGES file
to a new-style Changelog.ini file.

However, if you think the new tokens are important enough to be displayed as part of the text
and HTML format reports, let me know.

I have deliberately not included the Comments in reports since you can always just examine the
Changelog.ini file itself for such items. But that too could be changed.

=item o Are single-line comments acceptable?

Sure. Here is one:

	Comments=* INTERNAL: No Changes since 4.20_1. Declaring stable.

The '*' is not special, it is just part of the comment.

=item o What is with the datetime format?

It is called W3CDTF format. See:

http://search.cpan.org/dist/DateTime-Format-W3CDTF/

See also ISO8601 format:

http://search.cpan.org/dist/DateTime-Format-ISO8601/

=item o Why this file format?

Various reasons:

=over 4

=item o [Module] allows for [Script], [Library], and so on.

=item o *.ini files are easy for beginners to comprehend

=item o Other formats were considered. I made a decision

There is no perfect format which will please everyone.

Various references, in no particular order:

http://use.perl.org/~miyagawa/journal/34850

http://use.perl.org/~hex/journal/34864

http://redhanded.hobix.com/inspect/yamlIsJson.html

http://use.perl.org/article.pl?sid=07/09/06/0324215

http://use.perl.org/comments.pl?sid=36862&cid=57590

http://use.perl.org/~RGiersig/journal/34370/

=item o The module L<Config::IniFiles> already existed, for reading and writing this format

Specifically, L<Config::IniFiles> allows for here documents, which I use to hold the comments
authors produce for most of their releases.

=back

=item o What is the difference between release and version?

I am using release to refer not just to the version number, but also to all the notes
relating to that version.

And by notes I mean everything in one section under the name [V $version].

=item o Will you switch to YAML or XML format?

YAML? No, never. It is targetted at other situations, and while it can be used for simple
applications like this, it can't be hand-written I<by beginners>.

And it's unreasonable to force people to write a simple program to write a simple YAML file.

XML? Nope. It is great in I<some> situations, but too visually dense and slow to write for this one.

=item o What about adding Changed Requirements to the file?

No. That info will be in the changed C<Build.PL> or C<Makefile.PL> files.

It is a pointless burden to make the module author I<also> add that to Changelog.ini.

=item o Who said you had the power to decide on this format?

No-one. But I do have the time and the inclination to maintain L<Module::Metadata::Changes>
indefinitely.

Also, I had a pressing need for a better way to manage metadata pertaining my own modules,
for use in my database of modules.

One of the reports I produce from this database is visible here:

http://savage.net.au/Perl-modules.html

Ideally, there will come a time when all of your modules, if not the whole of CPAN,
will have Changelog.ini files, so producing such a report will be easy, and hence will be
that much more likely to happen.

=item o Why not use, say, L<Config::Tiny> to process Changelog.ini files?

Because L<Config::Tiny> contains this line, 's/\s\;\s.+$//g;', so it will mangle
text containing English semi-colons.

Also, authors add comments per release, and most C<Config::*> modules only handle lines
of the type X=Y.

=item o How are the old Changes/CHANGES files parsed?

The first line is scanned looking for /X::Y/ or /X\.$/. And yes, it fails for modules
which identify themselves like Fuse-PDF not at the end of the line.

Then lines looking something like /$a_version_number ... $a_datetime/ are searched for.
This is deemed to be the start of information pertaining to a specific release.

Everything up to the next release, or EOF, is deemed to belong to the release just
identified.

This means a line containing a version number without a date is not recognized as a new release,
so that that line and the following comments are added to the 'current' release info.

For an example of this, process the C<Changes> file from CGI::Session (t/Changes), and scan the
output for '[4.00_01]', which you will see contains stuff for V 3.12, 3.8 and 3.x.

See above, under the list of reserved tokens, for how security advisories are inserted in the output
stream.

=item o Is this conversion process perfect?

Well, no, actually, but it will be as good as I can make it.

For example, version numbers like '3.x' are turned into '3.'.

You will simply have to scrutinize (which means 'read I<carefully>') the output of this conversion process.

If a Changes/CHANGES file is not handled by the current version, log a bug report on Request Tracker:
http://rt.cpan.org/Public/

=item o How are datetimes in old-style files parsed?

Firstly try L<DateTime::Format::HTTP>, and if that fails, try these steps:

=over 4

=item o Strip 'st' from 1st, 'nd' from 2nd, etc

=item o Try L<DateTime::Format::Strptime>

=item o If that fails, strip Monday, etc, and retry L<DateTime::Format::Strptime>

I noticed some dates were invalid because the day of the week did not match
the day of the month. So, I arbitrarily chop the day of the week, and retry.

=back

Other date parsing modules are L<Date::Manip>, L<Date::Parse> and L<Regexp::Common::time>.

=item o Why did you choose these 2 modules?

I had a look at a few Changes/CHANGES files, and these made sense.

If appropriate, other modules can be added to the algorithm.

See the discussion on this page (search for 'parse multiple formats'):

http://datetime.perl.org/index.cgi?FAQBasicUsage

If things get more complicated, I will reconsider using L<DateTime::Format::Builder>.

=item o What happens for 2 releases on the same day?

It depends whether or not the version numbers are different.

The C<Changes> file for L<CGI::Session> contains 2 references to version 4.06 :-(.

As long as the version numbers are different, the date does not actually matter.

=item o Will a new file format mean more work for those who maintain CPAN?

Yes, I am afraid so, unless they completely ignore me!

But I am hopeful this will lead to less work overall.

=item o Why did you not use the C<Template Toolkit> for the HTML?

It is too complex for this tiny project.

=item o Where do I go for support?

Log a bug report on Request Tracker: http://rt.cpan.org/Public/

If it concerns failure to convert a specific Changes/CHANGES file, just provide the name of
the module and the version number.

It would help - if the problem is failure to parse a specific datetime format - if you could
advise me on a suitable C<DateTime::Format::*> module to use.

=back

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Module-Metadata-Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module::Metadata::Changes>.

=head1 See Also

L<App::ParseCPANChanges>.

L<CPAN::Changes>

L<Module::Changes>

=head1 Author

L<Module::Metadata::Changes> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
