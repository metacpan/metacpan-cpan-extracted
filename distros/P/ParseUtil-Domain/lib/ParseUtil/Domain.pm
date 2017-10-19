package ParseUtil::Domain;
$ParseUtil::Domain::VERSION = '2.427';
# VERSION

require Exporter;
our @ISA = qw(Exporter);

use Modern::Perl;
use Carp;
use autobox;
use autobox::Core;
use List::MoreUtils qw/any/;
use Net::IDN::Encode ':all';
use Net::IDN::Punycode ':all';
use Net::IDN::Nameprep;
#use Smart::Comments;

use ParseUtil::Domain::ConfigData;
our @EXPORT = qw(parse_domain puny_convert);
our %EXPORT_TAGS = (parse => [qw/parse_domain/], simple => [qw/puny_convert/]);

sub parse_domain  {
    my $name = shift;
    ### testing : $name
    my @name_segments = $name->split(qr{\Q@\E});
    ### namesegments : \@name_segments

    my @segments = $name_segments[-1]->split(qr/[\.\x{FF0E}\x{3002}\x{FF61}]/);
    ### executing with : $name
    my ( $zone, $zone_ace, $domain_segments ) =
      _find_zone( \@segments )->slice(qw/zone zone_ace domain/);

    ### found zone : $zone
    ### found zone_ace : $zone_ace

    my $puny_processed = _punycode_segments( $domain_segments, $zone );
    my ( $domain_name, $name_ace ) = $puny_processed->slice(qw/name name_ace/);
    ### puny processed : $puny_processed
    ### joining name slices : $domain_name
    $puny_processed->{name} = [ $domain_name, $zone ]->join('.')
      if $domain_name;
    $puny_processed->{name_ace} = [ $name_ace, $zone_ace ]->join('.')
      if $name_ace;
    @{$puny_processed}{qw/zone zone_ace/} = ( $zone, $zone_ace );

    # process .name "email" domains
    if ( @name_segments > 1 ) {
        my $punycoded_name = _punycode_segments( [ $name_segments[0] ], $zone );
        my ( $domain, $domain_ace ) =
          $punycoded_name->slice(qw/domain domain_ace/);

        $puny_processed->{domain} =
          [ $domain, $puny_processed->{domain} ]->join('@');
        if ($domain_ace) {
            $puny_processed->{domain_ace} =
              [ $domain_ace, $puny_processed->{domain_ace} ]->join('@');

        }
    }
    return $puny_processed;

}

sub puny_convert {
    my $domain = shift;
    my @keys;
    if ( $domain =~ /\.?xn--/ ) {
        @keys = qw/domain zone/;
    }
    else {
        @keys = qw/domain_ace zone_ace/;
    }
    my $parsed        = parse_domain($domain);
    my $parsed_domain = $parsed->slice(@keys)->join(".");

    return $parsed_domain;
}

sub _find_zone {
    my $domain_segments = shift;

    my $tld_regex = ParseUtil::Domain::ConfigData->tld_regex();
    ### Domain Segments: $domain_segments
    my $tld  = $domain_segments->pop;
    my $sld  = $domain_segments->pop;
    my $thld = $domain_segments->pop;

    my ( $possible_tld, $possible_thld );
    my ( $sld_zone_ace, $tld_zone_ace ) =
      map { domain_to_ascii( nameprep $_) } $sld, $tld;
    my $thld_zone_ace;
    $thld_zone_ace = domain_to_ascii( nameprep $thld) if $thld;
    if ( $tld =~ /^de$/ ) {
        ### is a de domain
        $possible_tld = join "." => $tld, _puny_encode($sld);
    }
    else {
        $possible_tld = join "." => $tld_zone_ace, $sld_zone_ace;
        $possible_thld = join "." => $possible_tld,
          $thld_zone_ace
          if $thld_zone_ace;
    }
    my ( $zone, @zone_params );

    # first checking for third level domain
    if ( $possible_thld and $possible_thld =~ /\A$tld_regex\z/ ) {
        ### $possible_thld: $possible_thld
        my $zone_ace = join "." => $thld_zone_ace, $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $thld, $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $possible_tld =~ /\A$tld_regex\z/ ) {
        ### possible_tld: $possible_tld
        push @{$domain_segments}, $thld;
        my $zone_ace = join "." => $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $tld_zone_ace =~ /\A$tld_regex\z/ ) {
        ### tld_zone_ace: $tld_zone_ace
        push @{$domain_segments}, $thld if $thld;
        push @{$domain_segments}, $sld;
        push @zone_params, zone_ace => $tld_zone_ace;
        $zone = $tld;
    }
    croak "Could not find tld." unless $zone;
    my $unicode_zone = domain_to_unicode($zone);
    return {
        zone   => $unicode_zone,
        domain => $domain_segments,
        @zone_params
    };
}

