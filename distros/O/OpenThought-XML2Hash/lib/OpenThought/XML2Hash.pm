# This file is Copyright (c) 2000-2003 Eric Andreychek.  All rights reserved.
# For distribution terms, please see the included LICENSE file.
#
# $Id: XML2Hash.pm,v 1.9 2003/08/10 03:25:13 andreychek Exp $
#

package OpenThought::XML2Hash;

$OpenThought::XML2Hash::VERSION = '0.57';

=head1 NAME

OpenThought::XML2Hash

=head1 SYNOPSIS

use OpenThought::XML2Hash;

my $xml = '<xml><packet type="example"/></xml>';
my $hash = xml2hash( $xml );

=head1 DESCRIPTION

OpenThought::XML2Hash is a no nonsense XML parser.  It's an attempt to create a
hash out of an XML packet as fast as possible.  It takes an XML file or string
and returns a hash of the appropriate nested depth based on the contents of the
XML.

XML2Hash only looks at XML attributes, start tags, end tags, and the
character data in between.  It ignores most everything else, including comments,
namespaces, and CDATA sections.  This is a feature :-)  One day, it'll probably
do something constructive with comments.

With the limited set of XML processed, and the methods used to process it,
XML2Hash appears to be almost twice as fast as any other module on CPAN which
can make a hash out of XML.

=head1 FUNCTIONS

=cut

use strict;
use XML::Parser::Expat();
require Exporter;

@OpenThought::XML2Hash::ISA       = qw( Exporter );
@OpenThought::XML2Hash::EXPORT_OK = qw( xml2hash );

=head2 hashref xml2hash( xml, [element] )

This is the main function of the XML2Hash package.  It accepts two arguments,
only the first is required.  It then returns the hash representation of your
data.

=over

=item Parameters

=over

=item xml

Path to the XML file, or a string containing an XML packet.

=item element (optional)

Don't process the XML data until reaching this element.  If you specify element
"foo" here, foo will not be used as a hash key, but the next XML tag to be
found will be.  It makes sense when you use it :-)

This would typically be used when you have a large XML file, but you only need
a small subsection as a hash.  By passing in the b<element> argument, you'd
save some CPU time by only processing the data you care about.

=back

=item Returns

=over

Returns a reference to a hash containing the contents of the XML file, with
each XML element being a hash key.  The hash is nested just as your XML was.

=cut

# Define these here so they stay in scope throughout this module
my $start_element;
my $parsing = 0;
my $hash_root = {};
my $last_element;
my $tag_open = 1;

sub xml2hash {
    my ( $xml, $start_element_param ) = @_;

    die "You must pass an XML string or file!\n"  unless $xml;

    # Reset these before use so we don't end up with stale values, as mod_perl
    # tends to keep them around
    $start_element = $start_element_param || "";
    $parsing = 0;
    $hash_root = {};
    $last_element = "";
    $tag_open = 1;

    # Create a new XML::Parser::Expat Object
    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers( 'Start'  => \&_handle_start );

    # If we were not passed a start element, we begin parsing immediatly
    unless ( $start_element ) {
        $parsing = 1;
        $parser->setHandlers( 'Char' => \&_handle_char,
                              'End'  => \&_handle_end  );
    }

    # If what we have begins with a <, it's likely an XML packet that we were
    # passed, as opposed to a file.
    if( substr( $xml, 0, 1 ) eq "<" ) {
        # Parse an XML string
        $parser->parse( $xml );
    }
    else {
        # Read in the XML Content from a file, and begin parsing
        open( XML, $xml ) or die "Couldn't open $xml: $!";
        $parser->parse( *XML );
        close( XML );
    }

    $parser->release();

    ### Return the hash we created to the calling function

    # Since we have a start element, we can return the exact contents of the
    # hash we just built
    if( $start_element ) {
        return $hash_root;
    }
    # We weren't provided with a start element.  Return the hash, minus the
    # opening element
    else {
        my @rootnode = keys %$hash_root;
        return $hash_root->{$rootnode[0]};
    }
}

# Sub which handles start tags
sub _handle_start {
    my ( $parser, $element, %attrs ) = @_;

    $last_element = $element;

    # If a start tag is listed, and the parsing flag has not yet been switched
    # on -- test to see if the current element is our start element.
    if ( $start_element and not $parsing ) {

        # If the current element is the start element, turn on parsing
        if( $element eq $start_element ) {
            $parsing = 1 if $element eq $start_element;
            $parser->setHandlers( 'Char' => \&_handle_char,
                                  'End'  => \&_handle_end  );
        }
        return;
    }

    return unless $parsing;

    # We want to handle element attributes if they were sent to us
    # ie, in <name first="eric"> -- first="eric" is the attribute, and is
    # handled as part of the start tag
    if( %attrs ) {
        while(my ( $key, $char ) = each( %attrs )) {
            _build_hash( $parser, $char, $key, $element );
        }
    }

}

sub _handle_end {
    my ( $parser, $element ) = @_;

    return unless $parsing;

    if( $last_element eq $element ) {
        _build_hash( $parser, "", "", $element );
    }

    $tag_open = 0;
}

# Sub which handles the character data
sub _handle_char {
    my ( $parser, $char ) = @_;

    return unless $parsing;

    # We get a lot of false data full of spaces which XML::Parser thinks is a
    # character element.. so if we are called with only spaces, just ignore
    # it..  Hopefully, we're doing anything really bad because of this :-)
    return if $char =~ m/^\s+$/;

    _build_hash( $parser, $char );
    $last_element = "";
}

#  $parser:  The XML::Parser::Expat object
#  $value:   The character data that just generated this event
#  $attr:    If the XML had an attribute, this would be passed to us from the
#            start_element event, with the name of the attribute.
#  $element: Like $attr, except that this parameter contains the name of the
#            opening element the attribute was part of.
sub _build_hash {
    my ( $parser, $value, $attr, $element ) = @_;

    # Create a new reference, to this reference to a hash.  hash_root will
    # remain at the root of our nested hash, $hash_ref will be used to traverse
    # the elements in the hash being built.
    my $hash_ref = $hash_root;

    # How deep are we into the XML?
    my @path = $parser->context();

    # The last element in this array is special -- this element will be a
    # simple hash key which contains a string.  Each other hash
    # key will contain a reference to a hash.
    my $last_key;

    # If we were passed an attribute, the last key should be the attribute
    # name.  Also, we need to add $element to the path.  When you are in the
    # start_element handler, and looking at an attribute, the result of
    # $parser->context does not include the start_element you are in.
    if( $attr ) {
        $last_key = $attr;
        push @path, $element;
    }
    # This would typically happen when called from an end_tag handler
    elsif( $element ) {
        $last_key = $element;
    }
    # We'll do this if we're just called from a char handler
    else {
        $last_key = pop @path;
    }

    # If we are trying to only parse a segment of the XML file,
    # $parser->context returns too much information.  Figure out what to drop
    # off the front of the path.
    my $parse;
    if ( $start_element ) {
        $parse = 0;
    }
    else {
        $parse = 1;
    }

    foreach my $key ( @path ) {

        if ( not $parse and $key eq $start_element ) {
            $parse = 1;
            next;
        }

        next unless $parse;

        # The reason this works is because Perl does not have multidimensional
        # hashes (or arrays, for that matter).  Instead, you simply have
        # multiple references to hashes which just point to each other.  This
        # next line creates a new reference to a hash, and tacks it on to the
        # existing nested hash.  $hash_ref will always point to the latest
        # hashref put onto our nested hash.  At any point, we can see the entire
        # nested hash via $hash_root.
        $hash_ref->{$key} ||= {};
        $hash_ref = $hash_ref->{$key};
    }

    unless ($parse) {
        $parsing = 0;
        $parser->finish;
    }

    # If our current $last_key doesn't already exist, assign it now!
    if ( !exists($hash_ref->{$last_key} )) {
        $hash_ref->{$last_key} = $value;
        $tag_open = 1;
    }

    # Sometimes, and for some odd reason, the char event may be called more
    # than once for the same character field.  In that case, we want to append
    # the data onto the existing key (ampersands seem to cause this behavior)
    elsif ( exists $hash_ref->{$last_key} and $tag_open ) {
        $hash_ref->{$last_key} .= $value;
    }

    # If the key we're trying to create already exists as an array, push the
    # new value on it
    elsif( ref( $hash_ref->{$last_key} ) eq "ARRAY") {
        push @{ $hash_ref->{$last_key} }, $value;
    }

    # Sometimes, the char handler is called multiple times, even before hitting
    # the end tag.  This is here to handle events like that -- the chars should
    # be strung together.
    elsif(( exists( $hash_ref->{$last_key} )) && ( $last_element eq "")) {
        $hash_ref->{$last_key} .= $value;
    }

    # If the key already exists, don't overwrite it, turn it into an array so we
    # can add as many values as desired
    elsif( exists( $hash_ref->{$last_key} )) {
        my $prev_val = $hash_ref->{$last_key};
        $hash_ref->{$last_key} = ();

        push @{ $hash_ref->{$last_key} }, $prev_val;
        push @{ $hash_ref->{$last_key} }, $value;
    }
    # The key doesn't exist yet, add it on as a typical scalar
    # This is somewhat of a default catchall behaviour, this should have
    # happened with the first if statement above
    else {
        $hash_ref->{$last_key} = $value;
    }
}


1;

=head1 SEE ALSO

OpenThought, XML::Parser::Expat

=head1 AUTHOR

Eric Andreychek (eric at openthought.net)

=head1 COPYRIGHT

OpenThought::XML2Hash is Copyright (c) 2000-2003 by Eric Andreychek.

=head1 BUGS

None known.

