################################################################################
# Copyright (c) 2008 Martin Scharrer <martin@scharrer-online.de>
# This is open source software under the GPL v3 or later.
#
# $Id: Node.pm 103 2008-10-14 21:11:21Z martin $
################################################################################
package SVN::Dumpfile::Node;
use strict;
use warnings;
use 5.008001;
use SVN::Dumpfile::Node::Headers;
use SVN::Dumpfile::Node::Properties;
use SVN::Dumpfile::Node::Content;
use Digest::MD5 qw(md5_hex);
use Carp;
use Date::Parse;
use Readonly;
Readonly my $NL => chr(10);

our $VERSION = do { '$Rev: 103 $' =~ /\$Rev: (\d+) \$/; '0.13' . ".$1" };

sub new {
    my $arg = shift;
    my $class = ref $arg || $arg;

    my %hasharg;
    my $hargref = \%hasharg;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        $hargref = shift;
    }
    elsif ( @_ % 2 == 0 ) {
        %hasharg = @_;
        $hargref = \%hasharg;
    }
    elsif ( @_ == 1 && !defined $_[0] ) {

        # Ignore single undef value
    }
    else {
        carp
            "${class}::new() awaits a hashref or even array with key/value pairs."
            . "Ignoring all arguments.";
    }

    my $self = bless {
        headers => SVN::Dumpfile::Node::Headers->new( $hargref->{'headers'} ),
        properties =>
            SVN::Dumpfile::Node::Properties->new( $hargref->{'properties'} ),
        contents => SVN::Dumpfile::Node::Content->new( $hargref->{'content'} ),
        changed => scalar keys %$hargref,
    }, $class;
    return $self;
}

sub newrev {
    my $arg = shift;
    my $class = ref $arg || $arg;
    my $r;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        $r = shift;
    }
    elsif ( @_ % 2 == 0 ) {
        $r = {@_};
    }
    elsif ( @_ == 1 && !defined $_[0] ) {

        # Ignore single undef value
    }
    else {
        carp
            "${class}::newrev() awaits a hashref or even array with key/value pairs."
            . "Ignoring all arguments.";
    }

    my $strdate;
    if (   !exists $r->{date}
        || $r->{date} =~ /^\d+$/
        || ( $strdate = str2time( $r->{date} ) ) )
    {
        my $time = $strdate || $r->{date} || time;
        my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime($time);

        # '2006-05-10T13:31:40.486172Z'
        $r->{date} = sprintf(
            "%04d-%02d-%02dT%02d:%02d:%02d.%06dZ",
            $year + 1900,
            $mon + 1, $mday, $hour, $min, $sec, 0
        );
    }
    elsif ( $r->{date} !~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/ ) {
        carp "Wrong format for new revision node given. Import of resulting "
            . "dumpfile might break.";
    }

    return $class->new(
        headers => {
            'Revision-number' => $r->{number} || 0,
            'Prop-content-length' => 0,
            'Content-length'      => 0,
        },
        properties => {
            'svn:author' => $r->{author} || $ENV{USER} || '(unknown)',
            'svn:date' => $r->{date},
            (exists $r->{'log'}) ? ('svn:log' => $r->{'log'}) : ()
        }
    );

}

sub content : lvalue {
    my $self = shift;
    $self->{contents}->value(@_);
}

sub contents {
    my $self = shift;
    return $self->{contents};
}

sub has_contents {
    my $self = shift;
    return unless exists $self->{contents};
    return $self->{contents}->exists;
}

sub header : lvalue {
    my ( $self, $h, $value ) = @_;

    $self->{headers}->{$h} = $value
        if defined $value;
    $self->{headers}->{$h};
}

sub headers {
    my $self = shift;
    return $self->{headers};
}

sub has_header {
    my $self = shift;
    my $header = shift;
    return unless exists $self->{headers};
    return exists $self->{headers}->{$header};
}

sub has_headers {
    my $self = shift;
    return if not exists $self->{headers};
    return scalar keys %{ $self->{headers} };
}

sub property : lvalue {
    my ( $self, $prop, $value ) = @_;
    if ( @_ == 1 ) {
        return $self->{properties}->{property};
    }
    $self->{properties}->{property}->{$prop} = $value
        if defined $value;
    $self->{properties}->{property}->{$prop};
}

sub has_property {
    my $self = shift;
    my $prop = shift;
    return
        unless exists $self->{properties}
            and exists $self->{properties}->{property};
    return exists $self->{properties}->{property}->{$prop};
}

sub properties {
    my $self = shift;
    return $self->{properties};
}

sub has_properties {
    my $self = shift;
    return
        unless exists $self->{properties}
            and exists $self->{properties}->{property};
    return scalar keys %{ $self->{properties}->{property} };
}

