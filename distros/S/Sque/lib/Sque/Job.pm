package Sque::Job;
$Sque::Job::VERSION = '0.010';
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use UNIVERSAL::require;
with 'Sque::Encoder';

# ABSTRACT: Sque job container

has sque => (
    is => 'rw',
    handles => [qw/ stomp /],
    default => sub { confess "This Sque::Job isn't associated to any Sque system yet!" }
);

has worker => (
    is => 'rw',
    lazy => 1,
    default => sub { $_[0]->sque->worker },
    predicate => 'has_worker'
);

has class => (
    is => 'rw',
    lazy => 1,
    default => sub { confess "This job needs a class to do some work." },
);

has queue => (
    is => 'rw',
    lazy => 1,
    default => \&queue_from_class,
    predicate => 'queued'
);

has args => ( is => 'rw', isa => 'ArrayRef', default => sub {[]} );

coerce 'HashRef'
    => from 'Str'
    => via { JSON->new->utf8->decode($_) };

has payload => (
    is => 'rw',
    isa => 'HashRef',
    coerce => 1,
    lazy => 1,
    default => sub {{
        class => $_[0]->class,
        args => $_[0]->args,
    }},
    trigger => sub {
        my ( $self, $hr ) = @_;
        $self->class( $hr->{class} );
        $self->args( $hr->{args} ) if $hr->{args};
    }
);

has headers => (
    is => 'rw',
    isa => 'HashRef',
    default => sub{ {} },
);

has frame => (
    is => 'ro',
    lazy => 1,
    default => sub { {} },
    trigger => sub {
        my ( $self, $frame ) = @_;
        $self->payload( $frame->body );
    }
);

sub encode {
    my $self = shift;
    $self->encoder->encode( $self->payload );
}

sub stringify {
    my $self = shift;
    sprintf( "(Job{%s} | %s | %s)",
        $self->queue,
        $self->class,
        $self->encoder->encode( $self->args )
    );
}
sub queue_from_class {
    my $class = shift->class;
    $class =~ s/://g;
    $class;
}

sub perform {
    my $self = shift;
    $self->class->require || confess $@;

    # First test if its OO
    if($self->class->can('new')){
        no strict 'refs';
        $self->class->new->perform( $self );
    }else{
        # If it's not OO, just call perform
        $self->class->can('perform')
            || confess $self->class . " doesn't know how to perform";

        no strict 'refs';
        &{$self->class . '::perform'}($self);
    }
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sque::Job - Sque job container

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 sque

=head2 worker

Worker running this job.
A new worker will be popped up from sque by default.

=head2 class

Class to be performed by this job.

=head2 queue

Name of the queue this job is or should be.

=head2 args

Array of arguments for this job.

=head2 payload

HashRef representation of the job.
When passed to constructor, this will restore the job from encoded state.
When passed as a string this will be coerced using JSON decoder.
This is read-only.

=head2 frame

Raw stomp frame representing the job.
This is read-only.

=head1 METHODS

=head2 encode

String representation(JSON) to be used on the backend.

=head2 stringify

=head2 queue_from_class

Normalize class name to be used as queue name.
    NOTE: future versions will try to get the
    queue name from the real class attr
    or $class::queue global variable.

=head2 perform

Load job class and call perform() on it.
This job objet will be passed as the only argument.

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
