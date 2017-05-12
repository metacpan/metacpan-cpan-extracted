package SeeAlso::Identifier::ISSN;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.5704';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

use base qw(SeeAlso::Identifier);
use Business::ISSN;
#use Carp;


#################### subroutine header end ####################


=head1 NAME

SeeAlso::Identifier::ISSN - SeeAlso handling of International Standard Serial Numbers


=head1 SYNOPSIS

  my $issn = new SeeAlso::Identifier::ISSN "";

  print "invalid" unless $issn; # $issn is defined but false !

  $issn->value;                  # get value
  $issn->value( '1456-5935' );   # set value

  $issn->canonical; # urn:ISSN:1456-5935
  $issn; # ISSN as URI (urn:ISSN:1456-5935)

  $issn->pretty; # 1456-5935   (most official form)

  $issn->hash; # long int 0 <= x <= 9.999.999 (or "")
  $issn->hash( 1456593 ); # set by hash value


=head1 DESCRIPTION

This module handles International Standard Serial Numbers as identifiers
by letting L<Business::ISSN> do the real work.
Unlike L<Business::ISSN> the constructor of SeeAlso::Identifier::ISSN 
always returns an defined identifier with all methods provided by
L<SeeAlso::Identifier>. 
As canonical form the URN representation of ISSN with hyphens is used. 
As hashed form of an ISSN, a 32 Bit integer can be calculated.

Please note that (hashed) 0 is a valid value representing ISSN 0000-0000.


=head1 METHODS

=head2 parse ( $value )

Get and/or set the value of the ISSN. Returns an empty string or the valid
ISSN with hyphens as determined by L<Business::ISSN>. You can also 
use this method as function.

=cut

sub parse {
    local($_) = shift;
    $_ = shift if ref($_) and scalar @_;

    return '' unless defined $_;

    my $testok;
    eval { $testok = $_->isa('Business::ISSN'); };
    unless ( $testok ) {
        s/^\s+//; s/\s+$//; s/\s+/ /g;  # normalize-spaces()
        s/^urn:ISSN://i;
        s/^ISSN\s*//i;
        $_ = Business::ISSN->new( $_ );
    }

    return '' unless defined $_;
    return '' unless $_->is_valid;
    return $_->as_string();
}

=head2 canonical

Returns a Uniform Resource Identifier (URI) for this ISSN (or an empty string).

This is an URI according to RFC 3044 ("urn:ISSN:...").

=cut

sub canonical {
    return ${$_[0]} eq '' ? '' : 'urn:ISSN:' . ${$_[0]};
}

=head2 hash ( [ $value ] )

Returns or sets a space-efficient representation of the ISSN as integer.
An ISSN always consists of 7 digits plus a check digit/character.
This makes 10.000.000 possible ISSN which fit in a 32 bit (signed or 
unsigned) integer value. The integer value is calculated from the ISSN by
removing the dash and the check digit.

=cut

sub hash {
    my $self = shift;

    # TODO: support use as constructor and as function

    if ( scalar @_ ) {
        my $value = shift;
        $value = defined $value ? "$value" : "";
        $value = '' if not $value =~ /^[0-9]+$/ or $value >= 9999999;
                                                               
        if ( $value eq "" ) {
            $$self = '';
            return '';
        }
        my $issn = Business::ISSN->new( sprintf("%07uX", $value));
        $issn->fix_checksum;
        $self->value( $issn );
        return $self->value;
    } else {
        (my $v = $$self) =~ tr/-//d;
        return (length($v) == 8) ? int(substr($v, 0, 7)) : "";
    }
}

=head2 pretty

Returns the standard form of an ISSN with dash and captialized check digit 'X'.

=cut

sub pretty {
    my $self = shift;
    my $value = Business::ISSN->new($self->value) or return "";
    return $value->as_string();
}


1;

=head1 AUTHOR

Thomas Berger C<< <THB@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Jakob Voss C<< <jakob.voss@gbv.de> >> crafted L<SeeAlso::Identifier::ISBN> where
this one is heavily derived from.

=head1 COPYRIGHT

Copyright (c) 2010-2011 Thomas Berger.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), L<Business::ISSN>, L<SeeAlso::Identifer>.

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

