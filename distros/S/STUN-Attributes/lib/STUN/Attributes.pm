
package STUN::Attributes;

use strict;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(attr_message);
$VERSION='0.01';

my %attr_code = (
    '0001'  => 'MappedAddress',
    '0002'  => 'ResponseAddress',
    '0003'  => 'ChangeRequest',
    '0004'  => 'SourceAddress',
    '0005'  => 'ChangedAddress',
    '0006'  => 'Username',
    '0007'  => 'Password',
    '0008'  => 'MessageIntegrity',
    '0009'  => 'ErrorCode',
    '000A'  => 'UnknownAttribute',
    '000B'  => 'ReflectedFrom',
    '0021'  => 'XorOnly',
    '8020'  => 'XorMappedAddress',
    '8022'  => 'ServerName',
    '8050'  => 'SecondaryAddress',   # Non-standard extention.
);

my $mnemonicCode = '';
my ($code, $message);
while (($code, $message) = each %attr_code) {
    # create mnemonic subroutines
    $message =~ tr/a-z \-/A-Z__/;
    $mnemonicCode .= "sub STUN_$message () { \"$code\" }\n";
    $mnemonicCode .= "*RC_$message = \\&STUN_$message;\n";  # legacy
    $mnemonicCode .= "push(\@EXPORT_OK, 'STUN_$message');\n";
    $mnemonicCode .= "push(\@EXPORT, 'RC_$message');\n";
}
eval $mnemonicCode; # only one eval for speed
die if $@;


%EXPORT_TAGS = (
   constants => [grep /^STUN_/, @EXPORT_OK],
);

sub attr_message ($) { $attr_code{$_[0]} };

1;

__END__

=head1 NAME

STUN::Attributes - STUN Attributes types. (RFC 5389)

=head1 SYNPOSIS

    use STUN::Attributes qw(attr_message :constants);

    print attr_message('0001'), "\n";

    print STUN_MAPPEDADDRESS. "\n";

=head1 DESCRIPTION

I<STUN::Attributes> is a library of routines for defining and classifying STUN attributes types. 

A STUN Attribute type is a hex number in the range 0x0000 - 0xFFFF. STUN attribute types in the range 0x0000 - 0x7FFF are considered comprehension-required; STUN attribute types in the range 0x8000 - 0xFFFF are considered comprehension-optional.  A STUN agent handles unknown comprehension-required and comprehension-optional attributes differently.

=head1 CONSTANTS

The following constant functions can be used as mnemonic status code
names.  None of these are exported by default.  Use the C<:constants>
tag to import them all.

    STUN_MAPPEDADDRESS      (0001)
    STUN_RESPONSEADDRESS    (0002)
    STUN_CHANGEREQUEST      (0003)
    STUN_SOURCEADDRESS      (0004)
    STUN_CHANGEADDRESS      (0005)
    STUN_USERNAME           (0006)
    STUN_PASSWORD           (0007)
    STUN_MESSAGEINTEGRITY   (0008)
    STUN_ERRORCODE          (0009)
    STUN_UNKNOWNATTRIBUTE   (000A)
    STUN_REFLECTEDFROM      (000B)
    STUN_XORONLY            (0021)
    STUN_XORMAPPEDADDRESS   (8020)
    STUN_SERVERNAME         (8022)
    STUN_SECONDARYADDRESS   (8050)

=head1 FUNCTIONS

=over 4

=item attr_message( $code )

The attr_message() function will translate status codes to human
readable strings. The string is the same as found in the constant
names above.  If the $code is unknown, then C<undef> is returned.

=back

=head1 AUTHOR

Thiago Rondon, thiago@aware.com.br

http://www.aware.com.br/

=head1 LICENSE

Perl license.


