
package PBS::Shell::Telnet ;

use 5.006 ;

use strict ;
use warnings ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.01' ;

use PBS::Output ;
use Net::Telnet ;
use Time::HiRes qw(gettimeofday tv_interval) ;

#-------------------------------------------------------------------------------

sub new
{
my $package = shift ;
my %config  = @_ ;

my $telnet_connection = new Net::Telnet
										(
										  Timeout => $config{TIMEOUT}
										, Prompt => $config{PROMPT}
										) ;

my $self = bless {TELNET_CONNECTION => $telnet_connection, %config}, __PACKAGE__ ;

return($self) ;
}

#-----------------------------------------------------------------------------

sub GetInfo
{
my $self = shift ;
my $user_info = $self->{USER_INFO} || '' ;
return(__PACKAGE__ . " $self->{USER_NAME} @ $self->{HOST_NAME}$user_info") ;
}

#-----------------------------------------------------------------------------

sub RunCommand
{
my $self       = shift ;
my $command    = shift ;
my $new_prompt = shift || $self->{PROMPT} ;

my $host_info = "$self->{USER_NAME}\@$self->{HOST_NAME}" ;

unless(defined $self->{LOGGED_IN})
	{
	my $t0 = [gettimeofday] ;

	$self->{TELNET_CONNECTION}->open($self->{HOST_NAME}) ;
	$self->{TELNET_CONNECTION}->login($self->{USER_NAME}, $self->{PASSWORD}) ;
	$self->{LOGGED_IN}++ ;
	
	PrintInfo(sprintf("Telnet: Connected to '$host_info' (%0.2f s).\n", tv_interval ($t0, [gettimeofday]))) ;
	
	for my $login_command (@{$self->{LOGIN_COMMANDS}})
		{
		local $PBS::Shell::silent_commands = 1 unless $login_command->[2] ;
		
		my ($command, $prompt) = ($login_command->[0], $login_command->[1]) ;
		
		$self->RunCommand($command, $prompt) ;
		}
		
	PrintInfo(sprintf("Telnet setup done. (%0.2f s).\n", tv_interval ($t0, [gettimeofday]))) ;
	}
	
my $colorizer = $self->{COMMAND_COLOR} || \&PrintInfo2  ;
$colorizer->("$command (Telnet:$host_info)\n") unless defined $PBS::Shell::silent_commands ;

my $error_string = "Error running Telnet command" ;
my $catch_error = "|| echo $error_string." ;

my @output  = $self->{TELNET_CONNECTION}->cmd
														(
														  String => $command . $catch_error
														, Prompt => $new_prompt
														);
   
$self->{PROMPT} = $new_prompt ;
$self->{TELNET_CONNECTION}->prompt($new_prompt) ;

if(@output >= 2 && $output[-2] =~ $error_string)
	{
	pop @output ; pop @output ; # remove error message
	 
	print STDERR @output ;
	
	die bless
		{
		error => 'Shell command failed!' 
		, command => $command
		, errno => -1
		, errno_string => $error_string
		}, 'PBS::Shell' ;
	}
else
	{
	unless(defined $PBS::Shell::silent_commands_output)
		{
		print STDOUT @output ;
		}
	}
}

#-------------------------------------------------------------------------------

sub RunPerlSub
{
my $self = shift ;
my $perl_sub = shift ;

unless(defined $PBS::Shell::silent_commands)
	{
	my $colorizer = $self->{COMMAND_COLOR} || \&PrintInfo2  ;
	$colorizer->( __PACKAGE__ . " running perl sub locally.\n") ;
	}

$perl_sub->(@_) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Shell::Telnet  -

=head1 SYNOPSIS

  use PBS::;
  blah blah blah

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO


=cut
