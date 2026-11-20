#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Perl::Critic ();
use Test::More;

my $POLICY = '^Perl::Critic::Policy::Performance::ProhibitRegexForSimpleSubstring$';

## no critic (RequireInterpolationOfMetachars)
my $EXPLANATION_FORMAT = q{Use index($string, %s) instead of a regex when looking for literal text};
## use critic

sub new_critic {
    my ($profile) = @_;

    $profile = q{} if !defined $profile;

    my $critic = eval {
        Perl::Critic->new(
            '-profile'       => $profile,
            '-severity'      => 1,
            '-single-policy' => $POLICY,
        );
    };
    Test::More::BAIL_OUT("cannot build a critic: $@") if !$critic;

    return $critic;
}

sub violations_of {
    my ( $critic, $source ) = @_;

    my @violations = $critic->critique( \$source );

    return @violations;
}

sub check_counts {
    my ( $critic, $label, $expected, $cases ) = @_;

    for my $name ( sort keys %{$cases} ) {
        my $source     = $cases->{$name};
        my $count      = violations_of( $critic, $source );
        my $case_label = "$label: $name";

        Test::More::is( $count, $expected, $case_label );
    }

    return;
}

sub check_explanation {
    my ( $critic, $name, $source, $quoted ) = @_;

    my @violations      = violations_of( $critic, $source );
    my $violation_count = @violations;
    my $case_label      = "explained: $name";

    Test::More::is( $violation_count, 1, $case_label );
    return if $violation_count != 1;

    my $expected    = sprintf $EXPLANATION_FORMAT, $quoted;
    my $explanation = $violations[0]->explanation();

    Test::More::is( $explanation, $expected, "$case_label text" );

    return;
}

my $ALLOW_PROFILE = join "\n",
    q{[Performance::ProhibitRegexForSimpleSubstring]},
    q{allow = grep_lines My::Util::match_all},
    q{};

my $allow_critic = new_critic( \$ALLOW_PROFILE );
my $critic       = new_critic();

## no critic (RequireInterpolationOfMetachars, ValuesAndExpressions::ProhibitEscapedCharacters)
my %REPORTED = (
    'bare list operator reported'              => q{foo m/foo/, $s;},
    'bare match'                               => q{/foo/;},
    'double a modifier reported'               => q{$str =~ m/foo/aa;},
    'escaped backslash is still literal'       => q{$str =~ /foo\\\\/;},
    'escaped metachar is still literal'        => q{$str =~ /foo\./;},
    'literal with space'                       => q{$str =~ /foo bar/;},
    'literal with special regex chars escaped' => q{$str =~ /foo\+bar/;},
    'match against dollar underscore'          => q{print if m/foo/;},
    'match in a grep block reported'           => q{grep { m/foo/ } @lines;},
    'msx modifiers reported'                   => q{$str =~ m/foo/msx;},
    'multiple literals'                        => q{$str =~ /hello world/;},
    'n modifier reported'                      => q{$str =~ m/foo/n;},
    'simple literal match'                     => q{$str =~ /foo/;},
);