sub _punycode_segments {
    my ( $domain_segments, $zone ) = @_;

    my @name_prefix;
    if ( not $zone or $zone !~ /^(?:de|fr|pm|re|tf|wf|yt)$/ ) {
        my $puny_encoded = [];
        foreach my $segment ( @{$domain_segments} ) {
            croak "Error processing domain."
              . " Please report to package maintainer."
              if not defined $segment
              or $segment eq '';
            my $nameprepped = nameprep( lc $segment );
            my $ascii       = domain_to_ascii($nameprepped);
            push @{$puny_encoded}, $ascii;
        }
        my $puny_decoded =
          [ map { domain_to_unicode($_) } @{$puny_encoded} ];
        croak "Undefined mapping!"
          if any { lc $_ ne nameprep( lc $_ ) } @{$puny_decoded};

        my $domain     = $puny_decoded->join(".");
        my $domain_ace = $puny_encoded->join(".");

        my $processed_name     = _process_name_part($puny_decoded);
        my $processed_name_ace = _process_name_part($puny_encoded);
        @{$processed_name_ace}{qw/name_ace prefix_ace/} =
          delete @{$processed_name_ace}{qw/name prefix/};

        return {
            domain     => $domain,
            domain_ace => $domain_ace,
            %{$processed_name},
            %{$processed_name_ace}
        };
    }

    # Avoid nameprep step for certain tlds
    my $puny_encoded =
      [ map { _puny_encode( lc $_ ) } @{$domain_segments} ];
    my $puny_decoded       = [ map { _puny_decode($_) } @{$puny_encoded} ];
    my $domain             = $puny_decoded->join(".");
    my $domain_ace         = $puny_encoded->join(".");
    my $processed_name     = _process_name_part($puny_decoded);
    my $processed_name_ace = _process_name_part($puny_encoded);
    @{$processed_name_ace}{qw/name_ace prefix_ace/} =
      delete @{$processed_name_ace}{qw/name prefix/};
    return {
        domain     => $domain,
        domain_ace => $domain_ace,
        %{$processed_name},
        %{$processed_name_ace}
    };

}

sub _process_name_part {
    my $processed = shift;
    my @name_prefix;
    my $name   = $processed->pop;
    my $prefix = $processed->join(".");
    push @name_prefix, name   => $name   if $name;
    push @name_prefix, prefix => $prefix if $prefix;
    return {@name_prefix};
}

sub _puny_encode {
    my $unencoded = shift;

    ### encoding : $unencoded
    # quick check to make sure that domain should be decoded
    my $temp_unencoded = nameprep $unencoded;
    ### namepreped : $temp_unencoded
    my $test_encode = domain_to_ascii($temp_unencoded);
    return $unencoded if $test_encode eq $unencoded;
    return "xn--" . encode_punycode($unencoded);
}

sub _puny_decode {
    my $encoded = shift;
    return $encoded
      unless $encoded =~ /xn--/;
    $encoded =~ s/^xn--//;
    ### decoding : $encoded
    my $test_decode = decode_punycode($encoded);
    ### test decode : $test_decode
    return $encoded if $encoded eq $test_decode;
    return decode_punycode($encoded);

}

