package Net::LCDproc::Screen;
$Net::LCDproc::Screen::VERSION = '0.104';
#ABSTRACT: represents an LCDproc screen

use v5.10.2;
use Types::Standard qw/ArrayRef Bool Enum HashRef InstanceOf Int Str/;
use Log::Any qw($log);
use Moo;
use namespace::clean;

has id => (is => 'ro', isa => Str, required => 1);

has name => (is => 'rwp', isa => Str);

has [qw/width height duration timeout cursor_x cursor_y/] => (
    is  => 'rwp',
    isa => Int,
);

has priority => (
    is  => 'rwp',
    isa => Enum([qw[hidden background info foreground alert input]]),
);

has heartbeat => (
    is  => 'rwp',
    isa => Enum([qw[on off open]]),
);

has backlight => (
    is  => 'rwp',
    isa => Enum([qw[on off open toggle blink flash ]]),
);

has cursor => (
    is  => 'rwp',
    isa => Enum([qw[on off under block]]),
);

has widgets => (
    is  => 'rw',
    isa => ArrayRef [InstanceOf ['Net::LCDproc::Widget']],
    default => sub { [] },
);

has is_new => (is => 'rw', isa => Bool, default  => 1);

has _lcdproc => (is => 'rw', isa => InstanceOf['Net::LCDproc']);

has _state => (is => 'ro', isa => HashRef, default => sub {{}});


sub set {
    my ($self, $attr, $val) = @_;

    # set the attribute
    my $setter = "_set_$attr";
    $self->$setter($val);

    # and record it is dirty
    $self->_state->{$attr} = 1;
    return 1;
}

# updates the screen on the server
sub update {
    my $self = shift;

    if ($self->is_new) {

        # screen needs to be added
        if ($log->is_debug) { $log->debug('Adding ' . $self->id) }
        $self->_lcdproc->_send_cmd('screen_add ' . $self->id);
        $self->is_new(0);
    }

    # even if the screen was new, we leave defaults up to the LCDproc server
    # so nothing *has* to be set

    foreach my $attr (keys %{$self->_state}) {
        $log->debug('Updating screen: ' . $self->id) if $log->is_debug;

        my $cmd_str = $self->_get_cmd_str_for($attr);

        $self->_lcdproc->_send_cmd($cmd_str);
        delete $self->_state->{$attr};
    }

    # now check the the widgets attached to this screen
    foreach my $widget (@{$self->widgets}) {
        $widget->update;
    }
    return 1;
}

# TODO accept an arrayref of widgets
sub add_widget {
    my ($self, $widget) = @_;
    $widget->screen($self);
    push @{$self->widgets}, $widget;
    return 1;
}

# removes screen from N::L, deletes from server, then cascades and kills its widgets (optionally not)
sub remove {
    my ($self, $keep_widgets) = @_;

    if (!defined $keep_widgets) {
        foreach my $widget (@{$self->widgets}) {
            $widget->remove;
        }
    }
    return 1;
}

### Private Methods

sub _get_cmd_str_for {
    my ($self, $attr) = @_;

    my $cmd_str = 'screen_set ' . $self->id;

    $cmd_str .= sprintf ' %s "%s"', $attr, $self->$attr;
    return $cmd_str;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Net::LCDproc::Screen - represents an LCDproc screen

=head1 VERSION

version 0.104

=head1 METHODS

=head2 C<set($attr, $val)>

Assign a new value to a screen attribute.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Net-LCDproc/issues>.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Net-LCDproc/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Net::LCDproc/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Net-LCDproc>
and may be cloned from L<git://github.com/ioanrogers/Net-LCDproc.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Ioan Rogers.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
