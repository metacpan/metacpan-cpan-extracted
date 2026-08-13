#!perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw( tempdir );
use File::Spec ();

use Perl::Critic::Policy::PreferredModules ();
use Perl::Critic                           ();

my $tmpdir     = tempdir( CLEANUP => 1 );
my $profile_rc = File::Spec->catfile( $tmpdir, 'profile.rc' );
my $config_ini = File::Spec->catfile( $tmpdir, 'preferred_modules.ini' );

sub _write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
}

# Fixture modules for the export inspection tests, so the results do not depend
# on what happens to be installed.
my $lib_dir = File::Spec->catdir( $tmpdir, 'lib' );
mkdir $lib_dir                                     or die "Cannot mkdir $lib_dir: $!";
mkdir File::Spec->catdir( $lib_dir, 'TestRand' )   or die "Cannot mkdir: $!";
unshift @INC, $lib_dir;

sub _write_module {
    my ( $name, $body ) = @_;

    my @parts = split m{::}, "$name.pm";
    _write_file( File::Spec->catfile( $lib_dir, @parts ), <<"EOS" );
package $name;
use strict;
use warnings;
use Exporter 'import';
sub rand  { return 4 }
sub irand { return 4 }
$body
1;
EOS

    return;
}

_write_module( 'TestRand::Default',   'our \@EXPORT = qw(rand); our \@EXPORT_OK = qw(irand);' );
_write_module( 'TestRand::OnRequest', <<'EOS' );
our @EXPORT = qw();
our @EXPORT_OK = qw(rand irand);
our %EXPORT_TAGS = ( all => [qw(rand irand)] );
EOS

# will not load, so its exports can only be read by parsing the source
_write_module( 'TestRand::Unloadable',    'our @EXPORT = qw(rand); die "boom";' );
_write_module( 'TestRand::UnloadableOnly', <<'EOS' );
our @EXPORT = qw();
our @EXPORT_OK = ( 'rand' );
die "boom";
EOS

_write_file( $profile_rc, <<"EOS" );
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

_write_file( $config_ini, <<EOS );
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

    _write_file( $config_ini, <<EOS );
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

    _write_file( $config_ini, <<EOS );
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

{    # using invalid INI syntax

    _write_file( $config_ini, <<EOS );
[Do::Not::Recommend
this is not valid INI
EOS

    like(
        dies {
            $critic = Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{Perl::Critic::Policy::PreferredModules Invalid configuration file},
        "Throw exception on invalid INI content"
    );

}

## Shared init

_write_file( $config_ini, <<EOS );
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
                'Prefer using module Something::Else over FindBin',
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
                'Prefer using module Something::Else over FindBin',
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
                'Prefer using module Something::Else over FindBin',
                'relax this is just a test'
            ],
            [
                'Prefer using module XML::Simple over XML::LibXML',
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

{
    note "'no Module' should not trigger violations";

    my $code = <<'EOS';
package My::Package;

no FindBin;

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 0, "no FindBin does not trigger a violation";
}

{
    note "'no' and 'use' of same module";

    my $code = <<'EOS';
package My::Package;

use FindBin;
no FindBin;

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 1, "only 'use' triggers, not 'no'";
}

# severity override tests

{
    note "severity override per module";

    _write_file( $config_ini, <<EOS );
[FindBin]
prefer = Something::Else
reason = relax this is just a test
severity = 5
[XML::LibXML]
prefer = XML::Simple
[XML::DOM]
severity = 1
EOS

    my $sev_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;

use FindBin;

1;
EOS

        my @violations = $sev_critic->critique( \$code );
        is scalar @violations => 1, "FindBin violation with severity override";
        is $violations[0]->severity, 5, "severity overridden to 5 for FindBin";
    }

    {
        my $code = <<'EOS';
package My::Package;

use XML::DOM;

1;
EOS

        my @violations = $sev_critic->critique( \$code );
        is scalar @violations => 1, "XML::DOM violation with severity override";
        is $violations[0]->severity, 1, "severity overridden to 1 for XML::DOM";
    }

    {
        my $code = <<'EOS';
package My::Package;

use XML::LibXML;

1;
EOS

        my @violations = $sev_critic->critique( \$code );
        is scalar @violations => 1, "XML::LibXML violation without severity override";
        is $violations[0]->severity, 3, "default severity (3) for XML::LibXML";
    }
}

{
    note "invalid severity value";

    _write_file( $config_ini, <<EOS );
[Bad::Module]
severity = 9
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{invalid severity '9'},
        "Throw exception on invalid severity value"
    );
}