1;

__END__

=encoding utf8

=head1 NAME

ParseUtil::Domain - Domain parser and puny encoder/decoder.


=for HTML <a href="https://travis-ci.org/heytrav/ParseUtil-Domain"><img src="https://travis-ci.org/heytrav/ParseUtil-Domain.svg?branch=remove-utf8"></a>


=head1 SYNOPSIS

  use ParseUtil::Domain ':parse';

    my $processed = parse_domain("somedomain.com");
    #$processed:
    #{
        #domain => 'somedomain',
        #domain_ace => 'somedomain',
        #zone => 'com',
        #zone_ace => 'com'
    #}


=head1 DESCRIPTION


This purpose of this module is to parse a domain name into its respective name and tld. Note that
the I<tld> may actually refer to a second- or third-level domain, e.g. co.uk or
plc.co.im.  It also provides respective puny encoded and decoded versions of
the parsed domain.

This module uses TLD data from the L<Public Suffix List|http://publicsuffix.org/list/> which is included with this
distribution.


=head1 INTERFACE


=head2 parse_domain


=over 2

=item
parse_domain(string)


=over 3

=item
Examples:


   1. parse_domain('somedomain.com');

    Result:
    {
        domain     => 'somedomain',
        zone       => 'com',
        domain_ace => 'somedomain',
        zone_ace   => 'com'
    }

  2. parse_domain('test.xn--o3cw4h');

    Result:
    {
        domain     => 'test',
        zone       => 'ไทย',
        domain_ace => 'test',
        zone_ace   => 'xn--o3cw4h'
    }

  3. parse_domain('bloß.co.at');

    Result:
    {
        domain     => 'bloss',
        zone       => 'co.at',
        domain_ace => 'bloss',
        zone_ace   => 'co.at'
    }

  4. parse_domain('bloß.de');

    Result:
    {
        domain     => 'bloß',
        zone       => 'de',
        domain_ace => 'xn--blo-7ka',
        zone_ace   => 'de'
    }

  5. parse_domain('www.whatever.com');

   Result:
    {
        domain     => 'www.whatever',
        zone       => 'com',
        domain_ace => 'www.whatever',
        zone_ace   => 'com',
        name       => 'whatever',
        name_ace   => 'whatever',
        prefix     => 'www',
        prefix_ace => 'www'
    }

=back



=back

=head2 puny_convert

Toggles a domain between puny encoded and decoded versions.


   use ParseUtil::Domain ':simple';

   my $result = puny_convert('bloß.de');
   # $result: xn--blo-7ka.de

   my $reverse = puny_convert('xn--blo-7ka.de');
   # $reverse: bloß.de






=head1 DEPENDENCIES

=over 3


=item
L<Net::IDN::Encode>


=item
L<Net::IDN::Punycode>


=item
L<Regexp::Assemble::Compressed>


=item
The L<Public Suffix List|http://publicsuffix.org/list/>.


=back


=head1 CHANGES


=over 3


=item *
Added extra I<prefix> and I<name> fields to output to separate the actual registered part of the domain from subdomains (or things like I<www>).

=item *
Updated with latest version of the public suffix list.

=item *
Added a bunch of new TLDs (nTLDs).



=back

=head1 LICENSE

This software is copyright (c) 2014 by Trav Holton <heytrav@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

--- The GNU General Public License, Version 1, February 1989 ---

This software is Copyright (c) 2014 by Trav Holton <heytrav@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 1, February 1989

                    GNU GENERAL PUBLIC LICENSE
                     Version 1, February 1989

 Copyright (C) 1989 Free Software Foundation, Inc.
 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The license agreements of most software companies try to keep users
at the mercy of those companies.  By contrast, our General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  The
General Public License applies to the Free Software Foundation's
software and to any other program whose authors commit to using it.
You can use it for your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Specifically, the General Public License is designed to make
sure that you have the freedom to give away or sell copies of free
software, that you receive source code or can get it if you want it,
that you can change the software or use pieces of it in new free
programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of a such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must tell them their rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  The precise terms and conditions for copying, distribution and
modification follow.

                    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License Agreement applies to any program or other work which
