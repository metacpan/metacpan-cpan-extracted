package Mojolicious::Command::listdeps;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Intent is to have perl critic to complete with no errors when run
##    at the HARSH (3) level
##****************************************************************************

=head1 NAME

Mojolicious::Command::listdeps - Command to list dependencies for a 
Mojolicious project

=head1 VERSION

Version 0.08

=head1 DESCRIPTION

L<Mojolicious::Command::listdeps> lists all module dependencies, and
is typically invoked from the command line in the root of your
L<Mojolicious> project

=head1 SYNOPSIS

  use Mojolicious::Command::listdeps;

  my $command = Mojolicious::Command::listdeps->new;
  $command->run(@ARGV);

=head1 COMMANDLINE OPTIONS

The listdeps command supports the following command line options:

=over 2

=item --include-tests

Include dependencies required for tests

=item --missing

Only list missing modules

=item --skip-lib

Do not list modules found in ./lib as a dependency

=item --verbose

List additional information

=item --core

Include core modules in list

=item --cpanfile

Create or append module information to cpanfile

=back

=cut

##****************************************************************************
##****************************************************************************
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command';
use File::Find;
use File::Spec;
use Module::CoreList;
use Cwd qw(abs_path);
use Getopt::Long qw(GetOptions :config pass_through);

our $VERSION = "0.08";

##****************************************************************************
## Object attributes
##****************************************************************************

=head1 ATTRIBUTES

L<Mojolicious::Command::listdeps> inherits the following attributes
from L<Mojolicious::Command>

=cut

##------------------------------------------------------------

=head2 C<description>

Short description displayed in the "mojo" command list

=cut

##------------------------------------------------------------
has description => qq{List module dependencies.\n};

##------------------------------------------------------------

=head2 C<usage>

Displayed in response to mojo help listdeps

=cut

##------------------------------------------------------------
has usage => << "EOF";
usage: $0 listdeps [OPTIONS]

Parses all files found in the current directory and below and
prints the names of perl modules used in those files.

These options are available:
  --include-tests  Include dependencies required for tests
  --missing        Only list missing modules
  --skip-lib       Do not list modules found in ./lib as a dependency
  --verbose        List additional information
  --core           Include core modules in list
  --cpanfile       Create or append module information to cpanfile 
EOF

##-----------------------------------------
## Module variables
##-----------------------------------------
my $include_tests = 0;       ## Scan test modules also
my $missing_only  = 0;       ## Display only missing modules
my $verbose       = 0;       ## Extra verbage
my $skip_core     = 1;       ## Skip core modules
my $skip_lib      = 0;       ## Skip modules found in ./lib
my $lib_dir       = qq{};    ## Local ./lib if found
my $cpanfile      = qq{};    ## Name of cpanfile

##****************************************************************************
## Object methods
##****************************************************************************

=head1 METHODS

L<Mojolicious::Command::listdeps> inherits its methods from 
from L<Mojolicious::Command>

=cut

##****************************************************************************
##****************************************************************************

=head2 C<run>

  $command->run;
  $command->run(@ARGV);

Used to invoke the command.

=cut