my %QUIET = (
    'alternation is not simple'         => q{$str =~ /foo|bar/;},
    'anchor is not simple'              => q{$str =~ /^foo/;},
    'backreference is not simple'       => q{$str =~ /(foo)\1/;},
    'capture group is not simple'       => q{$str =~ /(foo)/;},
    'case insensitive modifier'         => q{$str =~ /foo/i;},
    'char class is not simple'          => q{$str =~ /[a-z]/;},
    'compiled regex'                    => q{my $rx = qr/foo/;},
    'dot is not simple'                 => q{$str =~ /foo.bar/;},
    'empty regex should not flag'       => q{$m =~ //;},
    'end anchor'                        => q{$str =~ /foo$/;},
    'interpolation is not simple'       => q{$str =~ /$foo/;},
    'non-capturing group is not simple' => q{$str =~ /(?:foo)/;},
    'optional is not simple'            => q{$str =~ /fo?/;},
    'quantifier is not simple'          => q{$str =~ /fo+/;},
    'star quantifier'                   => q{$str =~ /fo*/;},
    'substitution'                      => q{$str =~ s/foo/bar/;},
    'use re aasx and char class'        => q{use re '/aasx'; $str =~ m/foo[ ]bar/;},
    'use re aasx and split'             => q{use re '/aasx'; split m/,/, $s;},
    'use re aasxi'                      => q{use re '/aasxi'; $str =~ m/foo/;},
    'use re i'                          => q{use re '/i'; $str =~ m/foo/;},
);

my %EXPLAINED = (
    'escaped dot decodes'            => [ q{$str =~ m/foo\.bar/;},                        q{'foo.bar'} ],
    'extended modifier'              => [ q{$str =~ /foo/x;},                             q{'foo'} ],
    'extended modifier keeps spaces' => [ q{$str =~ m/foo bar/x;},                        q{'foobar'} ],
    'multiline modifier'             => [ q{$str =~ /foo/m;},                             q{'foo'} ],
    'carriage return escape decodes' => [ q{$str =~ m/\r/;},                              q{"\r"} ],
    'comment under x decodes'        => [ qq{\$str =~ m/foo # the first half\nbar/x;},    q{'foobar'} ],
    'newline escape decodes'         => [ q{$str =~ m/\n/;},                              q{"\n"} ],
    'tab escape decodes'             => [ q{$str =~ m/\t/;},                              q{"\t"} ],
    'no re restores an x flag'       => [ q{use re '/x'; { no re '/x'; $str =~ m/foo/ }}, q{'foo'} ],
    'single-line modifier'           => [ q{$str =~ /foo/s;},                             q{'foo'} ],
    'undefined ordinal is generic'   => [ q{$str =~ m/\o{101}/;},                         q{$substring} ],
    'unicode escape decodes'         => [ q{$str =~ m/\x{ff}/;},                          q{"\x{ff}"} ],
    'use re sx'                      => [ q{use re '/sx'; $str =~ m/foo/;},               q{'foo'} ],
    'use re x'                       => [ q{use re '/x'; $str =~ m/foo/;},                q{'foo'} ],
    'use re x decodes spaces'        => [ q{use re '/x'; $str =~ m/foo bar/;},            q{'foobar'} ],
);

my %SPLIT_QUIET = (
          'annotation silences a literal match' => q{## no critic (Performance::ProhibitRegexForSimpleSubstring)} . "\n"
        . q{$str =~ m/foo/;},
    'core split'                        => q{CORE::split( m/x/, $s );},
    'double grouped split'              => q{split( ( m/x/ ), $s );},
    'last statement of a block'         => q{sub { split m/,/, $_[0] }},
    'method split with parentheses'     => q{$obj->split( m/x/, $s );},
    'method split without parentheses'  => q{$obj->split m/x/, $s;},
    'nested call keeps the inner split' => q{foo( split m/x/, $s );},
    'paren split bare match'            => q{split(/x/, $s);},
    'paren split match'                 => q{split( m/x/, $s );},
    'split assignment'                  => q{my @lines = split m/\n/, $text;},
    'split in a loop list'              => q{foreach my $line ( split m/\n/, File::Slurper::read_text($tt) ) { 1 }},
    'split low precedence or'           => q{split m/x/, $s or die;},
    'split match'                       => q{split m/x/, $s;},
    'split non literal stays quiet'     => q{split m/\s+/, $s;},
    'split one argument'                => q{split m/x/;},
    'split slash'                       => q{split /x/, $s;},
);

my %SPLIT_REPORTED = (
    'anonymous array is not the pattern' => q{split( [ m/x/ ], $s );},
    'binding match is not the pattern'   => q{split $sep, $str =~ m/x/;},
    'concatenation is not the pattern'   => q{split m/x/ . $more, $s;},
    'fat comma is not a call'            => q{my %h = ( split => m/foo/ );},
    'second split argument'              => q{split m/,/, m/x/;},
    'subscript is not the pattern'       => q{split( $h{ m/x/ }, $s );},
);

my %SPLIT_BOTH = (
    'ternary reports both branches' => q{split( $tab ? m/a/ : m/b/, $s );},
);

my @WARNING_SOURCES = (
    q{m/foo/;},
    q{split m/x/;},
    q{sub { m/foo/ }},
);

my %ALLOW_QUIET = (
    'bare allow matches a method'      => q{$obj->grep_lines( m/foo/ );},
    'bare allow matches a package'     => q{Other::grep_lines( m/foo/ );},
    'bare allow matches parentheses'   => q{grep_lines( m/foo/, @lines );},
    'bare allow matches the call'      => q{grep_lines m/foo/, @lines;},
    'class disambiguation method'      => q{My::Util::->match_all( m/foo/, $s );},
    'qualified allow matches a method' => q{My::Util->match_all( m/foo/, $s );},
    'qualified allow matches the sub'  => q{My::Util::match_all( m/foo/, $s );},
    'split stays in the allow list'    => q{split m/\n/, $text;},
);

my %ALLOW_REPORTED = (
    'bare qualified name is reported'         => q{match_all( m/foo/, $s );},
    'explicit namespace is not allowed'       => q{My::Util->Other::match_all( m/foo/ );},
    'object method is not the qualified name' => q{$obj->match_all( m/foo/ );},
    'other function is reported'              => q{foo( m/foo/ );},
    'other package is not the qualified name' => q{Other::match_all( m/foo/, $s );},
    'plain match is reported'                 => q{$str =~ m/foo/;},
    'second argument is reported'             => q{grep_lines( $s, m/foo/ );},
);

my %ALLOW_BOTH = (
    'logical operator in call reports both' => q{grep_lines(m/a/ or m/b/);},
);

my %ALLOW_DEFAULT = (
    'grep_lines is reported without allow' => q{grep_lines( m/foo/, @lines );},
);
## use critic

Test::More::subtest(
    'reported literal match' => sub {
        check_counts( $critic, 'reported', 1, \%REPORTED );
    }
);

Test::More::subtest(
    'patterns that are not a literal search' => sub {
        check_counts( $critic, 'quiet', 0, \%QUIET );
    }
);

Test::More::subtest(
    'decoded literal in the explanation' => sub {
        for my $name ( sort keys %EXPLAINED ) {
            my ( $source, $quoted ) = @{ $EXPLAINED{$name} };

            check_explanation( $critic, $name, $source, $quoted );
        }

        my $spaced     = $EXPLAINED{'extended modifier keeps spaces'}[0];
        my @violations = violations_of( $critic, $spaced );
        return if @violations != 1;

        my $explanation = $violations[0]->explanation();

        Test::More::ok(
            index( $explanation, q{'foo bar'} ) < 0,
            'extended modifier keeps spaces explanation omits the spaced source',
        );
    }
);

Test::More::subtest(
    'plain literal match names its text' => sub {
        check_explanation( $critic, 'simple literal match', $REPORTED{'simple literal match'}, q{'foo'} );
    }
);

Test::More::subtest(
    'split pattern is quiet' => sub {
        check_counts( $critic, 'split quiet', 0, \%SPLIT_QUIET );
    }
);

Test::More::subtest(
    'literal match outside a split pattern' => sub {
        check_counts( $critic, 'split reported', 1, \%SPLIT_REPORTED );
    }
);

Test::More::subtest(
    'ternary in a split pattern' => sub {
        check_counts( $critic, 'split both', 2, \%SPLIT_BOTH );
    }
);

my @WARNINGS;

sub record_warning {
    my ($warning) = @_;

    push @WARNINGS, $warning;

    return;
}

sub warning_count {
    my ($source) = @_;

    @WARNINGS = ();
    local $SIG{__WARN__} = \&record_warning;
    $critic->critique( \$source );

    my $count = @WARNINGS;

    return $count;
}

Test::More::subtest(
    'critique warns nothing' => sub {
        for my $source ( sort @WARNING_SOURCES ) {
            my $count = warning_count($source);

            Test::More::is( $count, 0, "warnings: $source" );
        }
    }
);

Test::More::subtest(
    'allow adds names' => sub {
        check_counts( $allow_critic, 'allow quiet',    0, \%ALLOW_QUIET );
        check_counts( $allow_critic, 'allow reported', 1, \%ALLOW_REPORTED );
    }
);

Test::More::subtest(
    'logical operator keeps both matches in the argument' => sub {
        check_counts( $allow_critic, 'allow both', 2, \%ALLOW_BOTH );
    }
);

Test::More::subtest(
    'default list is only split' => sub {
        check_counts( $critic, 'allow default', 1, \%ALLOW_DEFAULT );
    }
);

Test::More::done_testing();
