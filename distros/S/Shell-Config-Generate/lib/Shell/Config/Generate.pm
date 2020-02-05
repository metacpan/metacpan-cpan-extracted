package Shell::Config::Generate;

use strict;
use warnings;
use 5.008001;
use Shell::Guess;
use Carp qw( croak );
use Exporter ();

# ABSTRACT: Portably generate config for any shell
our $VERSION = '0.34'; # VERSION


sub new
{
  my($class) = @_;
  bless { commands => [], echo_off => 0 }, $class;
}


sub set
{
  my($self, $name, $value) = @_;

  push @{ $self->{commands} }, ['set', $name, $value];

  $self;
}


sub set_path
{
  my($self, $name, @list) = @_;

  push @{ $self->{commands} }, [ 'set_path', $name, @list ];

  $self;
}


sub append_path
{
  my($self, $name, @list) = @_;

  push @{ $self->{commands} }, [ 'append_path', $name, @list ]
    if @list > 0;

  $self;
}


sub prepend_path
{
  my($self, $name, @list) = @_;

  push @{ $self->{commands} }, [ 'prepend_path', $name, @list ]
    if @list > 0;

  $self;
}


sub comment
{
  my($self, @comments) = @_;

  push @{ $self->{commands} }, ['comment', $_] for @comments;

  $self;
}


sub shebang
{
  my($self, $location) = @_;
  $self->{shebang} = $location;
  $self;
}


sub echo_off
{
  my($self) = @_;
  $self->{echo_off} = 1;
  $self;
}


sub echo_on
{
  my($self) = @_;
  $self->{echo_off} = 0;
  $self;
}

