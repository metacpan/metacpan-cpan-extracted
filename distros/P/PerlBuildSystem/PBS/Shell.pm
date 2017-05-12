
package PBS::Shell ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;
use Data::Dumper ;
use Carp ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(RunShellCommands RunHostedShellCommands) ;
our $VERSION = '0.02' ;

our $silent_commands ;
our $silent_commands_output ;

use PBS::Output ;

#-------------------------------------------------------------------------------

sub new
{
my $class = shift ;
return(bless {@_}, __PACKAGE__) ;
}

#-----------------------------------------------------------------------------

sub GetInfo
{
my $self = shift ;

if(exists $self->{USER_INFO} && $self->{USER_INFO} ne '')
	{
	return(__PACKAGE__ . " " . $self->{USER_INFO}) ;
	}
else
	{
	return(__PACKAGE__) ;
	}
}

#-----------------------------------------------------------------------------

sub RunCommand
{
my $self = shift ;
my $command = shift ;

RunShellCommands($command) ;
}

#-------------------------------------------------------------------------------

sub RunPerlSub
{
my $self = shift ;
my $perl_sub = shift ;

$perl_sub->(@_) ;
}

#-------------------------------------------------------------------------------

sub RunShellCommands
{
# Run a command through system or sh
# if $PBS::Shell::silent_commands is defined, this sub
# will capture the output of the command
# and only show it if an error occures

# if an error occures while running the command, an exception is thrown.

# note that this is _not_ a member function.

for my $shell_command (@_)
	{
	if('' eq ref $shell_command)
		{
		PrintShell("$shell_command \n") unless defined $PBS::Shell::silent_commands ;
	
		if(defined $PBS::Shell::silent_commands_output)
			{
			my $output = `$shell_command 2>&1` ;
		
			if($?)
				{
				print $output if $output;
				
				die bless
					{
					  error        => 'Shell command failed!' 
					, command      => $shell_command
					, errno        => $?
					, errno_string => $!
					}, __PACKAGE__ ;
					
				}
			}
		else
			{
			if(system $shell_command)
				{
				die bless
					{
					error => 'Shell command failed!' 
						, command => $shell_command
					, errno => $?
					, errno_string => ''
					#~ , errno_string => $!
					}, __PACKAGE__ ;
				}
			}
		}
	else
		{
		croak ERROR "RunShellCommands doesn't accept references to '" . ref($shell_command) . "'!\n" ;
		}
	}
	
1 ;

}

#-------------------------------------------------------------------------------

sub RunHostedShellCommands
{
my $shell = shift || new PBS::Shell() ;

for my $shell_command (@_)
	{
	if('CODE' eq ref $shell_command)
		{
		$shell->RunPerlSub($shell_command) ;
		}
	else
		{
		$shell->RunCommand($shell_command) ;
		}
	}

1 ;

}

#-------------------------------------------------------------------------------

1 ;


__END__
=head1 NAME

PBS::Shell  -

=head1 SYNOPSIS

  use PBS::Shell ;
  
  RunShellCommands
	(
	"ls",
	"echo hi",
	"generate an exception"
	) ;

=head1 DESCRIPTION

PBS::Shell allows you to build a local shell object or to run commands in a local shell.

=head2 EXPORT

I<RunShellCommands>

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut

