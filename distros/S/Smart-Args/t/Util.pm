package t::Util;
use strict;
use warnings;
use utf8;
use base qw/Exporter/;
use base 'Test::Builder::Module';

my $CLASS = __PACKAGE__;

our @EXPORT = qw/lives_ok throws_ok lives_and/;

sub lives_ok(&;$) {
    my ($code, $description) = @_;
    my $tb = $CLASS->builder;
    eval { $code->() };
    $tb->ok(!$@, $description || "lives_ok");
}

sub throws_ok(&$;$) {
    my ($code, $regexp, $description) = @_;
    my $tb = $CLASS->builder;
    eval { $code->() };
    $tb->like($@, $regexp, $description || "throws_ok");
}

sub lives_and(&;$) {
    my ($code, $description) = @_;
    $CLASS->builder->subtest($description || 'lives_and', sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        eval {
            $code->();
        };
        $CLASS->builder->ok(!$@, $description || 'lives_and');
    });
}

1;

