#!perl
use Test::More tests => 29;

use strict;

BEGIN { use_ok( 'Module::Checkstyle' ); } # 1

diag( "Testing Module::Checkstyle $Module::Checkstyle::VERSION" );

# Check that loading of checks works
{
    my $config = <<'END_OF_CONFIG';
[Package]
is-first-statement = 1
END_OF_CONFIG
    
    my $cs = Module::Checkstyle->new(\$config);
    isa_ok($cs, 'Module::Checkstyle'); # 2
    
    ok(exists $cs->{handlers}->{'enter PPI::Document'}); # 3
    ok(exists $cs->{handlers}->{'PPI::Statement::Package'}); # 4
    ok(exists $cs->{handlers}->{'leave PPI::Document'}); # 5

    is(scalar @{$cs->{handlers}->{'PPI::Statement::Package'}}     , 1); # 6
    is(scalar @{$cs->{handlers}->{'PPI::Statement::Package'}->[0]}, 2); # 7
    isa_ok($cs->{handlers}->{'PPI::Statement::Package'}->[0]->[0], 'Module::Checkstyle::Check::Package'); # 8
}

{
    ok(Module::Checkstyle::_any_match("bar", [qr/foo/, qr/bar/, qr/baz/])); # 9
}

# Check that finding files works
{
    my @files = Module::Checkstyle::_get_files('.', 1);
    is(scalar @files, 13); # 10
}

# Check _post_event and _traverse_document
{
    my $cs = Module::Checkstyle->new(\<<'END_OF_CONFIG');
[Test00base1]
END_OF_CONFIG

    $cs->_post_event('enter PPI::Statement::Sub', 1);
    $cs->_post_event('PPI::Token::Symbol',        2);
    $cs->_post_event('leave PPI::Statement::Sub', 3);

    my @problems = $cs->get_problems();
    is(scalar @problems, 3); # 11
    is(shift @problems, 1); # 12
    is(shift @problems, 2); # 13
    is(shift @problems, 3); # 14

    @problems = $cs->flush_problems();
    is(scalar @problems, 3); # 15
    @problems = $cs->get_problems();
    is(scalar @problems, 0); # 16

    my $doc = PPI::Document->new(\<<'END_OF_CODE');
sub enter {
    $x++;
}
END_OF_CODE

    $cs->_traverse_element($doc, "");

    @problems = $cs->get_problems();
    is(scalar @problems, 3); # 17
    is(ref shift @problems, 'PPI::Statement::Sub'); # 18
    is(ref shift @problems, 'PPI::Token::Symbol' ); # 19
    is(ref shift @problems, 'PPI::Statement::Sub'); # 20
}

{
    my $cs = Module::Checkstyle->new(\<<'END_OF_CONFIG');
[Test00base2]
END_OF_CONFIG

    is($cs->check('.'), 12); # 21
    $cs->flush_problems();
    
    is($cs->check('t/00-base.t'), 1); # 22

    $cs->flush_problems();

    my $count = $cs->check('t', { ignore_common => 0 });
    my @problems = grep { /\.t$/ } $cs->get_problems();
    ok($count >= scalar @problems); # 23
}

# Misc tets
{
    my $cs = Module::Checkstyle->new(\q{});
    my $cs2 = $cs->new();
    isa_ok($cs2, 'Module::Checkstyle'); # 24
}

{
    my $cs = Module::Checkstyle->new(\q{[TestEmptyRegister]});
    is(scalar keys %{$cs->{handlers}}, 0); # 25
}

SKIP: {
    eval { require Test::Output; Test::Output->import() };

    skip "Test::Output not installed", 2 if $@;
    
    local $Module::Checkstyle::debug = 1;

    # Should trigger output to STDERR
    stderr_like(
                sub { Module::Checkstyle->new('config'); },
                qr/^Using configuration from:/
            ); # 26

    # Should not trigger output to STDERR
    stderr_unlike(
                  sub { Module::Checkstyle->new(\q{}); },
                  qr/^Using configuration from:/
              ); # 27
}

{
    my $cs = Module::Checkstyle->new(\q{});
    $cs->check(undef);
    is(scalar @{$cs->get_problems()}, 0); # 28

    eval {
        $cs->check('this-should-not-exist');
    };
    if ($@) {
        like($@, qr/does not exist/); # 29
    } else {
        fail('checked an non existing file'); # 29
    }
}

package Module::Checkstyle::Check::TestEmptyRegister;

use base qw(Module::Checkstyle::Check);

sub register {
    return ();
}

package Module::Checkstyle::Check::Test00base1;

use base qw(Module::Checkstyle::Check);

sub register {
    return ('enter PPI::Statement::Sub' => sub { return $_[1]; },
            'PPI::Token::Symbol'        => sub { return $_[1]; },
            'leave PPI::Statement::Sub' => sub { return $_[1]; },
        );
}

package Module::Checkstyle::Check::Test00base2;

use base qw(Module::Checkstyle::Check);

sub register {
    return ('enter PPI::Document' => sub { return $_[2]; });
}

1;
