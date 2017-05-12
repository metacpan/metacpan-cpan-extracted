package Rose::DBx::Bouquet;

# Author:
#	Ron Savage <ron@savage.net.au>
#
# Note:
#	\t = 4 spaces || die.

use strict;
use warnings;

require 5.005_62;

require Exporter;

use Carp;
use File::Path; # For mkpath and rmtree.
use HTML::Template;
use Rose::DBx::Bouquet::Config;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rose::DBx::Bouquet ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.04';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
	 # These values are the defaults for rose.app.gen.pl's command line options.
	 # If the default value here is undef, and the user did not provide a value via
	 # command line options to rose.app.gen.pl, then get the value from the config file.

	 _exclude    => undef,
	 _module     => 'Local::Wine',
	 _output_dir => undef,
	 _remove     => 0,
	 _tmpl_path  => undef,
	 _verbose    => undef,
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}
}

# -----------------------------------------------

sub log
{
	my($self, $message) = @_;

	if ($$self{'_verbose'})
	{
		print STDERR "$message\n";
	}

} # End of log.

# -----------------------------------------------

sub new
{
	my($class, $arg) = @_;
	my($self)        = bless({}, $class);
	my($config)      = Rose::DBx::Bouquet::Config -> new();

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($$arg{$arg_name}) )
		{
			$$self{$attr_name} = $$arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}

		if (! defined $$self{$attr_name})
		{
			# The '' is for when the user chops the option out of the config file,
			# and also refuses to specify a value on the command line.

			my($method)        = "get_$arg_name";
			$$self{$attr_name} = $config -> $method() || '';
		}
	}

	$$self{'_dir_name'}  = "$$self{'_output_dir'}\::$$self{'_module'}\::Rose";
	$$self{'_dir_name'}  = File::Spec -> catdir(split(/::/, $$self{'_dir_name'}) );
	$$self{'_db_module'} = "$$self{'_module'}\::Base\::DB";;
	my($file)            = $$self{'_db_module'};
	$file                =  File::Spec -> catdir(split(/::/, $file) );

	$self -> log("exclude:         $$self{'_exclude'}");
	$self -> log("module:          $$self{'_module'}");
	$self -> log("output_dir:      $$self{'_output_dir'}");
	$self -> log("remove:          $$self{'_remove'}");
	$self -> log("tmpl_path:       $$self{'_tmpl_path'}");
	$self -> log("verbose:         $$self{'_verbose'}");
	$self -> log("Working dir:     $$self{'_dir_name'}");
	$self -> log("Rose::DB module: $$self{'_db_module'}");

	# Ensure we can load the user's Rose::DB-based module.

	eval "require '$file.pm'";
	croak $@ if $@;

	return $self;

}	# End of new.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	if ($$self{'_remove'})
	{
		$self -> log("Removing:        $$self{'_dir_name'}");
		$self -> log('Success');

		rmtree([$$self{'_dir_name'}]);

		return 0;
	}

	my($rose_db) = $$self{'_db_module'} -> new();
	my($dbh)     = $rose_db -> retain_dbh();
	my($sth)     = $dbh -> table_info(undef, undef, '%', 'TABLE');

	my($data);
	my(@module);
	my($name);

	$self -> log('Processing tables:');

	while ($data = $sth -> fetchrow_hashref() )
	{
		next if ($$data{'TABLE_NAME'} =~ /$$self{'_exclude'}/);

		$self -> log($$data{'TABLE_NAME'});

		$name = ucfirst $$data{'TABLE_NAME'};
		$name =~ s/(.+?)_(.)/$1\u$2/g;

		push @module,
		{
			module_name => $name,
			table_name  => $$data{'TABLE_NAME'},
		}
	}

	$self -> log('Processing modules:');

	@module = sort{$$a{'module_name'} cmp $$b{'module_name'} } @module;

	my($module, @module_loop);
	my(@package_loop);

	for $module (@module)
	{
		$self -> log($$module{'module_name'});

		push @module_loop,
		{
			module => $$module{'module_name'},
		};

		push @package_loop,
		{
			module => $$module{'module_name'},
			prefix => $$self{'_module'},
			table  => $$module{'table_name'},
		};
	}

	mkpath([$$self{'_dir_name'}], 0, 0744);

	$self -> log('Processing template generator.pl.tmpl');

	my($template) = HTML::Template -> new(filename => File::Spec -> catfile($$self{'_tmpl_path'}, 'generator.pl.tmpl') );

	$template -> param(dir_name     => $$self{'_dir_name'});
	$template -> param(module_loop  => \@module_loop);
	$template -> param(package_loop => \@package_loop);
	$template -> param(prefix       => $$self{'_module'});
	$template -> param(remove       => $$self{'_remove'});
	$template -> param(tmpl_path    => $$self{'_tmpl_path'});
	$template -> param(verbose      => $$self{'_verbose'});

	print $template -> output();

	$self -> log('Success');

	return 0;

} # End of run.