# message override tests

{
    note "message key replaces auto-generated description";

    _write_file( $config_ini, <<EOS );
[FindBin]
prefer = Something::Else
reason = relax this is just a test
message = Do not use FindBin - see internal wiki
EOS

    my $msg_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use FindBin;

1;
EOS

    my @violations = $msg_critic->critique( \$code );
    is scalar @violations => 1, "FindBin violation with message override";

    is(
        _massage_violations(@violations),
        [
            [
                'Do not use FindBin - see internal wiki',
                'relax this is just a test'
            ]
        ],
        'message overrides auto-generated description, reason still used as explanation'
    );
}

{
    note "message key without prefer or reason";

    _write_file( $config_ini, <<EOS );
[Bad::Module]
message = This module is forbidden by policy
EOS

    my $msg_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use Bad::Module;

1;
EOS

    my @violations = $msg_critic->critique( \$code );
    is scalar @violations => 1, "Bad::Module violation with message only";

    is(
        _massage_violations(@violations),
        [
            [
                'This module is forbidden by policy',
                'Using module Bad::Module is not recommended'
            ]
        ],
        'message replaces description, default explanation used when no reason'
    );
}

{
    note "message key combined with severity override";

    _write_file( $config_ini, <<EOS );
[Dangerous::Module]
message = CRITICAL: Do not use this module
severity = 5
EOS

    my $msg_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use Dangerous::Module;

1;
EOS

    my @violations = $msg_critic->critique( \$code );
    is scalar @violations => 1, "Dangerous::Module violation with message + severity";
    is $violations[0]->severity, 5, "severity override works with message";

    is(
        _massage_violations(@violations),
        [
            [
                'CRITICAL: Do not use this module',
                'Using module Dangerous::Module is not recommended'
            ]
        ],
        'message and severity work together'
    );
}

{
    note "non-numeric severity value";

    _write_file( $config_ini, <<EOS );
[Bad::Module]
severity = high
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{invalid severity 'high'},
        "Throw exception on non-numeric severity value"
    );
}

SKIP: {
    skip "chmod has no effect for root", 1 if $> == 0;

    note "unreadable config file";

    my $unreadable = File::Spec->catfile( $tmpdir, 'unreadable.ini' );
    _write_file( $unreadable, "[Foo]\n" );
    chmod 0000, $unreadable;

    my $unreadable_rc = File::Spec->catfile( $tmpdir, 'unreadable.rc' );
    _write_file( $unreadable_rc, <<"EOS" );
severity = 1
[PreferredModules]
config = $unreadable
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $unreadable_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{Cannot open config file},
        "Throw exception when config file is unreadable"
    );

    chmod 0644, $unreadable;    # restore for cleanup
}

{
    note "Config::INI root section ignored";

    _write_file( $config_ini, <<EOS );
reason = global default

[FindBin]
prefer = Something::Else
reason = use Something::Else instead
EOS

    my $root_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;

use _;

1;
EOS

        my @violations = $root_critic->critique( \$code );
        is scalar @violations => 0,
          "root section '_' from Config::INI is not treated as a module";
    }

    {
        my $code = <<'EOS';
package My::Package;

use FindBin;

1;
EOS

        my @violations = $root_critic->critique( \$code );
        is scalar @violations => 1, "named sections still match normally";
    }
}

{
    note "multiple config errors reported together";

    _write_file( $config_ini, <<EOS );
[Alpha::Module]
boom = bad option
severity = 99

[Beta::Module]
fizz = another bad option
EOS

    my $err = dies {
        Perl::Critic->new(
            '-profile'       => $profile_rc,
            '-single-policy' => 'PreferredModules'
        )
    };
    ok $err, "Throws on multiple config errors";
    like $err, qr{Alpha::Module.*unknown setting 'boom'},
        "Reports unknown setting for Alpha";
    like $err, qr{Alpha::Module.*invalid severity '99'},
        "Reports invalid severity for Alpha";
    like $err, qr{Beta::Module.*unknown setting 'fizz'},
        "Reports unknown setting for Beta";
}

