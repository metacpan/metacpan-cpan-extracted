package Regex::Common::URI::RFC1738;
use strict;
use warnings;
use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

use vars qw /@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA/;

use Exporter ();
@ISA = qw /Exporter/;

my %vars;

BEGIN {
    $vars{low} = [
        qw /$digit $digits $hialpha $lowalpha $alpha $alphadigit
          $safe $extra $national $punctuation $unreserved
          $unreserved_range $reserved $uchar $uchars $xchar
          $xchars $hex $escape/
    ];

    $vars{connect} = [
        qw /$port $hostnumber $toplabel $domainlabel $hostname
          $host $hostport $user $password $login/
    ];

    $vars{parts} = [
        qw /$fsegment $fpath $group $article $grouppart
          $search $database $wtype $wpath $psegment
          $fieldname $fieldvalue $fieldspec $ppath/
    ];
}

use vars map { @$_ } values %vars;

@EXPORT      = qw /$host/;
@EXPORT_OK   = map { @$_ } values %vars;
%EXPORT_TAGS = ( %vars, ALL => [@EXPORT_OK] );

# RFC 1738, base definitions.

# Lowlevel definitions.
$digit            = '[0-9]';
$digits           = '[0-9]+';
$hialpha          = '[A-Z]';
$lowalpha         = '[a-z]';
$alpha            = '[a-zA-Z]';                      # lowalpha | hialpha
$alphadigit       = '[a-zA-Z0-9]';                   # alpha    | digit
$safe             = '[-$_.+]';
$extra            = "[!*'(),]";
$national         = '[][{}|\\^~`]';
$punctuation      = '[<>#%"]';
$unreserved_range = q [-a-zA-Z0-9$_.+!*'(),];        # alphadigit | safe | extra
$unreserved       = "[$unreserved_range]";
$reserved         = '[;/?:@&=]';
$hex              = '[a-fA-F0-9]';
$escape           = "(?:%$hex$hex)";
$uchar            = "(?:$unreserved|$escape)";
$uchars           = "(?:(?:$unreserved|$escape)*)";
$xchar            = "(?:[$unreserved_range;/?:\@&=]|$escape)";
$xchars           = "(?:(?:[$unreserved_range;/?:\@&=]|$escape)*)";

# Connection related stuff.
$port        = "(?:$digits)";
$hostnumber  = "(?:$digits\[.]$digits\[.]$digits\[.]$digits)";
$toplabel    = "(?:$alpha\[-a-zA-Z0-9]*$alphadigit|$alpha)";
$domainlabel = "(?:(?:$alphadigit\[-a-zA-Z0-9]*)?$alphadigit)";
$hostname    = "(?:(?:$domainlabel\[.])*$toplabel)";
$host        = "(?:$hostname|$hostnumber)";
$hostport    = "(?:$host(?::$port)?)";

$user     = "(?:(?:[$unreserved_range;?&=]|$escape)*)";
$password = "(?:(?:[$unreserved_range;?&=]|$escape)*)";
$login    = "(?:(?:$user(?::$password)?\@)?$hostport)";

# Parts (might require more if we add more URIs).

# FTP/file
$fsegment = "(?:(?:[$unreserved_range:\@&=]|$escape)*)";
$fpath    = "(?:$fsegment(?:/$fsegment)*)";

# NNTP/news.
$group     = "(?:$alpha\[-A-Za-z0-9.+_]*)";
$article   = "(?:(?:[$unreserved_range;/?:&=]|$escape)+" . '@' . "$host)";
$grouppart = "(?:[*]|$article|$group)";    # It's important that
                                           # $article goes before
                                           # $group.

# WAIS.
$search   = "(?:(?:[$unreserved_range;:\@&=]|$escape)*)";
$database = $uchars;
$wtype    = $uchars;
$wpath    = $uchars;

# prospero
$psegment   = "(?:(?:[$unreserved_range?:\@&=]|$escape)*)";
$fieldname  = "(?:(?:[$unreserved_range?:\@&]|$escape)*)";
$fieldvalue = "(?:(?:[$unreserved_range?:\@&]|$escape)*)";
$fieldspec  = "(?:;$fieldname=$fieldvalue)";
$ppath      = "(?:$psegment(?:/$psegment)*)";

# The various '(?:(?:[$unreserved_range ...]|$escape)*)' above need
# some loop unrolling to speed up the match.
1;

__END__

=pod

=head1 NAME

Regex::Common::URI::RFC1738 -- Definitions from RFC1738;

=head1 SYNOPSIS

    use Regex::Common::URI::RFC1738 qw /:ALL/;

=head1 DESCRIPTION

This package exports definitions from RFC1738. It's intended
usage is for Regex::Common::URI submodules only. Its interface
might change without notice.

=head1 REFERENCES

=over 4

=item B<[RFC 1738]>

Berners-Lee, Tim, Masinter, L., McCahill, M.: I<Uniform Resource
Locators (URL)>. December 1994.

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
