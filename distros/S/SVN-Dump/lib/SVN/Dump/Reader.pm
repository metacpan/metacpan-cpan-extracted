package SVN::Dump::Reader;

use strict;
use warnings;
use IO::Handle;
use Carp;

our @ISA = qw( IO::Handle );

# SVN::Dump elements
use SVN::Dump::Headers;
use SVN::Dump::Property;
use SVN::Dump::Text;
use SVN::Dump::Record;

# some useful definitions
my $NL = "\012";

# prepare the digest checkers
my @digest = grep {
    eval { require Digest; Digest->new(uc) }
} qw( md5 sha1 );

# the object is a filehandle
sub new {
    my ($class, $fh, $args) = @_;
    croak 'SVN::Dump::Reader parameter is not a filehandle'
        if !( $fh && ref $fh && ref($fh) eq 'GLOB' );
    %{*$fh} = %{ $args || {} };
    return bless $fh, $class;
}

sub read_record {
    my ($fh) = @_;

    my $record = SVN::Dump::Record->new();

    # first get the headers
    my $headers = $fh->read_header_block() or return;
    $record->set_headers_block( $headers );
    
    # get the property block
    $record->set_property_block( $fh->read_property_block() )
        if (
            exists $headers->{'Prop-content-length'} and
            $headers->{'Prop-content-length'}
        );

    # get the text block
    if ( exists $headers->{'Text-content-length'}
        and $headers->{'Text-content-length'} )
    {
        my $text = $fh->read_text_block( $headers->{'Text-content-length'} );

        # verify checksums (but not in delta dumps)
        if (${*$fh}{check_digest}
            && (  !$headers->{'Text-delta'}
                || $headers->{'Text-delta'} ne 'true' )
            )
        {
            for my $algo ( grep { $headers->{"Text-content-$_"} } @digest ) {
                my $digest = $text->digest($algo);
                croak
                    qq{$algo checksum mismatch: got $digest, expected $headers->{"Text-content-$algo"}}
                    if $headers->{"Text-content-$algo"} ne $digest;
            }
        }

        $record->set_text_block($text);
    }

    # some safety checks
    croak "Inconsistent record size"
        if ( $headers->{'Prop-content-length'} || 0 )
        + ( $headers->{'Text-content-length'} || 0 )
        != ( $headers->{'Content-length'} || 0 );

    # if we have a delete record with a 'Node-kind' header
    # we have to recurse for an included record
    if (   exists $headers->{'Node-action'}
        && $headers->{'Node-action'} eq 'delete'
        && exists $headers->{'Node-kind'} )
    {
        my $included = $fh->read_record();
        $record->set_included_record( $included );
    }

    # uuid and format record only contain headers
    return $record;
}

sub read_header_block {
    my ($fh) = @_;

    local $/ = $NL;

    # skip empty lines
    my $line;
    while(1) {
        $line = <$fh>;
        return if !defined $line;
        chop $line;
        last unless $line eq '';
    }

    my $headers = SVN::Dump::Headers->new();
    while(1) {
        my ($key, $value) = split /: /, $line, 2;
        $headers->{$key} = $value;

        $line = <$fh>;
        croak _eof() if !defined $line;
        chop $line;
        last if $line eq ''; # stop on empty line
    }

    croak "Empty line found instead of a header block line $."
       if ! keys %$headers;

    return $headers;
}

sub read_property_block {
    my ($fh) = @_;
    my $property = SVN::Dump::Property->new();

    local $/ = $NL;
    my @buffer;
    while(1) {
        my $line = <$fh>;
        croak _eof() if !defined $line;
        chop $line;

        # read a key/value pair
        if( $line =~ /\AK (\d+)\z/ ) {
            my $key = $fh->_read_string( $1 );

            $line = <$fh>;
            croak _eof() if !defined $line;
            chop $line;
         
            if( $line =~ /\AV (\d+)\z/ ) {
                my $value = $fh->_read_string( $1 );

                $property->set( $key => $value );

                # FIXME what happens if we see duplicate keys?
            }
            else {
                croak "Corrupted property"; # FIXME better error message
            }
        }
        # or a deleted key (only with fs-format-version >= 3)
        # FIXME shall we fail if fs-format-version < 3?
        elsif( $line =~ /\AD (\d+)\z/ ) {
            my $key = $fh->_read_string( $1 );
            
            $property->set( $key => undef ); # undef means deleted
        }
        # end of properties
        elsif( $line =~ /\APROPS-END\z/ ) {
            last;
        }
        # inconsistent data
        else {
            croak "Corrupted property"; # FIXME better error message
        }
    }

    return $property;
}

sub read_text_block {
    my ($fh, $size) = @_;

    return SVN::Dump::Text->new( $fh->_read_string( $size ) );
}

sub _read_string {

    my ( $fh, $size ) = @_;

    local $/ = $NL;

    my $text;
    my $characters_read = read( $fh, $text, $size );

    if ( defined($characters_read) ) {
        if ( $characters_read != $size ) {
            croak _eof();
        };
    } else {
        croak $!;
    };

    <$fh>; # clear trailing newline

    return $text;

};

# FIXME make this more explicit
sub _eof { return "Unexpected EOF line $.", }

__END__

=head1 NAME

SVN::Dump::Reader - A Subversion dump reader

=head1 SYNOPSIS

    # !!! You should use SVN::Dump, not SVN::Dump::Reader !!!

    use SVN::Dump::Reader;
    my $reader = SVN::Dump::Reader->new( $fh );
    my $record = $reader->read_record();

=head1 DESCRIPTION

The SVN::Dump::Reader class implements a reader object for Subversion
dumps.

=head1 METHODS

The following methods are available:

=over 4

=item new( $fh, \%options )

Create a new SVN::Dump::Reader attached to the C<$fh> filehandle.

The only supported option is C<check_digest>, which is disabled
by default.

=item read_record( )

Read and return a new L<SVN::Dump::Record> object from the dump filehandle.

If the option C<check_digest> is enabled, this method will recompute
the digests for a dump without deltas, based on the information in the
C<Text-content-md5> and C<Text-content-sha1> headers (if the corresponding
L<Digest> module is availabled). In case of a mismatch, the routine
will C<die()> with an exception complaining about a C<checksum mismatch>.

=item read_header_block( )

Read and return a new L<SVN::Dump::Headers> object from the dump filehandle.

=item read_property_block( )

Read and return a new L<SVN::Dump::Property> object from the dump filehandle.

=item read_text_block( )

Read and return a new L<SVN::Dump::Text> object from the dump filehandle.

=back

The C<read_...> methods will die horribly if asked to read inconsistent
data from a stream.

=head1 SEE ALSO

L<SVN::Dump>, L<SVN::Dump::Record>, L<SVN::Dump::Headers>, L<SVN::Dump::Property>,
L<SVN::Dump::Text>.

=head1 COPYRIGHT

Copyright 2006-2013 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
