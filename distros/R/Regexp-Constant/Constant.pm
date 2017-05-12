
package Regexp::Constant;

# $Id: Constant.pm,v 1.22 2004/10/25 16:34:35 root Exp $

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.22';

# FOR INTERNAL USE ONLY
use constant REGEX_DEL1 => q{\b(};
use constant REGEX_DEL2 => q{)\b};

# NUMERIC
use constant REGEX_SIGNED => q{\b(\-\+])\b};
use constant REGEX_BINARY => q{\b([01]+)\b};
use constant REGEX_DECIMAL => q{\b(\d+)\b};
use constant REGEX_FLOAT => q{\b(\d*\.\d+)\b};
use constant REGEX_HEX => q{\b([\da-fA-F]+)\b};
use constant REGEX_OCTAL => q{\b([0-7]+)\b};
use constant REGEX_OCTET => q{\b([0-9a-zA-Z]{2})\b};

use constant REGEX_COMMA_DELIMITED_NUMBER => q{\b([0-9])+([,]([0-9])+)*\b};

# MYSQL DATA TYPES
use constant REGEX_TINYINT => q{\b[012](\d1,2)\b};
use constant REGEX_TINYINT_SIGNED => REGEX_SIGNED . q{\b[01](\d1,2)\b};
use constant REGEX_SMALLINT => q{\b[0-6](\d1,4)\b};
use constant REGEX_SMALLINT_SIGNED => REGEX_SIGNED . q{\b[0-3](\d1,4)\b};
use constant REGEX_MEDIUMINT => q{\b[01](\d1,7)\b};
use constant REGEX_MEDIUMINT_SIGNED => REGEX_SIGNED . q{\b[0-8](\d1,6)\b};
use constant REGEX_INT => q{\b[0-4](\d1,9)\b};
use constant REGEX_INT_SIGNED => REGEX_SIGNED . q{\b[0-2](\d1,9)\b};
use constant REGEX_BIGINT => q{\b[01](\d1,19)\b};
use constant REGEX_BIGINT_SIGNED => REGEX_SIGNED . q{\b[0-9](\d1,18)\b};


# signed, exponents 1e4, percent, fraction "1 1/2"

# currency


# IP
use constant REGEX_MAC_ADDRESS => join (":", REGEX_OCTET, REGEX_OCTET, REGEX_OCTET, REGEX_OCTET, REGEX_OCTET, REGEX_OCTET);

