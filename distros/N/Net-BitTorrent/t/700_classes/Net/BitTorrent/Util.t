#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Module::Build;
use Time::HiRes qw[];
use lib q[../../../../lib];
use Net::BitTorrent::Util qw[:all];
$|++;
my $test_builder       = Test::More->builder;
my $simple_dot_torrent = q[./t/900_data/950_torrents/953_miniswarm.torrent];
chdir q[../../../../] if not -f $simple_dot_torrent;
my $build    = Module::Build->current;
my $okay_tcp = $build->notes(q[okay_tcp]);
my $verbose  = $build->notes(q[verbose]);
$SIG{__WARN__} = (
    $verbose
    ? sub {
        diag(sprintf(q[%02.4f], Time::HiRes::time- $^T), q[ ], shift);
        }
    : sub { }
);
$|++;
plan tests => 88;
SKIP: {
    is(bencode(4),   q[i4e],   q[integer]);
    is(bencode(0),   q[i0e],   q[zero]);
    is(bencode(-0),  q[i0e],   q[zero w/ sign]);
    is(bencode(-10), q[i-10e], q[negative integer]);
    is(bencode(+10), q[i10e],  q[positive integer]);
    is(bencode(time x 50), q[i] . (time x 50) . q[e], q[large number]);
    is(bencode(q[Perl]), q[4:Perl], q[string]);
    is(bencode(q[]),     q[0:],     q[null string]);
    is(bencode(),        q[0:],     q[undef]);
    is(bencode(undef),   q[0:],     q[undef]);
    is(bencode(\undef),  q[],       q[ref to undef]);
    is(bencode(q[0:0:]), q[4:0:0:], q[odd string (malformed bencoded int)]);
    is(bencode([1, 2, 3]), q[li1ei2ei3ee], q[list (integers)]);
    is(bencode([q[one], q[two], q[three]]),
        q[l3:one3:two5:threee], q[list (strings)]);
    is(bencode([q[three], 1, 2, 3, q[one], q[two]]),
        q[l5:threei1ei2ei3e3:one3:twoe],
        q[list (mixed scalars)]);
    is(bencode([]), q[le], q[empty list]);
    is(bencode([[q[Alice], q[Bob]], [2, 3]]),
        q[ll5:Alice3:Bobeli2ei3eee], q[list^list]);
    is(bencode({date => {month => q[January], year => 2009}}),
        q[d4:dated5:month7:January4:yeari2009eee],
        q[dictionary]);
    is(bencode({}), q[de], q[dictionary from empty hash]);
    is(bencode({age => 25, eyes => q[blue]}),
        q[d3:agei25e4:eyes4:bluee], q[dictionary from anon hash]);
    is( length bencode({join(q[], map(chr($_), 0 .. 255)) =>
                            join(q[], map(chr($_), 0 .. 255))
                       }
        ),
        522,
        q[anon hash with long key/value pair]
    );
    bencode(
        {sub => sub { return my $brain; }
        }
    );
    my $str = q[d7:Integeri42e4:Listl6:item 1i2ei3ee6:String9:The Valuee];
    is(bdecode, undef, q[Empty string]);
    my ($hashref) = bdecode($str);
    ok defined $hashref, q[bdecode() returned something];
    is ref $hashref, q[HASH], q[bdecode() returned a valid hash ref];
    ok defined $hashref->{q[Integer]}, q[Integer key present];
    is $hashref->{q[Integer]}, 42, q[  and its the correct value];
    ok defined $hashref->{q[String]}, q[String key present];
    is ${$hashref;}{q[String]}, q[The Value], q[  and its the correct value];
    ok defined $hashref->{q[List]}, q[List key present];
    is @{$hashref->{q[List]}}, 3, q[  list has 3 elements];
    is ${$hashref->{q[List]}}[0], q[item 1], q[    first element correct];
    is ${$hashref->{q[List]}}[1], 2,         q[    second element correct];
    is ${$hashref->{q[List]}}[2], 3,         q[    third element correct];
    my ($encoded_string) = bencode($hashref);
    ok defined $encoded_string, q[bencode() returned something];
    is $encoded_string, $str, q[  and it appears to be the correct value];
    is(bdecode(q[i4e]),      4,      q[integer]);
    is(bdecode(q[i0e]),      0,      q[zero]);
    is(bdecode(q[i-0e]) + 0, 0,      q[zero w/ sign]);
    is(bdecode(q[i-10e]),    -10,    q[negative integer]);
    is(bdecode(q[0:]),       q[],    q[zero length string]);
    is(bdecode(q[3:abc]),    q[abc], q[string]);
    is_deeply(scalar bdecode(bencode([qw[this that and the other]])),
              [qw[this that and the other]],
              q[list in scalar context]);
    is_deeply(scalar bdecode(bencode({qw[this that the other]})),
              {qw[this that the other]}, q[dictionary in scalar context]);
    is(bdecode(q[10:1234567890]), q[1234567890], q[integer cast as string]);
    is(bdecode(q[02:xy]), undef, q[string with leading zero in length]);
    is(bdecode(q[i03e]),  3,     q[integer with leading zero]);
    is(bdecode(q[0:0:]), '',
        q[trailing junk at end of valid bencoded string]);
    is_deeply([bdecode(q[leanfdldjfh])],
              [[], q[anfdldjfh]],
              q[empty list with trailing garbage]);
    is_deeply([bdecode(q[i])],           [], q[aborted integer]);
    is_deeply([bdecode(q[i0])],          [], q[unterminated integer]);
    is_deeply([bdecode(q[ie])],          [], q[empty integer]);
    is_deeply([bdecode(q[i341foo382e])], [], q[malformed integer]);
    is_deeply([bdecode(q[i123])],        [], q[unterminated integer]);
    is_deeply([bdecode(q[1:])],          [], q[string longer than data]);
    is_deeply([bdecode(q[i6easd])], [6, q[asd]],
              q[string with trailing junk]);
    is_deeply([bdecode(q[35208734823ljdahflajhdf])],
              [], q[garbage looking vaguely like a string, with large count]);
    is_deeply([bdecode(q[2:abfdjslhfld])],
              [q[ab], q[fdjslhfld]],
              q[string with trailing garbage]
    );
    is_deeply([bdecode(q[02:xy])], [],
              q[string with extra leading zero in count]);
    is_deeply([bdecode(q[l])], [[], q[]], q[unclosed empty list]);
    is_deeply([bdecode(q[relwjhrlewjh])], [], q[complete garbage]);
    is_deeply([bdecode(q[d])], [{}, q[]], q[unclosed empty dict]);
    is_deeply([bdecode(q[defoobar])],
              [{}, q[foobar]],
              q[Catch invalid format (empty dictionary w/ trailing garbage)]);
    is_deeply([bdecode(q[d3:fooe])],
              [{foo => undef}, undef],
              q[Catch invalid format (dictionary w/ empty key)]);
    is_deeply([bdecode(q[d1:ei0e1:mde1:pi48536e1:v15:µTorrent 1.7.7e])],
              [{e => 0,
                m => {},
                p => 48536,
                v => "\xC2\xB5Torrent 1.7.7"
               },
               q[]
              ],
              q[Complex structure (empty dictionary, 'safe' hex chars)]
    );
    is(compact(qw[127.0.0.1:98]), qq[\x7F\0\0\1\0b],  q[localhost]);
    is(compact(qw[127.0.0.1:0]),  qq[\x7F\0\0\1\0\0], q[port number of zero]);
    is(compact(qw[127.0.0.1:5000]),
        qq[\x7F\0\0\1\23\x88], q[Large port number]);
    is(compact(qw[127.0.0.1:65535]),
        qq[\x7F\0\0\1\xFF\xFF], q[Large port number]);
    is(compact(qw[127.0.0.1:3265 255.25.21.32:0]),
        qq[\x7F\0\0\1\f\xC1\xFF\31\25 \0\0],
        q[short list of peers]);
    is(compact(qw[127.0.0.1:3265 127.0.0.1:3265]),
        qq[\x7F\0\0\1\f\xC1], q[Filter duplicates]);
    is(compact(qw[127.0.0.1:000065]),
        qq[\x7F\0\0\1\0A], q[Port with leading zeros]);
    is(compact(qw[270.0.0.1:0]), undef, q[Invalid IP address: 270.0.0.1:0]);
    is(compact(qw[127.0.0.1:5000000]),
        undef, q[Port number beyond ephemeral range: 127.0.0.1:5000000]);
    is(compact(qw[127.0.0.1:500:30]),
        undef, q[Invalid IP address: 127.0.0.1:500:30]);
    is(compact(qw[127.0.0.1.3:50030]),
        undef, q[Invalid IP address: 127.0.0.1.3:50030]);
    is(compact(q[127.0.0.1:ABC]), undef, q[Bad port number: 127.0.0.1:ABC]);
    is(compact(qw[127.0.0.1:3265 255.25.21.32:0:4554845]),
        qq[\x7F\0\0\1\f\xC1], q[Invalid peer in list]);
    is(compact(qw[]),    undef, q[Empty list]);
    is(compact(q[]),     undef, q[String]);
    is(compact(undef),   undef, q[undef]);
    is(compact(),        undef, q[undef]);
    is(uncompact(q[]),   undef, q[Empty string]);
    is(uncompact(undef), undef, q[undef string]);
    is(uncompact(),      undef, q[undef string]);
    is(uncompact(qq[\x7F\0\0\1\xFF\xFF]),
        qw[127.0.0.1:65535], q[Large port number]);
    my @peers = sort(uncompact(qq[\x7F\0\0\1\f\xC1\xFF\31\25 \0\0]));
    is(@peers,    2,                 q[Short list of peers...]);
    is($peers[0], q[127.0.0.1:3265], q[   ...First checks out.]);
    is($peers[1], q[255.25.21.32:0], q[   ...Second is okay too.]);

    # TODO: IPv6 faking IPv4 and invalid IPv4 (ex: 999.999.999.999)
    #is( uncompact(qw[127.0.0.1:98]), qq[\x7F\0\0\1\0b], q[localhost] );
    #is( uncompact(qw[127.0.0.1:0]),
    #    qq[\x7F\0\0\1\0\0], q[port number of zero] );
    #is( uncompact(qw[127.0.0.1:5000]),
    #    qq[\x7F\0\0\1\23\x88], q[large port number] );
}
__END__
Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

$Id: Util.t d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $
