package Statistics::R::IO::ParserState;
# ABSTRACT: Current state of the IO parser
$Statistics::R::IO::ParserState::VERSION = '1.0001';
use 5.010;

use Class::Tiny::Antlers;
use namespace::clean;

has data => (
    is => 'ro',
    default => sub { [] },
);

has position => (
    is => 'ro',
    default => sub { 0 },
);

has singletons => (
    is => 'ro',
    default => sub { [] },
);


sub BUILDARGS {
    my $class = shift;
    my $attributes = {};
    
    if ( scalar @_ == 1) {
        if ( ref $_[0] eq 'HASH' ) {
            $attributes = $_[0]
        }
        else {
            $attributes->{name} = $_[0]
        }
    }
    elsif ( @_ % 2 ) {
        die "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments\n";
    }
    else {
        $attributes = { @_ };
    }

    # split strings into a list of individual characters
    if (defined $attributes->{data} && !ref($attributes->{data})) {
        $attributes->{data} = [split //, $attributes->{data}];
    }
        
    $attributes
}

sub BUILD {
    my $self = shift;
    
    die 'foo' unless ref($self->data) eq 'ARRAY'
}

sub at {
    my $self = shift;
    $self->data->[$self->position]
}

sub next {
    my $self = shift;
    
    ref($self)->new(data => $self->data,
                    position => $self->position+1,
                    singletons => [ @{$self->singletons} ])
}

sub add_singleton {
    my ($self, $singleton) = (shift, shift);

    my @new_singletons = @{$self->singletons};
    push @new_singletons, $singleton;
    ref($self)->new(data => $self->data,
                    position => $self->position,
                    singletons => [ @new_singletons ])
}

sub get_singleton {
    my ($self, $singleton_id) = (shift, shift);
    $self->singletons->[$singleton_id]
}

sub eof {
    my $self = shift;
    $self->position >= scalar @{$self->data};
}

    
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO::ParserState - Current state of the IO parser

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO::ParserState;
    
    my $state = Statistics::R::IO::ParserState->new(
        data => 'file.rds'
    );
    say $state->at
    say $state->next->at;

=head1 DESCRIPTION

You shouldn't create instances of this class, it exists mainly to
handle deserialization of R data files by the C<IO> classes.

=head1 METHODS

=head2 ACCESSORS

=over

=item data

An array reference to the data being parsed. The constructs accepts a
scalar, which will be L<split> into individual characters.

=item position

Position of the next data element to be processed.

=item at

Returns the element (byte) at the current C<position>.

=item eof

Returns true if the cursor (C<position>) is at the end of the C<data>.

=item singletons

An array reference in which unserialized data that should be exists as
singletons can be "stashed" by the parser for later reference.

=item get_singleton $id

Return the singleton data object with the given C<$id>.

=back

=head2 MUTATORS

C<ParserState> is intended to be immutable, so the "mutator" methods
actually return a new instance with appropriately modified values of
the attributes.

=over

=item next

Returns a new ParserState instance with C<position> advanced by one.

=item add_singleton $singleton

Returns a new ParserState instance with C<$singleton> argument
appended to the instance's C<singletons>.

=back

=head1 BUGS AND LIMITATIONS

Instances of this class are intended to be immutable. Please do not
try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILDARGS BUILD

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
