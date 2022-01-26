#!perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile;

use Perl::Critic::Policy::PreferredModules ();
use Perl::Critic                           ();

my $profile_rc = q[/test/profile.rc];
my $config_ini = q[/test/preferred_modules.ini];

my $mock_profile    = Test::MockFile->file($profile_rc);
my $mock_config_ini = Test::MockFile->file($config_ini);

$mock_profile->contents( <<"EOS" );
severity = 1
verbose  = 8

[PreferredModules]
config = $config_ini
EOS

{
    ok(
        dies {

            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            );

        },
        "Cannot load a policy without a configuration file"
    );
}

$mock_config_ini->contents( <<EOS );
[Do::Not::Recommend]
prefer = Another::Package
reason = Please prefer using Another::Package rather than package Do::Not::Recommend
EOS

my $critic = Perl::Critic->new(
    '-profile'       => $profile_rc,
    '-single-policy' => 'PreferredModules'
);

{
    my @policies = $critic->policies;
    is \@policies, ['PreferredModules'], "only PreferredModules is enabled"
      or diag explain \@policies;
}

{

    $mock_config_ini->contents( <<EOS );
[Do::Not::Recommend]
prefer = Another::Package
reason = Please prefer using Another::Package rather than package Do::Not::Recommend
[Foo]
[Bar]
[OnlyPrefer]
prefer=X
[OnlyReason]
reason=X
EOS

    $critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

}

{    # using invalid args

    $mock_config_ini->contents( <<EOS );
[Do::Not::Recommend]
boom = Unknown arg
EOS

    like(
        dies {
            $critic = Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{Perl::Critic::Policy::PreferredModules Invalid configuration - Package 'Do::Not::Recommend' is using an unknown setting 'boom'},
        "Throw exception on unknown settings"
    );

}

## Shared init

$mock_config_ini->contents( <<EOS );
[FindBin]
prefer = Something::Else
reason = relax this is just a test
[XML::LibXML]
prefer = XML::Simple
[XML::DOM]
EOS

$critic = Perl::Critic->new(
    '-profile'       => $profile_rc,
    '-single-policy' => 'PreferredModules'
);

{
    my $code = <<'EOS';
package My::Package;

use CPAN;

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 0, "nothing critic here";
}

{
    my $code = <<'EOS';
package My::Package;

use FindBin;

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 1, "use FindBin is a violation";

    is(
        _massage_violations(@violations),
        [
            [
                'Prefer using module module Something::Else over FindBin',
                'relax this is just a test'
            ]
        ],
        'violations description & explanation'
    );
}

{
    my $code = <<'EOS';
package My::Package;

require FindBin;

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 1, "require FindBin is a violation";

    is(
        _massage_violations(@violations),
        [
            [
                'Prefer using module module Something::Else over FindBin',
                'relax this is just a test'
            ]
        ],
        'violations description & explanation'
    );
}

{
    my $code = <<'EOS';
package My::Package;

use FindBin;
use Cwd;
use XML::LibXML ();
use XML::DOM    qw( :all );

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 3, "3 violations";

    is(
        _massage_violations(@violations),
        [
            [
                'Prefer using module module Something::Else over FindBin',
                'relax this is just a test'
            ],
            [
                'Prefer using module module XML::Simple over XML::LibXML',
                'Using module XML::LibXML is not recommended'
            ],
            [
                'Using module XML::DOM is not recommended',
                'Using module XML::DOM is not recommended'
            ]
        ],
        'violations description & explanation'
    );
}

done_testing;

sub _massage_violations {
    my (@violations) = @_;

    return [ map { [ $_->description, $_->explanation ] } @violations ];
}

1;
