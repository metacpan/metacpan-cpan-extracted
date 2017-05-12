package PAB3::Logger;
# =============================================================================
# Perl Application Builder
# Module: PAB3::Logger
# Use "perldoc PAB3::Logger" for documentation
# =============================================================================
use strict;
use warnings;

use Time::HiRes ();
use Carp ();

use vars qw($VERSION);

BEGIN {
	$VERSION = '1.0.1';
}

our @LOG_ITEM = ( 'None', 'Error', 'Warning', 'Info', 'Debug' );

our $LOG_LEVEL		= 0;
our $LOG_FORMAT		= 1;
our $LOG_FILE		= 2;
our $LOG_TIMESTART	= 3;
our $LOG_FMTSUB		= 4;
our $LOG_HANDLE		= 5;
our $LOG_HEADER		= 6;
our $LOG_RTID		= 7;
our $LOG_UTILS		= 8;

1;

sub DESTROY {
	my $this = shift or return;
	&close( $this );
}

sub new {
	my $class = shift;
	my %arg = @_;
	my $this  = [];
	bless( $this, $class );
	$this->[$LOG_LEVEL] = $arg{'level'} || 2;
	$this->[$LOG_FILE] = $arg{'file'};
	$this->[$LOG_FORMAT] = $arg{'format'};
	$this->[$LOG_HEADER] = $arg{'header'};
	$this->[$LOG_UTILS] = $arg{'utils'};
	if( $this->[$LOG_FORMAT] ) {
		$this->_set_format( $this->[$LOG_FORMAT] );
	}
	if( $this->[$LOG_FILE] ) {
		$this->open( $this->[$LOG_FILE] );
	}
	$this->[$LOG_TIMESTART] = &_microtime();
	if( $this->[$LOG_HEADER] ) {
		$this->send( $this->[$LOG_HEADER] );
	}
	$this->[$LOG_RTID] = ( rand() * time() * $$ ) % 65536;
	return $this;
}

sub reset {
	my $this = shift;
	$this->[$LOG_TIMESTART] = &_microtime();
	if( $this->[$LOG_HEADER] ) {
		$this->send( $this->[$LOG_HEADER] );
	}
}

sub open {
	my $this = shift;
	$this->close();
	return 1 unless $_[0];
	if( ref( $this->[$LOG_FILE] ) ) {
		$this->[$LOG_HANDLE] = $this->[$LOG_FILE];
		return 1;
	}
	open( $this->[$LOG_HANDLE], '>>', $_[0] ) or
		&Carp::croak( "Could not open log-file: $!" );
	my $ret = select( $this->[$LOG_HANDLE] );
	$| = 1;
	select( $ret );
	return 1;
}

sub close {
	my $this = shift;
	return 1 unless defined $this->[$LOG_HANDLE];
	if( ref( $this->[$LOG_FILE] )
		&& $this->[$LOG_HANDLE] eq $this->[$LOG_FILE]
	) {
		return 1;
	}
	close $this->[$LOG_HANDLE] or
		&Carp::carp( "Could not close log-file: $!" );
	$this->[$LOG_HANDLE] = undef;
	return 1;
}

sub send {
	my( $this, $message, $loglevel ) = @_;
	my( $li_client, $li_elapsed, $li_item, $li_time, $hlog, $time, $msg );
	$loglevel = 3 unless defined $loglevel;
	$hlog = $this->[$LOG_HANDLE];
	return 0 unless $message;
	return 0 if ! $loglevel || $this->[$LOG_LEVEL] < $loglevel;
	$li_time = $this->_unix_as_logtime();
	$li_item = $LOG_ITEM[$loglevel];
	$time = &_microtime();
	$li_elapsed = sprintf( '%06.4f',
		( $time - $this->[$LOG_TIMESTART] )
	);
	$li_client = $ENV{'REMOTE_ADDR'} || $ENV{'USER'} || '-unknown-';
	if( $this->[$LOG_FMTSUB] ) {
		$msg = $this->[$LOG_FMTSUB]->(
			$li_time, $li_elapsed, $li_client, $this->[$LOG_RTID]
		) . " $li_item\: $message";
	}
	else {
		$msg = "[$li_time] [$$] [$li_client] [$li_elapsed] $li_item\: $message";
	}
	if( $PAB3::Statistic::VERSION ) {
		my $r = $GLOBAL::MPREQ || $$;
		&PAB3::Statistic::send( "LOG|$r|" . time . "|$msg" );
	}
	return 0 unless defined $hlog;
	print $hlog $msg . "\n";
	return 1;
}

sub debug {
	$_[0]->send( $_[1], 4 );
}

sub info {
	$_[0]->send( $_[1], 3 );
}

sub warn {
	$_[0]->send( $_[1], 2 );
}

sub error {
	$_[0]->send( $_[1], 1 );
}

