#!perl
use 5.016;
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';
use Syntax::Highlight::Basic::Parser;

#===========================================================================
# Parser Fallback Tests
#===========================================================================

# Helper: find a token in parse result
sub find_token {
    my ($result, %criteria) = @_;
    for my $line (@$result) {
        for my $token (@$line) {
            my $match = 1;
            for my $key (keys %criteria) {
                $match = 0 unless defined $token->{$key} && $token->{$key} eq $criteria{$key};
            }
            return $token if $match;
        }
    }
    return undef;
}

#===========================================================================
# Constructor with unknown language
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_language_xyz');
    isa_ok($p, 'Syntax::Highlight::Basic::Parser', 'constructor with unknown language succeeds');
}

#===========================================================================
# Fallback string detection — double quotes
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_xyz');
    my $result = $p->parse('"hello world"');
    my $token = find_token($result, sub_group => 'String');
    ok(defined $token, 'fallback: double-quoted string detected');
}

#===========================================================================
# Fallback string detection — single quotes
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_xyz');
    my $result = $p->parse("'single quoted'");
    my $token = find_token($result, sub_group => 'String');
    ok(defined $token, 'fallback: single-quoted string detected');
}

#===========================================================================
# Fallback number detection
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_xyz');
    my $result = $p->parse('42');
    my $token = find_token($result, sub_group => 'Number');
    ok(defined $token, 'fallback: integer 42 detected as Number');
}

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_xyz');
    my $result = $p->parse('3.14');
    my $token = find_token($result, sub_group => 'Number');
    ok(defined $token, 'fallback: float 3.14 detected as Number');
}

#===========================================================================
# Fallback delimiter detection
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_xyz');
    my $result = $p->parse('{');
    my $token = find_token($result, sub_group => 'Delimiter');
    ok(defined $token, 'fallback: { detected as Delimiter');
}

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'nonexistent_xyz');
    my $result = $p->parse('(');
    my $token = find_token($result, sub_group => 'Delimiter');
    ok(defined $token, 'fallback: ( detected as Delimiter');
}

#===========================================================================
# User-supplied syntax_dirs
#===========================================================================

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $shb_path = "$tmpdir/fakelang.shb";
    open(my $fh, '>', $shb_path) or die "Cannot create $shb_path: $!";
    print $fh <<'SHB';
language: fakelang
extensions: fk

[keyword:Statement]
fookeyword
SHB
    close($fh);

    my $p = Syntax::Highlight::Basic::Parser->new(
        language    => 'fakelang',
        syntax_dirs => [$tmpdir],
    );
    isa_ok($p, 'Syntax::Highlight::Basic::Parser', 'constructor with custom syntax_dirs');

    my $result = $p->parse('fookeyword');
    my $token = find_token($result, text => 'fookeyword');
    ok(defined $token, 'found fookeyword token');
    ok($token->{class} ne 'text', 'fookeyword is not text (recognized as keyword)');
}

done_testing();