#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Tag::Reader::Perl;

# Object.
my $obj = Tag::Reader::Perl->new;

# Example data.
my $sgml = <<'END';
<DOKUMENT> 
  <adresa stát="cs">
    <město>
    <ulice>Nová</ulice>
    <číslo>5</číslo>
  </adresa>
</DOKUMENT>
END

# Set data to object.
$obj->set_text(decode_utf8($sgml));

# Tokenize.
while (my @tag = $obj->gettoken) {
        print "[\n";
        print "\t[0]: '".encode_utf8($tag[0])."'\n";
        print "\t[1]: ".encode_utf8($tag[1])."\n";
        print "\t[2]: $tag[2]\n";
        print "\t[3]: $tag[3]\n";
        print "]\n";
}

# Output:
# [
# 	[0]: '<DOKUMENT>'
# 	[1]: dokument
# 	[2]: 1
# 	[3]: 1
# ]
# [
# 	[0]: ' 
#   '
# 	[1]: data
# 	[2]: 1
# 	[3]: 11
# ]
# [
# 	[0]: '<adresa stát="cs">'
# 	[1]: adresa
# 	[2]: 2
# 	[3]: 3
# ]
# [
# 	[0]: '
#     '
# 	[1]: data
# 	[2]: 2
# 	[3]: 21
# ]
# [
# 	[0]: '<město>'
# 	[1]: město
# 	[2]: 3
# 	[3]: 5
# ]
# [
# 	[0]: '
#     '
# 	[1]: data
# 	[2]: 3
# 	[3]: 12
# ]
# [
# 	[0]: '<ulice>'
# 	[1]: ulice
# 	[2]: 4
# 	[3]: 5
# ]
# [
# 	[0]: 'Nová'
# 	[1]: data
# 	[2]: 4
# 	[3]: 12
# ]
# [
# 	[0]: '</ulice>'
# 	[1]: /ulice
# 	[2]: 4
# 	[3]: 16
# ]
# [
# 	[0]: '
#     '
# 	[1]: data
# 	[2]: 4
# 	[3]: 24
# ]
# [
# 	[0]: '<číslo>'
# 	[1]: číslo
# 	[2]: 5
# 	[3]: 5
# ]
# [
# 	[0]: '5'
# 	[1]: data
# 	[2]: 5
# 	[3]: 12
# ]
# [
# 	[0]: '</číslo>'
# 	[1]: /číslo
# 	[2]: 5
# 	[3]: 13
# ]
# [
# 	[0]: '
#   '
# 	[1]: data
# 	[2]: 5
# 	[3]: 21
# ]
# [
# 	[0]: '</adresa>'
# 	[1]: /adresa
# 	[2]: 6
# 	[3]: 3
# ]
# [
# 	[0]: '
# '
# 	[1]: data
# 	[2]: 6
# 	[3]: 12
# ]
# [
# 	[0]: '</DOKUMENT>'
# 	[1]: /dokument
# 	[2]: 7
# 	[3]: 1
# ]
# [
# 	[0]: '
# '
# 	[1]: data
# 	[2]: 7
# 	[3]: 12
# ]