#
# This file is part of TBX-Min
#
# This software is copyright (c) 2016 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Min::NoteGrp;
use strict;
use warnings;
use Carp;

our $VERSION = '0.08'; # VERSION

# ABSTRACT: Store information from one TBX-Min C<noteGrp> element

sub new {
    my ($class, $args) = @_;

    my $self;
    if((ref $args) eq 'HASH'){
        # only 'notes' allowed in input hash
        if(my @invalids = grep {$_ ne 'notes'} sort keys %$args){
            croak 'Invalid attributes for class: ' .
                join ' ', @invalids
        }
        if($args->{notes} && ref $args->{notes} ne 'ARRAY'){
            croak q{Attribute 'notes' should be an array reference};
        }
        $self = $args;
    }else{
        $self = {};
    }
    $self->{notes} ||= [];
    return bless $self, $class;
}

sub notes { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (notes is a getter only)';
    }
    return $self->{notes};
}

sub add_note {
    my ($self, $note) = @_;
    if( !$note || !$note->isa('TBX::Min::Note') ){
        croak 'argument to add_note should be a TBX::Min::Note';
    }
    push @{$self->{notes}}, $note;
    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TBX::Min::NoteGrp - Store information from one TBX-Min C<noteGrp> element

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use TBX::Min::NoteGrp;
    use TBX::Min::Note;
    my $note_grp = TBX::Min::NoteGrp->new(
    my $note = TBX::Min::Note->new({noteKey => 'grammaticalGender', noteValue => 'male'});
    $note_grp->add_note($note);
    my $notes = $note_grp->notes;
    print $#$notes; # '1'

=head1 DESCRIPTION

This class represents a single note group contained in a TBX-Min file. A note
group contains a single noteValue and and optional noteKey.

=head1 METHODS

=head2 C<new>

Creates a new C<TBX::Min::NoteGrp> instance. Optionally you may pass in a hash
reference which is used to initialized the object. The fields of the hash
correspond to the names of the accessor methods listed below.

=head2 C<notes>

Returns an array ref containing all of the C<TBX::Min::NoteGrp> objects
in this tig. The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=head2 C<add_note>

Adds the input C<TBX::Min::Note> object to the list of language groups
contained by this object.

=head1 SEE ALSO

L<TBX::Min>

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>, James Hayes <james.s.hayes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