# -----------------------------------------------

1;

=head1 NAME

C<Rose::DBx::Bouquet> - Use a database schema to generate Rose-based source code

=head1 Synopsis

	Step 1: Unpack the distros:
	shell> tar xvzf Rose-DBx-Bouquet-1.00.tgz (from CPAN)
	shell> tar xvzf Local-Wine-1.06.tgz (see FAQ)

	Step 2: Check for (and install) the pre-requisites:
	shell> cd Rose-DBx-Bouquet-1.00
	shell> perl Build.PL
	shell> cd ../Local-Wine-1.06
	shell> perl Build.PL

	Note: You /must/ now be in Local-Wine-1.06/.

	Step 3: Create and optionally populate the database:
	Edit lib/Local/Wine/.htwine.conf
	and then
	shell> scripts/create.tables.pl
	shell> scripts/populate.tables.pl

	Step 4: Edit:
	o lib/Rose/DBx/Bouquet/.htrose.bouquet.conf
	o lib/Local/Wine/.htwine.conf

	Step 5: Run the first code generator (see scripts/rosy for an overview):
	shell> scripts/run.rose.app.gen.pl > scripts/run.rose.pl

	Step 6: This is the log from run.rose.app.gen.pl:
	exclude:         ^(?:pg_|sql_)
	module:          Local::Wine
	output_dir:      ./lib
	remove:          0
	tmpl_path:       /home/ron/perl.modules/Rose-DBx-Bouquet-1.00/templates
	verbose:         1
	Working dir:     lib/Local/Wine/Rose
	Rose::DB module: Local::Wine::Base::DB
	Processing tables:
	grape
	vineyard
	wine
	wine_maker
	Processing modules:
	Grape
	Vineyard
	Wine
	WineMaker
	Processing template generator.pl.tmpl
	Success

	Step 7: Run the second code generator:
	shell> perl -Ilib scripts/run.rose.pl

	Step 8: This is the log from run.rose.pl:
	Processing Rose::DB-based modules:
	Generated lib/Local/Wine/Rose/Grape.pm
	Generated lib/Local/Wine/Rose/Vineyard.pm
	Generated lib/Local/Wine/Rose/Wine.pm
	Generated lib/Local/Wine/Rose/WineMaker.pm
	Processing */Manager.pm modules:
	Generated lib/Local/Wine/Rose/Grape/Manager.pm
	Generated lib/Local/Wine/Rose/Vineyard/Manager.pm
	Generated lib/Local/Wine/Rose/Wine/Manager.pm
	Generated lib/Local/Wine/Rose/WineMaker/Manager.pm
	Processing */Form.pm modules:
	Module: Grape. Columns: id, name
	Generated lib/Local/Wine/Rose/Grape/Form.pm
	Module: Vineyard. Columns: id, name
	Generated lib/Local/Wine/Rose/Vineyard/Form.pm
	Module: Wine. Columns: grape_id, id, rating, review_date, vineyard_id, vintage, wine_maker_id
	Generated lib/Local/Wine/Rose/Wine/Form.pm
	Module: WineMaker. Columns: id, name
	Generated lib/Local/Wine/Rose/WineMaker/Form.pm
	Success

	You can see this generated 12 files.
	These files are used by CGI::Application::Bouquet::Rose (on CPAN), and by test.rose.pl.

	Step 9: Test the generated code:
	shell> scripts/test.rose.pl

	Step 10: This is the log (12 lines) from test.rose.pl:
	Total grape record count: 63.
	Page: 1 of 'name like S%'.
	1: Sangiovese,Shiraz.
	2: Sauvignon,Semillon.
	3: Sav Blanc.
	4: Sav Blanc,Semillon.
	Page: 2 of 'name like S%'.
	1: Sav Blanc,Verdelho.
	2: Semillon.
	3: Shiraz.
	4: Sparkling Shiraz.
	Page: 3 of 'name like S%'.

	Step 11: Switch to the instructions for CGI::Application::Bouquet::Rose.