sub changed {
    my $self = shift;
    $self->{changed} = 1;
    return;
}

sub has_changed {
    my $self = shift;
    return $self->{changed};
}

sub is_rev {
    my $self = shift;
    return exists $self->{headers}{'Revision-number'};
}

sub revnum : lvalue {
    my ( $self, $value ) = shift;
    $self->{headers}{'Revision-number'} = $value
        if defined $value;

    $self->{headers}{'Revision-number'};
}

sub read {
    my $self = shift;
    my $fh   = shift;    # Filehandle to read
    my $line;

    return unless defined $fh and eval { $fh->isa('IO::Handle') };

    my $header = $self->{'headers'};

    my $irs = IO::Handle->input_record_separator($NL);

    $self->{headers}->read($fh);
    return if $fh->eof;

    # Get properties when they exist (but then they can be empty also!)
    $self->{properties}->read( $fh, $header->{'Prop-content-length'} )
        if exists $header->{'Prop-content-length'};

    # Get content
    $self->{contents}->read( $fh, $header->{'Text-content-length'} )
        if exists $header->{'Text-content-length'};

    # Save delimiter blank lines to be able to restore the input file exact
    $self->{delim} = "";
    my $c;
    while ( $c = $fh->getc and $c eq $NL ) {
        $self->{delim} .= $c;
    }
    $fh->ungetc( ord $c ) if defined $c;

    IO::Handle->input_record_separator($irs);
    return 1;
}

#################
## Write node entry to filehandle

sub write {
    my $self = shift;    # Hash (as reference) with node to be written
    my $fh   = shift;    # Filehandle to write to
    my $ret  = 1;

    croak "Given argument is not a valid file handle."
        unless defined $fh;

    my $header = $self->{headers};

    return unless ( $header->number );    # skip if there is no header

    $self->recalc_headers if $self->{changed};

    $ret &&= $self->{headers}->write($fh);

    # Properties
    $ret &&= $self->{properties}->write($fh)
        if ( exists $header->{'Prop-content-length'}
        and $header->{'Prop-content-length'} > 0 );

    # Content
    $ret &&= $self->{contents}->write($fh)
        if ( exists $header->{'Text-content-length'}
        and $header->{'Text-content-length'} > 0 );

    $ret &&= $fh->print( exists $self->{delim} ? $self->{delim} : $NL );
    return $ret;
}

sub as_string {
    my $self = shift;
    return '' unless ( $self->has_headers );    # skip if there are no header
    $self->recalc_headers if $self->{changed};

    return ''
        . $self->{headers}->as_string
        . $NL
        . $self->{properties}->as_string
        . $self->{contents}->as_string
        . ( $self->{delim} || $NL );
}

sub recalc_headers {
    my $self = shift;

    $self->recalc_textcontent_header;
    $self->recalc_prop_header;

    $self->{changed} = 0;
    return;
}

#################
## recalc_content_header - Recalculate 'Content-length' header
#####
# Depends on correct values in other headers.
# Will be called by other recalc-functions.

sub recalc_content_header {
    my $self   = shift;
    my $header = $self->{headers};
    no warnings 'uninitialized';

    my $header_existed = exists $header->{'Content-length'};

    $header->{'Content-length'}
        = $header->{'Text-content-length'} + $header->{'Prop-content-length'};

    if ( $header->{'Content-length'} == 0 && !$header_existed ) {
        delete $header->{'Content-length'};
    }
    return;
}

#################
## recalc_textcontent_header - Recalculate 'Text-content'* and dependend headers
#####

sub recalc_textcontent_header {
    use bytes;
    no warnings 'uninitialized';
    my $self   = shift;
    my $header = $self->{headers};

    my $oldlength      = $header->{'Text-content-length'};
    my $header_existed = exists $header->{'Text-content-length'};

    my $length
        = defined $self->{'contents'}
        ? $self->{'contents'}->length
        : 0;

    if ( !$header_existed && $length == 0 ) {
        delete $header->{'Text-content-length'};
        delete $header->{'Text-content-md5'};
    }
    else {
        $header->{'Text-content-length'} = $length;
        $header->{'Text-content-md5'}    = md5_hex( ${ $self->{'contents'} } );
    }

    $self->recalc_content_header
        if ( $oldlength != $header->{'Text-content-length'} );
    return;
}

#################
## recalc_prop_header - Recalculate 'Prop-content-length' and dependend headers
#####

