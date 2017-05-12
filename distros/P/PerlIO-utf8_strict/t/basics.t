#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;

use File::Spec::Functions qw/catfile/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

{
    my $filename = catfile(qw/corpus test1.txt/);
    open my $fh, '<:utf8_strict', $filename or die "Couldn't open file $filename";

    my $line = <$fh>;

    is($line, "Foö-Báŗ\n", 'Content is Foö-Báŗ');
}

{
    my $filename = catfile(qw/corpus quickbrown.txt/);
    open my $fh, '<:utf8_strict', $filename or die "Couldn't open file $filename";

    lives_ok { my $data = do { local $/; <$fh> } } 'successfull reading quickbrown.txt'
}

{
    my $filename = catfile(qw/corpus test1-latin1.txt/);
    open my $fh, '<:utf8_strict', $filename or die "Couldn't open file $filename";

    my $line;
    throws_ok { $line = <$fh> } qr/^Can't decode ill-formed UTF-8 octet sequence/, 'Trying to read ill-formed encoded UTF-8 fails' or diag "Just read '$line'";
}

done_testing;