# parent/base module argument checking

{
    note "use parent module checking";

    _write_file( $config_ini, <<EOS );
[Banned::Parent]
prefer = Good::Parent
reason = Banned::Parent has issues
[Another::Bad]
EOS

    my $parent_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;
use parent 'Banned::Parent';
1;
EOS

        my @violations = $parent_critic->critique( \$code );
        is scalar @violations => 1, "use parent catches banned module in arguments";
        like $violations[0]->description, qr/Banned::Parent/, "violation mentions the parent module";
    }

    {
        my $code = <<'EOS';
package My::Package;
use base 'Banned::Parent';
1;
EOS

        my @violations = $parent_critic->critique( \$code );
        is scalar @violations => 1, "use base catches banned module in arguments";
    }

    {
        my $code = <<'EOS';
package My::Package;
use parent qw(Banned::Parent Another::Bad);
1;
EOS

        my @violations = $parent_critic->critique( \$code );
        is scalar @violations => 2, "use parent qw() catches multiple banned parents";
    }

    {
        my $code = <<'EOS';
package My::Package;
use parent -norequire, 'Banned::Parent';
1;
EOS

        my @violations = $parent_critic->critique( \$code );
        is scalar @violations => 1, "use parent -norequire still catches banned parent";
    }

    {
        my $code = <<'EOS';
package My::Package;
use parent 'Safe::Module';
1;
EOS

        my @violations = $parent_critic->critique( \$code );
        is scalar @violations => 0, "use parent with non-banned module is fine";
    }

    {
        my $code = <<'EOS';
package My::Package;
use parent 'Banned::Parent', 'Safe::Module';
1;
EOS

        my @violations = $parent_critic->critique( \$code );
        is scalar @violations => 1, "use parent with mix of banned and safe catches only banned";
    }
}

# partial preferences: the 'for' key

{
    note "partial preference using 'for'";

    _write_file( $config_ini, <<EOS );
[File::Slurper]
prefer = File::Slurper::Temp
for = write_binary write_text
reason = File::Slurper::Temp writes atomically
EOS

    my $for_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper qw{ write_text };

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 1, "importing a listed function is a violation";

        is(
            _massage_violations(@violations),
            [
                [
                    'Prefer using module File::Slurper::Temp over File::Slurper for write_binary, write_text',
                    'File::Slurper::Temp writes atomically'
                ]
            ],
            'violation mentions the functions it applies to'
        );
    }

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper qw{ read_text read_binary };

my $content = read_text($file);

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 0, "importing only unlisted functions is fine";
    }

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper qw{ read_text write_binary };

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 1, "a single listed function among others is a violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper 'write_text';

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 1, "quoted import list is honored";
    }

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper;

write_text( $file, $content );

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 1, "call to a listed function without an import list is a violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

require File::Slurper;

File::Slurper::write_binary( $file, $content );

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 1, "fully qualified call to a listed function is a violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper;

my $content = File::Slurper::read_text($file);

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 0, "no listed function used, no violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

use File::Slurper ();

my $obj = Some::Object->write_text($file);

1;
EOS

        my @violations = $for_critic->critique( \$code );
        is scalar @violations => 0, "a method call is not a function call";
    }
}

{
    note "'for' without prefer";

    _write_file( $config_ini, <<EOS );
[XML::LibXML]
for = parse_html_string
EOS

    my $for_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use XML::LibXML qw{ parse_html_string };

1;
EOS

    my @violations = $for_critic->critique( \$code );
    is scalar @violations => 1, "'for' works without a prefer entry";

    is(
        _massage_violations(@violations),
        [
            [
                'Using module XML::LibXML is not recommended for parse_html_string',
                'Using module XML::LibXML is not recommended'
            ]
        ],
        'violation description'
    );
}

{
    note "comma separated 'for' list";

    _write_file( $config_ini, <<EOS );
[File::Slurper]
prefer = File::Slurper::Temp
for = write_binary, write_text
EOS

    my $for_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use File::Slurper qw{ write_binary };

1;
EOS

    my @violations = $for_critic->critique( \$code );
    is scalar @violations => 1, "comma separated list is honored";
}

{
    note "empty 'for' value";

    _write_file( $config_ini, <<EOS );
[Bad::Module]
for =
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{has an empty 'for' list},
        "Throw exception on an empty 'for' list"
    );
}

