
package PBS::Shell::SSH ;
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
use Net::SSH::Perl ;
use Time::HiRes qw(gettimeofday tv_interval) ;

my %live_connections ;

#-------------------------------------------------------------------------------

sub new
{
my $package = shift ;
my %config  = @_ ;

my(undef, $file, $line) = caller() ;

die ERROR "USER_NAME && HOST_NAME must be defined at '$file:$line'\n" unless (defined $config{USER_NAME} && defined $config{HOST_NAME}) ;

my %args =
	(
	  protocol => $config{PROTOCOL} || 2 # use SSH2 by default
	#~ ,   debug => 1
	) ;

my $ssh_connection ;
my $reuse_connection = exists $config{REUSE_CONNECTION} && $config{REUSE_CONNECTION} == 1 ;
my $connection_name = "$config{USER_NAME}\@$config{HOST_NAME}" ;

if($reuse_connection && exists $live_connections{$connection_name})
	{
	#~ PrintInfo "Reusing SSH connection $connection_name\n" ;
	$ssh_connection = $live_connections{$connection_name} ;
	}
else
	{
	my $t0 = [gettimeofday] ;
	
	eval { $ssh_connection = Net::SSH::Perl->new($config{HOST_NAME}, %args);} ;
	
	if($@)
		{
		chomp $@ ;
		$@ =~ s/ at \/.*$// ;
		
		die ERROR "$@ at $file:$line\n" ;
		}
		
	PrintInfo(sprintf("SSH: Connected to '$connection_name' (%0.2f s).\n", tv_interval ($t0, [gettimeofday]))) ;
	
	# log in when a command is run
	
	if($reuse_connection)
		{
		$live_connections{$connection_name} = $ssh_connection ;
		}
	}
	
return(bless {SSH_CONNECTION => $ssh_connection, %config}, $package) ;
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
my $self = shift ;
my $command = shift ;

my $host_info = "(SSH:$self->{USER_NAME}\@$self->{HOST_NAME})" ;

unless(defined $self->{LOGGED_IN})
	{
	#~ PrintInfo("SSH: logging in '$host_info'.\n") ;
	
	my $t0 = [gettimeofday] ;
	
	eval { $self->{SSH_CONNECTION}->login($self->{USER_NAME}) ;} ;
	
	if($@)
		{
		die bless
			{
			error => "SSH login failed! for '$host_info'." 
			, command => 'SSH login'
			, errno => -1
			, errno_string => $@
			}, 'PBS::Shell' ;
		}
		
	$self->{LOGGED_IN}++ ;
	
	PrintInfo(sprintf("SSH: logged in '$host_info' (%0.2f s).\n", tv_interval ($t0, [gettimeofday]))) ;
	}

my $colorizer = $self->{COMMAND_COLOR} || \&PrintInfo2  ;
$colorizer->("$command $host_info\n") unless defined $PBS::Shell::silent_commands ;

my($stdout, $stderr, $exit) = $self->{SSH_CONNECTION}->cmd($command) ;

if($exit == 0)
	{
	unless(defined $PBS::Shell::silent_commands_output)
		{
		print STDOUT $stdout if defined $stdout ;
		print STDERR $stderr if defined $stderr ;
		}
	}
else
	{
	PrintInfo2 "$command $host_info\n" if defined $PBS::Shell::silent_commands ;
	
	print STDOUT $stdout if defined $stdout ;
	print STDERR $stderr if defined $stderr ;
	
	die bless
		{
		error => "SSH command failed! $host_info." 
		, command => $command
		, errno => $exit
		, errno_string => "SSH command failed! $host_info."
		}, 'PBS::Shell' ;
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

PBS::Shell::SSH -

=head1 SYNOPSIS

  use PBS::Shell::SSH;

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO


=cut