sub _value_escape_csh
{
  my $value = shift() . '';
  $value =~ s/([\n!])/\\$1/g;
  $value =~ s/(')/'"$1"'/g;
  $value;
}

sub _value_escape_fish
{
  my $value = shift() . '';
  $value =~ s/([\n])/\\$1/g;
  $value =~ s/(')/'"$1"'/g;
  $value;
}

sub _value_escape_sh
{
  my $value = shift() . '';
  $value =~ s/(')/'"$1"'/g;
  $value;
}

sub _value_escape_win32
{
  my $value = shift() . '';
  $value =~ s/%/%%/g;
  $value =~ s/([&^|<>()])/^$1/g;
  $value =~ s/\n/^\n\n/g;
  $value;
}

#   `0  Null
#   `a  Alert bell/beep
#   `b  Backspace
#   `f  Form feed (use with printer output)
#   `n  New line
#   `r  Carriage return
# `r`n  Carriage return + New line
#   `t  Horizontal tab
#   `v  Vertical tab (use with printer output)

my %ps = ( # microsoft would have to be different
  "\0" => '`0',
  "\a" => '`a',
  "\b" => '`b',
  "\f" => '`f',
  "\r" => '`r',
  "\n" => '`n',
  "\t" => '`t',
  #"\v" => '`v',
);

sub _value_escape_powershell
{
  my $value = shift() . '';
  $value =~ s/(["'`\$#()])/`$1/g;
  $value =~ s/([\0\a\b\f\r\n\t])/$ps{$1}/eg;
  $value;
}


sub set_alias
{
  my($self, $alias, $command) = @_;

  push @{ $self->{commands} }, ['alias', $alias, $command];
}


sub set_path_sep
{
  my($self, $sep) = @_;
  push @{ $self->{commands} }, ['set_path_sep', $sep];
}


sub generate
{
  my($self, $shell) = @_;

  if(defined $shell)
  {
    if(ref($shell) eq '')
    {
      my $method = join '_', $shell, 'shell';
      if(Shell::Guess->can($method))
      {
        $shell = Shell::Guess->$method;
      }
      else
      {
        croak("unknown shell type: $shell");
      }
    }
  }
  else
  {
    $shell = Shell::Guess->running_shell;
  }

  $self->_generate($shell);
}

sub _generate
{
  my($self, $shell) = @_;

  my $buffer = '';
  my $sep    = $shell->is_win32 ? ';' : ':';

  if(exists $self->{shebang} && $shell->is_unix)
  {
    if(defined $self->{shebang})
    { $buffer .= "#!" . $self->{shebang} . "\n" }
    else
    { $buffer .= "#!" . $shell->default_location . "\n" }
  }

  if($self->{echo_off} && ($shell->is_cmd || $shell->is_command))
  {
    $buffer .= '@echo off' . "\n";
  }

  foreach my $args (map { [@$_] } @{ $self->{commands} })
  {
    my $command = shift @$args;

    if($command eq 'set_path_sep')
    {
      $sep = shift @$args;
      next;
    }

    # rewrite set_path as set
    if($command eq 'set_path')
    {
      $command = 'set';
      my $name = shift @$args;
      $args = [$name, join $sep, @$args];
    }

    if($command eq 'set')
    {
      my($name, $value) = @$args;
      if($shell->is_c)
      {
        $value = _value_escape_csh($value);
        $buffer .= "setenv $name '$value';\n";
      }
      elsif($shell->is_fish)
      {
        $value = _value_escape_fish($value);
        $buffer .= "set -x $name '$value';\n";
      }
      elsif($shell->is_bourne)
      {
        $value = _value_escape_sh($value);
        $buffer .= "$name='$value';\n";
        $buffer .= "export $name;\n";
      }
      elsif($shell->is_cmd || $shell->is_command)
      {
        $value = _value_escape_win32($value);
        $buffer .= "set $name=$value\n";
      }
      elsif($shell->is_power)
      {
        $value = _value_escape_powershell($value);
        $buffer .= "\$env:$name = \"$value\"\n";
      }
      else
      {
        croak 'don\'t know how to "set" with ' . $shell->name;
      }
    }

    elsif($command eq 'append_path' || $command eq 'prepend_path')
    {
      my($name, @values) = @$args;
      if($shell->is_c)
      {
        my $value = join $sep, map { _value_escape_csh($_) } @values;
        $buffer .= "test \"\$?$name\" = 0 && setenv $name '$value' || ";
        if($command eq 'prepend_path')
        { $buffer .= "setenv $name '$value$sep'\"\$$name\"" }
        else
        { $buffer .= "setenv $name \"\$$name\"'$sep$value'" }
        $buffer .= ";\n";
      }
      elsif($shell->is_bourne)
      {
        my $value = join $sep, map { _value_escape_sh($_) } @values;
        $buffer .= "if [ -n \"\$$name\" ] ; then\n";
        if($command eq 'prepend_path')
        { $buffer .= "  $name='$value$sep'\$$name;\n  export $name;\n" }
        else
        { $buffer .= "  $name=\$$name'$sep$value';\n  export $name\n" }
        $buffer .= "else\n";
        $buffer .= "  $name='$value';\n  export $name;\n";
        $buffer .= "fi;\n";
      }
      elsif($shell->is_fish)
      {
        my $value = join ' ', map { _value_escape_fish($_) } @values;
        $buffer .= "if [ \"\$$name\" == \"\" ]; set -x $name $value; else; ";
        if($command eq 'prepend_path')
        { $buffer .= "set -x $name $value \$$name;" }
        else
        { $buffer .= "set -x $name \$$name $value;" }
        $buffer .= "end\n";
      }
      elsif($shell->is_cmd || $shell->is_command || $shell->is_power)
      {
        my $value = join $sep, map { $shell->is_power ? _value_escape_powershell($_) : _value_escape_win32($_) } @values;
        if($shell->is_power)
        {
          $buffer .= "if(\$env:$name) { ";
          if($command eq 'prepend_path')
          { $buffer .= "\$env:$name = \"$value$sep\" + \$env:$name" }
          else
          { $buffer .= "\$env:$name = \$env:$name + \"$sep$value\"" }
          $buffer .= " } else { \$env:$name = \"$value\" }\n";
        }
        else
        {
          $buffer .= "if defined $name (set ";
          if($command eq 'prepend_path')
          { $buffer .= "$name=$value$sep%$name%" }
          else
          { $buffer .= "$name=%$name%$sep$value" }
          $buffer .=") else (set $name=$value)\n";
        }
      }
      else
      {
        croak 'don\'t know how to "append_path" with ' . $shell->name;
      }
    }

    elsif($command eq 'comment')
    {
      if($shell->is_unix || $shell->is_power)
      {
        $buffer .= "# $_\n" for map { split /\n/, } @$args;
      }
      elsif($shell->is_cmd || $shell->is_command)
      {
        $buffer .= "rem $_\n" for map { split /\n/, } @$args;
      }
      else
      {
        croak 'don\'t know how to "comment" with ' . $shell->name;
      }
    }

    elsif($command eq 'alias')
    {
      if($shell->is_bourne)
      {
        $buffer .= "alias $args->[0]=\"$args->[1]\";\n";
      }
      elsif($shell->is_c)
      {
        $buffer .= "alias $args->[0] $args->[1];\n";
      }
      elsif($shell->is_cmd || $shell->is_command)
      {
        $buffer .= "DOSKEY $args->[0]=$args->[1] \$*\n";
      }
      elsif($shell->is_power)
      {
        $buffer .= sprintf("function %s { %s \$args }\n", $args->[0], _value_escape_powershell($args->[1]));
      }
      elsif($shell->is_fish)
      {
        $buffer .= "alias $args->[0] '$args->[1]';\n";
      }
      else
      {
        croak 'don\'t know how to "alias" with ' . $shell->name;
      }
    }
  }

  $buffer;
}


sub generate_file
{
  my($self, $shell, $filename) = @_;
  my $fh;
  open($fh, '>', $filename) or die "cannot open $filename: $!";
  print $fh $self->generate($shell) or die "cannot write $filename: $!";
  close $fh or die "error closing $filename: $!";
}

*import = \&Exporter::import;

our @EXPORT_OK = qw( win32_space_be_gone cmd_escape_path powershell_escape_path );


*_win_to_posix_path = $^O =~ /^(cygwin|msys)$/ ? \&Cygwin::win_to_posix_path : sub { $_[0] };
*_posix_to_win_path = $^O =~ /^(cygwin|msys)$/ ? \&Cygwin::posix_to_win_path : sub { $_[0] };

sub win32_space_be_gone
{
  return @_ if $^O !~ /^(MSWin32|cygwin|msys)$/;
  map { /\s/ ? _win_to_posix_path(Win32::GetShortPathName(_posix_to_win_path($_))) : $_ } @_;
}


sub cmd_escape_path
{
  my $path = shift() . '';
  $path =~ s/%/%%/g;
  $path =~ s/([&^|<>])/^$1/g;
  $path =~ s/\n/^\n\n/g;
  "\"$path\"";
}


sub powershell_escape_path
{
  map { my $p = _value_escape_powershell($_); $p =~ s/ /` /g; $p } @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shell::Config::Generate - Portably generate config for any shell

=head1 VERSION

version 0.34

=head1 SYNOPSIS

With this start up:

 use Shell::Guess;
 use Shell::Config::Generate;
 
 my $config = Shell::Config::Generate->new;
 $config->comment( 'this is my config file' );
 $config->set( FOO => 'bar' );
 $config->set_path(
   PERL5LIB => '/foo/bar/lib/perl5',
               '/foo/bar/lib/perl5/perl5/site',
 );
 $config->append_path(
   PATH => '/foo/bar/bin',
           '/bar/foo/bin',
 );

This:

 $config->generate_file(Shell::Guess->bourne_shell, 'config.sh');

will generate a config.sh file with this:

 # this is my config file
 FOO='bar';
 export FOO;
 PERL5LIB='/foo/bar/lib/perl5:/foo/bar/lib/perl5/perl5/site';
 export PERL5LIB;
 if [ -n "$PATH" ] ; then
   PATH=$PATH:'/foo/bar/bin:/bar/foo/bin';
   export PATH
 else
   PATH='/foo/bar/bin:/bar/foo/bin';
   export PATH;
 fi;

and this:

 $config->generate_file(Shell::Guess->c_shell, 'config.csh');

will generate a config.csh with this:

 # this is my config file
 setenv FOO 'bar';
 setenv PERL5LIB '/foo/bar/lib/perl5:/foo/bar/lib/perl5/perl5/site';
 test "$?PATH" = 0 && setenv PATH '/foo/bar/bin:/bar/foo/bin' || setenv PATH "$PATH":'/foo/bar/bin:/bar/foo/bin';

and this:

 $config->generate_file(Shell::Guess->cmd_shell, 'config.cmd');

will generate a C<config.cmd> (Windows C<cmd.exe> script) with this:

 rem this is my config file
 set FOO=bar
 set PERL5LIB=/foo/bar/lib/perl5;/foo/bar/lib/perl5/perl5/site
 if defined PATH (set PATH=%PATH%;/foo/bar/bin;/bar/foo/bin) else (set PATH=/foo/bar/bin;/bar/foo/bin)

=head1 DESCRIPTION

This module provides an interface for specifying shell configurations
for different shell environments without having to worry about the
arcane differences between shells such as csh, sh, cmd.exe and command.com.

It does not modify the current environment, but it can be used to
create shell configurations which do modify the environment.

This module uses L<Shell::Guess> to represent the different types
of shells that are supported.  In this way you can statically specify
just one or more shells:

 #!/usr/bin/perl
 use Shell::Guess;
 use Shell::Config::Generate;
 my $config = Shell::Config::Generate->new;
 # ... config config ...
 $config->generate_file(Shell::Guess->bourne_shell,  'foo.sh' );
 $config->generate_file(Shell::Guess->c_shell,       'foo.csh');
 $config->generate_file(Shell::Guess->cmd_shell,     'foo.cmd');
 $config->generate_file(Shell::Guess->command_shell, 'foo.bat');

This will create foo.sh and foo.csh versions of the configurations,
which can be sourced like so:

 #!/bin/sh
 . ./foo.sh

or

 #!/bin/csh
 source foo.csh

It also creates C<.cmd> and C<.bat> files with the same configuration
which can be used in Windows.  The configuration can be imported back
into your shell by simply executing these files:

 C:\> foo.cmd

or

 C:\> foo.bat

Alternatively you can use the shell that called your Perl script using
L<Shell::Guess>'s C<running_shell> method, and write the output to
standard out.

 #!/usr/bin/perl
 use Shell::Guess;
 use Shell::Config::Generate;
 my $config = Shell::Config::Generate->new;
 # ... config config ...
 print $config->generate(Shell::Guess->running_shell);

If you use this pattern, you can eval the output of your script using
your shell's back ticks to import the configuration into the shell.

 #!/bin/sh
 eval `script.pl`

or

 #!/bin/csh
 eval `script.pl`

=head1 CONSTRUCTOR

=head2 new

 my $config = Shell::Config::Generate->new;

creates an instance of She::Config::Generate.

=head1 METHODS

There are two types of instance methods for this class:

=over 4

=item * modifiers

adjust the configuration in an internal portable format

=item * generators

generate shell configuration in a specific format given
the internal portable format stored inside the instance.

=back

The idea is that you can create multiple modifications
to the environment without worrying about specific shells,
then when you are done you can create shell specific
versions of those modifications using the generators.

This may be useful for system administrators that must support
users that use different shells, with a single configuration
generation script written in Perl.

=head2 set

 $config->set( $name => $value );

Set an environment variable.

=head2 set_path

 $config->set_path( $name => @values );

Sets an environment variable which is stored in standard
'path' format (Like PATH or PERL5LIB).  In UNIX land this
is a colon separated list stored as a string.  In Windows
this is a semicolon separated list stored as a string.
You can do the same thing using the C<set> method, but if
you do so you have to determine the correct separator.

This will replace the existing path value if it already
exists.

=head2 append_path

 $config->append_path( $name => @values );

Appends to an environment variable which is stored in standard
'path' format.  This will create a new environment variable if
it doesn't already exist, or add to an existing value.

=head2 prepend_path

 $config->prepend_path( $name => @values );

Prepend to an environment variable which is stored in standard
'path' format.  This will create a new environment variable if
it doesn't already exist, or add to an existing value.

=head2 comment

 $config->comment( $comment );

This will generate a comment in the appropriate format.

B<note> that including comments in your configuration may mean
it will not work with the C<eval> backticks method for importing
configurations into your shell.

=head2 shebang

 $config->shebang;
 $config->shebang($location);

This will generate a shebang at the beginning of the configuration,
making it appropriate for use as a script.  For non UNIX shells this
will be ignored.  If specified, C<$location> will be used as the
interpreter location.  If it is not specified, then the default
location for the shell will be used.

B<note> that the shebang in your configuration may mean
it will not work with the C<eval> backticks method for importing
configurations into your shell.

=head2 echo_off

 $config->echo_off;

For DOS/Windows configurations (C<command.com> or C<cmd.exe>), issue this as the
first line of the config:

 @echo off

=head2 echo_on

 $config->echo_on;

Turn off the echo off (that is do not put anything at the beginning of
the config) for DOS/Windows configurations (C<command.com> or C<cmd.exe>).

=head2 set_alias

 $config->set_alias( $alias => $command )

Sets the given alias to the given command.

Caveat:
some older shells do not support aliases, such as
the original bourne shell.  This module will generate
aliases for those shells anyway, since /bin/sh may
actually be a more modern shell that DOES support
aliases, so do not use this method unless you can be
reasonable sure that the shell you are generating
supports aliases.  On Windows, for PowerShell, a simple
function is used instead of an alias so that arguments
may be specified.

=head2 set_path_sep

 $config->set_path_sep( $sep );

Use C<$sep> as the path separator instead of the shell
default path separator (generally C<:> for Unix shells
and C<;> for Windows shells).

Not all characters are supported, it is usually best
to stick with the shell default or to use C<:> or C<;>.

=head2 generate

 my $command_text = $config->generate;
 my $command_text = $config->generate( $shell );

Generate shell configuration code for the given shell.
C<$shell> is an instance of L<Shell::Guess>.  If C<$shell>
is not provided, then this method will use Shell::Guess
to guess the shell that called your perl script.

You can also pass in the shell name as a string for
C<$shell>.  This should correspond to the appropriate
I<name>_shell from L<Shell::Guess>.  So for csh you
would pass in C<"c"> and for tcsh you would pass in
C<"tc">, etc.

=head2 generate_file

 $config->generate_file( $shell, $filename );

Generate shell configuration code for the given shell
and write it to the given file.  C<$shell> is an instance
of L<Shell::Guess>.  If there is an IO error it will throw
an exception.

=head1 FUNCTIONS

=head2 win32_space_be_gone

 my @new_path_list = win32_space_be_gone( @orig_path_list );

On C<MSWin32> and C<cygwin>:

Given a list of directory paths (or filenames), this will
return an equivalent list of paths pointing to the same
file system objects without spaces.  To do this
C<Win32::GetShortPathName()> is used on to find alternative
path names without spaces.

NOTE that this breaks when Windows is told not to create
short (C<8+3>) filenames; see L<http://www.perlmonks.org/?node_id=333930>
for a discussion of this behaviour.

In addition, on just C<Cygwin>:

The input paths are first converted from POSIX to Windows paths
using C<Cygwin::posix_to_win_path>, and then converted back to
POSIX paths using C<Cygwin::win_to_posix_path>.

Elsewhere:

Returns the same list passed into it

=head2 cmd_escape_path

 my @new_path_list = cmd_escape_path( @orig_path_list )

Given a list of directory paths (or filenames), this will
return an equivalent list of paths escaped for cmd.exe and command.com.

=head2 powershell_escape_path

 my @new_path_list = powershell_escape_path( @orig_path_list )

Given a list of directory paths (or filenames), this will
return an equivalent list of paths escaped for PowerShell.

=head1 CAVEATS

The test suite tests this module's output against the actual
shells that should understand them, if they can be found in
the path.  You can generate configurations for shells which
are not available (for example C<cmd.exe> configurations from UNIX or
bourne configurations under windows), but the test suite only tests
them if they are found during the build of this module.

The implementation for C<csh> depends on the external command C<test>.
As far as I can tell C<test> should be available on all modern
flavors of UNIX which are using C<csh>.  If anyone can figure out
how to prepend or append to path type environment variable without
an external command in C<csh>, then a patch would be appreciated.

The incantation for prepending and appending elements to a path
on csh probably deserve a comment here.  It looks like this:

 test "$?PATH" = 0 && setenv PATH '/foo/bar/bin:/bar/foo/bin' || setenv PATH "$PATH":'/foo/bar/bin:/bar/foo/bin';

=over 4

=item * one line

The command is all on one line, and doesn't use if, which is
probably more clear and ideomatic.  This for example, might
make more sense:

 if ( $?PATH == 0 ) then
   setenv PATH '/foo/bar/bin:/bar/foo/bin'
 else
   setenv PATH "$PATH":'/foo/bar/bin:/bar/foo/bin'
 endif

However, this only works if the code interpreted using the csh
C<source> command or is included in a csh script inline.  If you
try to invoke this code using csh C<eval> then it will helpfully
convert it to one line and if does not work under csh in one line.

=back

There are probably more clever or prettier ways to
append/prepend path environment variables as I am not a shell
programmer.  Patches welcome.

Only UNIX (bourne, bash, csh, ksh, fish and their derivatives) and
Windows (command.com, cmd.exe and PowerShell) are supported so far.

Fish shell support should be considered a tech preview.  The Fish
shell itself is somewhat in flux, and thus some tests are skipped
for the Fish shell since behavior is different for different versions.
In particular, new lines in environment variables may not work on
newer versions.

Patches welcome for your favorite shell / operating system.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brad Macpherson (BRAD, brad-mac)

mohawk

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
