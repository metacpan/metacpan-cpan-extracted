use strict;
use warnings;

use Test::More;
use Test::Skip::UnlessExistsExecutable 'gpg';
use PerlIO::via::GnuPG;
use PerlIO::via::GnuPG::Maybe;

$ENV{GNUPGHOME} = './t/gpghome';

# this is nice, not mandatory -- that is, it just quiets down any "unsafe
# perms!" warnings -- so ignoring any errors that might occur here is
# intentional.
chmod 0700 => $ENV{GNUPGHOME};

# TODO: need warnings, death tests

subtest ':via(GnuPG) opening encrypted text' => sub {
    open(my $fh, '<:via(GnuPG)', 't/input.txt.asc')
        or die "cannot open! $!";

    my @in = <$fh>;

    is_deeply
        [ @in                 ],
        [ "Hey, it worked!\n" ],
        'file decrypted',
        ;
};

subtest ':via(GnuPG::Maybe) opening encrypted text' => sub {

    open(my $fh, '<:via(GnuPG::Maybe)', 't/input.txt.asc')
        or die "cannot open! $!";

    my @in = <$fh>;

    is_deeply
        [ @in                 ],
        [ "Hey, it worked!\n" ],
        'file decrypted',
        ;
};

subtest ':via(GnuPG::Maybe) opening unencrypted text' => sub {

    no warnings 'PerlIO::via::GnuPG::unencrypted';

    open(my $fh, '<:via(GnuPG::Maybe)', 't/input.txt')
        or die "cannot open! $!";

    my @in = <$fh>;

    is_deeply
        [ @in                 ],
        [ "Hey, it worked!\n" ],
        'file passedthrough OK',
        ;
};

done_testing;
