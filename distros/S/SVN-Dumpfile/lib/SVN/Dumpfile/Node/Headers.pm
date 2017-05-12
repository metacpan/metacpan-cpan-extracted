################################################################################
# Copyright (c) 2008 Martin Scharrer <martin@scharrer-online.de>
# This is open source software under the GPL v3 or later.
#
# $Id: Headers.pm 103 2008-10-14 21:11:21Z martin $
################################################################################
package SVN::Dumpfile::Node::Headers;
use strict;
use warnings;
use Carp;
use Readonly;
Readonly my $NL => chr(10);

our $VERSION = do { '$Rev: 103 $' =~ /\$Rev: (\d+) \$/; '0.13' . ".$1" };

my @SVNHEADER = qw(
    Revision-number
    Node-path
    Node-kind
    Node-action
    Node-copyfrom-rev
    Node-copyfrom-path
    Prop-delta
    Prop-content-length
    Text-delta
    Text-content-length
    Text-copy-source-md5
    Text-content-md5
    Content-length
);

sub new {
    my $class = shift;
    my $self  = {};

    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        $self = { %{ $_[0] } };
    }
    elsif ( @_ == 1 && ref $_[0] eq 'ARRAY' && @{ $_[0] } % 2 == 0 ) {
        $self = { @{ $_[0] } };
    }
    elsif ( @_ % 2 == 0 ) {
        $self = {@_};
    }
    elsif ( @_ == 1 && !defined $_[0] ) {

        # Ignore single undef value
    }
    else {
        carp "${class}::new() awaits hashref, key/value pairs or an "
            . "arrayref to them as arguments. Ignoring all arguments.";
        return;
    }
    $self = bless $self, $class;
    return $self;
}

sub number {
    my $self = shift;
    scalar keys %$self;
}

sub read {
    my $self = shift;
    my $fh   = shift;

    my $line = eval { $fh->getline };
    return unless defined $line;

    while ( defined $line and $line =~ /^$/ ) {
        $line = $fh->getline;
    }

    # Should be 'Node-path: ' or 'Revision-number: ' now
    if ( $line !~ /^(Node-path|Revision-number): / ) {
        chomp($line);
        croak "No node start found at input file position ", $fh->tell, ".";
    }

    # Read headers
    do {
        if ( $line =~ /^([^:]+):\s*(.*)$/ ) {
            $self->{$1} = $2;
        }
        else {
            chomp $line;
            croak "Error in header at position ", $fh->tell,
                ", input line '$line'";
        }
    } while ( defined( $line = $fh->getline ) && $line !~ /^$/ );

    return 1;
}

sub as_string {
    my $self = shift;
    my $str  = "";

    my %not_printed = map { $_ => 0 } keys %$self;

    # Print in given order
    foreach my $key (@SVNHEADER) {
        next unless exists $self->{$key};
        $str .= "${key}: $self->{$key}$NL";
        delete $not_printed{$key};
    }

    # Print rest if exists
    foreach my $key ( keys %not_printed ) {
        $str .= "${key}: $self->{$key}$NL";
    }
    return $str;
}

*to_string = \&as_string;

sub write {
    my $self = shift;
    my $fh   = shift;

    unless ( eval { $fh->isa('IO::Handle') }
        || ref $fh  eq 'GLOB'
        || ref \$fh eq 'GLOB' )
    {
        croak "Given argument is no valid file handle.";
    }

    return $fh->print( $self->as_string . $NL );
}

#################
## sanitycheck - Checks if needed Headers exists and belong to each other
#####

