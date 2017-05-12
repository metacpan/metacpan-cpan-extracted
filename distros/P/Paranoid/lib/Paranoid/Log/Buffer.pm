# Paranoid::Log::Buffer -- Log buffer support for paranoid programs
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Log/Buffer.pm, 2.05 2017/02/06 01:48:57 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Log::Buffer;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use Paranoid::Debug qw(:all);

($VERSION) = ( q$Revision: 2.05 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant DEFAULT_BUFFSIZE => 20;

#####################################################################
#
# Module code follows
#
#####################################################################

{

    # Buffers
    my %buffers = ();

    sub addLogger {

        # Purpose:  Creates the named buffer
        # Returns:  Boolean
        # Usage:    $rv = addLogger(%rec);

        my %rec = @_;

        $buffers{ $rec{name} } = [];

        return 1;
    }

    sub delLogger {

        # Purpose:  Deletes the named buffer
        # Returns:  True (1)
        # Usage:    $rv = _delBuffer($name);

        my $name = shift;

        delete $buffers{$name} if exists $buffers{$name};

        return 1;
    }

    sub init {
        return 1;
    }

    sub logMsg {
        my %record = @_;
        my ( $rv, $size, $buffer );

        pdebug( 'entering w/%s', PDLEVEL1, %record );
        pIn();

        if ( exists $buffers{ $record{name} } ) {
            $size =
                exists $record{options}{size}
                ? $record{options}{size}
                : DEFAULT_BUFFSIZE;
            $buffer = $buffers{ $record{name} };

            # Add the message
            push @$buffer, [ @record{qw(msgtime message)} ];

            # Trim if needed
            while ( scalar @$buffer > $size ) {
                shift @$buffer;
            }

            $rv = 1;
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

        return $rv;
    }

    sub dumpBuffer {

        # Purpose:  Returns the contents of the named buffer
        # Returns:  Array
        # Usage:    @events = dump($name);

        my $name = shift;
        my @rv;

        @rv = @{ $buffers{$name} } if exists $buffers{$name};

        return @rv;
    }

}

1;

__END__

=head1 NAME

Paranoid::Log::Buffer - Log Buffer Functions

=head1 VERSION

$Id: lib/Paranoid/Log/Buffer.pm, 2.05 2017/02/06 01:48:57 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Log;
  
  startLogger('events', 'Buffer', PL_DEBUG, PL_GE);
  startLogger('crit-events', 'buffer', PL_CRIT, PL_EQ, { size => 100 });

  @messages = Paranoid::Log::Buffer::dumpBuffer($name);

=head1 DESCRIPTION
k

This module implements named buffers to be used for logging purposes.
Each buffer is an fixed length array of message records.  Each message record
consists of a two-element array, with the first element being the message time
(in UNIX epoch seconds) and the second being the message text itself.

With the exception of the B<dumpBuffer> function this module is not meant to 
be used directly.  B<Paranoid::Log> should be your exclusive interface for
logging.

When creating a named buffer with L<Paranoid::Log> you can specify a size
option on a per-buffer basis.  The default size is 20.

=head1 OPTIONS

The options recognized for use in the options hash are as follows:

    Option      Value       Description
    -----------------------------------------------------
    size        integer     number of entries to maintian 
                            in buffer

=head1 SUBROUTINES/METHODS

B<NOTE>:  Given that this module is not intended to be used directly nothing
is exported.

=head2 init

=head2 logMsg

=head2 addLogger

=head2 delLogger

=head2 dumpBuffer

  @entries = Paranoid::Log::Buffer::dumpBuffer($name);

This dumps all current entries in the named buffer.  Each entry is an
array reference to a two-element array.  The first element is the timestamp
of the message (in UNIX epoch seconds), the second the actual message
itself.

=head1 DEPENDENCIES

=over

=item o

Paranoid::Debug

=back

=head1 SEE ALSO

=over

=item o

L<Paranoid::Log>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

