package
    Pinto::Remote::SelfContained::Chrome; # hide from PAUSE

use v5.10;
use Moo;

use Carp qw(croak);
use IO::Handle; # ensure methods are available
use Types::Standard qw(Bool FileHandle Int);

use namespace::clean;

our $VERSION = '1.000';

has verbose => (is => 'ro', isa => Int, default => 0);
has quiet => (is => 'ro', isa => Bool, default => 0);

# Not currently overridable:
sub color { 0 }
sub palette { [qw(green yellow red)] }

has stderr => (is => 'ro', isa => FileHandle, default => sub { \*STDERR });
has stdout => (is => 'ro', isa => FileHandle, default => sub {
    return \*STDOUT if !-t STDOUT;

    my $pager = $ENV{PINTO_PAGER} // $ENV{PAGER}
        // return \*STDOUT;

    open my $fh, '|-', $pager, grep defined, $ENV{PINTO_PAGER_OPTIONS}
        or croak("Can't open pipe to pager $pager: $!");
    $fh->autoflush(1);

    return $fh;
});

has has_made_progress => (is => 'rw', isa => Bool, default => 0);

sub diag_levels { qw(error warning notice info) }

sub error   { shift->diag(@_) if $_[0]->should_render_diag(0); return }
sub warning { shift->diag(@_) if $_[0]->should_render_diag(1); return }
sub notice  { shift->diag(@_) if $_[0]->should_render_diag(2); return }
sub info    { shift->diag(@_) if $_[0]->should_render_diag(3); return }

sub show {
    my ($self, $msg, $opts) = @_;

    $opts //= {};
    $msg .= "\n" if !$opts->{no_newline};
    $self->stdout->print($msg) or croak($!);
    return $self;
}

sub diag {
    my ($self, $msg, $opts) = @_;

    $opts //= {};

    return if $self->quiet;

    $msg = $msg->() if ref $msg eq 'CODE';
    chomp $msg;
    $msg .= "\n" if !$opts->{no_newline};

    $self->stderr->print($msg) or croak($!);
}

sub should_render_diag {
    my ($self, $level) = @_;

    return 1 if $level == 0;
    return 0 if $self->quiet;
    return $level <= $self->verbose + 1;
}

sub show_progress {
    my ($self) = @_;

    return if !$self->should_render_progress;

    $self->stderr->autoflush;    # Make sure pipes are hot
    $self->stderr->print('.');
    $self->has_made_progress(1);

    return 1;
}

sub progress_done {
    my ($self) = @_;

    return 0
        if !$self->has_made_progress
        || !$self->should_render_progress;

    $self->stderr->print("\n") or croak($!);
    return 1;
}

sub should_render_progress {
    my ($self) = @_;

    return $self->verbose > 0
        && ! $self->quiet
        && -t $self->stdout;
}

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Chrome - UI for self-contained remote operations

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