# preferring a module over a builtin function: [perl/<function>]

{
    note "prefer a module over a builtin function";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = Crypt::PRNG
reason = the builtin rand is not cryptographically secure
[perl/sleep]
prefer = Time::HiRes
EOS

    my $builtin_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;

my $x = rand();

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 1, "calling the builtin rand is a violation";

        is(
            _massage_violations(@violations),
            [
                [
                    'Prefer using Crypt::PRNG::rand over the builtin rand',
                    'the builtin rand is not cryptographically secure'
                ]
            ],
            'violation description & explanation'
        );
    }

    {
        my $code = <<'EOS';
package My::Package;

my $x = rand;

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 1, "a call without parentheses is a violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

sleep 1;
my $x = rand(10);

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 2, "multiple [perl/...] sections are all honored";

        is(
            [ map { $_->description } @violations ],
            [
                'Prefer using Time::HiRes::sleep over the builtin sleep',
                'Prefer using Crypt::PRNG::rand over the builtin rand',
            ],
            'one violation per configured builtin'
        );
    }

    {
        my $code = <<'EOS';
package My::Package;

use Crypt::PRNG qw{ rand };

my $x = rand();

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 0, "importing the preferred implementation clears the violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

use Crypt::PRNG ();

my $x = rand();

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 1, "`use Module ()` imports nothing, so the builtin is still used";
    }

    {
        my $code = <<'EOS';
package My::Package;

use Crypt::PRNG qw{ irand };

my $x = rand();

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 1, "importing another function does not clear the violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

my $x = $prng->rand();
my %h = ( rand => 1, sleep => 2 );

sub rand_helper { return 42 }

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 0, "method calls, hash keys and sub names are not builtin calls";
    }

    {
        my $code = <<'EOS';
package My::Package;

my $x = Crypt::PRNG::rand();

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 0, "a fully qualified call does not match a [perl/...] section";
    }

    {
        my $code = <<'EOS';
package My::Package;

sub roll {
    return rand();
}

use Crypt::PRNG qw{ rand };

1;
EOS

        my @violations = $builtin_critic->critique( \$code );
        is scalar @violations => 0, "the import is looked up document wide, not per scope";
    }
}

{
    note "a bare use only silences the violation when the function is exported by default";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::Default
EOS

    my $default_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use TestRand::Default;

my $x = rand();

1;
EOS

    my @violations = $default_critic->critique( \$code );
    is scalar @violations => 0, "rand is in \@EXPORT, so a bare use does provide it";
}

{
    note "a module that exports the function on request only";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::OnRequest
EOS

    my $on_request_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;

use TestRand::OnRequest;

my $x = rand();

1;
EOS

        my @violations = $on_request_critic->critique( \$code );
        is scalar @violations => 1, "a bare use does not provide a function that is not in \@EXPORT";

        is(
            _massage_violations(@violations),
            [
                [
                    'Prefer using TestRand::OnRequest::rand over the builtin rand',
                    'TestRand::OnRequest exports rand on request only, so this call is still the builtin'
                      . ' - import it explicitly with `use TestRand::OnRequest qw{ rand }`'
                ]
            ],
            'the explanation says what went wrong and how to fix it'
        );
    }

    {
        my $code = <<'EOS';
package My::Package;

use TestRand::OnRequest qw{ rand };

my $x = rand();

1;
EOS

        my @violations = $on_request_critic->critique( \$code );
        is scalar @violations => 0, "importing it explicitly clears the violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

use TestRand::OnRequest qw{ :all };

my $x = rand();

1;
EOS

        my @violations = $on_request_critic->critique( \$code );
        is scalar @violations => 0, "an export tag covering the function clears the violation";
    }

    {
        my $code = <<'EOS';
package My::Package;

use TestRand::OnRequest qw{ :nonesuch };

my $x = rand();

1;
EOS

        my @violations = $on_request_critic->critique( \$code );
        is scalar @violations => 0, "an unknown tag is assumed to cover the function";
    }

    {
        my $code = <<'EOS';
package My::Package;

use TestRand::OnRequest qw{ irand };

my $x = rand();

1;
EOS

        my @violations = $on_request_critic->critique( \$code );
        is scalar @violations => 1, "importing a different function does not clear the violation";
    }
}

