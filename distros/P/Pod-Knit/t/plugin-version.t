use strict;
use warnings;

use Test::Most;

use Pod::Knit::Plugin::Version;
use Pod::Knit::Document;

subtest 'version 1' => sub {
    my $plugin = Pod::Knit::Plugin::Version->new(
        version => 1,
    );

    like $plugin->munge(
        Pod::Knit::Document->new( content => '' ) 
    )->as_pod => qr/
        ^=head1 \s+ VERSION
        \s*
        version \s 1
        \s*
    /xm;
};

subtest 'no version' => sub {
    my $plugin = Pod::Knit::Plugin::Version->new(
    );

    like $plugin->munge(
        Pod::Knit::Document->new( content => '' ) 
    )->as_pod => qr/
        ^=head1 \s+ VERSION
        \s*
        version \s UNSPECIFIED
        \s*
    /xm;
};

subtest 'from stash' => sub {
    my $plugin = Pod::Knit::Plugin::Version->new(
        stash => { version => '1.0.0' },
    );

    like $plugin->munge(
        Pod::Knit::Document->new( content => '' ) 
    )->as_pod => qr/
        ^=head1 \s+ VERSION
        \s*
        version \s 1.0.0
        \s*
    /xm;
};

done_testing;

