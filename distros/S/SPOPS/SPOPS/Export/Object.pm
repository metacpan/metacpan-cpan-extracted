package SPOPS::Export::Object;

# $Id: Object.pm,v 3.3 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Export );

$SPOPS::Export::Object::VERSION  = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

sub create_header {
    my ( $self, $fields ) = @_;
    my $field_names_show = join ' ', @{ $fields };
    my $object_class = $self->object_class;
    return join( "\n", '$item = [',
                       "  { spops_class => '$object_class',",
                       "    field_order => [ qw/ $field_names_show / ] },\n" );
}

sub create_record {
    my ( $self, $object, $fields ) = @_;
    return '  [' .
           join( ', ', map { $self->serialize_field_data( $object->{ $_ } ) } @{ $fields } ) .
           "],\n";
}


sub create_footer { return "];\n"; }


sub serialize_field_data {
    my ( $self, $data ) = @_;
    if ( $data !~ /\}/ ) { return 'q{' . $data . '}' }
    if ( $data !~ /\)/ ) { return 'q(' . $data . ')' }
    if ( $data !~ /\|/ ) { return 'q|' . $data . '|' }
}

1;

__END__

=head1 NAME

SPOPS::Export::Object - Dump SPOPS objects to a portable format

=head1 SYNOPSIS

 # See SPOPS::Export

=head1 DESCRIPTION

You can use this format yourself, or feed it to
L<SPOPS::Import::Object|SPOPS::Import::Object> to easily move objects
from one database to another.

=head1 PROPERTIES

No extra ones beyond L<SPOPS::Export|SPOPS::Export>

=head1 METHODS

B<create_header()>

Creates the text for the variable initialization and the two pieces of
metadata we need.

B<create_record()>

Dumps the record, each field being serialized by
C<serialize_field_data()>.

B<create_footer()>

Just close up the variable initialized in C<create_header()>.

B<serialize_field_data( $data )>

Return a string suitable for serializing the value of $data. You must
ensure that it will return properly after an C<eval{}>. For instance,
the following:

 $object->{publisher} = "O'Reilly and Associates";

Cannot simply be returned in single quotes:

 'O'Reilly and Associates'

Because it will not evaluate properly. The default return for all
object values is:

 q{O'Reilly and Associates}

But we also check the string to see if it has any braces in it and if
so, try a few other characters.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Import::Object|SPOPS::Import::Object>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