{
    note "a module that cannot be loaded is read from its source";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::Unloadable
EOS

    my $unloadable_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use TestRand::Unloadable;

my $x = rand();

1;
EOS

    my @violations = $unloadable_critic->critique( \$code );
    is scalar @violations => 0, "\@EXPORT is parsed out of a module that will not load";
}

{
    note "a module that cannot be loaded and does not export by default";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::UnloadableOnly
EOS

    my $unloadable_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use TestRand::UnloadableOnly;

my $x = rand();

1;
EOS

    my @violations = $unloadable_critic->critique( \$code );
    is scalar @violations => 1, "parsing the source also catches the on-request case";
}

{
    note "a module whose exports cannot be resolved at all";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::NoSuchModule
EOS

    my $unknown_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use TestRand::NoSuchModule;

my $x = rand();

1;
EOS

    my @violations = $unknown_critic->critique( \$code );
    is scalar @violations => 0, "an unresolvable module is assumed to export the function";
}

{
    note "builtin preference without prefer, and severity override";

    _write_file( $config_ini, <<EOS );
[perl/each]
reason = iterating with each() is error prone
severity = 4
EOS

    my $builtin_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

while ( my ( $k, $v ) = each(%h) ) { }

1;
EOS

    my @violations = $builtin_critic->critique( \$code );
    is scalar @violations => 1, "a builtin can be discouraged without a preferred module";

    is(
        _massage_violations(@violations),
        [
            [
                'Using the builtin each is not recommended',
                'iterating with each() is error prone'
            ]
        ],
        'violation description & explanation'
    );

    is $violations[0]->severity, 4, "severity override applies to builtin sections";
}

{
    note "module and builtin preferences side by side";

    _write_file( $config_ini, <<EOS );
[FindBin]
prefer = Something::Else
[perl/rand]
prefer = Crypt::PRNG
EOS

    my $mixed_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use FindBin;

my $x = rand();

1;
EOS

    my @violations = $mixed_critic->critique( \$code );
    is scalar @violations => 2, "module and builtin sections coexist";
}

{
    note "a bare [perl] section";

    _write_file( $config_ini, <<EOS );
[perl]
prefer = Crypt::PRNG
for = rand
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{use a '\[perl/<function>\]' section to prefer a module over a builtin function},
        "Throw exception pointing at the right spelling"
    );
}

{
    note "'for' inside a [perl/...] section";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = Crypt::PRNG
for = rand
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{Package 'perl/rand' is using an unknown setting 'for'},
        "'for' is not a valid setting for a builtin section"
    );
}

{
    note "invalid severity inside a [perl/...] section";

    _write_file( $config_ini, <<EOS );
[perl/rand]
severity = 9
EOS

    like(
        dies {
            Perl::Critic->new(
                '-profile'       => $profile_rc,
                '-single-policy' => 'PreferredModules'
            )
        },
        qr{Package 'perl/rand' has invalid severity '9'},
        "severity is validated in builtin sections too"
    );
}


# loading a module to inspect its exports is unsafe

{
    note "a config that has to load modules requires -allow-unsafe";

    # -single-policy bypasses the safety check, so ask for the policy by name
    sub _load_policy {
        my (%extra) = @_;

        my $critic = Perl::Critic->new(
            '-profile' => $profile_rc,
            '-only'    => 1,
            '-include' => ['PreferredModules'],
            %extra,
        );

        return scalar $critic->policies;
    }

    _write_file( $config_ini, <<EOS );
[FindBin]
prefer = Something::Else
EOS

    is _load_policy() => 1, "module preferences alone are safe";

    _write_file( $config_ini, <<EOS );
[perl/rand]
reason = just do not
EOS

    is _load_policy() => 1, "a builtin section without prefer never loads anything";

    _write_file( $config_ini, <<EOS );
[FindBin]
prefer = Something::Else
[perl/rand]
prefer = TestRand::OnRequest
EOS

    is _load_policy() => 0, "preferring a module over a builtin is unsafe";
    is _load_policy( '-allow-unsafe' => 1 ) => 1, "-allow-unsafe loads it";
}

