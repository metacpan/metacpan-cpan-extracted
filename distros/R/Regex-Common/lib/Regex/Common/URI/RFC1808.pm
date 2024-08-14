package Regex::Common::URI::RFC1808;
use strict;
use warnings;

our $VERSION = 'v1.0.0'; # VERSION

use vars qw /@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA/;

use Exporter ();
@ISA = qw /Exporter/;

my %vars;

BEGIN {
    $vars{low} = [
        qw /$punctuation $reserved_range $reserved $national
          $extra $safe $digit $digits $hialpha $lowalpha
          $alpha $alphadigit $hex $escape $unreserved_range
          $unreserved $uchar $uchars $pchar_range $pchar
          $pchars/
      ],

      $vars{parts} = [
        qw /$fragment $query $param $params $segment
          $fsegment $path $net_loc $scheme $rel_path
          $abs_path $net_path $relativeURL $generic_RL
          $absoluteURL $URL/
      ],
      ;
}

use vars map { @$_ } values %vars;

@EXPORT      = qw /$host/;
@EXPORT_OK   = map { @$_ } values %vars;
%EXPORT_TAGS = ( %vars, ALL => [@EXPORT_OK] );

# RFC 1808, base definitions.

# Lowlevel definitions.
$punctuation    = '[<>#%"]';
$reserved_range = q [;/?:@&=];
$reserved       = "[$reserved_range]";
$national       = '[][{}|\\^~`]';
$extra          = "[!*'(),]";
$safe           = '[-$_.+]';

$digit      = '[0-9]';
$digits     = '[0-9]+';
$hialpha    = '[A-Z]';
$lowalpha   = '[a-z]';
$alpha      = '[a-zA-Z]';       # lowalpha | hialpha
$alphadigit = '[a-zA-Z0-9]';    # alpha    | digit

$hex    = '[a-fA-F0-9]';
$escape = "(?:%$hex$hex)";

$unreserved_range = q [-a-zA-Z0-9$_.+!*'(),];        # alphadigit | safe | extra
$unreserved       = "[$unreserved_range]";
$uchar            = "(?:$unreserved|$escape)";
$uchars           = "(?:(?:$unreserved+|$escape)*)";

$pchar_range = qq [$unreserved_range:\@&=];
$pchar       = "(?:[$pchar_range]|$escape)";
$pchars      = "(?:(?:[$pchar_range]+|$escape)*)";

# Parts
$fragment = "(?:(?:[$unreserved_range$reserved_range]+|$escape)*)";
$query    = "(?:(?:[$unreserved_range$reserved_range]+|$escape)*)";

$param  = "(?:(?:[$pchar_range/]+|$escape)*)";
$params = "(?:$param(?:;$param)*)";

$segment  = "(?:(?:[$pchar_range]+|$escape)*)";
$fsegment = "(?:(?:[$pchar_range]+|$escape)+)";
$path     = "(?:$fsegment(?:/$segment)*)";

$net_loc = "(?:(?:[$pchar_range;?]+|$escape)*)";
$scheme  = "(?:(?:[-a-zA-Z0-9+.]+|$escape)+)";

$rel_path = "(?:$path?(?:;$params)?(?:?$query)?)";
$abs_path = "(?:/$rel_path)";
$net_path = "(?://$net_loc$abs_path?)";

$relativeURL = "(?:$net_path|$abs_path|$rel_path)";
$generic_RL  = "(?:$scheme:$relativeURL)";
$absoluteURL = "(?:$generic_RL|"
  . "(?:$scheme:(?:[$unreserved_range$reserved_range]+|$escape)*))";
$URL = "(?:(?:$absoluteURL|$relativeURL)(?:#$fragment)?)";

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::RFC1808 -- Definitions from RFC1808;

=head1 SYNOPSIS

    use Regex::Common::URI::RFC1808 qw /:ALL/;

=head1 DESCRIPTION

This package exports definitions from RFC1808. It's intended
usage is for Regex::Common::URI submodules only. Its interface
might change without notice.

=head1 REFERENCES

=over 4

=item B<[RFC 1808]>

Fielding, R.: I<Relative Uniform Resource Locators (URL)>. June 1995.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 LICENSE and COPYRIGHT

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
glasswalk3r at yahoo.com.br

This file is part of regex-common project.

regex-commonis free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

regex-common is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
regex-common. If not, see (http://www.gnu.org/licenses/).

The original project [Regex::Common](https://metacpan.org/pod/Regex::Common)
is licensed through the MIT License, copyright (c) Damian Conway
(damian@cs.monash.edu.au) and Abigail (regexp-common@abigail.be).

=cut