contains a notice placed by the copyright holder saying it may be
distributed under the terms of this General Public License.  The
"Program", below, refers to any such program or work, and a "work based
on the Program" means either the Program or any work containing the
Program or a portion of it, either verbatim or with modifications.  Each
licensee is addressed as "you".

  1. You may copy and distribute verbatim copies of the Program's source
code as you receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice and
disclaimer of warranty; keep intact all the notices that refer to this
General Public License and to the absence of any warranty; and give any
other recipients of the Program a copy of this General Public License
along with the Program.  You may charge a fee for the physical act of
transferring a copy.

  2. You may modify your copy or copies of the Program or any portion of
it, and copy and distribute such modifications under the terms of Paragraph
1 above, provided that you also do the following:

    a) cause the modified files to carry prominent notices stating that
    you changed the files and the date of any change; and

    b) cause the whole of any work that you distribute or publish, that
    in whole or in part contains the Program or any part thereof, either
    with or without modifications, to be licensed at no charge to all
    third parties under the terms of this General Public License (except
    that you may choose to grant warranty protection to some or all
    third parties, at your option).

    c) If the modified program normally reads commands interactively when
    run, you must cause it, when started running for such interactive use
    in the simplest and most usual way, to print or display an
    announcement including an appropriate copyright notice and a notice
    that there is no warranty (or else, saying that you provide a
    warranty) and that users may redistribute the program under these
    conditions, and telling the user how to view a copy of this General
    Public License.

    d) You may charge a fee for the physical act of transferring a
    copy, and you may at your option offer warranty protection in
    exchange for a fee.

Mere aggregation of another independent work with the Program (or its
derivative) on a volume of a storage or distribution medium does not bring
the other work under the scope of these terms.

  3. You may copy and distribute the Program (or a portion or derivative of
it, under Paragraph 2) in object code or executable form under the terms of
Paragraphs 1 and 2 above provided that you also do one of the following:

    a) accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of
    Paragraphs 1 and 2 above; or,

    b) accompany it with a written offer, valid for at least three
    years, to give any third party free (except for a nominal charge
    for the cost of distribution) a complete machine-readable copy of the
    corresponding source code, to be distributed under the terms of
    Paragraphs 1 and 2 above; or,

    c) accompany it with the information you received as to where the
    corresponding source code may be obtained.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form alone.)

Source code for a work means the preferred form of the work for making
modifications to it.  For an executable file, complete source code means
all the source code for all modules it contains; but, as a special
exception, it need not include source code for modules which are standard
libraries that accompany the operating system on which the executable
file runs, or for standard header files or definitions files that
accompany that operating system.

  4. You may not copy, modify, sublicense, distribute or transfer the
Program except as expressly provided under this General Public License.
Any attempt otherwise to copy, modify, sublicense, distribute or transfer
the Program is void, and will automatically terminate your rights to use
the Program under this License.  However, parties who have received
copies, or rights to use copies, from you under this General Public
License will not have their licenses terminated so long as such parties
remain in full compliance.

  5. By copying, distributing or modifying the Program (or any work based
on the Program) you indicate your acceptance of this license to do so,
and all its terms and conditions.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the original
licensor to copy, distribute or modify the Program subject to these
terms and conditions.  You may not impose any further restrictions on the
recipients' exercise of the rights granted herein.

  7. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of the license which applies to it and "any
later version", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
the license, you may choose any version ever published by the Free Software
Foundation.

  8. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

                            NO WARRANTY

  9. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  10. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

                     END OF TERMS AND CONDITIONS

        Appendix: How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to humanity, the best way to achieve this is to make it
free software which everyone can redistribute and change under these
terms.

  To do so, attach the following notices to the program.  It is safest to
attach them to the start of each source file to most effectively convey
the exclusion of warranty; and each file should have at least the
"copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) 19yy  <name of author>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 1, or (at your option)
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA


Also add information on how to contact you by electronic and paper mail.

If the program is interactive, make it output a short notice like this
when it starts in an interactive mode:

    Gnomovision version 69, Copyright (C) 19xx name of author
    Gnomovision comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the
appropriate parts of the General Public License.  Of course, the
commands you use may be called something other than `show w' and `show
c'; they could even be mouse-clicks or menu items--whatever suits your
program.

You should also get your employer (if you work as a programmer) or your
school, if any, to sign a "copyright disclaimer" for the program, if
necessary.  Here a sample; alter the names:

  Yoyodyne, Inc., hereby disclaims all copyright interest in the
  program `Gnomovision' (a program to direct compilers to make passes
  at assemblers) written by James Hacker.

  <signature of Ty Coon>, 1 April 1989
  Ty Coon, President of Vice

That's all there is to it!


--- The Artistic License 1.0 ---

This software is Copyright (c) 2014 by Trav Holton <heytrav@cpan.org>.

This is free software, licensed under:

  The Artistic License 1.0

The Artistic License

Preamble

The intent of this document is to state the conditions under which a Package
may be copied, such that the Copyright Holder maintains some semblance of
artistic control over the development of the package, while giving the users of
the package the right to use and distribute the Package in a more-or-less
customary fashion, plus the right to make reasonable modifications.

Definitions:

  - "Package" refers to the collection of files distributed by the Copyright
    Holder, and derivatives of that collection of files created through
    textual modification.
  - "Standard Version" refers to such a Package if it has not been modified,
    or has been modified in accordance with the wishes of the Copyright
    Holder.
  - "Copyright Holder" is whoever is named in the copyright or copyrights for
    the package.
  - "You" is you, if you're thinking about copying or distributing this Package.
  - "Reasonable copying fee" is whatever you can justify on the basis of media
    cost, duplication charges, time of people involved, and so on. (You will
    not be required to justify it to the Copyright Holder, but only to the
    computing community at large as a market that must bear the fee.)
  - "Freely Available" means that no fee is charged for the item itself, though
    there may be fees involved in handling the item. It also means that
    recipients of the item may redistribute it under the same conditions they
    received it.

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you
duplicate all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications derived
from the Public Domain or from the Copyright Holder. A Package modified in such
a way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided that
you insert a prominent notice in each changed file stating how and when you
changed that file, and provided that you do at least ONE of the following:

  a) place your modifications in the Public Domain or otherwise make them
     Freely Available, such as by posting said modifications to Usenet or an
     equivalent medium, or placing the modifications on a major archive site
     such as ftp.uu.net, or by allowing the Copyright Holder to include your
     modifications in the Standard Version of the Package.

  b) use the modified Package only within your corporation or organization.

  c) rename any non-standard executables so the names do not conflict with
     standard executables, which must also be provided, and provide a separate
     manual page for each non-standard executable that clearly documents how it
     differs from the Standard Version.

  d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or executable
form, provided that you do at least ONE of the following:

  a) distribute a Standard Version of the executables and library files,
     together with instructions (in the manual page or equivalent) on where to
     get the Standard Version.

  b) accompany the distribution with the machine-readable source of the Package
     with your modifications.

  c) accompany any non-standard executables with their corresponding Standard
     Version executables, giving the non-standard executables non-standard
     names, and clearly documenting the differences in manual pages (or
     equivalent), together with instructions on where to get the Standard
     Version.

  d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this
Package.  You may charge any fee you choose for support of this Package. You
may not charge a fee for this Package itself. However, you may distribute this
Package in aggregate with other (possibly commercial) programs as part of a
larger (possibly commercial) software distribution provided that you do not
advertise this Package as a product of your own.

6. The scripts and library files supplied as input to or produced as output
from the programs of this Package do not automatically fall under the copyright
of this Package, but belong to whomever generated them, and may be sold
commercially, and may be aggregated with this Package.

7. C or perl subroutines supplied by you and linked into this Package shall not
be considered part of this Package.

8. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

9. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

The End