##----------------------------------------------------------------------------
sub run    ## no critic (RequireArgUnpacking)
{
  my $self = shift;
  my @args = @_;

  ## Parse the options
  GetOptions(
    'include-tests' => sub { $include_tests = 1; },
    'core'          => sub { $skip_core     = 0; },
    'missing'       => sub { $missing_only  = 1; },
    'skip-lib'      => sub { $skip_lib      = 1; },
    'verbose'       => sub { $verbose       = 1; },
    'cpanfile:s'    => 
      sub
      {
        my $opt_name  = shift;
        $cpanfile     = shift;
        ## If no value is provided, use the default "cpanfile"
        $cpanfile = qq{cpanfile} unless ($cpanfile);
      },
  );

  ## See if we can load the required modules
  foreach my $module (qq{PPI}, qq{Module::Info},)
  {
    unless (_load_module($module))
    {
      print STDERR (qq{ERROR: Could not load $module!\n});
      return -1;
    }
  }

  ## Convert perl version to something find_version can use
  my $numeric_v = _numify_version($^V);

  ## Determine hash of core modules
  my $core_modules = Module::CoreList->find_version($numeric_v);
  unless ($core_modules)
  {
    print STDERR (
      qq{ERROR: Could not determine list of core modules },
      qq{for this version of perl!\n}
    );
    return -1;
  }

  ## List of files to scan
  my @files = ();

  ## Find files to be scanned
  File::Find::find(
    {
      wanted => sub {
        ## Always look for modules (*.pm)
        push(@files, File::Spec->canonpath($File::Find::name))
          if ($_ =~ /\.pm$/x);
        ## Also check test scripts (*.t) if enabled
        push(@files, File::Spec->canonpath($File::Find::name))
          if ($include_tests && ($_ =~ /\.t$/x));
      },
    },
    qq{.},    ## Starting directory
  );

  ## Set additional library paths
  if (-d qq{lib})
  {
    ## Use canonpath to conver file separators
    $lib_dir = File::Spec->canonpath(abs_path(qq{./lib}));
  }

  ## Display extra information
  if ($verbose)
  {
    print(
      qq{Checking for module dependencies (},
      ($include_tests ? qq{including} : qq{ignoring}),
      qq{ test scripts)\n}
    );
    print(qq{Adding "./lib/" to include path\n})         if ($lib_dir);
    print(qq{Skipping modules loaded from "$lib_dir"\n}) if ($lib_dir);
    print(qq{Scanning the following:},
      qq{\n  "}, join(qq{",\n  "}, @files), qq{"\n});
  }

  ## Now scan files for dependencies
  my $dependencies = _scan_for_dependencies(@files);

  ## Process the list
  _process_results($dependencies, $core_modules);
  return (0);
}