sub _set_format {
	my( $this, $fmt ) = @_;
	my( @earg, @sarg, $eval );
	unless( $fmt ) {
		$this->[$LOG_FMTSUB] = undef;
		return;
	}
	while( $fmt =~ s!\%(\w)!\%\!! ) {
		if( $1 eq 't' ) {
			push @earg, '$_[0]';
			push @sarg, '%s';
		}
		elsif( $1 eq 'p' ) {
			push @earg, '$$';
			push @sarg, '%u';
		}
		elsif( $1 eq 'e' ) {
			push @earg, '$_[1]';
			push @sarg, '%s';
		}
		elsif( $1 eq 'c' ) {
			push @earg, '$_[2]';
			push @sarg, '%s';
		}
		elsif( $1 eq 'e' ) {
			push @earg, '$_[3]';
			push @sarg, '%s';
		}
		else {
			push @sarg, '\%' . $1;
		}
	}
	foreach( @sarg ) {
		$fmt =~ s!\%\!!$_!;
	}
	$eval = "sub { return sprintf( '$fmt', " . join( ', ', @earg ) . " ); }";
	$this->[$LOG_FMTSUB] = eval( $eval );
}

sub _microtime {
	my( $sec, $usec ) = &Time::HiRes::gettimeofday();
	return $sec + $usec / 1000000;
}

sub _unix_as_logtime {
	my $this = shift;
	my @t = $this->[$LOG_UTILS]
		? $this->[$LOG_UTILS]->localtime( defined $_[0] ? $_[0] : time )
		: localtime( defined $_[0] ? $_[0] : time )
	;
	return
		(
			$t[4] == 0 ? 'Jan' :
			$t[4] == 1 ? 'Feb' :
			$t[4] == 2 ? 'Mar' :
			$t[4] == 3 ? 'Apr' :
			$t[4] == 4 ? 'May' :
			$t[4] == 5 ? 'Jun' :
			$t[4] == 6 ? 'Jul' :
			$t[4] == 7 ? 'Aug' :
			$t[4] == 8 ? 'Sep' :
			$t[4] == 9 ? 'Oct' :
			$t[4] == 10 ? 'Nov' :
			$t[4] == 11 ? 'Dec' :
			''
		)
		. ' ' .
		( $t[3] < 10 ? '0' . $t[3] : $t[3] )
		. ' ' .
		( $t[2] < 10 ? '0' . $t[2] : $t[2] )
		. ':' .
		( $t[1] < 10 ? '0' . $t[1] : $t[1] )
		. ':' .
		( $t[0] < 10 ? '0' . $t[0] : $t[0] )
	;
}

__END__

=head1 NAME

PAB3::Logger - Logging extension to PAB3

=head1 SYNOPSIS

  use PAB3::Logger;
  
  $logger = PAB3::Logger->new(
      'file' => '/path/to/log/file'
  );
  
  $logger->debug( 'debugging message' );
  $logger->info( 'informative message' );
  $logger->warn( 'warning message' );
  $logger->error( 'error message' );


=head1 DESCRIPTION

PAB3::Logger provides an interace for logging methods.

Depending on the the current LogLevel setting, only logging with the same
log level or lower will be loaded. For example if the current LogLevel is
set to warning, only messages with log level of the level warning or
lower (error) will be logged.

=head1 METHODS

=over

=item new ( %arg )

Creates a new logger class.

B<Parameters>

I<%arg>

A combination of the following parameters:

  level        => a logging level
  file         => a target file or handle to write log message to
  format       => a logging format
  header       => a header message (info) to be send on every session
  utils        => a reference to a PAB3::Utils class

B<I<level>>

The logging level. Only messages with log level of the level defined or
lower will be logged. Default level is 2.

  0 - log nothing
  1 - log error messages
  2 - log warning messages
  3 - log informative messages
  4 - log debugging messages

B<I<file>>

A filename or a file handle to write to.

I<Example>

  # using STDERR
  PAB3::Logger->new(
      'file' => \*STDERR,
  );

B<I<format>>

A log format string. Following parameters are defined

  %t   Current time in format mmm dd HH:MM:SS
  %p   Process ID ($$)
  %r   Runtime ID, a randomly generated id
  %e   Elapsed time in seconds (i.e. 0.0025 = 2.5 ms)
  %c   Client (REMOTE_ADDR or USER)

B<I<header>>

A string to be send on every session starting by L<new()|PAB3::Logger/new>
or L<reset()|PAB3::Logger/reset>.
The header will send as level "info".

B<I<utils>>

A reference to a PAB3::Utils class to write log time returned by
utils->localtime().

B<Return Values>

Returns a new logger class.

B<Example>

  $logger = PAB3::Logger->new(
      'file'   => '/path/to/log/file',
      'level'  => 4, # log all
      'format' => '[%t] [%p] [%r] [%c] [%e]',
      'header' => '--- starting session ---',
  );
  
  ...
  
  # end of script
  $logger->info( 'session finished' );


=item send ( $msg )

=item send ( $msg, $level )

Send a message with the specified level. If no level is defined, default level
of 2 will be used.


=item debug ( $msg )

Send a debugging message to the logger. Maps to send( $msg, 4 )


=item info ( $msg )

Send an informative message to the logger. Maps to send( $msg, 3 )


=item warn ( $msg )

Send a warning message to the logger. Maps to send( $msg, 2 )


=item error ( $msg )

Send an error message to the logger. Maps to send( $msg, 1 )


=item reset ()

Resets the elapsed time and sends a log header if provided.

=back

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::Logger module is free software. You may distribute under
the terms of either the GNU General Public License or the Artistic
License, as specified in the Perl README file.

=cut
