package Module::Metadata::CoreList;

use strict;
use warnings;

use Config;

use Date::Simple;

use File::Spec;

use Hash::FieldHash ':all';

use Module::CoreList;

use Module::Metadata::CoreList::Config;

use Text::Xslate 'mark_raw';

fieldhash my %config       => 'config';
fieldhash my %dir_name     => 'dir_name';
fieldhash my %file_name    => 'file_name';
fieldhash my %module_name  => 'module_name';
fieldhash my %perl_version => 'perl_version';
fieldhash my %report_type  => 'report_type';

our $VERSION = '1.07';

# ------------------------------------------------

sub _build_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6.0.4'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;
}
 # End of _build_environment.

# -----------------------------------------------

sub check_perl_for_module
{
	my($self)         = @_;
	my($module_name)  = $self -> module_name;
	my($perl_version) = $self -> perl_version;

	if ($module_name && $perl_version)
	{
		if ($Module::CoreList::version{$perl_version} && exists $Module::CoreList::version{$perl_version}{$module_name})
		{
			print exists $Module::CoreList::version{$perl_version}{$module_name} ? $Module::CoreList::version{$perl_version}{$module_name} : 'undef', "\n";
		}
		else
		{
			die "Unknown version of Perl ($perl_version), or unknown module ($module_name)\n";
		}
	}
	else
	{
		die "Either module_name or perl_version not specified\n";
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of check_perl_for_module.

# -----------------------------------------------

sub check_perl_module
{
	my($self)         = @_;
	my($module_name)  = $self -> module_name;
	my($perl_version) = $self -> perl_version;

	if ($module_name)
	{
		my($prefix) = "Module names which match the regexp qr/$module_name/" . ($perl_version ? " in Perl V $perl_version: " : ': ');

		print $prefix, join(', ', Module::CoreList::find_modules(qr/$module_name/, $perl_version ? $perl_version : () ) ), ". \n";
	}
	elsif ($perl_version)
	{
		print 'Module::CoreList ', (Module::CoreList::find_version($perl_version) ? 'recognizes' : 'does not recognize'), " V $perl_version of Perl. \n";
	}
	else
	{
		die "Neither module_name nor perl_version specified\n";
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of check_perl_module.

# -----------------------------------------------

sub _init
{
	my($self, $arg)     = @_;
	$$arg{config}       = Module::Metadata::CoreList::Config -> new -> config;
	$$arg{dir_name}     ||= '.';    # Caller can set.
	$$arg{file_name}    ||= '';     # Caller can set.
	$$arg{module_name}  ||= '';     # Caller can set.
	$$arg{perl_version} ||= '';     # Caller can set.
	$$arg{report_type}  ||= 'text'; # Caller can set.

	return from_hash($self, $arg);

} # End of _init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# -----------------------------------------------

sub process_build_pl
{
	my($self, $line_ara) = @_;

	# Assumed input format:
	# build_requires =>
	# {
	#	"Test::More" => 0,
	#	'Test::Pod'  => 0,
	# },
	# configure_requires =>
	# {
	#	Module::Build => 0,
	# },
	# requires =>
	# {
	#	Module::CoreList => 0,
	# },

	my(@name);

	my($candidate) = 0;

	for my $line (@$line_ara)
	{
		if ($line =~ /^\s*(?:build_|configure_|)requires/i)
		{
			$candidate = 1;
		}
		elsif ($candidate && $line =~ /^\s*}/)
		{
			$candidate = 0;
		}
		elsif ($candidate && ($line =~ /^\s*(['"])?([\w:]+)\1?\s*=>\s*(.+),/) )
		{
			push @name, [$2, $3];
		}
	}

	return [sort{$$a[0] cmp $$b[0]} @name];

}	# End of process_build_pl.

# -----------------------------------------------

sub process_makefile_pl
{
	my($self, $line_ara) = @_;

	# Assumed input format:
	# PREREQ_PM =>
	# {
	#	Module::CoreList => 0,
	#	'Test::More'     => 0,
	#	"Test::Pod"      => 0,
	# },

	my(@name);

	my($candidate) = 0;

	for my $line (@$line_ara)
	{
		if ($line =~ /^\s*PREREQ_PM/i)
		{
			$candidate = 1;
		}
		elsif ($candidate && $line =~ /^\s*}/)
		{
			$candidate = 0;
		}
		elsif ($candidate && ($line =~ /^\s*(['"])?([\w:]+)\1?\s*=>\s*(.+),/) )
		{
			push @name, [$2, $3];
		}
	}

	return [sort{$$a[0] cmp $$b[0]} @name];

}	# End of process_makefile_pl.

#  -----------------------------------------------

sub report_as_html
{
	my($self, $module_list) = @_;
	my($templater) = Text::Xslate -> new
		(
		 input_layer => '',
		 path        => ${$self -> config}{template_path},
		);

	my(%module_list)    = map{($$_[0] => undef)} @$module_list;
	my(%module_version) = map{($$_[0] => $$_[1])} @$module_list;
	my($perl_version)   = $self -> perl_version;
	my(@present)        = [{td => 'Module'}, {td => $self -> file_name}, {td => 'CoreList'}];

	for my $name (@$module_list)
	{
		for my $module (sort keys %{$Module::CoreList::version{$perl_version} })
		{
			if ($module eq $$name[0])
			{
				$module_list{$module} = $Module::CoreList::version{$perl_version}{$module} || 0;

				push @present, [{td => $$name[0]}, {td => $$name[1]} , {td => $module_list{$module} }];
			}
		}
	}

	my(@absent) = [{td => 'Module'}, {td => $self -> file_name}];

	for my $name (sort keys %module_list)
	{
		if (! defined $module_list{$name})
		{
			push @absent, [{td => $name} ,{td => $module_version{$name} }];
		}
	}

	my($config)      = $self -> config;
	my(@module_list) =
	(
		'<a href="https://metacpan.org/release/Module-CoreList">Module::CoreList</a>',
		'<a href="https://metacpan.org/release/Module-Metadata-CoreList">Module::Metadata::CoreList</a>',
	);

	push @module_list, '<a href="https://metacpan.org/release/Data-Session">Data::Session</a>' if ($ENV{AUTHOR_TESTING});

	print $templater -> render
	(
	'web.page.tx',
	{
		absent_heading  => "Modules found in @{[$self -> file_name]} but not in Module::CoreList V $Module::CoreList::VERSION",
		absent_modules  => [@absent],
		default_css     => "$$config{css_url}/default.css",
		environment     => $self -> _build_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		module_list     => mark_raw(join(', ', @module_list) ),
		options         => "-d @{[$self -> dir_name]} -f @{[$self -> file_name]} -p @{[$self -> perl_version]}",
		present_heading => "Modules found in @{[$self -> file_name]} and in Module::CoreList V $Module::CoreList::VERSION",
		present_modules => [@present],
		version         => $VERSION,
	}
	);

} # End of report_as_html.

#  -----------------------------------------------

sub report_as_text
{
	my($self, $module_list) = @_;

	print "Options: -d @{[$self -> dir_name]} -f @{[$self -> file_name]} -p @{[$self -> perl_version]}. \n";

	my(%module_list)    = map{($$_[0] => undef)} @$module_list;
	my(%module_version) = map{($$_[0] => $$_[1])} @$module_list;

	print "Modules found in @{[$self -> file_name]} and in Module::CoreList V $Module::CoreList::VERSION:\n";

	my($perl_version) = $self -> perl_version;

	for my $name (@$module_list)
	{
		for my $module (sort keys %{$Module::CoreList::version{$perl_version} })
		{
			if ($module eq $$name[0])
			{
				$module_list{$module} = $Module::CoreList::version{$perl_version}{$module} || 0;

				print "$module => $$name[1] and $module_list{$module}. \n";
			}
		}
	}

	print "Modules found in @{[$self -> file_name]} but not in Module::CoreList V $Module::CoreList::VERSION: \n";

	for my $name (sort keys %module_list)
	{
		if (! defined $module_list{$name})
		{
			print "$name => $module_version{$name}. \n";
		}
	}

} # End of report_as_text.

#  -----------------------------------------------

sub run
{
	my($self)      = @_;
	my($file_name) = $self -> file_name;

	if (! $file_name)
	{
		$file_name = 'Build.PL|Makefile.PL';
	}
	elsif ($file_name !~ /^(?:Build.PL|Makefile.PL)$/i)
	{
		die "The file_name option's value must be either Build.PL or Makefile.PL\n";
	}

	opendir(INX, $self -> dir_name) || die "Can't opendir(@{[$self -> dir_name]}): $!\n";
	my(@file) = sort grep{/^(?:$file_name)$/} readdir INX;
	closedir INX;

	if ($#file < 0)
	{
		die "Can't find either Build.PL or Makefile.PL in directory '@{[$self -> dir_name]}'\n";
	}

	# Read whatever name ends up in $file[0].

	$self -> file_name($file[0]);

	open(INX, File::Spec -> catfile($self -> dir_name, $file[0]) ) || die "Can't open($file[0]): $!\n";
	my(@line) = <INX>;
	close INX;

	chomp @line;

	my($module_list);

	if ($file[0] eq 'Build.PL')
	{
		$module_list = $self -> process_build_pl(\@line);
	}
	else
	{
		$module_list = $self -> process_makefile_pl(\@line);
	}

	if ($self -> report_type =~ /^h/i)
	{
		$self -> report_as_html($module_list);
	}
	else
	{
		$self -> report_as_text($module_list);
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# -----------------------------------------------

1;

=head1 NAME

Module::Metadata::CoreList - Scripts to cross-check Build.PL/Makefile.PL with Module::CoreList, etc

=head1 Synopsis

These scripts are shipped in the bin/ directory of the distro, and hence are installed along with the modules,
and will then be on your $PATH.

=head2 bin/cc.corelist.pl

bin/cc.corelist.pl is a parameterized version of the following code.

Try running cc.corelist.pl -h.

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Module::Metadata::CoreList;

	# -----------------------------------------------

	Module::Metadata::CoreList -> new
	(
	dir_name     => '/home/ron/perl.modules/Data-Session',
	perl_version => '5.012001',
	report_type  => 'html',
	) -> run;

=head2 bin/cc.perlmodule.pl

bin/cc.perlmodule.pl is a parameterized version of the following code.

Try running cc.perlmodule.pl -h.

=head3 Usage with just a Perl version specified:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Module::Metadata::CoreList;

	# -----------------------------------------------

	Module::Metadata::CoreList -> new
	(
	perl_version => '5.012001',
	) -> check_perl_module;

Output:

	Module::CoreList recognizes V 5.012001 of Perl.

But try running it with perl_version => '5.012005' and the output is:

	Module::CoreList does not recognize V 5.012005 of Perl.

=head3 Usage with module_name specified, with or without perl_version specified:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Module::Metadata::CoreList;

	# -----------------------------------------------

	Module::Metadata::CoreList -> new
	(
	module_name => 'warnings',
	) -> check_perl_module;

Output:

	Module names which match the regexp qr/warnings/: encoding::warnings, warnings, warnings::register.

Now add perl_version => '5.008001', and the output is:

	Module names which match the regexp qr/warnings/ in Perl V 5.008001: warnings, warnings::register.

This means encoding::warnings was not shipped in V 5.8.1 of Perl.

=head2 cc.whichperlmodule.pl

Run this module as:

	cc.whichperlmodule.pl -p 5.008001 -m Module::CoreList
	cc.whichperlmodule.pl -p 5.014001 -m Module::CoreList
	cc.whichperlmodule.pl -p 5.014002 -m strict

and the outputs will be:

	Unknown version of Perl (5.008001), or unknown module (Module::CoreList)
	2.49_01
	1.04

meaning that if the module was shipped with that version of Perl, the version # of the module is reported.

There is no -report_type option for this program. Output is just 1 line of text.
This means there is no need to edit the config file to run cc.whichperlmodule.pl.

=head1 Description

L<Module::Metadata::CoreList> is a pure Perl module.

=head2 Usage via method check_perl_for_module()

This usage cross-checks a module's existence within the modules shipped with a specific version of Perl.

It's aim is to aid module authors in fine-tuning the versions of modules listed in Build.PL and Makefile.PL.

See L</bin/cc.whichperlmodule.pl> as discussed in the synopsis.

=head2 Usage via method check_perl_module()

This usage tells you whether or not you've correctly specified a Perl version number, as recognized by L<Module::CoreList>,
by calling the latter module's find_version() function.

Further, you can detrmine whether or not a specific module is shipped with a specific version of Perl, by calling
L<Module::CoreList>'s function find_modules().

See L</bin/cc.perlmodule.pl> as discussed in the synopsis.

=head2 Usage via method run()

This usage cross-checks a module's pre-requisites with the versions shipped with a specific version of Perl.

It's aim is to aid module authors in fine-tuning the versions of modules listed in Build.PL and Makefile.PL.

It does this by reading Build.PL or Makefile.PL to get a list of pre-requisites, and looks
up those module names in L<Module::CoreList>.

The output report can be in either text or HTML.

Here is a sample HTML report: L<http://savage.net.au/Perl-modules/html/module.metadata.corelist.report.html>.

This report is shipped in htdocs/.

See L</bin/cc.corelist.pl> as discussed in the synopsis.

=head2 Inheritance model

To keep this module light-weight, it uses L<Hash::FieldHash> mutators for managing object attributes.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Installation

=head2 The Module Itself

Install L<Module::Metadata::CoreList> as you would for any C<Perl> module:

Run:

	cpanm Module::Metadata::CoreList

or run:

	sudo cpan Module::Metadata::CoreList

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head2 The Configuration File

All that remains is to tell L<Module::Metadata::CoreList> your values for some options.

For that, see config/.htmodule.metadata.corelist.conf.

The default value for template_path is /dev/shm/html/assets/templates/module/metadata/corelist,
where /dev/shm/ is Debian's RAM disk, since on my dev box I have the web server's doc root dir
set to /dev/shm/html/.

The template files are shipped in htdocs/assets/templates/module/metadata/corelist.

If you are using Build.PL, running Build (without parameters) will run scripts/copy.config.pl,
as explained next.

If you are using Makefile.PL, running make (without parameters) will also run scripts/copy.config.pl.

Either way, before editing the config file, ensure you run scripts/copy.config.pl. It will copy
the config file using L<File::HomeDir>, to a directory where the run-time code in
L<Module::Metadata::CoreList> will look for it. Run it manually like this:

	shell>cd Module-Metadata-CoreList-1.00
	shell>perl scripts/copy.config.pl

Under Debian, this directory will be $HOME/.perl/Module-Metadata-CoreList/. When you
run copy.config.pl, it will report where it has copied the config file to.

Check the docs for L<File::HomeDir> to see what your operating system returns for a
call to my_dist_config().

The point of this is that after the module is installed, the config file will be
easily accessible and editable without needing permission to write to the directory
structure in which modules are stored.

That's why L<File::HomeDir> and L<Path::Class> are pre-requisites for this module.

All modules which ship with their own config file are advised to use the same mechanism
for storing such files.

=head1 Constructor and initialization

new(...) returns an object of type L<Module::Metadata::CoreList>.

This is the class's contructor.

Usage: C<< Module::Metadata::CoreList -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options:

=over 4

=item o dir_name => $dir_name

Specify the directory to search in for Build.PL and/or Makefile.PL.

Default: '.'.

This key is optional.

=item o file_name => Build.PL or Makefile.PL

Specify that you only want to process the given file.

This means the code searches for both Build.PL and Makefile.PL,
and processes the first one after sorting the names alphabetically.

Default: ''.

This key is optional.

=item o module_name => $module_name

Specify the name of the module to use, in the call to check_perl_module().

When method run() is called, this value is ignored.

Default: ''.

This key is optional, but if omitted then perl_version must be specified.

=item o perl_version => $version

Specify the specific version of Perl to consider, when accessing L<Module::CoreList>.

Perl V 5.10.1 must be written as 5.010001, and V 5.12.1 as 5.012001.

Default: ''.

This key is mandatory when calling run(), but when calling check_perl_module() it need only
be specified if module_name is not specified.

=item o report_type => 'html' or 'text'

Specify what type of report to produce. This report is written to STDOUT.

Default: 'text'.

This key is optional.

Here is a sample HTML report: L<http://savage.net.au/Perl-modules/html/module.metadata.corelist.report.html>.

This report is shipped in htdocs/.

=back

=head1 Methods

=head2 check_perl_for_module()

As the name says, Perl itself is checked to see if a module ships with a given version of perl.

See L</bin/cc.whichperlmodule.pl> as discussed in the synopsis.

Method check_perl_for_module() always returns 0 (for success).

=head2 check_perl_module()

This module first checks the value of the module_name option.

=over 4

=item o If the user has specified a module name...

Use both the specified module name, and the perl version (if any), to call L<Module::CoreList>'s
find_modules() function.

The output is a single line of text. The value of report_type is ignored.

=item o If the user has not specified a module name...

Use just the perl version to call L<Module::CoreList>'s find_version() function.

The output is a single line of text. The values of module_name and report_type are ignored.

=back

See L</bin/cc.perlmodule.pl> as discussed in the synopsis.

Method check_perl_module() always returns 0 (for success).

=head2 process_build_pl($line_ara)

Process Build.PL.

$line_ara is an arrayref of lines, chomped, read from Build.PL.

Returns an arrayref of module names extracted from the build_requires, configure_requires and requires
sections of Build.PL.

Each element of the returned arrayref is an arrayref of 2 elements: The module name and the version #.

The arrayref is sorted by module name.

Called from L</run()>.

=head2 process_makefile_pl($line_ara)

Process Makefile.PL.

$line_ara is an arrayref of lines, chomped, read from Makefile.PL.

Returns an arrayref of module names extracted from the PREREQ_PM section of Makefile.PL.

Each element of the returned arrayref is an arrayref of 2 elements: The module name and the version #.

The arrayref is sorted by module name.

Called from L</run()>.

=head2 report_as_html($module_list)

$module_list is the arrayref returned from L</process_build_pl($line_ara)> and L</process_makefile_pl($line_ara)>.

Outputs a HTML report to STDOUT.

Called from L</run()>.

=head2 report_as_text($module_list)

$module_list is the arrayref returned from L</process_build_pl($line_ara)> and L</process_makefile_pl($line_ara)>.

Outputs a text report to STDOUT.

Called from L</run()>.

=head2 run()

Does all the work.

Calls either L<process_build_pl($line_ara)> or L</process_makefile_pl($line_ara)>, then calls either
L</report_as_html($module_list)> or L</report_as_text($module_list)>.

See L</bin/cc.corelist.pl> as discussed in the synopsis.

Method run() always returns 0 (for success).

=head1 Author

L<Module::Metadata::CoreList> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