{
    note "the configuration is read and parsed once";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::Default
EOS

    my $parses = 0;
    my $reader = \&Config::INI::Reader::read_string;

    no warnings 'redefine';
    local *Config::INI::Reader::read_string = sub { $parses++; return $reader->(@_) };
    use warnings 'redefine';

    # is_safe() asks for the configuration before initialize_if_enabled does
    Perl::Critic->new(
        '-profile'      => $profile_rc,
        '-only'         => 1,
        '-include'      => ['PreferredModules'],
        '-allow-unsafe' => 1,
    );

    is $parses => 1, "the INI file is parsed once, not once per caller";
}

{
    note "the policy still works when unsafe is allowed";

    _write_file( $config_ini, <<EOS );
[perl/rand]
prefer = TestRand::OnRequest
EOS

    my $critic = Perl::Critic->new(
        '-profile'      => $profile_rc,
        '-only'         => 1,
        '-include'      => ['PreferredModules'],
        '-allow-unsafe' => 1,
    );

    my $code = <<'EOS';
package My::Package;

use TestRand::OnRequest;

my $x = rand();

1;
EOS

    my @violations = $critic->critique( \$code );
    is scalar @violations => 1, "the export check runs once unsafe is allowed";
}

# use if conditional loading tests

{
    note "use if detection with quoted module name";

    _write_file( $config_ini, <<EOS );
[Some::Module]
prefer = Better::Module
reason = Some::Module is deprecated
EOS

    my $if_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    {
        my $code = <<'EOS';
package My::Package;

use if $] >= 5.010, "Some::Module";

1;
EOS

        my @violations = $if_critic->critique( \$code );
        is scalar @violations => 1, "use if with double-quoted module is a violation";

        is(
            _massage_violations(@violations),
            [
                [
                    'Prefer using module Better::Module over Some::Module',
                    'Some::Module is deprecated'
                ]
            ],
            'use if violation has correct description and explanation'
        );
    }

    {
        my $code = <<'EOS';
package My::Package;

use if $^O eq 'linux', 'Some::Module';

1;
EOS

        my @violations = $if_critic->critique( \$code );
        is scalar @violations => 1, "use if with single-quoted module is a violation";
    }
}

{
    note "use if with bare word module name";

    _write_file( $config_ini, <<EOS );
[Foo::Bar]
reason = Foo::Bar is banned
EOS

    my $if_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use if 1, Foo::Bar;

1;
EOS

    my @violations = $if_critic->critique( \$code );
    is scalar @violations => 1, "use if with bare word module is a violation";
}

{
    note "use if with import list";

    _write_file( $config_ini, <<EOS );
[Win32::Console]
prefer = Term::ANSIColor
reason = Not portable
EOS

    my $if_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use if $^O eq 'MSWin32', 'Win32::Console', qw( STD_OUTPUT_HANDLE );

1;
EOS

    my @violations = $if_critic->critique( \$code );
    is scalar @violations => 1, "use if with import list is a violation";
}

{
    note "use if with severity override";

    _write_file( $config_ini, <<EOS );
[Dangerous::Module]
severity = 5
reason = Known security issue
EOS

    my $sev_if_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use if $ENV{DANGER}, "Dangerous::Module";

1;
EOS

    my @violations = $sev_if_critic->critique( \$code );
    is scalar @violations => 1, "use if violation with severity override";
    is $violations[0]->severity, 5, "severity override applies to use if modules";
}

{
    note "use if with unconfigured module is not a violation";

    _write_file( $config_ini, <<EOS );
[Bad::Module]
reason = This one is bad
EOS

    my $if_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use if 1, "Good::Module";

1;
EOS

    my @violations = $if_critic->critique( \$code );
    is scalar @violations => 0, "use if with unconfigured module is not a violation";
}

{
    note "regular use of 'if' pragma is not flagged when 'if' is not configured";

    _write_file( $config_ini, <<EOS );
[Something::Else]
reason = do not use
EOS

    my $if_critic = Perl::Critic->new(
        '-profile'       => $profile_rc,
        '-single-policy' => 'PreferredModules'
    );

    my $code = <<'EOS';
package My::Package;

use if $] >= 5.010, "Safe::Module";

1;
EOS

    my @violations = $if_critic->critique( \$code );
    is scalar @violations => 0, "use if with non-configured module is fine";
}

done_testing;

sub _massage_violations {
    my (@violations) = @_;

    return [ map { [ $_->description, $_->explanation ] } @violations ];
}

1;
