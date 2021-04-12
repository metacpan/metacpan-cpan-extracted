package Music::Note::Role::Operators;
$Music::Note::Role::Operators::VERSION = '0.04';
# ABSTRACT: Adds operator overloading, clone and interval calculation to Music::Note

use Storable ();
use Role::Tiny;
use Music::Intervals;

requires 'format';

use overload
    '>'  => 'gt',
    '<'  => 'lt',
    '==' => 'eq',
    '>=' => 'gte',
    '<=' => 'lte',
    '-' => 'subtract',
    fallback => 1,
    ;

=head1 NAME

Music::Note::Role::Operators

=head2 DESCRIPTION

L<Role::Tiny> to be applied on top L<Music::Note> with comparison methods
added and overloaded operators.  Also adds a clone method and a way to
generate Music::Interval objects via a Music::Note.

=head2 SYNOPSIS

If you're working with a L<Music::Note> subclass:

    package Music::MyNote;
    use parent 'Music::Note';
    use Role::Tiny::With;
    with 'Music::Note::Role::Operators';
    # etc

Or if you're working in a script and just want the behaviour:

    use Music::Note;
    use Role::Tiny (); # Don't import R::T into current namespace for cleanliness
    Role::Tiny->apply_roles_to_package('Music::Note', 'Music::Note::Role::Operators');

=head2 SUMMARY

Assuming you're working in a script:

    my $note = Music::Note->new('C#');
    my $other = Music::Note->new('E');

    my $true = $other->gt($note);
    $true = $other > $note;

    $true = $note->lt($other);
    $true = $note < $other;

    $true = $note->eq($note->clone);
    $true = $note == $note->clone;

    $true = $note->gte($note->clone);
    $true = $note >= $note->clone;

    $true = $note->lte($note->clone);
    $true = $note <= $note->clone;

    my $interval = $note->interval($other);
    my $conveneince_interval = $note->interval(%args_for_music_interval);

=head2 CAVEAT

Don't try to do something like C<$note == 90>>.  The overloading expects a
L<Music::Note> on both sides.  To perform comparisons versus note and not a
note you should be doing C<< $note->format('midi') == 90 >>.

=head3 AUTHOR

Kieren Diment L<zarquon@cpan.org>

=head3 LICENSE

This code can be redistributed on the same terms as perl itself

=cut

sub gt {
    my ($self, $other) = @_;
    $self->_maybe_bail_on_comparison($other);
    return $self->format('midinum') > $other->format('midinum');
}

sub lt {
    my ($self, $other) = @_;
    $self->_maybe_bail_on_comparison($other);
    return $self->format('midinum') < $other->format('midinum');
}

sub eq {
    my ($self, $other) = @_;
    $self->_maybe_bail_on_comparison($other);
    return $self->format('midinum') == $other->format('midinum');
}

sub gte {
    my ($self, $other) = @_;
    $self->_maybe_bail_on_comparison($other);
    return $self->format('midinum') >= $other->format('midinum');
}

sub lte {
    my ($self, $other) = @_;
    $self->_maybe_bail_on_comparison($other);
    return $self->format('midinum') <= $other->format('midinum');
}

sub subtract {
    my ($self, $other) = @_;
    $self->_maybe_bail_on_comparison($other);
    return $self->format('midinum') - $other->format('midinum');
}

=head2 get_interval

If called with a single Music::Note as argument is returns a
Music::Interval object

    my $interval = $self->get_interval($other);

If called with an arguments hash

    my $interval = $self->get_interval(%args_for_music_interval)

Note that this will default to 1 for the following constructor attributes,
so if you don't want these values you'll have to explicitly set them to
something else in the constructor.

NOTE: It would be nice to have the subtract method return a Music::Interval
but it's a complex module, and only seems to deal with intervals inside a
single octave.

=cut

sub get_interval {
    my $self = shift;
    my ($other, %args);
    if (ref $_[0] && $_[0]->isa('Music::Note') ) {
        ($other, %args) = @_;
    }
    else {
        %args = @_;
    }

    $self->_maybe_bail_on_comparison($other) unless $other || $args{notes};
    $args{notes} ||= [ $self->format('isobase'), $other->format('isobase') ];
    $args{$_} ||= 1 for qw/chords equalt freqs interval cents prime integer/;
    $args{size} ||= scalar @{$args{notes}};
    my $interval = Music::Intervals->new(%args);
    return $interval;
}

sub clone {
    return Storable::dclone($_[0]);
}

sub _maybe_bail_on_comparison {
    my ($self, $other) = @_;
    die "$other is not a Music::Note" unless $other->isa('Music::Note');
}

1;
