package SJIS2004::R2;
######################################################################
#
# SJIS2004::R2 - provides minimal SJIS2004 I/O subroutines by short name
#
# http://search.cpan.org/dist/SJIS2004-R2/
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Galapagos Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.05';
$VERSION = $VERSION;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use UTF8::R2;
use IOas::SJIS2004;

sub import {
    no strict qw(refs);
    tie my %mb, 'UTF8::R2';
    *{caller().'::mb'}     = \%mb;
    *{caller().'::mbeach'} = sub { UTF8::R2::split(qr//,$_[0]) };
    *{caller().'::mbtr'  } = \&UTF8::R2::tr;
    *{caller().'::iolen' } = \&IOas::SJIS2004::length;
    *{caller().'::iomid' } = \&IOas::SJIS2004::substr;
    *{caller().'::ioget' } = \&IOas::SJIS2004::readline;
    *{caller().'::ioput' } = \&IOas::SJIS2004::print;
    *{caller().'::ioputf'} = \&IOas::SJIS2004::printf;
    *{caller().'::iosort'} = \&IOas::SJIS2004::sort;
}

1;

__END__

=pod

=head1 NAME

SJIS2004::R2 - provides minimal SJIS2004 I/O subroutines by short name

=head1 SYNOPSIS

  use SJIS2004::R2;

    @result = mbeach($utf8str)
    $result = mbtr($utf8str, 'ABC', 'XYZ', 'cdsr')
    $result = iolen($utf8str)
    $result = iomid($utf8expr, $offset_as_sjis2004, $length_as_sjis2004, $utf8replacement)
    @result = ioget(FILEHANDLE)
    $result = ioput(FILEHANDLE, @utf8str)
    $result = ioputf(FILEHANDLE, $utf8format, @utf8list)
    @result = iosort(@utf8str)

    $result = $utf8str =~ $mb{qr/$utf8regex/imsxogc}
    $result = $utf8str =~ s<$mb{qr/before/imsxo}><after>egr

=head1 MBCS SUBROUTINES for SCRIPTING

It is useful to treat regex in perl script as code point of UTF-8.
Following subroutines and tied hash variable provide UTF-8 semantics for us.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Acts as SBCS             Acts as MBCS
  Octet in Script          Octet in Script                             Note and Limitations
  ------------------------------------------------------------------------------------------------------------------------------------------
  // or m// or qr//        $mb{qr/$utf8regex/imsxogc}                  not supports metasymbol \X that match grapheme
                                                                       not support range of codepoint(like an "[A-Z]")
                                                                       not supports POSIX character class (like an [:alpha:])
                                                                       (such as \N{GREEK SMALL LETTER EPSILON}, \N{greek:epsilon}, or \N{epsilon})
                                                                       not supports character properties (like \p{PROP} and \P{PROP})

                           Special Escapes in Regex                    Support Perl Version
                           --------------------------------------------------------------------------------------------------
                           $mb{qr/ \x{Unicode} /}                      since perl 5.006
                           $mb{qr/ [^ ... ] /}                         since perl 5.008  ** CAUTION ** perl 5.006 cannot this
                           $mb{qr/ \h /}                               since perl 5.010
                           $mb{qr/ \v /}                               since perl 5.010
                           $mb{qr/ \H /}                               since perl 5.010
                           $mb{qr/ \V /}                               since perl 5.010
                           $mb{qr/ \R /}                               since perl 5.010
                           $mb{qr/ \N /}                               since perl 5.012

  ------------------------------------------------------------------------------------------------------------------------------------------
  s/before/after/imsxoegr  s<$mb{qr/before/imsxo}><after>egr
  ------------------------------------------------------------------------------------------------------------------------------------------
  split(//,$_)             mbeach($utf8str)                            split $utf8str into each characters
  ------------------------------------------------------------------------------------------------------------------------------------------
  tr/// or y///            mbtr($utf8str, 'ABC', 'XYZ', 'cdsr')        not support range of codepoint(like a "tr/A-Z/a-z/")
  ------------------------------------------------------------------------------------------------------------------------------------------

=head1 MBCS SUBROUTINES for I/O

If you use following subroutines then I/O encoding convert is automatically.
These subroutines provide SJIS2004 octets semantics for you.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Acts as SBCS             Acts as MBCS
  Octet in Script          Octet of I/O Encoding                       Note and Limitations
  ------------------------------------------------------------------------------------------------------------------------------------------
  <FILEHANDLE>             ioget(FILEHANDLE)                           get UTF-8 codepoint octets from SJIS2004 file
  ------------------------------------------------------------------------------------------------------------------------------------------
  length                   iolen($utf8str)                             octet count of UTF-8 string as SJIS2004 encoding
  ------------------------------------------------------------------------------------------------------------------------------------------
  print                    ioput(FILEHANDLE, @utf8str)                 print @utf8str as SJIS2004 encoding
  ------------------------------------------------------------------------------------------------------------------------------------------
  printf                   ioputf(FILEHANDLE, $utf8format, @utf8list)  printf @utf8str as SJIS2004 encoding
  ------------------------------------------------------------------------------------------------------------------------------------------
  sort                     iosort(@utf8str)                            sort @utf8str as SJIS2004 encoding
  ------------------------------------------------------------------------------------------------------------------------------------------
  sprintf                  (nothing)                                   "iosputf" is bad interface because it makes confuse by bringing
                                                                       both internal code and external code into your script
  ------------------------------------------------------------------------------------------------------------------------------------------
  substr                   iomid($utf8expr, $offset_as_sjis2004, $length_as_sjis2004, $utf8replacement)
                                                                       substr $utf8expr as SJIS2004 octets
  ------------------------------------------------------------------------------------------------------------------------------------------

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
