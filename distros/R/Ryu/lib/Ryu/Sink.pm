package Ryu::Sink;

use strict;
use warnings;

use parent qw(Ryu::Node);

our $VERSION = '3.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Ryu::Sink - base representation for a thing that receives events

=head1 DESCRIPTION

This is currently of limited utility.

 my $src = Ryu::Source->new;
 my $sink = Ryu::Sink->new;
 $sink->from($src);
 $sink->source->say;

=cut

use Future;

=head1 METHODS

=cut

sub new {
    my $class = shift;
    $class->SUPER::new(
        @_
    )
}

=head2 from

Given a source, will attach it as the input for this sink.

=cut

sub from {
    my ($self, $src, %args) = @_;

    die 'expected a subclass of Ryu::Source, received ' . $src . ' instead' unless $src->isa('Ryu::Source');

    $self = $self->new unless ref $self;
    $src->each_while_source(sub {
        $self->emit($_)
    }, $self->source);
    $src->completed->on_ready(sub {
        my $f = $self->source->completed;
        shift->on_ready($f) unless $f->is_ready;
    });
# $self->{source} = $src;
    return $self
}

sub emit {
    my ($self, $data) = @_;
    $self->source->emit($data);
    $self
}

sub source {
    my ($self) = @_;
    $self->{source} //= do {
        my $src = ($self->{new_source} //= sub { Ryu::Source->new })->();
        Scalar::Util::weaken($src->{parent} = $self);
        $src;
    };
}

sub _completed { shift->source->_completed }

sub notify_child_completion { }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2023. Licensed under the same terms as Perl itself.