=head1 Description

C<Rose::DBx::Bouquet> is a pure Perl module.

It uses a database schema to generate Rose-based source code.

This documentation uses Local::Wine as the basis for all discussions. See the FAQ for the availability
of the Local::Wine distro.

The generated code can be used as-is, or it can be used by C<CGI::Application::Bouquet::Rose>.

This module is actually a very simple version of C<Rose::DBx::Garden>, and was inspired by the latter.

The main difference, apart from its lack of sophistication of course, is that C<Rose::DBx::Bouquet> uses
C<HTML::Template>-style templates to control the format of all generated code.

C<Rose::DBx::Bouquet> contains just enough code to be usable by C<CGI::Application::Bouquet::Rose>.

If you wish to use C<Rose::DBx::Garden> instead of C<Rose::DBx::Bouquet>, there are a couple of places
in the templates which have to be changed.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<Rose::DBx::Bouquet>.

This is the class's contructor.

Usage: C<< Rose::DBx::Bouquet -> new() >>.

This method takes a hashref of options.

Call C<new()> as C<< new({option_1 => value_1, option_2 => value_2, ...}) >>.

Available options:

=over 4

=item exclude

This takes a regexp (without the //) of table names to exclude.

Code is generated for each table which is I<not> excluded.

If not specified, the value defaults to the value in lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

The default value is ^(?:information_schema|pg_|sql_), which suits users of C<Postgres>.

=item module

This takes the name of a module to be used in the prefix of the namespace of the generated modules.

Generate a set of modules under this name. So, C<Local::Wine> would result in:

=over 4

=item ./lib/Local/Wine/Rose/*.pm (1 per table)

=item ./lib/Local/Wine/Rose/*/Form.pm (1 per table)

=item ./lib/Local/Wine/Rose/*/Manager.pm (1 per table)

=back

These examples assume -output_dir is defaulting to ./lib.

The default value for 'module' is C<Local::Wine>, because this document uses C<Local::Wine> for all examples,
and because you can download the C<Local::Wine> distro from my website, as explained in the FAQ, for testing.

=item output_dir

This takes the path where the output modules are to be written.

If not specified, the value defaults to the value in lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

See the discussion of the 'module' option above for more information.

The default value is ./lib.

=item remove

This takes either a 0 or a 1.

Removes files generated by an earlier run of this program.

For instance, given the output listed under the 'module' option above, it removes
the directory ./lib/Local/Wine/Rose/.

The default value is 0, meaning do not remove files.

=item tmpl_path

This is the path to C<Rose::DBx::Bouquet's> template directory.

These templates are input to the code generation process.

If not specified, the value defaults to the value in lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

The default value is ../Rose-DBx-Bouquet-1.00/templates.

Note: The point of the '../' is because I assume you have done 'cd Local-Wine-1.06'
or the equivalent for whatever module you are working with.

=item verbose

This takes either a 0 or a 1.

Write more or less progress messages to STDERR, during code generation.

The default value is 0.

=back

=head1 FAQ

=over 4

=item Availability of Local::Wine

Download Local::Wine from http://savage.net.au/Perl-modules/Local-Wine-1.06.tgz

The schema is at: http://savage.net.au/Perl-modules/wine.png

C<Rose::DBx::Bouquet> ships with C<rose.app.gen.pl> in the bin/ directory, whereas
C<Local::Wine> ships with various programs in the scripts/ directory.

Files in the /bin directory get installed via 'make install'. Files in the scripts/ directory
are not intended to be installed; they are only used during the code-generation process.

Note also that 'make install' installs lib/Rose/DBx/Bouquet/.htrose.bouquet.conf, and - depending
on your OS - you may need to change its permissions in order to edit it.

=item Minimum modules required when replacing Local::Wine with your own code

Short answer:

=over 4

=item Local::Wine

=item Local::Wine::Config

You can implement this module any way you want. It just has to provide the same methods.

Note specifically that even if you re-write C<Local::Wine::Config>, rather than just copying all the code
into your new module, I believe you should still provide to the end user a config file of options equivalent
to those in .htwine.conf.

=item Local::Wine::Base::Create

=item Local::Wine::DB

This module will use the default type and domain, where 'type' and 'domain' are Rose concepts.

=item Local::Wine::Object

=back

Long answer:

See the docs for Local::Wine.

=item Why isn't Local::Wine on CPAN?

To avoid the problem of people assuming it can be downloaded and used just like any other module.

=item Do you support DBIx::Class besides Rose?

I did not try, but I assume it would be easy to do.

=item How does C<Rose::DBx::Bouquet> handle rows with a great many columns?

All columns are processed.

Future versions of either or both of C<Rose::DBx::Bouquet> and C<CGI::Application::Bouquet::Rose>
will support a 'little language' (http://en.wikipedia.org/wiki/Little_language) which will allow you to
specify the columns to be displayed from the current table.

=item How does C<Rose::DBx::Bouquet> handle foreign keys?

When C<CGI::Application::Bouquet::Rose> displays a HTML form containing a foreign key input field,
you must enter a value (optionally with SQL wild cards) for the foreign key, if you wish to use that field
as a search key.

Future versions of either or both of C<Rose::DBx::Bouquet> and C<CGI::Application::Bouquet::Rose>
will support a 'little language' which will allow you to specify the columns to be displayed from the
foreign table via the value of the foreign key.

=item A note on option management

You'll see a list of option names and default values near the top of this file, in the hash %_attr_data.

Some default values are undef, and some are scalars.

My policy is this:

=over 4

=item If the default is undef...

Then the real default comes from a config file, and is obtained via the *::Config module.

=item If the default is a scalar...

Then that scalar is the default, and cannot be over-ridden by a value from a conf file.

=back

=item But why have such a method of handling options?

Because I believe it makes sense for the end user (you, dear reader), to have the power to change
configuration values without patching the source code. Hence the conf file.

However, for some values, I don't think it makes sense to do that. So, for those options, the default
value is a scalar in the source code of this module.

=item Is this option arrangement permanent?

No. Options whose defaults are already in the config file will never be deleted from that file.

However, options not currently in the config file may be made available via the config file,
depending on feedback.

Also, the config file is an easy way of preparing for more user-editable options.

=back

=head1 Method: log($message)

If C<new()> was called as C<< new({verbose => 1}) >>, write the message to STDERR.

If C<new()> was called as C<< new({verbose => 0}) >> (the default), do nothing.

=head1 Method: run()

Do everything.

See C<bin/rose.app.gen.pl> for an example of how to call C<run()>.

=head1 See also

C<Rose::DBx::Garden>.

=head1 Author

C<Rose::DBx::Bouquet> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