sub sanitycheck {
    my $header = shift;
    my $error  = 0;

    # Revision entry needs also 'Prop-content-length' and 'Content-length'
    if ( exists $header->{'Revision-number'} ) {
        if (   !exists $header->{'Prop-content-length'}
            || !exists $header->{'Content-length'} )
        {
            carp "Missing needed header(s) after 'Revision-number'.\n";
            $error++;
        }
    }

    elsif ( !exists $header->{'Node-path'} ) {
        carp "Missing needed header 'Node-path' or 'Revision-number'.";
        return 10_000;
    }

    # Nodes need 'Node-action' at minimum.
    elsif ( !exists $header->{'Node-action'} ) {
        carp "Missing needed header 'Node-action' after 'Node-path'.";
        $error++;
    }
    else    # 'Node-action' exists:
    {
        my $action = $header->{'Node-action'};    # buffer
        if ( $action eq 'delete' ) {
            my $num_headers_expected
                = ( exists $header->{'Node-kind'} ) ? 3 : 2;

            if ( keys %$header != $num_headers_expected ) {
                carp "Two much headers for 'Node-action: delete'.\n";
                local $, = "\n";

                while ( my ( $key, $value ) = each %$header ) {
                    print STDERR "$key: $value\n";
                }
                $error++;
            }
        }
        elsif ( $action eq 'add' or $action eq 'replace' ) {
            if ( !exists $header->{'Node-kind'} ) {
                carp "Missing header 'Node-kind' for 'Node-action: add'.\n";
                $error++;
            }
            elsif ( $header->{'Node-kind'} eq 'file' ) {
                unless (    # This two header both exist
                    (      exists $header->{'Text-content-length'}
                        && exists $header->{'Text-content-md5'}
                        && !(    # and this two both exist or both non-exist
                            exists $header->{
                                'Node-copyfrom-rev'} ^    #\ xor+negation
                            exists $header->{
                                'Node-copyfrom-path'}     #/ = equivalence
                        )
                    )
                    || (    # This two header both exist
                        exists $header->{'Node-copyfrom-rev'}
                        && exists $header->{'Node-copyfrom-path'}
                        && !(    # and this two both exist or both non-exist
                            exists $header->{
                                'Text-content-length'} ^    #\ xor+negation
                            exists $header->{
                                'Text-content-md5'}         #/ = equivalence
                        )
                    )
                    )
                {    # then there is something wrong
                    carp "Missing/wrong header(s) for 'Node-action: add'/"
                        . "'Node-kind: file'.";
                    $error++;
                }
            }
            elsif ( $header->{'Node-kind'} eq 'dir' ) {
                if (   exists $header->{'Text-content-length'}
                    || exists $header->{'Text-content-md5'} )
                {
                    carp "To much header(s) for 'Node-action: add'/'Node-kind:
                    dir'.";
                    $error++;
                }
            }
            else {
                carp "Invalid value '"
                    . $header->{'Node-kind'}
                    . "' for 'Node-kind'.";
                $error++;
            }
        }
        elsif ( $action eq 'change' ) {

        }
        else {

        }
    }    # end of else path of "if ( !exists $header->{'Node-action'} )"

    #print STDERR Data::Dumper->Dump([$header], ['%header']) if $error;
    return $error;
}

1;
__END__

=head1 NAME

SVN::Dumpfile::Node::Headers - Represents the header of a node in a subversion
dumpfile.

=head1 SYNOPSIS

Objects of this class are used in SVN::Dumpfile::Node objects. For normal
dumpfile operations this subclass is an implementation detail. Some scripts
however might need to use methods of the class directly.

    use SVN::Dumpfile; # or use SVN::Dumpfile::Node:Content;
    $df = new SVN::Dumpfile ("filename");
    $node = $df->read_node;
    my $header = $node->headers;

    $header->{'Node-path'} =~ s/old/new/;
    # but should be done using:
    $node->header('Node-path') =~ s/old/new/;

=head1 DESCRIPTION, SEE ALSO, AUTHOR, COPYRIGHT

See L<SVN::Dumpfile>.


=head1 METHODS

=over 4

=item new()

Returns a new SVN::Dumpfile::Node::Headers object. Headers line can be given as
hash reference, as array reference or as list. Array and list must be even and
contain key/value pairs like a hash. For internal reasons a single but undefined
argument is ignored. The method returns undef if the number or kind of arguments
are incorrect.


=item number()

Returns the number of header lines. Can be taken as bool to check if there are
any headers.


=item read($filehandle)

Reads header lines from the given filehandle. This lines must be in the format
'Name: value' and must be followed by a blank line. The method croaks when a
miss-formatted line is found.


=item as_string()

=item to_string()

Returns all header lines as one string I<without> the needed blank line
separator which must be added manually.
The header lines are always returned in a pre-defined order, unlike properties.


=item write($filehandle)

Writes all header lines and a blank line as separator to the given filehandle.
The header lines are always written in a pre-defined order, unlike properties.


=item sanitycheck()

Checks the header is consistent, i.e. if the combination of header lines makes
sens. This method is work in progress and might not work at all at the moment.


=back

