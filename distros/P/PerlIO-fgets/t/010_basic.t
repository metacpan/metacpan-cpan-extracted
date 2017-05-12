#!perl -w
use strict;
use warnings;

use IO::File      qw[SEEK_SET];
use PerlIO::fgets qw[fgets];

use Test::More tests => 15;
use Test::HexString;

sub rewind(*) {
    seek($_[0], 0, SEEK_SET)
      || die(qq/Couldn't rewind file handle: '$!'/);
}

sub new_tmpfile_with {
    my $fh = IO::File->new_tmpfile
      || die(qq/Couldn't create a new temporary file: '$!'/);

    binmode($fh)
      || die(qq/Couldn't binmode temporary file handle: '$!'/);

    print({$fh} @_)
      || die(qq/Couldn't write to temporary file handle: '$!'/);

    seek($fh, 0, SEEK_SET)
      || die(qq/Couldn't rewind temporary file handle: '$!'/);

    return $fh;
}

{
    my $fh = new_tmpfile_with("HelloWorld\n");
    is_hexstr fgets($fh, 1024), "HelloWorld\n";
    rewind($fh);
    is_hexstr fgets($fh, 5), "Hello";
    is_hexstr fgets($fh, 5), "World";
    is_hexstr fgets($fh, 5), "\n";
    is_hexstr fgets($fh, 5), "";
}

{
    my $fh = new_tmpfile_with("\nHello\nWorld\n\n");
    is_hexstr fgets($fh, 1024), "\n";
    is_hexstr fgets($fh, 1024), "Hello\n";
    is_hexstr fgets($fh, 1024), "World\n";
    is_hexstr fgets($fh, 1024), "\n";
    is_hexstr fgets($fh, 1024), "";
}

{
    my $fh = new_tmpfile_with("Hello\0World\n");
    is_hexstr fgets($fh, 1024), "Hello\0World\n";
    is_hexstr fgets($fh, 1024), "";
}

{
    my $fh = new_tmpfile_with("");
    is_hexstr fgets($fh, 1024), "";
    is_hexstr fgets($fh, 1024), "";
    close($fh);
    is fgets($fh, 1024), undef;
}

