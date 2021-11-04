#+##############################################################################
#                                                                              #
# File: No/Worries/DN.pm                                                       #
#                                                                              #
# Description: Distinguished Names handling without worries                    #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::DN;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate_pos :types);

#
# constants
#

use constant FORMAT_RFC2253 => "rfc2253";
use constant FORMAT_JAVA    => "java";
use constant FORMAT_OPENSSL => "openssl";

#
# global variables
#

our(
    %_Map,        # map of known attribute types
    $_TypeRE,     # regexp for a valid attribute type
    $_ValueRE,    # regexp for a valid attribute value
);

foreach my $type (qw(Email emailAddress EMAILADDRESS)) {
    $_Map{$type} = $type;
}

foreach my $type (qw(C CN DC L O OU ST)) {
    $_Map{$type} = $_Map{lc($type)} = $type;
}

$_TypeRE = join("|", keys(%_Map));

$_ValueRE = "[" .
    "0-9a-zA-Z" .   # alphanumerical
    "\\x20" .       # space
    "\\x27" .       # quote
    "\\x28" .       # left parenthesis
    "\\x29" .       # right parenthesis
    "\\x2d" .       # dash
    "\\x2e" .       # dot
    "\\x2f" .       # slash
    "\\x3a" .       # colon
    "\\x40" .       # at sign
    "\\x5f" .       # underscore
    "\\xa0-\\xff" . # some high-bit characters that may come from ISO-8859-1
"]+";

#
# parse a string containing a DN and return an array reference
#

sub dn_parse ($) {
    my($string) = @_;
    my($sep, @list, @dn);

    validate_pos(@_, { type => SCALAR });
    if ($string =~ m/^(\/[a-z]+=[^=]*){3,}$/i) {
        $sep = "/";
    } elsif ($string =~ m/^[a-z]+=[^=]*(,[a-z]+=[^=]*){2,}$/i) {
        $sep = ",";
    } elsif ($string =~ m/^[a-z]+=[^=]*(, [a-z]+=[^=]*){2,}$/i) {
        $sep = ", ";
    } else {
        dief("unexpected DN: %s", $string);
    }
    @list = split(/$sep/, $string);
    shift(@list) if $sep eq "/";
    @dn = ();
    foreach my $attr (@list) {
        if ($attr =~ /^($_TypeRE)=($_ValueRE)$/) {
            # type=value
            push(@dn, "$_Map{$1}=$2");
        } elsif (@dn and $attr =~ /^($_ValueRE)$/) {
            # value only, assumed to come from previous attribute
            $dn[-1] .= $sep . $attr;
        } else {
            dief("invalid DN: %s", $string);
        }
    }
    @dn = reverse(@dn) if $sep eq "/";
    return(\@dn);
}

#
# convert the given parsed DN into a string
#

sub dn_string ($$) {
    my($dn, $format) = @_;

    validate_pos(@_, { type => ARRAYREF }, { type => SCALAR });
    return(join(",", @{ $dn })) if $format eq FORMAT_RFC2253;
    return(join(", ", @{ $dn })) if $format eq FORMAT_JAVA;
    return(join("/", "", reverse(@{ $dn }))) if $format eq FORMAT_OPENSSL;
    dief("unsupported DN format: %s", $format);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, map("dn_$_", qw(parse string)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::DN - Distinguished Names handling without worries

=head1 SYNOPSIS

  use No::Worries::DN qw(dn_parse dn_string);

  $dn = dn_parse("/C=US/O=Acme Corporation/CN=John Doe");
  $string = dn_string($dn, No::Worries::DN::FORMAT_JAVA);

=head1 DESCRIPTION

This module eases Distinguished Names (DNs) handling by providing
convenient functions to parse and convert DNs from and to different
formats. All the functions die() on error.

=head1 FUNCTIONS

This module provides the following functions (none of them being
exported by default):

=over

=item dn_parse(STRING)

parse a string containing DN information and return an array reference

=item dn_string(DN, FORMAT)

convert the given parsed DN (an array reference) into a string of the
given format, this is somehow the opposite of dn_parse()

=back

=head1 FORMATS

Here are the supported formats:

=over

=item No::Worries::DN::FORMAT_RFC2253

this is the format defined by RFC 2253, for instance:
C<CN=John Doe,O=Acme Corporation,C=US>

=item No::Worries::DN::FORMAT_JAVA

this is a variant of RFC 2253, with extra spaces, for instance:
C<CN=John Doe, O=Acme Corporation, C=US>

=item No::Worries::DN::FORMAT_OPENSSL

this is the default format used by OpenSSL, for instance:
C</C=US/O=Acme Corporation/CN=John Doe>

=back

=head1 SEE ALSO

L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
