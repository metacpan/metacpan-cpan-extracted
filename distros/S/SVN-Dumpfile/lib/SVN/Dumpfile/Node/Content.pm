################################################################################
# Copyright (c) 2008 Martin Scharrer <martin@scharrer-online.de>
# This is open source software under the GPL v3 or later.
#
# $Id: Content.pm 103 2008-10-14 21:11:21Z martin $
################################################################################
package SVN::Dumpfile::Node::Content;
use IO::File;
use Carp;
use strict;
use warnings;
use Readonly;
Readonly my $NL => chr(10);

our $VERSION = do { '$Rev: 103 $' =~ /\$Rev: (\d+) \$/; '0.13' . ".$1" };

use overload
    '""'     => \&as_string,
    fallback => 1;

sub new {
    my $class  = shift;
    my $scalar = shift;
    my $self   = bless \$scalar, ref $class || $class;
    return $self;
}

sub exists {
    my $self = shift;
    return ( defined $$self and $$self ne '' );
}

sub delete {
    my $self = shift;
    $$self = undef;
    return;
}

sub value : lvalue {
    my $self     = shift;
    my $newvalue = shift;
    $$self = $newvalue
        if defined $newvalue;
    $$self;
}

sub as_string {
    my $self = shift;
    return ( ( defined $$self ) ? $$self : '' );
}

*to_string = \&as_string;

sub read {
    my ( $self, $fh, $length ) = @_;
    return $fh->read( $$self, $length );
}

sub write {
    my $self = shift;
    my $fh   = shift;

    unless ( eval { $fh->isa('IO::Handle') }
        || ref $fh  eq 'GLOB'
        || ref \$fh eq 'GLOB' )
    {
        croak "Given argument is no valid file handle.";
    }

    return ($$self) ? $fh->print($$self) : '0 but true';
}

sub save {
    my ( $self, $fr ) = @_;
    my $fh;
    return unless defined $fr and defined $$self;

    # $fr can be filename or handle
    if ( !ref $fr ) {
        $fh = eval { new IO::File $fr, '>' };
        if ( !$fh ) {
            carp("Can't print to given filename!");
            return;
        }
        $fh->binmode;
    }
    elsif ( eval { $fr->can('print') } ) {
        $fh = $fr;
    }
    else {
        carp("Can't print to given handle!");
        return;
    }
    return $fh->print($$self);
}

sub load {
    use bytes;
    my ( $self, $fr ) = @_;
    my $fh;

    # $fr can be filename or handle
    if ( !ref $fr ) {
        $fh = eval { new IO::File $fr, '<' };
        return unless $fh;
        $fh->binmode;
    }
    elsif ( eval { $fr->can('getlines') } ) {
        $fh = $fr;
    }
    else {
        carp "Can't print to given handle!";
        return;
    }

    $$self = join '', $fh->getlines;
    return bytes::length($$self);
}

sub lines {
    my $self  = shift;
    my $lines = 0;
    $lines = ( $self =~ tr/\012// );
    $lines++ if $self !~ /$NL\Z/m;
    return $lines;    # Count lines
}

sub length {
    use bytes;
    my $self = shift;
    return 0 unless defined $$self;
    return bytes::length $$self;
}

1;
__END__

=head1 NAME

SVN::Dumpfile::Node::Content - Represents the content of a node in a subversion
dumpfile.

=head1 SYNOPSIS

Objects of this class are used in SVN::Dumpfile::Node objects. For normal
dumpfile operations this subclass is an implementation detail. Some scripts
however might need to use methods of the class directly.

    use SVN::Dumpfile; # or use SVN::Dumpfile::Node:Content;
    $df = new SVN::Dumpfile ("filename");
    $node = $df->read_node;
    my $content = $node->content;

    # Saves or loads content to file:
    $content->load('filename');
    $content->save('filename');

=head1 DESCRIPTION, SEE ALSO, AUTHOR, COPYRIGHT

See L<SVN::Dumpfile>.

=head1 OVERLOADED METHODS

The stringification operator '""' is overloaded to call as_string().
So the following two lines give identical results:

    "text " . $content->as_string() . " text"
    "text $content text"

Please note that the content can include binary elements.


=head1 METHODS

=over 4


=item new()

Returns a new SVN::Dumpfile::Node::Content object. A initial content can be
given as argument.


=item exists()

Returns true if there is a defined, not empty content.


=item delete()

Deletes the content of the object (but not the object itself). Don't forget to
remove the corresponding header lines by mark the node changed().


=item value()

=item value("new value")

=item value()= "new value"

Returns or sets the content which is returned as lvalue.


=item as_string()

=item to_string()

Returns the content as one string. Please note that the string can contain
binary elements. This is identical to call value() without an argument and not
using it as lvalue.


=item read($filehandle, $length)

Reads <length> bytes from the given filehandle and stores them as content.
Returns true if successful.


=item write($filehandle)

Writes the content to the given filehandle. Returns true if successful.
Returns true if successful.


=item save($filename)

=item save($filehandle)

Saves the content in the given file which is created when given as name.
This is used to export the content and so differs from write().
Returns true if successful.


=item load($filename)

=item load($filehandle)

Loads the content from a given file. The whole file is taken as content. This is
used to import content from an external file and so differs from read().
Returns the number of bytes of the loaded content if successful, undef
otherwise.


=item lines()

Returns the number of line breaks (NL, "\012") in the content. This can be
used to keep track of the current line number of the dumpfile for warning or
error messages, etc..


=item length()

Returns the length in bytes of the content. To check if there is any content use
exists().

=back