use constant REGEX_IP_CLASS_A => q{\b([01]?\d?\d|2[0-4]\d|25[0-5])\b};
use constant REGEX_IP_CLASS_B => q{\b(} . join (".", REGEX_IP_CLASS_A, REGEX_IP_CLASS_A) . REGEX_DEL2;
use constant REGEX_IP_CLASS_C => q{\b(} . join (".", REGEX_IP_CLASS_B, REGEX_IP_CLASS_A) . REGEX_DEL2;
use constant REGEX_IP_ADDRESS => q{\b(} . join (".", REGEX_IP_CLASS_C, REGEX_IP_CLASS_A) . REGEX_DEL2;

use constant REGEX_DOMAIN_NAME => qw{\b(([\w\-]+)+\.\w+)\b};
use constant REGEX_EMAIL_ADDRESS => q{([\w\-]+)\@} . REGEX_DOMAIN_NAME;

# TIME
use constant REGEX_HOUR => q{\b([ 01]\d|2[0-3])\b};
use constant REGEX_MINUTE => q{\b([0-5]\d)\b};
use constant REGEX_SECOND => q{\b([0-5]\d)\b};
use constant REGEX_TIME => q{\b(} . join(":", REGEX_HOUR, REGEX_MINUTE, REGEX_SECOND) . REGEX_DEL2;

use constant REGEX_GMT_OFFSET => q{([\+\-]\d{4})};

# TIMEZONE
use constant REGEX_TIMEZONE => q{\b([A-Z]{3})\b};

# DAY
use constant REGEX_DAY => q{(\d{1,2})};
use constant REGEX_WEEKDAY_ABBREVIATED => q{\b(Sun|Mon|Tue|Wed|Thu|Fri|Sat)\b};
use constant REGEX_WEEKDAY_NAME => q{\b(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)\b};
use constant REGEX_WEEKDAY => q{\b(} . join ("|", REGEX_WEEKDAY_ABBREVIATED, REGEX_WEEKDAY_NAME) . REGEX_DEL2;

# MONTH
use constant REGEX_MONTH_NUMERIC => q{\b(\d|[ 0]\d|[1][012])\b};
use constant REGEX_MONTH_NAME_ABBREVIATED => q{\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b};
use constant REGEX_MONTH_NAME => q{\b(January|February|March|April|May|June|July|August|September|October|November|December)\b};
use constant REGEX_MONTH => q{\b(} . join("|", REGEX_MONTH_NUMERIC, REGEX_MONTH_NAME_ABBREVIATED, REGEX_MONTH_NAME) . REGEX_DEL2;

# DATE
use constant REGEX_YEAR => q{\b(\d{2}|\d{4})\b};
use constant REGEX_CLF_DATE => join("[\/-]", REGEX_DAY, REGEX_MONTH, REGEX_YEAR);
use constant REGEX_MYSQL_DATE => join ("-", REGEX_YEAR, REGEX_MONTH_NUMERIC, REGEX_DAY);

# DATE TIME
use constant REGEX_CLF_DATETIME => REGEX_DEL1 . REGEX_CLF_DATE . ":" . REGEX_TIME . REGEX_DEL2;
use constant REGEX_MYSQL_DATETIME => REGEX_DEL1 . REGEX_MYSQL_DATE . " " . REGEX_TIME . REGEX_DEL2;
use constant REGEX_SHELL_DATE => REGEX_DEL1 . join (q{\s}, REGEX_WEEKDAY, REGEX_MONTH, REGEX_DAY, REGEX_TIME, REGEX_TIMEZONE, REGEX_YEAR) . REGEX_DEL2;



use constant REGEX_ROMAN_NUMERAL => q{\b(?i:M{0,3}((C[DM])|(D?C{0,3}))?L?(X((X{1,2})|L|C)?)?((I((I{1,2})|V|X|L)?)|(V?I{0,3}))?)\b};



# PHONE
# TODO: "(303) 622-2173", "1-800-CALL-FIG"
use constant REGEX_AREA_CODE => q{((\(\d{3}\))|(\d{3}))};
use constant REGEX_PHONE_EXCHANGE => q{(\d{3})};
use constant REGEX_PHONE_EXTENSION => q{(\d{4})};
use constant REGEX_PHONE => REGEX_DEL1 . join(q{[ \-\.]?}, REGEX_AREA_CODE, REGEX_PHONE_EXCHANGE, REGEX_PHONE_EXTENSION) . REGEX_DEL2;

# HTML
use constant REGEX_HTML_SIMPLE => q{\b(<[^>]+>)\b};

use constant REGEX_REQUEST_METHOD => q{(\S+)};

use constant REGEX_REQUEST_OBJECT => q{([^ ]+)};
use constant REGEX_URI => q{};

use constant REGEX_PROTOCOL => q{(\w+\/[\d\.]+)};
use constant REGEX_RESPONSE_CODE => q{(\d+|\-)};
use constant REGEX_CONTENT_LENGTH => q{(\d+|\-)};
use constant REGEX_HTTP_REFERER => q{([^"]+)};
use constant REGEX_HTTP_USER_AGENT => q{([^"]+)};
use constant REGEX_COOKIE => q{([^"]+)};

use constant REGEX_STATE => q{\b(Alabama|Alaska|American Samoa|Arizona|Arkansas|California|Colorado|Connecticut|Delaware|District of Columbia|Federated States of Micronesia|Florida|Georgia|Guam|Hawaii|Idaho|Illinois|Indiana|Iowa|Kansas|Kentucky|Louisiana|Maine|Marshall Islands|Maryland|Massachusetts|Michigan|Minnesota|Mississippi|Missouri|Montana|Nebraska|Nevada|New Hampshire|New Jersey|New Mexico|New York|North Carolina|North Dakota|Northern Mariana Islands|Ohio|Oklahoma|Oregon|palau|Pennsylvania|Puerto Rico|Rhode Island|South Carolina|South Dakota|Tennessee|Texas|Utah|Vermont|Virgin Islands|Virginia|Washington|West Virginia|Wisconsin|Wyoming)\b};
use constant REGEX_STATE_ABBREVIATION => q{\b(A[AELKPSZR]|C[AOT]|D[EC]|F[NL]|G[AU]|HI|I[DLNA]|K[SY]|LA|M[EHDAINSOT]|N[EVHJMYCD]|MP|O[HKR]|P[WR]|RI|S[CD]|T[NX]|UT|V[TIA]|W[AVIY])\b};

use constant REGEX_ZIP_CODE => q{\b(\d{5})\b};
use constant REGEX_ZIP_CODE_PLUS_FOUR => REGEX_ZIP_CODE . q{\-\b(\d{4})\b};

use constant REGEX_REPEATED_WORD => q{\b(\w+)\s+\1\b};

use constant REGEX_WINDOWS_FILENAME => q{(([a-zA-Z]:)|(\\{2}\w+)\$?)(\\(\w[\w ]*))+\.([0-9a-zA-Z]+)};

# WORD / TEXT
use constant REGEX_NUMBER => q{\b(\d+)\b};
use constant REGEX_WORD_UNCAPITALIZED => q{\b([a-z]+)\b};
use constant REGEX_WORD_CAPITALIZED => q{\b([A-Z][a-z]*)\b};

# NAME [T.F. Johnson], [John O'Neil], [Mary-Kate Johnson] 

use constant REGEX_MD5 => q{\b([a-z][0-9]{32})\b};
use constant REGEX_GUID => q{\b([0-9a-fA-F]{8}[-]?([0-9a-fA-F]{4}[-]?){3}[0-9a-fA-F]{12})\b};

use constant REGEX_ISBN => q{\b((ISBN *)?\d[ \-]?\d{5}[ \-]?\d{3}[ \-]?[\dxX])\b};
use constant REGEX_SSN => q{\b(\d{3}[ \-]?\d{2}[ \-]?\d{4})\b};

# CREDIT CARD
use constant REGEX_VISA => REGEX_DEL1 . join ("([ \-]|)", q{4\d{3}}, q{\d{4}}, q{\d{4}}, q{\d{4}}) . REGEX_DEL2;
use constant REGEX_MASTERCARD => REGEX_DEL1 . join ("([ \-]|)", q{5\d{3}}, q{\d{4}}, q{\d{4}}, q{\d{4}}) . REGEX_DEL2;
use constant REGEX_DISCOVER => REGEX_DEL1 . join ("([ \-]|)", "6011", q{\d{4}}, q{\d{4}}, q{\d{4}}) . REGEX_DEL2;
use constant REGEX_DINERS_CLUB => REGEX_DEL1 . join ("([ \-]|)", q{(3[68]\d{2}|30[0-5]\d)}, q{\d{4}}, q{\d{4}}, q{\d{4}}) . REGEX_DEL2;
use constant REGEX_AMERICAN_EXPRESS => q{\b(3[47]\d{13})\b};

use constant REGEX_CREDIT_CARD => REGEX_DEL1 . join ("|", REGEX_VISA, REGEX_MASTERCARD, REGEX_DISCOVER, REGEX_DINERS_CLUB, REGEX_AMERICAN_EXPRESS) . REGEX_DEL2;
use constant REGEX_CREDIT_CARD_EXPIRATION => REGEX_DEL1 . join("[ \-\/]", REGEX_MONTH_NUMERIC, REGEX_YEAR) . REGEX_DEL2;
use constant REGEX_CREDIT_CARD_VALIDATION => q{\b(\d{3})\b};

# comma delimited list , ,"", etc ,(?!(?<=(?:^|,)\s*"(?:[^"]|""|\\")*,)(?:[^"]|""|\\")*"\s*(?:,|$))


1;
__END__

=head1 SYNOPSIS

  The following example shows how a complicated string, such as the date / time string from the unix "date" command, can be matched against a regular expression defined as a constant. The original regular expression is 5 lines long.

  use Regexp::Constant;

  my $date = "Mon Oct 25 11:59:13 EDT 2004";
  print $1 if $date =~ /@{[REGEX_SHELL_DATE]}/;
  exit();

=head1 ABSTRACT

  WARNING - BETA SOFTWARE - NOT ALL REGEX'S HAVE BEEN TESTED

  A module for defining commonly used regular expressions as constants. 


=head1 DESCRIPTION

=head2 Numeric regular expressions

 REGEX_SIGNED
 REGEX_BINARY
 REGEX_DECIMAL
 REGEX_FLOAT
 REGEX_HEX
 REGEX_OCTAL
 REGEX_OCTET

 REGEX_COMMA_DELIMITED_NUMBER

=head2 MYSQL data types

 REGEX_TINYINT
 REGEX_TINYINT_SIGNED
 REGEX_SMALLINT
 REGEX_SMALLINT_SIGNED
 REGEX_MEDIUMINT
 REGEX_MEDIUMINT_SIGNED
 REGEX_INT
 REGEX_INT_SIGNED
 REGEX_BIGINT
 REGEX_BIGINT_SIGNED

=head2 IP & host matching

 REGEX_MAC_ADDRESS
 REGEX_IP_CLASS_A
 REGEX_IP_CLASS_B
 REGEX_IP_CLASS_C
 REGEX_IP_ADDRESS
 REGEX_DOMAIN_NAME
 REGEX_EMAIL_ADDRESS

=head2 Time

 REGEX_HOUR
 REGEX_MINUTE
 REGEX_SECOND
 REGEX_TIME
 REGEX_GMT_OFFSET
 REGEX_TIMEZONE

=head2 Date

 REGEX_DAY
 REGEX_WEEKDAY_ABBREVIATED
 REGEX_WEEKDAY_NAME
 REGEX_WEEKDAY
 REGEX_MONTH_NUMERIC
 REGEX_MONTH_NAME_ABBREVIATED
 REGEX_MONTH_NAME
 REGEX_MONTH
 REGEX_YEAR
 REGEX_ROMAN_NUMERAL

=head2 DateTime

 REGEX_CLF_DATE
 REGEX_MYSQL_DATE
 REGEX_CLF_DATETIME
 REGEX_MYSQL_DATETIME
 REGEX_SHELL_DATE

=head2 Telephone (US)

 REGEX_AREA_CODE
 REGEX_PHONE_EXCHANGE
 REGEX_PHONE_EXTENSION
 REGEX_PHONE

=head2 HTML

 REGEX_HTML_SIMPLE

=head2 URI & web server log

 REGEX_REQUEST_METHOD
 REGEX_REQUEST_OBJECT
 REGEX_URI
 REGEX_PROTOCOL
 REGEX_RESPONSE_CODE
 REGEX_CONTENT_LENGTH
 REGEX_HTTP_REFERER
 REGEX_HTTP_USER_AGENT
 REGEX_COOKIE

=head2 Region (US)

 REGEX_STATE
 REGEX_STATE_ABBREVIATION
 REGEX_ZIP_CODE
 REGEX_ZIP_CODE_PLUS_FOUR

=head2 Miscellaneous

 REGEX_REPEATED_WORD
 REGEX_WINDOWS_FILENAME
 REGEX_NUMBER
 REGEX_WORD_UNCAPITALIZED
 REGEX_WORD_CAPITALIZED

=head2 ID

 REGEX_MD5
 REGEX_GUID
 REGEX_ISBN
 REGEX_SSN

=head2 Credit Card

 REGEX_VISA
 REGEX_MASTERCARD
 REGEX_DISCOVER
 REGEX_DINERS_CLUB
 REGEX_AMERICAN_EXPRESS
 REGEX_CREDIT_CARD
 REGEX_CREDIT_CARD_EXPIRATION
 REGEX_CREDIT_CARD_VALIDATION

=head2 EXPORT

None by default.



=head1 PREREQUISITES

None.

=head1 BUGS

Some values are not defined, or use basic matching (HTML, Cookie, etc).

Telephone does not properly match paranthesis around area code.

Many REGEX untested or partially tested.

=head1 AUTHOR

David Tiberio, E<lt>dtiberio5@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 David Tiberio, dtiberio5@hotmail.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

