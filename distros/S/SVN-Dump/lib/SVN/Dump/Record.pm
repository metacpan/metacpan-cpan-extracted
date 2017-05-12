package SVN::Dump::Record;

use strict;
use warnings;

use SVN::Dump::Headers;
use SVN::Dump::Property;
use SVN::Dump::Text;

my $NL = "\012";

sub new {
    my ($class, @args) = @_;
    return bless {}, $class
}

for my $attr (qw( headers_block property_block text_block included_record )) {
    no strict 'refs';
    *{"set_$attr"} = sub { $_[0]->{$attr} = $_[1]; };
    *{"get_$attr"} = sub { $_[0]->{$attr} };
}

sub type {
    my ($self) = @_;
    return $self->{headers_block} ? $self->{headers_block}->type() : '';
}

sub has_text { return defined $_[0]->get_text_block(); }
sub has_prop { return defined $_[0]->get_property_block(); }
sub has_prop_only {
    return defined $_[0]->get_property_block()
       && !defined $_[0]->get_text_block();
}
sub has_prop_or_text {
    return defined $_[0]->get_property_block()
        || defined $_[0]->get_text_block();
}

# length methods
sub property_length {
    my ($self) = @_;
    my $prop = $self->get_property_block();
    return defined $prop ? length( $prop->as_string() ) : 0;
}

sub text_length {
    my ($self) = @_;
    my $text = $self->get_text();
    return defined $text ? length($text) : 0;
}

sub as_string {
    my ($self) = @_;
    my $headers_block = $self->get_headers_block();

    # the headers block
    my $string = $headers_block->as_string();

    # the properties
    $string .= $self->get_property_block()->as_string()
        if $self->has_prop();

    # the text
    $string .= $self->get_text_block()->as_string()
        if $self->has_text();

    # is there an included record?
    if( my $included = $self->get_included_record() ) {
        $string .= $included->as_string() . $NL;
    }

    # add a record separator if needed
    my $type = $self->type();
    return $string if $type =~ /\A(?:format|uuid)\z/;

    $string .= $type eq 'revision'  ? $NL
        : $self->has_prop_or_text() ? $NL x 2
        :                             $NL ;

    return $string;
}

sub update_headers {
    my ($self)  = @_;
    my $proplen = $self->property_length();
    my $textlen = $self->text_length();

    $self->set_header( 'Text-content-length' => $textlen )
        if defined $self->get_text_block();
    $self->set_header( 'Prop-content-length', $proplen )
        if $proplen;
    $self->set_header( 'Content-length' => $proplen + $textlen );
}

# access methods to the inner blocks
sub set_header {
    my ($self, $h, $v) = @_;
    my $headers = $self->get_headers_block()
      || $self->set_headers_block( SVN::Dump::Headers->new() );
    $headers->set( $h, $v );
}

sub get_header {
    my ($self, $h) = @_;
    return $self->get_headers_block()->get($h);
}

sub set_property {
    my ( $self, $k, $v ) = @_;
    my $prop = $self->get_property_block()
      || $self->set_property_block( SVN::Dump::Property->new() );
    $prop->set( $k, $v );
    $self->update_headers();
    return $v;
}

sub get_property {
    my ($self, $k) = @_;
    return $self->get_property_block()->get($k);
}

sub delete_property {
    my ( $self, @keys ) = @_;
    my $prop = $self->get_property_block()
        || $self->set_property_block( SVN::Dump::Property->new() );
    my @result = $prop->delete(@keys);
    $self->update_headers();
    return wantarray ? @result : pop @result; # behave like delete()
}

sub set_text {
    my ($self, $t) = @_;
    my $text_block = $self->get_text_block()
      || $self->set_text_block( SVN::Dump::Text->new() );

    $text_block->set( $t );
    $self->update_headers();
    return $t;
}

sub get_text {
    my ($self) = @_;
    my $text_block = $self->get_text_block();
    return defined $text_block ? $text_block->get() : undef;
}

1;

__END__

=head1 NAME

SVN::Dump::Record - A SVN dump record

=head1 SYNOPSIS

    # SVN::Dump::Record objects are returned by the next_record()
    # method of SVN::Dump

=head1 DESCRIPTION

An SVN::Dump::Record object represents a Subversion dump record.

=head1 METHODS

L<SVN::Dump> provides the following gourps of methods:

=head2 Record methods

=over 4

=item new()

Create a new empty SVN::Dump::Record object.

=item type()

Return the record type, as guessed from its headers.

The method dies if the record type cannot be determined.

=item set_header( $h, $v )

Set the header C<$h> to the value C<$v>.

=item get_header( $h )

Get the value of header C<$h>.

=item set_property( $p, $v )

Set the property C<$p> to the value C<$v>.

=item get_property( $p )

Get the value of property C<$p>.

=item delete_property( @k )

Delete the properties named in C<@p>. Properties
that do not exist in the record will be silently ignored.

=item set_text( $t )

Set the value of the text block.

=item get_text()

Get the value of the text block.

=back

=head2 Inner blocks manipulation

A SVN::Dump::Record is composed of several inner blocks of various kinds:
L<SVN::Dump::Headers>, L<SVN::Dump::Property> and L<SVN::Dump::Text>.

The following methods provide access to these blocks:

=over 4

=item set_headers_block( $headers )

=item get_headers_block()

Get or set the L<SVN::Dump::Headers> object that represents the record
headers.

=item set_property_block( $property )

=item get_property_block()

Get or set the L<SVN::Dump::Property> object that represents the record
property block.

=item delete_property( @keys )

Delete the given properties. Behaves like the builtin C<delete()>.

=item set_text_block( $text )

=item get_text_block()

Get or set the L<SVN::Dump::Text> object that represents the record
text block.

=item set_included_record( $record )

=item get_included_record()

Some special record are actually output recursiveley by B<svnadmin dump>.
The "record in the record" is stored within the parent record, so they
are parsed as a single record with an included record.

C<get_record()> / C<set_record()> give access to the included record.

According to the Subversion sources (F<subversion/libsvn_repos/dump.c>),
this is a "delete original, then add-with-history" node. The dump looks
like this:

    Node-path: tags/mytag/myfile
    Node-kind: file
    Node-action: delete
    
    Node-path: tags/mytag/myfile
    Node-kind: file
    Node-action: add
    Node-copyfrom-rev: 23
    Node-copyfrom-path: trunk/myfile
    
    
    
    

Note that there is a single blank line after the first header block,
and four after the included one.

=item update_headers()

Update the various C<...-length> headers. Used internally.

B<You must call this method if you update the inner property or text
blocks directly, or the results of C<as_string()> will be inconsistent.>

=back

=head2 Information methods

=over 4

=item has_prop()

Return a boolean value indicating if the record has a property block.

=item has_text()

Return a boolean value indicating if the record has a text block.

=item has_prop_only()

Return a boolean value indicating if the record has only a property block
(and no text block).

=item has_prop_or_text()

Return a boolean value indicating if the record has a property block
or a text block.

=item property_length()

Return the length of the property block.

=item text_length()

Return the length of the text block.

=back

=head2 Output method

=over 4

=item as_string()

Return a string representation of the record that will be
understood by other Subversion tools, such as C<svnadmin>.

B<Warning:> dumping a record currently returns the information that
was read from the original dump. This means that if you modified the
property or text block of a record, the headers will be inconsistent.

=back

=head1 ENCAPSULATION

When using L<SVN::Dump> to manipulate a SVN dump, one should not
access the L<SVN::Dump::Headers>, L<SVN::Dump::Property> and
L<SVN::Dump::Text> components of a L<SVN::Dump::Record> object directly, but use
the appropriate C<set_...()> and C<get_...()> methods of the record object.

These methods compute the appropriate modifications of the header values,
so that the C<as_string()> method outputs the correct information after
any modification of the record.

=head1 SEE ALSO

L<SVN::Dump>, L<SVN::Dump::Reader>,
L<SVN::Dump::Headers>, L<SVN::Dump::Property>, L<SVN::Dump::Text>.

=head1 COPYRIGHT

Copyright 2006-2013 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
