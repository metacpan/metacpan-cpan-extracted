package MsOffice::Word::Surgeon::BookmarkBoundary;
use 5.24.0;
use Moose;
use Moose::Util::TypeConstraints   qw(enum);
use MooseX::StrictConstructor;

use namespace::clean -except => 'meta';

our $VERSION = '2.07';

#======================================================================
# ATTRIBUTES
#======================================================================

has 'kind'        => (is => 'ro', isa => enum([qw/Start End/]), required => 1);
has 'id'          => (is => 'ro', isa => 'Str',                 required => 1);
has 'xml_before'  => (is => 'rw', isa => 'Str',                 default => "");
has 'node_xml'    => (is => 'rw', isa => 'Str',                 default => "");
has 'name'        => (is => 'ro', isa => 'Str',                 default => "");

#======================================================================
# METHODS
#======================================================================

sub prepend_xml {my ($self, $more_xml) = @_; substr $self->{node_xml}, 0, 0, $more_xml;}
sub append_xml  {my ($self, $more_xml) = @_; $self->{node_xml} .= $more_xml;}

  

1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::BookmarkBoundary - internal representation for a MsWord bookmark

=head1 DESCRIPTION

This is used internally by L<MsOffice::Word::Surgeon> for storing
bookmark fragments.


=head1 METHODS

=head2 new

  my $field = MsOffice::Word::Surgeon::Bookmark(%args);

Constructor for a new bookmark object. Arguments are :

=over

=item kind

Either C<Start> or C<End>

=item id

Numerical identifier for the bookmark

=item name

The bookmark name. Only present in C<Start> boundaries.

=item xml_before

A string containing arbitrary XML preceding that bookmark in the complete document.

=item node_xml

The complete XML for this node.

=back

=head1 METHODS

=head2 prepend_xml

Adds an XML fragment in front of the current node_xml.

=head2 append_xml

Adds an XML fragment after the current node_xml.

=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
