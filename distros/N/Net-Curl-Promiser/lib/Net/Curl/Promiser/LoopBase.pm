package Net::Curl::Promiser::LoopBase;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::LoopBase - base class for event-loop-based implementations

=head1 INVALID METHODS

The following methods from L<Net::Curl::Promiser> are unneeded in instances
of this class and thus produce an exception if called:

=over

=item C<process()>

=item C<time_out()>

=item C<get_timeout()>

=back

=head1 TODO

This is a rather hacky way accomplish this. Refactor it to be more-better.

Also incorporate the copy-pasted timeout logic from subclasses.

=cut

#----------------------------------------------------------------------

use parent qw( Net::Curl::Promiser );

use Net::Curl ();

# In production there’s probably little reason to care about this,
# but it might be useful for debugging.
use constant _STRICT_STOP_POLL => 0;

#----------------------------------------------------------------------

*_process_in_loop = __PACKAGE__->can('SUPER::process');
*_time_out_in_loop = __PACKAGE__->can('SUPER::time_out');

# 7.66 is observed not to have this problem;
# assumedly newer libcurls won’t regress.
use constant _MINIMUM_LIBCURL_TO_WARN_ABOUT_EXTRA_STOP_POLL => 7.52;

sub process { die 'Unneeded method: ' . (caller 0)[3] };
sub get_timeout { die 'Unneeded method: ' . (caller 0)[3] };
sub time_out { die 'Unneeded method: ' . (caller 0)[3] };

sub _GET_FD_ACTION {
    return +{ @{ $_[1] } };
}

sub _handle_extra_stop_poll {
    my ($self, $fd) = @_;

    if (_STRICT_STOP_POLL) {
        my $version = Net::Curl::LIBCURL_VERSION();

        if ( $version =~ m<\A([0-9]+\.[0-9]+)> ) {
            if ($1 >= _MINIMUM_LIBCURL_TO_WARN_ABOUT_EXTRA_STOP_POLL) {
                my $ref = ref $self;
                warn "$ref: Unexpected “extra” FD stop (libcurl $version): [$fd]";
            }
        }
        else {
            warn "Unparseable LIBCURL_VERSION: [$version]";
        }
    }

    return;
}

1;