sub recalc_prop_header {
    use bytes;
    my $self   = shift;
    my $header = $self->{'headers'};
    my $prop   = $self->{'properties'};

    # Don't remove or create header unless necessary
    my $header_existed = exists $header->{'Prop-content-length'};

    # Correct properties length:
    $header->{'Prop-content-length'} = $prop->length;

    if ( !$header_existed && $header->{'Prop-content-length'} eq 10 ) {
        delete $header->{'Prop-content-length'};
    }

    $self->recalc_content_header;
    return;
}

1;
__END__

=head1 NAME

SVN::Dumpfile::Node - Represents a node in a subversion dumpfile.

=head1 SYNOPSIS

Objects of this class are returned by SVN::Dumpfile method read_node():

    use SVN::Dumpfile;
    my $df = new SVN::Dumpfile ('filename');
    my $node = $df->read_node();

=head1 DESCRIPTION, SEE ALSO, AUTHOR, COPYRIGHT

See L<SVN::Dumpfile>.

=head1 METHODS

=over 4

=item new()

Returns new node object. A node consists out of a header ('key: value' lines),
optional properties and optional content. All three can be given by providing a
hash (as reference or list) or by extra methods (see below).

    my $enode = new SVN::Dumpfile::Node();   # Empty node
    my $fnode = new SVN::Dumpfile::Node(     # Filled node
        headers => {
                'Node-path' => 'a/path',
                ....
                },
        properties => { # can be [ to maintain given order
                'svn:keywords' => 'Author Id',
                ....
                },      # or ]
        content => "some text or binary content"
    );

=item newrev()

Returns a new revision node which represents the start of a new revision. This
is a special node which has a 'Revision-number' header line and normaly the
'svn:author', 'svn:date' and 'svn:log' properties. All can be given by providing
a hash (as reference or list) or by extra methods (see below).

    my $rev = newrev SVN::Dumpfile::Node (
        number => 123,
        author => 'martin',
        date   => time,
        log    => 'Implemented feature XYZ.',
    );

Note that date must be either an Unix time integer or a string with the format
'YYYY-MM-DDTHH:MM:SS.SFRACTZ' ('T' and 'Z' are literals), e.g.:
'2006-05-10T13:31:40.486172Z'. The date string is in GMT ("Zulu") time.


=item content()

=item content('new content')

=item content() = 'new content'

Returns or sets the node content. The new value can be set by
providing it as argument or by assigning it to the method which returns an 
lvalue.


=item contents()

Returns a reference to the node content object which is from the class
L<SVN::Dumpfile::Node::Content>. Because the stringification operator of this
class is overloaded it returns as_string() in string context, i.e.:

    $node->contents . 'some string, can be empty'


=item has_contents()

Returns true if the node has content.


=item header('name')

=item header('name', 'new value')

=item header('name') = 'new value'

Returns or sets a node header line. The new value can be set by 
providing it as argument or by assigning it to the method which returns an 
lvalue.


=item headers()

Returns a reference to the node header object which is from the class 
L<SVN::Dumpfile::Node::Headers>.


=item has_header('header')

Returns true if the node has the the given header line.


=item has_headers()

Returns number of header lines and so true if the node has header lines.
Without correct header lines the node is not valid and properties and 
content will not be written with write().


=item property('name')

=item property('name', 'new value')

=item property('name') = 'new value'

Returns or sets a node property. The new value can be set by providing it as
argument or by assigning it to the method which returns an lvalue.


=item has_property('name')

Returns true if the node has the given property.


=item properties()

Returns a reference to the node properties object which is from the class
L<SVN::Dumpfile::Node::Properties>.


=item has_properties()

Returns true if the node has properties.


=item changed()

Marks the node as changed, e.g. the content and properties header are
out-of-date. This will cause an recalc_headers() call at write() or as_string().


=item has_changed()

Returns true if the node is marked as changed. Call recall_headers() to unmark
the note. See also L<changed>.


=item is_rev()

Returns true if the node is a revision node.


=item revnum()

=item revnum($new_revnum)

=item revnum() = $new_revnum

Returns or sets the revision number if the node is a revision node. Otherwise
the method call is ignore and does return undef.
The new number can be set by providing it as
argument or by assigning it to the method which returns an lvalue.


=item read($filehandle)

Reads the node from the given filehandle. This is normally called from a
L<SVN::Dumpfile> object.


=item write($filehandle)

Writes the node to the given filehandle. This is normally called from a
L<SVN::Dumpfile> object.


=item as_string()

Returns the whole node as string like it would be written to the dumpfile.


=item recalc_headers()

Recalculates all content and property header lines. This is needed to have
correct length and MD5 header lines after properties and/or content have changed.


=item recalc_content_header()

Recalculates content header lines. This method is also called by the two
following methods.

=item recalc_textcontent_header()

Recalculates text content header lines.

=item recalc_prop_header()

Recalculates properties header lines.

=back

