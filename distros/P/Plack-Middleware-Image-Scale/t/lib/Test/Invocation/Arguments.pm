package Test::Invocation::Arguments;
# ABSTRACT: Capture method invocation arguments
use Moose;
use Class::MOP;
use Data::Dumper;

has class  => ( is => 'ro', isa => 'ClassName' );
has method => ( is => 'ro', isa => 'Str' );
has method_orig => ( is => 'rw' );

has _log => (
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        push   => 'push',
        pop    => 'pop',
        count  => 'count',
    }
);

sub BUILD {
    my $self = shift;
    my $meta = Class::MOP::Class->initialize( $self->class );
    $self->method_orig( $meta->get_method( $self->method ) );
    $meta->add_before_method_modifier( $self->method, sub {
        my $invocant = shift;
        $self->push( \@_ );
        ## TODO should make a deep copy first
    } );
}

sub DEMOLISH {
    my $self = shift;
    my $meta = Class::MOP::Class->initialize( $self->class );
    $meta->add_method( $self->method, $self->method_orig )
        if defined $self->method_orig;
}

1;
