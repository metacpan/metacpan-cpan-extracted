package TRD::Watch::Ping;

use warnings;
use strict;
use Carp;
use threads ( 'exit' => 'threads_only' );
use Time::HiRes qw(sleep);
use TRD::DebugLog;
#$TRD::DebugLog::enabled = 1;

use version;
our $VERSION = '0.0.4';

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;

our $default_timeout = 5;	# sec
our $default_interval = 60;	# sec

#=======================================================================
sub new {
	my $pkg = shift;
	my $name = (@_) ? shift : '';
	my $host = (@_) ? shift : undef;
	my $errfunc = (@_) ? shift : undef;
	my $recoverfunc = (@_) ? shift : undef;
	my $timeout = (@_) ? shift : $default_timeout;
	my $interval = (@_) ? shift : $default_interval;
	bless {
		name => $name,
		timeout => $timeout,
		interval => $interval,
		host => $host,
		errfunc => $errfunc,
		recoverfunc => $recoverfunc,
		pid => undef,
		start => 0,
	}, $pkg;
}

#=======================================================================
sub setName
{
	my $self = shift;
	my $name = (@_) ? shift : '';
	$self->{'name'} = $name;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
}

#=======================================================================
sub setTimeout
{
	dlog( "<<<" );
	my $self = shift;
	my $timeout = (@_) ? shift : $default_timeout;
	$self->{'timeout'} = $timeout;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
	dlog( ">>>" );
}

#=======================================================================
sub setInterval
{
	dlog( "<<<" );
	my $self = shift;
	my $interval = (@_) ? shift : $default_interval;
	$self->{'interval'} = $interval;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
	dlog( ">>>" );
}

#=======================================================================
sub setHost
{
	dlog( "<<<" );
	my $self = shift;
	my $host = (@_) ? shift : undef;
	$self->{'host'} = $host;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
	dlog( ">>> ");
}

#=======================================================================
sub setErrorFunc
{
	dlog( "<<<" );
	my $self = shift;
	my $errfunc = (@_) ? shift : undef;
	$self->{'errfunc'} = $errfunc;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
	dlog( ">>>" );
}

#=======================================================================
sub setRecoverFunc
{
	dlog( "<<<" );
	my $self = shift;
	my $recoverfunc = (@_) ? shift : undef;
	$self->{'recoverfunc'} = $recoverfunc;
	if( $self->{'start'} ){
		$self->stop;
		$self->start;
	}
	dlog( ">>>" );
}

#=======================================================================
sub start
{
	dlog( "<<<" );
	my $self = shift;

	my $retval = 1;
	if( $self->{'start'} ){
		dlog( "already started." );
	} else {
		my $pid;
		$pid = threads->new( \&ping_thread, $self );
		$self->{'pid'} = $pid;
		$self->{'start'} = 1;
		$retval = 0;
	}
	dlog( ">>>" );
	return $retval;
}

#=======================================================================
sub stop
{
	dlog( "<<<" );
	my $self = shift;

	my $retval = 1;
	if( !$self->{'start'} ){
		dlog( "already stoped." );
	} else {
		$self->{'pid'}->kill('KILL')->detach();
		$self->{'pid'} = undef;
		$self->{'start'} = 0;
		$retval = 0;
	}
	dlog( ">>>" );
	return $retval;
}

#=======================================================================
sub ping_thread
{
	dlog( "<<<" );
	my $self = shift;
	my $stat = 1;
	my $old_stat = undef;

	$SIG{'KILL'} = sub { threads->exit(); };

	while( 1 ){
		my $pid = threads->new( \&ping, $self );
		my $t = 0;
		while( 1 ){
			if( $pid->is_running ){
				$stat = 1;
			} else {
				$stat = $pid->join();
				last;
			}
			if( $t >= $self->{'timeout'} ){
				$pid->kill('KILL')->detach();
				$stat = 1;
				last;
			}
			sleep( 0.1 );
			$t += 0.1;
		}
		if( defined( $old_stat ) ){
			if( $old_stat != $stat ){
				my $func = undef;
dlog( "stat=${stat}" );
				if( $stat ){
					$func = $self->{'errfunc'};
				} else {
					$func = $self->{'recoverfunc'};
				}
				if( ref( $func ) eq 'CODE' ){
					&{$func}( $self->{'name'}, $self->{'host'} );
				}
			}
		}
		$old_stat = $stat;
		sleep( $self->{'interval'} - $t );
	}

	dlog( ">>>" );
	return $stat;
}

#=======================================================================
sub ping
{
	my $self = shift;
	dlog( "<<<". $self->{'host'} );
	$SIG{'KILL'} = sub { threads->exit(); };
	my $retval = 1;

	if( !$self->{'host'} ){
		$retval = 1;
	} else {
		my $cmd = 'ping -c 1 -n -q '. $self->{'host'};
		my $res = `${cmd}`;

		if( $res =~m/ 0%/ ){
			$retval = 0;
		} else {
			$retval = 1;
		}
	}
	dlog( ">>>". $retval );
	return $retval;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

TRD::Watch::Ping - [One line description of module's purpose here]


=head1 VERSION

This document describes TRD::Watch::Ping version 0.0.1


=head1 SYNOPSIS

    use TRD::Watch::Ping;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
TRD::Watch::Ping requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-trd-watch-ping@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Takuya Ichikawa  C<< <ichi@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Takuya Ichikawa C<< <ichi@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
