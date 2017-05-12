package Shell::Guess;

use strict;
use warnings;
use File::Spec;

# TODO: see where we can use P9Y::ProcessTable

# ABSTRACT: Make an educated guess about the shell in use
our $VERSION = '0.06'; # VERSION


sub _win32_getppid
{
  require Win32::Getppid;
  Win32::Getppid::getppid();
}

sub running_shell
{
  if($^O eq 'MSWin32')
  {
    my $shell_name = eval {
      require Win32::Process::List;
      my $parent_pid = _win32_getppid();
      Win32::Process::List->new->{processes}->[0]->{$parent_pid}
    };
    if(defined $shell_name)
    {
      if($shell_name =~ /cmd\.exe$/)
      { return __PACKAGE__->cmd_shell }
      elsif($shell_name =~ /powershell\.exe$/)
      { return __PACKAGE__->power_shell }
      elsif($shell_name =~ /command\.com$/)
      { return __PACKAGE__->command_shell }
    }
  }

  if($^O eq 'MSWin32')
  {
    if($ENV{ComSpec} =~ /cmd\.exe$/)
    { return __PACKAGE__->cmd_shell }
    else
    { return __PACKAGE__->command_shell }
  }

  return __PACKAGE__->dcl_shell     if $^O eq 'VMS';
  return __PACKAGE__->command_shell if $^O eq 'dos';

  my $shell = eval {
    open(my $fh, '<', File::Spec->catfile('', 'proc', getppid, 'cmdline')) || die;
    my $command_line = <$fh>;
    die unless defined $command_line; # don't spew warnings if read failed
    close $fh;
    $command_line =~ s/\0.*$//;
    _unixy_shells($command_line);
  }
  
  || eval {
    require Unix::Process;
    my $method = $^O eq 'solaris' ? 'comm' : 'command';
    my($command) = map { s/\s+.*$//; $_ } Unix::Process->$method(getppid);
    _unixy_shells($command);
  };
  
  $shell || __PACKAGE__->login_shell;
}


sub login_shell
{
  shift; # class ignored
  my $shell;

  if($^O eq 'MSWin32')
  {
    if(Win32::IsWin95())
    { return __PACKAGE__->command_shell }
    else
    { return __PACKAGE__->cmd_shell }
  }

  return __PACKAGE__->dcl_shell     if $^O eq 'VMS';
  return __PACKAGE__->command_shell if $^O eq 'dos';

  my $username = shift || $ENV{USER} || $ENV{USERNAME} || $ENV{LOGNAME};

  if($^O eq 'darwin')
  {
    my $command = `dscl . -read /Users/$username UserShell`;
    $shell = _unixy_shells($command);
    return $shell if defined $shell;
  }

  eval {
    my $pw_shell = (getpwnam($username))[-1];
    $shell = _unixy_shells($pw_shell);
    $shell = _unixy_shells(readlink $pw_shell) if !defined($shell) && -l $pw_shell;
  };

  $shell = __PACKAGE__->bourne_shell unless defined $shell;

  return $shell;
}


sub bash_shell { bless { bash => 1, bourne => 1, unix => 1, name => 'bash', default_location => '/bin/bash' }, __PACKAGE__ }


sub bourne_shell { bless { bourne => 1, unix => 1, name => 'bourne', default_location => '/bin/sh' }, __PACKAGE__ }


sub c_shell { bless { c => 1, unix => 1, name => 'c', default_location => '/bin/csh' }, __PACKAGE__ }


sub cmd_shell { bless { cmd => 1, win32 => 1, name => 'cmd', default_location => 'C:\\Windows\\system32\\cmd.exe' }, __PACKAGE__ }


sub command_shell { bless { command => 1, win32 => 1, name => 'command', default_location => 'C:\\Windows\\system32\\command.com' }, __PACKAGE__ }


sub dcl_shell { bless { dcl => 1, vms => 1, name => 'dcl' }, __PACKAGE__ }


sub fish_shell { bless { fish => 1, unix => 1, name => 'fish' }, __PACKAGE__ }


sub korn_shell { bless { korn => 1, bourne => 1, unix => 1, name => 'korn', default_location => '/bin/ksh' }, __PACKAGE__ }


sub power_shell { bless { power => 1, win32 => 1, name => 'power' }, __PACKAGE__ }


sub tc_shell { bless { c => 1, tc => 1, unix => 1, name => 'tc', default_location => '/bin/tcsh' }, __PACKAGE__ }


sub z_shell { bless { z => 1, bourne => 1, unix => 1, name => 'z', default_location => '/bin/zsh' }, __PACKAGE__ }


foreach my $type (qw( cmd command dcl bash fish korn c win32 unix vms bourne tc power z ))
{
  eval qq{
    sub is_$type
    {
      my \$self = ref \$_[0] ? shift : __PACKAGE__->running_shell;
      \$self->{$type} || 0;
    }
  };
  die $@ if $@;
}


sub name
{
  my $self = ref $_[0] ? shift : __PACKAGE__->running_shell;
  $self->{name};
}


sub default_location
{
  my $self = ref $_[0] ? shift : __PACKAGE__->running_shell;
  $self->{default_location};
}

sub _unixy_shells
{
  my $shell = shift;
  if($shell =~ /tcsh$/)
  { return __PACKAGE__->tc_shell     }
  elsif($shell =~ /csh$/)
  { return __PACKAGE__->c_shell      }
  elsif($shell =~ /ksh$/)
  { return __PACKAGE__->korn_shell   }
  elsif($shell =~ /bash$/)
  { return __PACKAGE__->bash_shell   }
  elsif($shell =~ /zsh$/)
  { return __PACKAGE__->z_shell      }
  elsif($shell =~ /fish$/)
  { return __PACKAGE__->fish_shell   }
  elsif($shell =~ /sh$/)
  { return __PACKAGE__->bourne_shell }
  else
  { return; }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shell::Guess - Make an educated guess about the shell in use

=head1 VERSION

version 0.06

=head1 SYNOPSIS

guessing shell which called the Perl script:

 use Shell::Guess;
 my $shell = Shell::Guess->running_shell;
 if($shell->is_c) {
   print "setenv FOO bar\n";
 } elsif($shell->is_bourne) {
   print "export FOO=bar\n";
 }

guessing the current user's login shell:

 use Shell::Guess;
 my $shell = Shell::Guess->login_shell;
 print $shell->name, "\n";

guessing an arbitrary user's login shell:

 use Shell::Guess;
 my $shell = Shell::Guess->login_shell('bob');
 print $shell->name, "\n";

=head1 DESCRIPTION

Shell::Guess makes a reasonably aggressive attempt to determine the 
shell being employed by the user, either the shell that executed the 
perl script directly (the "running" shell), or the users' login shell 
(the "login" shell).  It does this by a variety of means available to 
it, depending on the platform that it is running on.

=over 4

=item * getpwent

On UNIXy systems with getpwent, that can be used to determine the login
shell.

=item * dscl

Under Mac OS X getpwent will typically not provide any useful information,
so the dscl command is used instead.

=item * proc file systems

On UNIXy systems with a proc filesystems (such as Linux), Shell::Guess 
will attempt to use that to determine the running shell.

=item * ps

On UNIXy systems without a proc filesystem, Shell::Guess will use the
ps command to determine the running shell.

=item * L<Win32::Getppid> and L<Win32::Process::List>

On Windows if these modules are installed they will be used to determine
the running shell.  This method can differentiate between PowerShell,
C<command.com> and C<cmd.exe>.

=item * ComSpec

If the above method is inconclusive, the ComSpec environment variable
will be consulted to differentiate between C<command.com> or C<cmd.exe>
(PowerShell cannot be detected in this manner).

=item * reasonable defaults

If the running or login shell cannot be otherwise determined, a reasonable
default for your platform will be used as a fallback.  Under OpenVMS this is
dcl, Windows 95/98 and MS-DOS this is command.com and Windows NT/2000/XP/Vista/7
this is cmd.exe.  UNIXy platforms fallback to bourne shell.

=back

The intended use of this module is to enable a Perl developer to write 
a script that generates shell configurations for the calling shell so they
can be imported back into the calling shell using C<eval> and backticks
or C<source>.  For example, if your script looks like this:

 #!/usr/bin/perl
 use Shell::Guess;
 my $shell = Shell::Guess->running_shell;
 if($shell->is_bourne) {
   print "export FOO=bar\n";
 } else($shell->is_c) {
   print "setenv FOO bar\n";
 } else {
   die "I don't support ", $shell->name, " shell";
 }

You can then import FOO into your bash or c shell like this:

 % eval `perl script.pl`

or, you can write the output to a configuration file and source it:

 % perl script.pl > foo.sh
 % source foo.sh

L<Shell::Config::Generate> provides a portable interface for generating
such shell configurations, and is designed to work with this module.

=head1 CLASS METHODS

These class methods return an instance of Shell::Guess, which can then be 
interrogated by the instance methods in the next section below.

=head2 Shell::Guess->running_shell

Returns an instance of Shell::Guess based on the shell which directly
started the current Perl script.  If the running shell cannot be determined,
it will return the login shell.

=head2 Shell::Guess->login_shell( [ $username ] )

Returns an instance of Shell::Guess for the given user.  If no username is specified then
the current user will be used.  If no shell can be guessed then a reasonable fallback
will be chosen based on your platform.

=head2 Shell::Guess-E<gt>bash_shell

Returns an instance of Shell::Guess for bash.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = bash

=item * $shell-E<gt>is_bash = 1

=item * $shell-E<gt>is_bourne = 1

=item * $shell-E<gt>is_unix = 1

=item * $shell-E<gt>default_location = /bin/bash

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>bourne_shell

Returns an instance of Shell::Guess for the bourne shell.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = bourne

=item * $shell-E<gt>is_bourne = 1

=item * $shell-E<gt>is_unix = 1

=item * $shell-E<gt>default_location = /bin/sh

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>c_shell

Returns an instance of Shell::Guess for c shell.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = c

=item * $shell-E<gt>is_c = 1

=item * $shell-E<gt>is_unix = 1

=item * $shell-E<gt>default_location = /bin/csh

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>cmd_shell

Returns an instance of Shell::Guess for the Windows NT cmd shell (cmd.exe).

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = cmd

=item * $shell-E<gt>is_cmd = 1

=item * $shell-E<gt>is_win32 = 1

=item * $shell-E<gt>default_location = C:\Windows\system32\cmd.exe

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>command_shell

Returns an instance of Shell::Guess for the Windows 95 command shell (command.com).

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = command

=item * $shell-E<gt>is_command = 1

=item * $shell-E<gt>is_win32 = 1

=item * $shell-E<gt>default_location = C:\Windows\system32\command.com

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>dcl_shell

Returns an instance of Shell::Guess for the OpenVMS dcl shell.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = dcl

=item * $shell-E<gt>is_dcl = 1

=item * $shell-E<gt>is_vms = 1

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>fish_shell

Returns an instance of Shell::Guess for the fish shell.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = fish

=item * $shell-E<gt>is_fish = 1

=item * $shell-E<gt>is_unix = 1

=back

=head2 Shell::Guess-E<gt>korn_shell

Returns an instance of Shell::Guess for the korn shell.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = korn

=item * $shell-E<gt>is_korn = 1

=item * $shell-E<gt>is_bourne = 1

=item * $shell-E<gt>is_unix = 1

=item * $shell-E<gt>default_location = /bin/ksh

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>power_shell

Returns an instance of Shell::Guess for Windows PowerShell.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = power

=item * $shell-E<gt>is_power = 1

=item * $shell-E<gt>is_win32 = 1

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>tc_shell

Returns an instance of Shell::Guess for tcsh.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = tc

=item * $shell-E<gt>is_tc = 1

=item * $shell-E<gt>is_c = 1

=item * $shell-E<gt>is_unix = 1

=item * $shell-E<gt>default_location = /bin/tcsh

=back

All other instance methods will return false

=head2 Shell::Guess-E<gt>z_shell

Returns an instance of Shell::Guess for zsh.

The following instance methods will return:

=over 4

=item * $shell-E<gt>name = z

=item * $shell-E<gt>is_z = 1

=item * $shell-E<gt>is_bourne = 1

=item * $shell-E<gt>is_unix = 1

=item * $shell-E<gt>default_location = /bin/zsh

=back

All other instance methods will return false

=head1 INSTANCE METHODS

The normal way to call these is by calling them on the result of either
I<running_shell> or I<login_shell>, but they can also be called as class
methods, in which case the currently running shell will be used, so

 Shell::Guess->is_bourne

is the same as

 Shell::Guess->running_shell->is_bourne

=head2 $shell-E<gt>is_bash

Returns true if the shell is bash.

=head2 $shell-E<gt>is_bourne

Returns true if the shell is the bourne shell, or a shell which supports bourne syntax (e.g. bash or korn).

=head2 $shell-E<gt>is_c

Returns true if the shell is csh, or a shell which supports csh syntax (e.g. tcsh).

=head2 $shell-E<gt>is_cmd

Returns true if the shell is the Windows command.com shell.

=head2 $shell-E<gt>is_command

Returns true if the shell is the Windows cmd.com shell.

=head2 $shell-E<gt>is_dcl

Returns true if the shell is the OpenVMS dcl shell.

=head2 $shell-E<gt>is_fish

Returns true if the shell is Fish shell.

=head2 $shell-E<gt>is_korn

Returns true if the shell is the korn shell.

=head2 $shell-E<gt>is_power

Returns true if the shell is Windows PowerShell.

=head2 $shell-E<gt>is_tc

Returns true if the shell is tcsh.

=head2 $shell-E<gt>is_unix

Returns true if the shell is traditionally a UNIX shell (e.g. bourne, bash, korn)

=head2 $shell-E<gt>is_vms

Returns true if the shell is traditionally an OpenVMS shell (e.g. dcl)

=head2 $shell-E<gt>is_win32

Returns true if the shell is traditionally a Windows shell (command.com, cmd.exe)

=head2 $shell-E<gt>is_z

Returns true if the shell is zsh

=head2 $shell-E<gt>name

Returns the name of the shell.

=head2 $shell-E<gt>default_location

The usual location for this shell, for example /bin/sh for bourne shell
and /bin/csh for c shell.  May not be defined for all shells.

=head1 CAVEATS

Shell::Guess shouldn't ever die or crash, instead it will attempt to make a guess or use a fallback 
about either the login or running shell even on unsupported operating systems.  The fallback is the 
most common shell on the particular platform that you are using, so on UNIXy platforms the fallback 
is bourne, and on OpenVMS the fallback is dcl.

These are the operating systems that have been tested in development and are most likely to guess
reliably.

=over 4

=item * Linux

=item * Cygwin

=item * FreeBSD

=item * Mac OS X

=item * Windows (Strawberry Perl)

=item * Solaris (x86)

=item * MS-DOS (djgpp)

=item * OpenVMS

Always detected as dcl (a more nuanced view of OpenVMS is probably possible, patches welcome).

=back

UNIXy platforms without a proc filesystem will use L<Unix::Process> if installed, which will execute 
ps to determine the running shell.

It is pretty easy to fool the -E<gt>running_shell method by using fork, or if your Perl script
is not otherwise being directly executed by the shell.

Patches are welcome to make other platforms work more reliably.

=cut

=head1 AUTHOR

author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

contributors:

Buddy Burden (BAREFOOT)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
