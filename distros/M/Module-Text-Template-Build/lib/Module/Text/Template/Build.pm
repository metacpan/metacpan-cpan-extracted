
package Module::Text::Template::Build ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{
use vars qw ($VERSION);
$VERSION     = '0.05';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
#~ Readonly my $EMPTY_STRING => q{} ;

use Text::Template ;
use File::Basename ;
use File::HomeDir ;
use File::Find::Rule ;
use File::Path ;
use File::Slurp ;
use Module::Util qw( :all );
use Data::TreeDumper ;

$OUTPUT_AUTOFLUSH++ ;

#-------------------------------------------------------------------------------

=head1 NAME

Module::Text::Template::Build - Create a module based on a template to use with Module::Build

=head1 SYNOPSIS

 $> create_module --MODULE My::Module --TEMPLATE module_template_directory 

=head1 DESCRIPTION

This script allows you to simply create perl modules from a template. A default template is provided
but you can easily create your own or modify the default template.

=head1 DOCUMENTATION

Given a template structure like this one:

  module_template/
    |-- Build.PL
    |-- Changes
    |-- Makefile.PL
    |-- README
    |-- Todo
    |-- lib
    |   `-- $MODULE_ROOT+$MODULE_NAME.pm
    |-- scripts
    `-- t
      |-- 001_load.t
      |-- 002_pod_coverage.t
      |-- 003_pod.t
      `-- 004_perl_critic.t

Running the command:

  $>create_module --MODULE CONFIG::XYZ --TEMPLATE module_template

Will create this file structure under your current directory:

  CONFIG/
    `-- XYZ
      |-- Build.PL
      |-- Changes
      |-- Makefile.PL
      |-- README
      |-- Todo
      |-- lib
      |   `-- CONFIG
      |       `-- XYZ.pm
      `-- t
        |-- 001_load.t
        |-- 002_pod_coverage.t
        |-- 003_pod.t
        `-- 004_perl_critic.t


All the file in the module template directory are run through L<Text::Template>. Any perl code within '{{' and '}}'
will be evaluated.

This allows you to do variable replacement like this:

  module_name => '{{$FULL_MODULE_NAME}}',

or

  {{$MODULE_NAME}}
  {{'=' x length $MODULE_NAME}}

Thanks to L<Text::Template > you can do advanced query and replacements. You can, for example,
query the module description if you haven't given it on the command line.

  {{
  $|++ ;
  unless(defined $MODULE_DESCRIPTION)
  	{
  	print q{'MODULE_DESCRIPTION' needed for template: '} . __FILE__ . "'.\n" ;
  	print STDOUT "Please input module description: " ;
  	$MODULE_DESCRIPTION = <STDIN> ;
  	}
  }}

=head1 SCRIPT ARGUMENTS

See subroutine C<create_module>

=head1 DEFAULT TEMPLATE

The default template that is installed is based on my experience and may be very different from what 
you expect. It's a good template if you haven't created Perl modules for distribution on CPAN before.

I use Module::Builder as a build system and I use B<git> as a version control system. This is reflected
in the default template.

The xt/author contains many extra tests that are executed when you run:

  ./Build author_test

Changing the template is very easy and you should not hesitate to do it. Being able to very simply 
change the template was the reason I wrote this module.

Also note that the default license is the perl license.

=head2 Variables available to use in the template

I<create_module> will display the available variables and the values they had when creating the module.

  Using these template variables:
    |- DATE = Mon Nov 27 11:42:13 2006
    |- DISTRIBUTION = CONFIG-XYZ
    |- DISTRIBUTION_DIRECTORY = CONFIG/XYZ
    |- DISTRIBUTION_ENV_VARIABLE = CONFIG_XYZ
    |- FULL_MODULE_NAME = CONFIG::XYZ
    |- MODULE = CONFIG::XYZ
    |- MODULE_HIERARCHY = CONFIG::
    |- MODULE_NAME = XYZ
    |- MODULE_ROOT = CONFIG/
    |- MODULE_ROOT+ = CONFIG/
    |- RT_NAME = config-xyz
    |- TEMPLATE = module_template/
    `- YEAR = 2006

=head2 Defining other variables

You can very easily define variables on the command line that you can use in your personal template:

  create_module --MY_VARIABLE 'something I need badly' --MODULE My::Module ...

You can now use I<{{$MY_VARIABLE}}> in your templates and even check if it defined before using it.

=head1 BEFORE THE FIRST RUN

Modify the default template that was installed in your home directory. Grep for the 'MODIFY_ME_BEFORE_FIRST_RUN'
string.

=head1 SCRIPTS

I<create_module> is installed when you install this module.

=head1 SUBROUTINES/METHODS

=cut

sub create_module
{

=head2 create_module(@OPTIONS)

Creates a module skeleton based on a template.

  create_module('My::Next::Module') ;
	
  or
  
  create_module
	(
	'--MODULE' => 'My::Next::Module',
	'--MODULE_DESCRIPTION' =>  'Short description',
	'--TEMPLATE' => 'path_to_template_directory',
	) ;

I<Arguments>

Accepts a single argument, the module name, or a set of key=value pairs.

=over 2 

=item * MODULE - The name of the module to create. For example B<My::Next::Module>.

=item * MODULE_DESCRIPTION - Short description for the module. You'll be prompted for one if none is given.

=item * TEMPLATE - The template location. It is either passed as an argument to I<create_module>
or is automatically searched for in your home directory under I<~/.perl_module_template>.

=item * OUTPUT_DIRECTORY - The directory under which the module will be generated, must exist. Defaults
to your current directory.

=back

I<Returns> - Nothing

I<Exceptions> - croaks, with a message, if the arguments are wrong or the creation doesn't succeed.

=cut

my (@options) = @_ ;

# accept a single argument
if(@options == 1)
	{
	unshift @options, '--MODULE' ;
	}

my $variables = get_template_variables(@options) ;

# check distibution existance
if(-e $variables->{DISTRIBUTION_DIRECTORY})
	{
	croak "Error: Module already exists!\n" ;
	}
else
	{
	mkdir $variables->{DISTRIBUTION_DIRECTORY} ;
	}
	
# copy the template directory structure, replacing pathes and file names

for my $file (File::Find::Rule->readable()->in($variables->{TEMPLATE}))
	{
	create_module_element($file, $variables) ;
	}

return ;
}

#-----------------------------------------------------------------------------------------

sub create_module_element
{

=head2 create_module_element($template_file, \%template_variables)

Runs the given file through the template system and adds it to the module directory

I<Arguments>

=over 2 

=item * $template_file - The file to be run through the template system.

=item * \%template_variables - Variables available during the template system run.

=back

I<Returns> - Nothing.

I<Exceptions> - croaks in case of error.

=cut

my ($template_file, $template_variables) = @_ ;

my $module_element_source = $template_file ;

my $module_element =  $template_file ;
$module_element    =~ s/^$template_variables->{TEMPLATE}//sxm ;
$module_element    =  evaluate_name
					(
					  $template_variables->{DISTRIBUTION_DIRECTORY} . q{/} . $module_element
					, $template_variables
					) ;

# create
my ($basename, $path, $ext) = File::Basename::fileparse($module_element, ('\..*')) ;

unless(-e $path)
	{
	mkpath $path or croak "Error: Couldn't create directory '$path': $!" ;
	}
	
if(-d $template_file)
	{
	mkpath $module_element ;
	}
	
if(-f $template_file)
	{
	my $template = Text::Template->new
					(
					TYPE => 'FILE',
					SOURCE => $template_file,
					DELIMITERS => ['{{', '}}'],
					BROKEN => \&broken_template_handler,
					);
					
	my $text = $template->fill_in(HASH => $template_variables) ;

	unless(defined $text)
		{
		croak "Error: Can't evaluate template '$module_element_source':\n\t$Text::Template::ERROR\n" ;
		}
	
	write_file($module_element, $text) or croak "Error: Failed generating image of '$File::Find::name' : $!" ;
	}

return ;
}

#-----------------------------------------------------------------------------------------

sub broken_template_handler
{

=head2 broken_template_handler()

Error handler required by the template system.

=cut

my %args = @_ ;
croak $args{error} ;

return; # stop template processing
}

#-----------------------------------------------------------------------------------------

sub evaluate_name
{

=head2 evaluate_name($name, \%lookup_table))

Interpolates variables embedded i a string.

I<Arguments>

=over 2 

=item * $name - A string with, possibly, embedded variables to interpolate

=item * \%lookup_table - A hash where the keys are the variable names and the keys their values

=back

I<Returns> - A string with the, possibly, embedded variables interpolated 

=cut

my ($name, $lookup_table) = @_ ;

# check the used variable exists
while($name =~ /\$([a-zA-Z0-9+_]+)/sxmg)
	{
	my $element = $1 ;
	
	unless(exists $lookup_table->{$element})
		{
		warn ("configuration variable '$element' doesn't exist!\n") ;
		next ;
		}
	}

$name =~ s/\$([a-zA-Z0-9+_]+)/exists $lookup_table->{$1} ? $lookup_table->{$1} : $1 /sxmge ;

return($name) ;
}

#-----------------------------------------------------------------------------------------

sub get_template_variables
{

=head2 get_template_variables(@command_line_arguments)

Verify the variables passed as arguments. It also creates new variables to be made available to the template system.

I<Arguments> - Same arguments as sub B<create_module>

I<Returns> - A variable look-up table (a hash where the keys are the variable names and the keys their values).

I<Exceptions> croaks if the options are not passed as key and value pairs or if required definitions are missing.

=cut

my (@command_line_arguments) = @_ ;

if(@command_line_arguments % 2 )
	{
	croak "Error: expected options in key=value format! Run 'perldoc Module::Text::Template::Build' for help.\n" ;
	}

my (%template_variables, @invalid_arguments)  ;

while (@command_line_arguments)
	{
	my($argument, $value) = (shift @command_line_arguments, shift @command_line_arguments) ;
	
	if($argument !~ /^--?[a-zA-Z0-9_:]+/sxm)
		{
		push @invalid_arguments, $argument ;
		}
	else
		{
		$argument =~ s/^--?//sxm ;
		$template_variables{$argument} = $value ;
		}
	}

if(@invalid_arguments)
	{
	croak "Error: Invalid argument!\n" . join("\n", @invalid_arguments) . "\n" ;
	}

# output directory
unless(exists $template_variables{OUTPUT_DIRECTORY})
	{
	$template_variables{OUTPUT_DIRECTORY} = q{./} ;
	}
	
croak "Error: Output directory doesn't exists!\n"  unless(-e $template_variables{OUTPUT_DIRECTORY}) ;

# module
croak "Error: Missing MODULE argument!\n" unless exists $template_variables{MODULE} ;
croak "Error: Invalid module name!\n"  unless(is_valid_module_name($template_variables{MODULE} )) ;

unless(exists $template_variables{MODULE_DESCRIPTION})
	{
	print "MODULE_DESCRIPTION' needed to fill template:\n" or croak q{Can't use 'print'} ;
	print 'Please input single line module description: ' or croak q{Can't use 'print'} ;
	$template_variables{MODULE_DESCRIPTION} = <STDIN> ;
	}

chomp($template_variables{MODULE_DESCRIPTION}) ;

# template
unless(exists $template_variables{TEMPLATE})
	{
	my $default_template = home() . '/.perl_module_template' ;
	
	if(-e $default_template)
		{
		$template_variables{TEMPLATE} = $default_template ;
		warn "Using default template at '$default_template'.\n" ;
		}
	else
		{
		croak "Error: Missing TEMPLATE argument!\n" ;
		}
	}

croak "Error: Template doesn't exists!\n"  unless(-e $template_variables{TEMPLATE}) ;
croak "Error: Template is not a directory!\n" unless(-d $template_variables{TEMPLATE}) ;

# generate variables
(my $distribution_directory = $template_variables{MODULE}) =~ s/::/\//sxmg ;

my ($basename, $module_root, $ext) = File::Basename::fileparse($distribution_directory, ('\..*')) ;
my $module_name = "$basename$ext" ;

(my $module_hierarchy = $module_root) =~ s/\//::/sxmg ;

my $full_module_name = $module_hierarchy . $module_name ;
(my $distribution = $full_module_name) =~ s/::/-/sxmg ;
(my $distribution_env_variable = $full_module_name) =~ s/::/_/sxmg ;

my $rt_name = lc $distribution ;

# under output directory
$distribution_directory = $template_variables{OUTPUT_DIRECTORY} . q{/} . $distribution_directory ;

Readonly my $YEAR_INDEX => 5 ;
Readonly my $YEAR_1900 => 1900 ;

%template_variables =
	(
	DISTRIBUTION_DIRECTORY => $distribution_directory, 
	'MODULE_ROOT+'         => $module_root,
	DATE                   => scalar localtime,
	DISTRIBUTION           => $distribution,
	DISTRIBUTION_ENV_VARIABLE => $distribution_env_variable,
	MODULE_HIERARCHY       => $module_hierarchy,
	MODULE_NAME            => $module_name,
	MODULE_ROOT            => $module_root,
	FULL_MODULE_NAME       => $full_module_name,
	RT_NAME                => $rt_name,
	YEAR                   => (localtime())[$YEAR_INDEX] + $YEAR_1900,
	%template_variables,
	) ;

print DumpTree(\%template_variables, 'Using these template variables:', DISPLAY_ADDRESS => 0) or croak q{Can't use 'print'} ;

return(\%template_variables) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Text::Template::Build

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Text-Template-Build>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-module-text-template-build@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Text-Template-Build>

=back

=head1 SEE ALSO

L<Module::Starter> from which I proudly stole the good ideas while trying to avoid the excessive boilerplate.

B<h2xs>

L<Module::Template::Setup>

L<Text::Template>

=cut
