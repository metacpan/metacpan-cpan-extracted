package Module::Install::GetProgramLocations;

use strict;
use 5.005;

use Config;
use Cwd;
use Carp;
use File::Spec;
use Sort::Versions;
use Exporter();

use vars qw( @ISA $VERSION @EXPORT );

use Module::Install::Base;
@ISA = qw( Module::Install::Base Exporter );

@EXPORT = qw( &get_gnu_version
              &get_bzip2_version
            );

$VERSION = sprintf "%d.%02d%02d", q/0.30.8/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub get_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };

  foreach my $program (keys %info)
  {
    croak "argname is required for $program"
      unless defined $info{$program}{'argname'};

    if (exists $info{$program}{'types'}) {
      foreach my $type (keys %{ $info{$program}{'types'} }) {
        next unless exists $info{$program}{'types'}{$type}{'fetch'};

        croak "Fetch routine must be a valid code reference"
          unless ref $info{$program}{'types'}{$type}{'fetch'} eq "CODE" &&
            defined &{ $info{$program}{'types'}{$type}{'fetch'} };
      }
    }
  }

  $self->include_deps('Config',0);
  $self->include_deps('File::Spec',0);
  $self->include_deps('Sort::Versions',0);
  $self->include_deps('Cwd',0);

  my %user_specified_program_paths =
    $self->_get_user_specified_program_locations(\%info);

  if (keys %user_specified_program_paths)
  {
    return $self->_get_argv_program_locations(\%info,
      \%user_specified_program_paths);
  }
  else
  {
    return $self->_prompt_user_for_program_locations(\%info);
  }
}

# ---------------------------------------------------------------------------

sub _get_user_specified_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };

  my %user_specified_program_paths;
  my @remaining_args;

  # Look for user-provided paths in @ARGV
  foreach my $arg (@ARGV)
  {
    my ($var,$value) = $arg =~ /^(.*?)=(.*)$/;

    push(@remaining_args, $arg), next unless defined $var;

    $value = undef if $value eq '';

    my $is_a_program_arg = 0;

    foreach my $program (keys %info)
    {
      if ($var eq $info{$program}{'argname'})
      {
        $user_specified_program_paths{$program} = $value;
        $is_a_program_arg = 1;
        last;
      }
    }

    push @remaining_args, $arg unless $is_a_program_arg;
  }

  @ARGV = @remaining_args;

  return %user_specified_program_paths;
}

# ---------------------------------------------------------------------------

sub _get_argv_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };
  my %program_locations = %{ shift @_ };

  my %program_info;

  foreach my $program_name (sort keys %info)
  {
    $program_info{$program_name} = 
      { 'path' => undef, 'type' => undef, 'version' => undef };

    next if exists $program_locations{$program_name} &&
      $program_locations{$program_name} eq '';

    $program_locations{$program_name} = $info{$program_name}{'default'}
      unless exists $program_locations{$program_name};

    my $full_path = $self->_Make_Absolute($program_locations{$program_name});
    if (!defined $self->can_run($full_path))
    {
      warn "\"$full_path\" does not appear to be a valid executable\n";
      warn "Using anyway\n";

      $program_info{$program_name} =
        { path => $full_path, type => undef, version => undef };
    }
    else
    {
      my ($is_valid,$type,$version) = 
        $self->_program_version_is_valid($program_name,$full_path,\%info);
      
      unless($is_valid)
      {
        warn "\"$full_path\" is not a correct version\n";
        warn "Using anyway\n";
      }

      $program_info{$program_name} =
        { path => $full_path, type => $type, version => $version };
    }
  }

  return %program_info;
}

# ---------------------------------------------------------------------------

sub _prompt_user_for_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };

  # Force the include inc/Module/Install/Can.pm message to appear early
  $self->can_run();

  print "Enter the full path, or \"none\" for none.\n";

  my $last_choice = '';

  my %program_info;

  ASK: foreach my $program_name (sort keys %info)
  {
    my ($name,$full_path);

    # Convert any default to a full path, initially
    $name = $Config{$program_name};
    $full_path = $self->can_run($name);

    if ($name eq '' || !defined $full_path)
    {
      $name = $info{$program_name}{'default'};
      $full_path = $self->can_run($name);
    }

    $full_path = 'none' if !defined $full_path || $name eq '';

    my $allowed_types = '';
    if (exists $info{$program_name}{'types'})
    {
      foreach my $type (keys %{ $info{$program_name}{'types'} } )
      {
        $allowed_types .= ", $type";
      }

      $allowed_types =~ s/^, //;
      $allowed_types =~ s/(.*), /$1, or /;
      $allowed_types = " ($allowed_types";
      $allowed_types .= scalar(keys %{ $info{$program_name}{'types'} }) > 1 ?
        " types)" : " type)";
    }

    my $choice = $self->prompt(
      "Where can I find your \"$program_name\" executable?" .
      "$allowed_types", $full_path);

    $program_info{$program_name} =
      { path => undef, type => undef, version => undef }, next
      if $choice eq 'none';

    $choice = $self->_Make_Absolute($choice);

    if (!defined $self->can_run($choice))
    {
      warn "\"$choice\" does not appear to be a valid executable\n";

      if ($last_choice ne $choice)
      {
        $last_choice = $choice;
        redo ASK;
      }

      warn "Using anyway\n";
    }
    else
    {
      my ($is_valid,$type,$version) = 
        $self->_program_version_is_valid($program_name,$choice,\%info);
      
      if(!$is_valid)
      {
        warn "\"$choice\" is not a correct version\n";

        if ($last_choice ne $choice)
        {
          $last_choice = $choice;
          redo ASK;
        }

        warn "Using anyway\n";
      }

      $program_info{$program_name} =
        { path => $choice, type => $type, version => $version };
    }
  }

  return %program_info;
}

# ---------------------------------------------------------------------------

sub _program_version_is_valid
{
  my $self = shift;
  my $program_name = shift;
  my $program = shift;
  my %info = %{ shift @_ };

  if (exists $info{$program_name}{'types'})
  {
    my $version;

    TYPE: foreach my $type (keys %{$info{$program_name}{'types'}})
    {
      $version = &{$info{$program_name}{'types'}{$type}{'fetch'}}($program);

      next TYPE unless defined $version;

      if ($self->version_matches_range($version,
        $info{$program_name}{'types'}{$type}{'numbers'}))
      {
        return (1,$type,$version);
      }
    }

    my $version_string = '<UNKNOWN>';
    $version_string = $version if defined $version;
    warn "\"$program\" version $version_string is not valid for any of the following:\n";

    foreach my $type (keys %{$info{$program_name}{'types'}})
    {
      warn "  $type => " .
        $info{$program_name}{'types'}{$type}{'numbers'} . "\n";
    }

    return (0,undef,undef);
  }

  return (1,undef,undef);
}

# ---------------------------------------------------------------------------

sub version_matches_range
{
  my $self = shift;
  my $version = shift;
  my $version_specification = shift;

  my $range_pattern = '([\[\(].*?\s*,\s*.*?[\]\)])';

  my @ranges = $version_specification =~ /$range_pattern/g;

  die "Version specification \"$version_specification\" is incorrect\n"
    unless @ranges;

  foreach my $range (@ranges)
  {
    my ($lower_bound,$lower_version,$upper_version,$upper_bound) =
      ( $range =~ /([\[\(])(.*?)\s*,\s*(.*?)([\]\)])/ );
    $lower_bound = '>' . ( $lower_bound eq '[' ? '=' : '');
    $upper_bound = '<' . ( $upper_bound eq ']' ? '=' : '');

    my ($lower_bound_satisified, $upper_bound_satisified);

    $lower_bound_satisified =
      ($lower_version eq '' || versioncmp($version,$lower_version) == 1 ||
      ($lower_bound eq '>=' && versioncmp($version,$lower_version) == 0));
    $upper_bound_satisified =
      ($upper_version eq '' || versioncmp($version,$upper_version) == -1 ||
      ($upper_bound eq '<=' && versioncmp($version,$upper_version) == 0));

    return 1 if $lower_bound_satisified && $upper_bound_satisified;
  }

  return 0;
}

