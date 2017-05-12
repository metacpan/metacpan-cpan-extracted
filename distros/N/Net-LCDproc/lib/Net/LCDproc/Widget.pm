package Net::LCDproc::Widget;
$Net::LCDproc::Widget::VERSION = '0.104';
#ABSTRACT: Base class for all the widgets

use v5.10.2;
use Log::Any qw($log);
use Types::Standard qw/ArrayRef Bool InstanceOf Str/;
use Moo;
use namespace::clean;

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has type => (
    is      => 'ro',
    isa     => Str,
    traits  => ['NoState'],
    default => sub {
        my $pkg = ref $_[0];
        my @parts = split /::/, $pkg;
        return lc $parts[-1];
    },
);

has frame_id => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_frame_id',

    #isa => 'Net::LCDproc::Widget::Frame',
);

has screen => (
    is  => 'rw',
    isa => InstanceOf ['Net::LCDproc::Screen'],
);

has is_new => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has changed => (
    is  => 'rw',
    isa => Bool,
);

has _set_cmd => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 1,
    default  => sub { [] },
);

### Public Methods

sub update {
    my $self = shift;

    if ($self->is_new) {

        # needs to be added
        $self->_create_widget_on_server;
    }

    if (!$self->changed) {
        return;
    }
    $log->debug('Updating widget: ' . $self->id) if $log->is_debug;
    my $cmd_str = $self->_get_set_cmd_str;

    $self->screen->_lcdproc->_send_cmd($cmd_str);

    $self->changed(0);
    return 1;
}

# removes this widget from the LCDproc server, unhooks from $self->server, then destroys itself
sub remove {
    my $self = shift;

    my $cmd_str = sprintf 'widget_del %s %s', $self->screen->id, $self->id;
    $self->_lcdproc->_send_cmd($cmd_str);

    return 1;
}

### Private Methods
sub _get_set_cmd_str {
    my ($self) = @_;

    my $cmd_str = sprintf 'widget_set %s %s', $self->screen->id, $self->id;

    foreach my $attr (@{$self->_set_cmd}) {
        $cmd_str .= sprintf ' "%s"', $self->$attr;
    }

    return $cmd_str;

}

sub _create_widget_on_server {
    my $self = shift;
    $log->debugf('Adding new widget: %s - %s', $self->id, $self->type);
    my $add_str = sprintf 'widget_add %s %s %s',
      $self->screen->id, $self->id, $self->type;

    if ($self->has_frame_id) {
        $add_str .= " -in " . $self->frame_id;
    }
    $self->screen->_lcdproc->_send_cmd($add_str);

    $self->is_new(0);

    # make sure it gets set
    $self->changed(1);
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Net::LCDproc::Widget - Base class for all the widgets

=head1 VERSION

version 0.104

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
