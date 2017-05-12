#
# This file is part of TBX-Min
#
# This software is copyright (c) 2016 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Min::TIG;
use strict;
use warnings;
use subs qw(part_of_speech status note_groups);
use Class::Tiny qw(
    term
    part_of_speech
    customer
    status
    note_groups
);
use Carp;

our $VERSION = '0.08'; # VERSION

# ABSTRACT: Store information from one TBX-Min C<tig> element



sub part_of_speech {
    my ($self, $pos) = @_;
    if(defined $pos){
        _validate_pos($pos);
        $self->{part_of_speech} = $pos;
    }
    return $self->{part_of_speech};
}

sub note_groups { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (note_groups is a getter only)';
    }
    return $self->{note_groups};
}

sub add_note_group {
    my ($self, $note_grp) = @_;
    if( !$note_grp || !$note_grp->isa('TBX::Min::NoteGrp') ){
        croak 'argument to add_term_group should be a TBX::Min::TIG';
    }
    push @{$self->{note_groups}}, $note_grp;
    return;
}


sub status {
    my ($self, $status) = @_;
    if(defined $status){
        _validate_status($status);
        $self->{status} = $status;
    }
    return $self->{status};
}

# above Pod::Coverage makes this not "naked" via Pod::Coverage::TrustPod

my %valid = map {+($_=>1)} Class::Tiny->get_all_attributes_for(__PACKAGE__);
sub BUILD {
    my ($self, $args) = @_;

    # validate arguments
    if(my @invalids = grep {!$valid{$_}} sort keys %$args){
        croak 'Invalid attributes for class: ' .
            join ' ', @invalids
    }
    if($args->{note_groups} && ref $args->{note_groups} ne 'ARRAY'){
        croak q{Attribute 'note_groups' should be an array reference};
    }

    if($args->{part_of_speech}){
        _validate_pos($args->{part_of_speech});
    }
    if($args->{status}){
        _validate_status($args->{status});
    }
    $self->{note_groups} ||= [];
    return;
}

my @allowed_pos = qw(noun properNoun verb adjective adverb other);
sub _validate_pos {
    my ($pos) = @_;
    if(!grep{$pos eq $_} @allowed_pos){
        croak "Illegal part of speech '$pos'";
    }
    return;
}

my @allowed_status = qw(admitted preferred notRecommended obsolete);
sub _validate_status {
    my ($pos) = @_;
    if(!grep{$pos eq $_} @allowed_status){
        croak "Illegal status '$pos'";
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TBX::Min::TIG - Store information from one TBX-Min C<tig> element

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use TBX::Min::TIG;
    my $term_grp = TBX::Min::TIG->new(
        {term => 'bat signal', status => "preferred"});
    $term_grp->part_of_speech('noun');
    $term_grp->customer('GCPD');
    print $term_grp->term; # 'bat signal'

=head1 DESCRIPTION

This class represents a single term group contained in a TBX-Min file. A term
group contains a single term and information pertaining to it, such as part of
speech, a note, or the associated customer.

=head1 METHODS

=head2 C<new>

Creates a new C<TBX::Min::TIG> instance. Optionally you may pass in a hash
reference which is used to initialized the object. The fields of the hash
correspond to the names of the accessor methods listed below.

=head2 C<term>

Get or set the term text associated with this term group.

=head2 C<part_of_speech>

Get or set the part of speech associated with this term group.

=head2 C<note_groups>

Returns an array ref containing all of the C<TBX::Min::NoteGrp> objects
in this tig. The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=head2 C<add_note_group>

Adds the input C<TBX::Min::NoteGrp> object to the list of language groups
contained by this object.

=head2 C<customer>

Get or set a customer associated with this term group.

=head2 C<status>

Get or set a status  associated with this term group.

=head1 SEE ALSO

L<TBX::Min>

=for Pod::Coverage BUILD

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>, James Hayes <james.s.hayes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