##----------------------------------------------------------------------------
##     @fn _process_results($modules_ref, $core_modules)
##  @brief Process the hash reference containing the moudle dependencies
##  @param $modules_ref - HASH reference whose keys are dependencies
##  @param $core_modules - HASH reference whose keys are core perl modules
## @return
##   @note
##----------------------------------------------------------------------------
sub _process_results
{
  my $modules_ref  = shift;
  my $core_modules = shift;
  my $cpanfh;

  ## Set the include path for Module::Info
  my @new_inc = @INC;
  push(@new_inc, $lib_dir) if ($lib_dir);

  ## Open file if needed
  if ($cpanfile)
  {
    open($cpanfh, qq{>>}, $cpanfile);
    print {$cpanfh} (qq{##}, qq{-} x 60, qq{\n});
    print {$cpanfh} (qq{## Auto generated }, 
      scalar(localtime), 
      qq{\n## using $0 listdeps }, 
      qq{--cpanfile "$cpanfile"\n});
    print {$cpanfh} (qq{##}, qq{-} x 60, qq{\n});
  }
  
  ## Process the list
  foreach my $key (sort(keys(%{$modules_ref})))
  {
    ## Convert Module/Name.pm (if needed)
    my $module = $key;
    $module =~ s{/}{::}gx;
    
    ## Skip core modules
    next if (exists($core_modules->{$module}) && $skip_core);

    ## Get the module info
    my $module_info = Module::Info->new_from_module($module, @new_inc);

    ## Skip modules that can be found (i.e. have $module_info
    next if ($missing_only && $module_info);

    ## Skip modules that are not located in $lib_dir
    next
      if ($skip_lib
      && $module_info
      && $lib_dir           
      && ($lib_dir eq substr($module_info->file, 0, length($lib_dir))));

    ## See if we are creating a cpanfile
    if ($cpanfh)
    {
      ## Write module name to the file
      print {$cpanfh}(qq{require "$module"});
      my $version;
      eval { $version = $module_info->version; };
      $version = qq{} if ($version and ($version eq qq{undef}));
      if ($version)
      {
        ## Write version information to the cpanfile
        print {$cpanfh}(qq{, "$version"});
      }
      print {$cpanfh}(qq{;\n});
    }

    ## If we get here, then we need to list the file
    print($module);
    if ($verbose)
    {
      if ($module_info)
      {
        ## Found the module, so display the filename
        print(qq{ loaded from "}, $module_info->file, qq{"});
      }
      else
      {
        ## Module is missing, so display name of files using the module
        print(qq{ MISSING used by "},
          join(qq{", "}, @{$modules_ref->{$module}->{used_by}}), qq{"});
      }
    }
    print(qq{\n});
  }

  ## Close the cpanfile (if it was open)
  close($cpanfh) if ($cpanfh);
  return;

}

##----------------------------------------------------------------------------
##     @fn _scan_for_dependencies(@file_list)
##  @brief Use PPI to scan the list of files, returning a hash whose keys
##         are module names
##  @param @file_list - List of files to scan
## @return HASH REFERENCE - Hash reference whose keys are module names
##   @note Based on code in Perl::PrereqScanner
##----------------------------------------------------------------------------
sub _scan_for_dependencies
{
  my @files  = @_;
  my $result = {};

  ## Iterate through the list of files
  foreach my $file (@files)
  {
    ## Use PPI to parse the perl source
    my $ppi_doc = PPI::Document->new($file);

    ## See if PPI encountered problems
    if (defined($ppi_doc))
    {
      ## Find regular use and require
      my $includes = $ppi_doc->find('Statement::Include') || [];
      for my $node (@{$includes})
      {
        ## Ignore perl version require/use statments (i.e. "use 5.8;"
        next if ($node->version);

        ## lib.pm is not a "real" dependency, so ignore it
        next if grep { $_ eq $node->module } qw{ lib };

        ## Check for inheritance ("base 'Foo::Bar';"
        if (grep { $_ eq $node->module } qw{ base parent })
        {
          ## Ignore the arguments, just look for the name of the parent
          my @important = grep {
                 $_->isa('PPI::Token::QuoteLike::Words')
              || $_->isa('PPI::Token::Quote')
          } $node->arguments;

          ## Based on code from Perl::PrereqScanner
          my @base_modules = map {
            (
              (
                     $_->isa('PPI::Token::QuoteLike::Words')
                  || $_->isa('PPI::Token::Number')
              ) ? $_->literal : $_->string
              )
          } @important;

          ## Add the modules
          foreach my $module (@base_modules)
          {
            ## Add the dependency of the parent
            _add_used_by($result, $module, $file);
          }
        }
        else
        {
          ## Skip statements like "require $foo"
          next unless $node->module;

          ## Add the dependency
          _add_used_by($result, $node->module, $file);
        }
      }
    }
    else
    {
      print STDERR (qq{Could not scan file "$file"\n});
    }
  }

  return ($result);
}

##----------------------------------------------------------------------------
##     @fn _add_used_by($hash_ref, $module_name, $used_by)
##  @brief Add an entry to the given hash (or create the entry if needed)
##  @param $hash_ref - HASH reference whose keys are module names
##  @param $module_name - Name of the required module
##  @param $used_by - Name of the script requiring the module
## @return
##   @note
##----------------------------------------------------------------------------
sub _add_used_by
{
  my $hash_ref    = shift;
  my $module_name = shift;
  my $used_by     = shift;

  ## See if entry exists
  unless (exists($hash_ref->{$module_name}))
  {
    ## Entry does not exist, so create a new entry
    $hash_ref->{$module_name} = {used_by => [],};
  }

  ## Add to the used_by key
  push(@{$hash_ref->{$module_name}->{used_by}}, $used_by);

  return;
}

##----------------------------------------------------------------------------
##     @fn _load_module($module)
##  @brief Load the given module and return TRUE if module was loaded
##  @param $module - Name of the module
## @return
##   @note
##----------------------------------------------------------------------------
sub _load_module
{
  my $module = shift;

  ## For ease of reading
  my $eval_stmt = qq{require $module; import  $module; 1;};

  ## Attempt to load module
  my $loaded = eval $eval_stmt;    ## no critic (ProhibitStringyEval)

  return $loaded;
}

##----------------------------------------------------------------------------
##     @fn numify_version($ver)
##  @brief Examine proivded version and return as version number
##  @param $ver - Version
## @return SCALAR - Numeric representation of version
##   @note
##----------------------------------------------------------------------------
sub _numify_version
{
  my $ver = shift;

  ## See if version has multiple dots
  if ($ver =~ /\..+\./x)
  {
    ## We need the version module to convert
    unless (_load_module(qq{version}))
    {
      print STDERR (qq{ERROR: Cannot determine version from "$ver"\n});
      return -1;
    }
    ## Convert version into number
    $ver = version->new($ver)->numify;
  }
  ## Added 0 ensures perl treats variable as numeric
  $ver += 0;

  return $ver;
}

1;
__END__

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.


=head1 THANKS

This module was inspired by the listdeps command in L<Dist::Zilla> 

=cut
