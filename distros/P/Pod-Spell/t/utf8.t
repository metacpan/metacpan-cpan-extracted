use 5.008; # for utf8
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;

use Pod::Spell;
use Pod::Wordlist;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":utf8";

my $podfile  = File::Temp->new;

binmode($podfile, ":utf8");

print $podfile <<'ENDPOD';
=encoding utf8

=for :stopwords
virtE<ugrave> résumé

=head1 Testing virtE<ugrave> & résumé

Our virtE<ugrave> & virtù & résumé for Mengué in 日本

=cut
ENDPOD

my @cases = (
    {
        label => "wide chars allowed",
        options => {},
        expected => [ qw( Testing Our for Mengué in 日本 ) ],
    },
    {
        label => "wide chars stripped",
        options => { no_wide_chars => 1 },
        expected => [ qw( Testing Our for Mengué in ) ],
    },
);



for my $c ( @cases ) {
    my $check = sub {
        my ($name, $content) = @_;
        my @words = split " ", $content;

        my @expected = @{ $c->{expected} };

        is scalar @words, scalar @expected, "$c->{label}: word count";

        is_deeply [ sort @words ], [ sort @expected ], "$name - $c->{label}: words match"
            or diag "@words";
    };

    my $parse = sub {
        my $p = Pod::Spell->new( %{ $c->{options} });
        $podfile->seek( 0, 0 );
        $p->parse_from_filehandle( $podfile, @_ );
    };

    {
        my $textfile = File::Temp->new( 'pod-spell-XXXXX', TMPDIR => 1, UNLINK => 1 );
        $parse->($textfile);

        $textfile->seek( 0, 0 );
        my $content = do { local $/; <$textfile> };

        $check->('temp file', Encode::decode_utf8($content));
    }

    {
        my $textfile = File::Temp->new( 'pod-spell-XXXXX', TMPDIR => 1, UNLINK => 1 );
        binmode $textfile, ':utf8';
        $parse->($textfile);

        $textfile->seek( 0, 0 );
        my $content = do { local $/; <$textfile> };

        $check->('temp file (utf8)', $content);
    }

    {
        my $content = '';
        open my $fh, '>', \$content;
        $parse->($fh);

        $check->('in memory', Encode::decode_utf8($content));
    }

    {
        my $content = '';
        open my $fh, '>:utf8', \$content;
        $parse->($fh);

        $check->('in memory (utf8)', Encode::decode_utf8($content));
    }

    {
        open(my $oldout, '>&', \*STDOUT)
            or die "Can't dup STDOUT: $!";

        my ($fh, $file) = File::Temp::tempfile( 'pod-spell-XXXXX', TMPDIR => 1, UNLINK => 1 );

        open(STDOUT, '>', $file)
            or die "Can't redirect STDOUT: $!";

        $parse->();

        open(STDOUT, '>&', $oldout)
            or die "Can't dup \$oldout: $!";

        seek $fh, 0, 0;
        my $content = do { local $/; <$fh> };

        $check->('STDOUT', Encode::decode_utf8($content));
    }

    {
        open(my $oldout, '>&', \*STDOUT)
            or die "Can't dup STDOUT: $!";

        my ($fh, $file) = File::Temp::tempfile( 'pod-spell-XXXXX', TMPDIR => 1, UNLINK => 1 );

        open(STDOUT, '>:utf8', $file)
            or die "Can't redirect STDOUT: $!";

        $parse->();

        close STDOUT;

        open(STDOUT, '>&', $oldout)
            or die "Can't dup \$oldout: $!";

        seek $fh, 0, 0;
        my $content = do { local $/; <$fh> };

        $check->('STDOUT (utf8)', Encode::decode_utf8($content));
    }
}

done_testing;
