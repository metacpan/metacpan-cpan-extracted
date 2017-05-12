package t::TestEtherealGlue;
# $Id: TestEtherealGlue.pm 131 2005-10-02 17:24:31Z abworrall $

# Provides some routines used in various tests ...

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;
use Carp qw(carp croak confess);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(hexdump_to_monologues list_testfiles);

=head2 hexdump_to_monologues ($fname)

Ethereal has a nice feature to assemble TCP streams from packets. However, when
you save it as ascii, the monologues are separated by blank lines - which could
be present in the data.

Luckily, there is a hex output mode, which uses indentation to indicate which
side is doing the talking. Here is an example, with the blank lines removed:

 00000000  47 45 54 20 2f 69 6e 64  65 78 2e 68 74 6d 6c 20 GET /ind ex.html
 00000010  48 54 54 50 2f 31 2e 30  0d 0a 55 73 65 72 2d 41 HTTP/1.0 ..User-A
 00000020  67 65 6e 74 3a 20 57 67  65 74 2f 31 2e 38 2e 32 gent: Wg et/1.8.2
 00000030  0d 0a 48 6f 73 74 3a 20  77 77 77 2e 67 6f 6f 67 ..Host:  www.goog
 00000040  6c 65 2e 63 6f 6d 0d 0a  41 63 63 65 70 74 3a 20 le.com.. Accept:
 00000050  2a 2f 2a 0d 0a 43 6f 6e  6e 65 63 74 69 6f 6e 3a */*..Con nection:
 00000060  20 4b 65 65 70 2d 41 6c  69 76 65 0d 0a 0d 0a     Keep-Al ive....
                                                                               00000000  48 54 54 50 2f 31 2e 31  20 32 30 30 20 4f 4b 0d HTTP/1.1  200 OK.
                                                                               00000010  0a 43 6f 6e 6e 65 63 74  69 6f 6e 3a 20 4b 65 65 .Connect ion: Kee
                                                                               00000020  70 2d 41 6c 69 76 65 0d  0a 43 61 63 68 65 2d 43 p-Alive. .Cache-C



This routine loads up an Ethereal hex save file, and returns an arrayref of
monologues.

More recent versions of wireshark indent the responses a lot less, e.g.:

 00000260  50 72 61 67 6d 61 3a 20  6e 6f 2d 63 61 63 68 65 Pragma:  no-cache

 00000270  0d 0a 43 61 63 68 65 2d  43 6f 6e 74 72 6f 6c 3a ..Cache- Control:

 00000280  20 6e 6f 2d 63 61 63 68  65 0d 0a 0d 0a           no-cach e....

     00000000  48 54 54 50 2f 31 2e 31  20 32 30 30 20 4f 4b 0d HTTP/1.1  200 OK.

     00000010  0a 44 61 74 65 3a 20 57  65 64 2c 20 33 31 20 4d .Date: W ed, 31 M

     00000020  61 72 20 32 30 31 30 20  31 36 3a 33 32 3a 31 35 ar 2010  16:32:15

=cut

sub hexdump_to_monologues {
    my ($fname) = shift;
    my ($curr_ind) = '';
    my (@m, $curr);

    open (IN, $fname) || die "open+r $fname: $!\n";

    while (<IN>) {
        next if (/^\s*$/); # I think these blank lines are a bug in Ethereal
        my ($ind, $data) = (/^(\s*)[0-9a-f]{8}  ([0-9a-f ]{48})/i);
        $data =~ s/ //g;
        my $raw = pack("H*", $data);

        if ($ind ne $curr_ind) {
            die "but empty ?" if ($curr eq '');
            push (@m, $curr);
            $curr = '';
            $curr_ind = $ind;
        }
        $curr .= $raw;
    }

    close (IN);

    push (@m, $curr);

    return \@m;
}

=head2 list_testfiles ([$regex])

Returns a sorted list of the stemnames of the TCP testfiles we have, e.g.

 ['t1_google', 't2_lost_packet', ...

optional argument is a regex that the stemname must match.

=cut

sub list_testfiles {
    my ($regex) = @_;

    opendir (DIR, "t") || die "opendir 't': $!\n";
    my @f = sort map {s/.tcp//;$_} grep {/^t.*tcp$/} readdir (DIR);
    closedir (DIR);

    @f = grep {/$regex/} @f if (defined $regex);

    return (wantarray) ? @f : \@f;
}

1;