# ---------------------------------------------------------------------------

# Returns the original if the full path can't be found
sub _Make_Absolute
{
  my $self = shift;
  my $program = shift;

  if(File::Spec->file_name_is_absolute($program))
  {
    return $program;
  }
  else
  {
    my $path_to_choice = undef;

    foreach my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), cwd())
    {
      $path_to_choice = File::Spec->catfile($dir, $program);
      last if defined $self->can_run($path_to_choice);
    }

    return $program unless -e $path_to_choice;

    warn "WARNING: Avoiding security risks by converting to absolute paths\n";
    warn "\"$program\" is currently in your path at \"$path_to_choice\"\n";

    return $path_to_choice;
  }
}

# ---------------------------------------------------------------------------

sub get_gnu_version
{
  my $program = shift;

  die "Missing GNU program to get version for" unless defined $program;

  my $version_message;

  # Newer versions
  {
    my $command = "\"$program\" --version 2>" . File::Spec->devnull();
    $version_message = `$command`;
  }

  # Older versions use -V
  unless($version_message =~ /\b(GNU|Free\s+Software\s+Foundation)\b/s)
  {
    my $command = "\"$program\" -V 2>&1 1>" . File::Spec->devnull();
    $version_message = `$command`;
  }

  return undef unless
    $version_message =~ /\b(GNU|Free\s+Software\s+Foundation)\b/s;

  my ($program_version) = $version_message =~ /^.*?([\d]+\.[\d.a-z]+)/s;

  return $program_version;
}

# ---------------------------------------------------------------------------

sub get_bzip2_version
{
  my $program = shift;

  my $command = "\"$program\" --help 2>&1 1>" . File::Spec->devnull();
  my $version_message = `$command`;

  my ($program_version) = $version_message =~ /^.*?([\d]+\.[\d.a-z]+)/s;

  return $program_version;
}

1;

# ---------------------------------------------------------------------------

=head1 NAME

Module::Install::GetProgramLocations - A Module::Install extension that allows the user to interactively specify the location of programs needed by the module to be installed


=head1 SYNOPSIS

A simple example:

  use inc::Module::Install;
  ...
  my %info = (
    # No default, and can't specify it on the command line
    'diff'     => {},
    # A full path default and a command line variable
    'grep'     => { default => '/usr/bin/grep', argname => 'GREP' },
    # A no-path default and a command line variable
    'gzip'     => { default => 'gzip', argname => 'GZIP' },
  );

  my %location_info = get_program_locations(\%info);

  print "grep path is " . $location_info{'grep'}{'path'} . "\n";

A complex example showing all the bells and whistles:

  use inc::Module::Install;
  ...
  # User-defined get version program
  sub get_solaris_grep_version
  {
    my $program = shift;

    my $result = `strings $program | $program SUNW_OST_OSCMD`;

    return undef unless $result =~ /SUNW_OST_OSCMD/;

    # Solaris grep isn't versioned, so we'll just return 0 for it
    return 0;
  }

  my %info = (
    # Either the GNU or the Solaris version
    'grep'     => { default => 'grep', argname => 'GREP',
                    type => {
                      # Any GNU version higher than 2.1
                      'GNU' =>     { fetch => \&get_gnu_version,
                                     numbers => '[2.1,)', },
                      # Any solaris version
                      'Solaris' => { fetch => \&get_solaris_grep_version,
                                     numbers => '[0,)', },
                    },
                  },
  );

  my %location_info = get_program_locations(\%info);

  print "grep path is " . $location_info{'grep'}{'path'} . "\n";
  print "grep type is " . $location_info{'grep'}{'type'} . "\n";
  print "grep version is " . $location_info{'grep'}{'version'} . "\n";


=head1 DESCRIPTION

If you are installing a module that calls external programs, it's best to make
sure that those programs are installed and working correctly. This
Module::Install extension helps with that process. Given a specification of
the required programs, it attempts to find a working version on the system
based on the Perl configuration and the user's path.  The extension then
returns a hash mapping the program names to a hash containing the absolute
path to the program, the type, and the version number. (It's best to use the
absolute path in order to avoid security problems.)

The program specification allows the user to specify a default program, a
command-line name for the program to be set, and multiple types of satisfying
implementations of the program. For the types, the user can specify a function
to extract the version, and a version range to check the version.

The extension defaults to interactive mode, where it asks the user to specify
the paths to the programs. If the user specifies a relative path, the
extension converts this to an absolute path. The user can specify
"none", in which case the hash values will be undefined. Similarly, if the , or if the type or version cannot be determined, then the
hash values will be undefined.

The extension also supports a noninteractive mode, where the programs are
provided on the command line. For example, "perl Makefile.PL
PROGRAM=<program>" is used on the command line to indicate the desired
program. The path is converted to an absolute path.  "<program>" can be empty
to indicate that it is not available.

This extension will perform validation on the program, whether or not it was
specified interactively. It makes sure that the program can be run, and will
optionally check the version for correctness if the user provides that
information. If the program can't be run or is the wrong version, an error
message is displayed. In interactive mode, the user is prompted again.  If the
user enters the same information twice, then the information is used
regardless of any problems. In noninteractive mode, the program is used
anyway.

=head1 METHODS

=over 4

=item get_program_locations(E<lt>HASH REFE<gt>)

This function takes as input a hash with information for the programs to be
found, and returns a hash representing program location data. The keys of the
argument hash are the program names (and can actually be anything). The values
are named:

=over 2

=item default

The default program. This can be non-absolute, in which case the user's PATH
is searched. For example, you might specify "bzip2" as a default for the
"bzip" program because bzip2 can unpack older bzip archives.

=item argname

The command line variable name. For example, if you want the user to be able
to set the path to bzip2, you might set this to "BZIP2" so that the user can
run "perl Makefile.PL BZIP2=/usr/bin/bzip2".

=item types

A hash mapping a descriptive version name to a hash containing a mapping for
two keys:

=over 2

=item fetch

Specifies a subroutine that takes the program path as an argument, and returns
either undef (if the program is not correct) or a version number.

=item numbers

A string containing allowed version ranges. Ranges are specified using
interval notation. That is "[1,2)" indicates versions between 1 and 2,
including 1 but not 2. Any characters can separate ranges, although you'd best
not use any of "[]()" in order to avoid confusing the module.

This module uses the Sort::Versions module for comparing version numbers. See
that module for a summary of version string syntax, and an explanation of how
they compare.

=back

Each of your fetch routines should only succeed for one kind of
implementation, returning undef when they fail.

=back

The return value for get_program_locations is a hash whose keys are the same
as those of %info, and whose values are hashes having three values:

=over 2

=item path

The absolute path to the program. This value is undef if the user chose no
program.

=item type

The name of the type, if there are multiple possible types. This name
corresponds to the name originally given in the "types" hash. This value is
undef if no program was chosen by the user, or if there was no types hash
value.

=item version

The version number of the program.

=back


=item version_matches_range(E<lt>PROGRAM VERSIONE<gt>, E<lt>RANGEE<gt>);

This function takes a program version string and a version ranges specification
and returns true if the program version is in any of the ranges. For example
'1.2.3a' is in the second range of '[1.0,1.1) (1.2.3,)' because 1.2.3a is
higher than 1.2.3, but less than infinity.

=back

=head1 VERSIONING METHODS

This module provides some functions for extracting the version number from
common programs. They are exported by default into the caller's namespace.
Feel free to submit new version functions for programs that you use.

=over 4

=item $version = get_gnu_version(E<lt>PATH TO PROGRAME<gt>)

Gets the version of a general GNU program. Returns undef if the application
does not appear to be a GNU application. This function relies on certain
conventions that the Free Software Foundation uses for printing the version of
GNU applications. It may not work for all programs.

=item $version = get_bzip2_version($path_to_program)

Gets the version of bzip2.

=back

=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.

=head1 AUTHOR

David Coppit E<lt>david@coppit.orgE<gt>

=head1 SEE ALSO

L<Module::Install>

=cut
