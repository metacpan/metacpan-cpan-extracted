use strict;
use warnings;
use utf8;
use Test::More;

use Perl::MinimumVersion::Fast;

diag "Compiler::Lexer: $Compiler::Lexer::VERSION";

note '--- minimum_version';
for (
    ['-1', '5.006'],
    ['use utf8', '5.008'],
    ['each %hash', '5.006'],
    ['my %hash; each %hash', '5.006'],
    ['each $hashref', '5.014'],
    ['my $hashref; each $hashref', '5.014'],
    ['each @array', '5.012'],
    ['my @array; each @array', '5.012'],
    ['keys @array', '5.012'],
    ['my @array; keys @array', '5.012'],
    ['keys $hashref', '5.014'],
    ['my $hashref; keys $hashref', '5.014'],
    ['my @array; each @array', '5.012'],
    ['values @array', '5.012'],
    ['my @array; values @array', '5.012'],
    ['values $hashref', '5.014'],
    ['my $hashref; values $hashref', '5.014'],
    ['push @array', '5.006'],
    ['my @array; push @array', '5.006'],
    ['push $arrayref', '5.014'],
    ['push($arrayref, 1)', '5.014'],
    ['push(($arrayref, 1)', '5.014'],
    ['my $arrayref; push $arrayref', '5.014'],
    ['my $arrayref; push($arrayref', '5.014'],
    ['unshift @array', '5.006'],
    ['my @array; unshift @array', '5.006'],
    ['unshift $arrayref', '5.014'],
    ['unshift($arrayref', '5.014'],
    ['my $arrayref; unshift $arrayref', '5.014'],
    ['my $arrayref; unshift($arrayref', '5.014'],
    ['pop @array', '5.006'],
    ['my @array; pop @array', '5.006'],
    ['pop $arrayref', '5.014'],
    ['pop($arrayref', '5.014'],
    ['my $arrayref; pop $arrayref', '5.014'],
    ['my $arrayref; pop($arrayref', '5.014'],
    ['shift @array', '5.006'],
    ['my @array; shift @array', '5.006'],
    ['shift $arrayref', '5.014'],
    ['shift($arrayref', '5.014'],
    ['my $arrayref; shift $arrayref', '5.014'],
    ['my $arrayref; shift($arrayref', '5.014'],
    ['splice @array', '5.006'],
    ['my @array; splice @array', '5.006'],
    ['splice $arrayref', '5.014'],
    ['splice($arrayref', '5.014'],
    ['my $arrayref; splice $arrayref', '5.014'],
    ['my $arrayref; splice($arrayref', '5.014'],
    ['...', '5.012'],
    ['package Foo', '5.006'],
    ['package Foo;', '5.006'],
    ['package Foo 3', '5.012'],
    ['package Foo 3.14', '5.012'],
    ['package Foo 3.14_01', '5.012'],
    ['package Foo v0.0.1', '5.012'],
    ['package Foo { }', '5.014'],
    ['package Foo 3 { }', '5.014'],
    ['package Foo 3.14 { }', '5.014'],
    ['package Foo v0.0.1 { }', '5.014'],
    ['package Foo; { }', '5.006'],

    # mro.pm is 5.10+ feature. But there is MRO::Compat.
    # MRO::Compat do `$INC{'mro.pm'} = 1 `.
    # MRO::Compat supports 5.6
    ['require mro', '5.006'],
    ['use mro', '5.006'],

    ['use feature', '5.010'],
    ['use feature;', '5.010'],
    ['use feature "unicode_strings"', '5.012'],
    ['use feature "unicode_eval"', '5.016'],
    ['use feature "current_sub"', '5.016'],
    ['use feature "fc"', '5.016'],
    ['use feature "experimental::lexical_subs"', '5.018'],
    ['use feature ":5.14"', '5.014'],
    ['use feature ":5.16"', '5.016'],
    ['use feature ":5.18"', '5.018'],
    ['require feature', '5.010'],
    ['use Data::Dumper', '5.006'],
    ['require Data::Dumper', '5.006'],
    ['require strict', '5.006'],
    ['use strict', '5.006'],
    ['use 5', '5.006'],
    ['require 5', '5.006'],
    ['1 // 2', '5.010'],
    ['1 ~~ 2', '5.010'],
    ['$x //= 2', '5.010'],
    ['%+', '5.010'],
    ['$+{"a"}', '5.010'],
    ['@+{"a"}', '5.010'],
    ['warn %-', '5.010'],
    ['$-{"a"}', '5.010'],
    ['@-{"a"}', '5.010'],
    ['when (1) {}', '5.010'],
    ['when ([1,2,3]) {}', '5.010'],
    [q{print "$_," when [1,2,3];}, '5.012'],
    [q{print "$_," when([1,2,3]);}, '5.012'],
    [q{print "$_," when 1}, '5.012'],
    [q!warn; when (1) { }!, '5.010'],
    [q!use 5.010!, '5.010'],
    [q!use 5.010_001!, '5.010_001'],
    [q!split // => 3!, '5.006'],
    [q!split //, 3!, '5.006'],
    [q!split //!, '5.006'],
    [q!(split //)!, '5.006'],
    [q!{split //}!, '5.006'],
    [q!{split(//)}!, '5.006'],
    [q!if (//) { }!, '5.006'],
    [q!map //, 3!, '5.006'],
    [q!grep //, 3!, '5.006'],
    [q!time // time!, '5.010'],
) {
    my ($src, $version) = @$_;
    my $p = Perl::MinimumVersion::Fast->new(\$src);
    is($p->minimum_version, $version, $src) or die;
    dump_version_markers($p);
}

subtest 'minimum_explict_version/minimum_syntax_version' => sub {
    for (
        # code                 explict      syntax
        [q!use     5.010_001!, '5.010_001', '5.006'],
        [q!require 5.010_001!, '5.010_001', '5.006'],
        ['...',                undef,       '5.012'],
    ) {
        my ($src, $explicit_version, $syntax_version) = @$_;
        my $p = Perl::MinimumVersion::Fast->new(\$src);
        is($p->minimum_explicit_version, $explicit_version, "$src - explicit");
        is($p->minimum_syntax_version,   $syntax_version,   "$src - syntax");
    }
};

subtest 'version markers' => sub {
    {
        my $p = Perl::MinimumVersion::Fast->new(\'use 5.010_001');
        is_deeply(
            [$p->version_markers], [
                '5.010_001' => [
                    'explicit',
                ],
            ],
        );
    }

    {
        my $p = Perl::MinimumVersion::Fast->new(\'...');
        is_deeply(
            [$p->version_markers], [
                '5.012' => [
                    'yada-yada-yada operator(...)',
                ],
            ],
        );
    }
};

done_testing;

sub dump_version_markers {
    my $p = shift;
    my @rv = $p->version_markers;
    for (my $i=0; $i<@rv; $i+=2) {
        note $rv[$i] . ":\n" . join("\n", map { "  - $_" } @{$rv[$i+1]});
    }
}
