use v5.26;
use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

sub _write_module {
    my ($base, $module, $content) = @_;

    my @parts = split /::/, $module;
    my $file  = pop @parts;

    my $dir = File::Spec->catdir($base, @parts);
    make_path($dir);

    my $path = File::Spec->catfile($dir, "$file.pm");

    open my $fh, '>:encoding(UTF-8)', $path
        or die "open($path) failed: $!";
    print {$fh} $content
        or die "write($path) failed: $!";
    close $fh
        or die "close($path) failed: $!";

    return $path;
}

sub _require_module {
    my ($module) = @_;

    (my $file = "$module.pm") =~ s{::}{/}g;
    delete $INC{$file};

    local $@;
    my $ok = eval { require $file; 1 };
    my $err = $@;

    return ($ok, $err);
}

my $tmp = tempdir(CLEANUP => 1);
local @INC = ($tmp, @INC);

_write_module(
    $tmp,
    'Local::AlwaysTrue::Flag',
    <<'PERL',
use Modern::Perl::Prelude qw(
    -class
    -utf8
    -always_true
);

class Local::AlwaysTrue::Flag {
    field $name :param;

    method greet {
        return "Hello, $name";
    }
}

0;
PERL
);

my ($ok_flag, $err_flag) = _require_module('Local::AlwaysTrue::Flag');
ok($ok_flag, 'flag-style always_true lets a module load without trailing 1')
    or diag $err_flag;

if ($ok_flag) {
    is(
        Local::AlwaysTrue::Flag->new(name => 'José')->greet,
        'Hello, José',
        'flag-style always_true works for a class module',
    );
}

_write_module(
    $tmp,
    'Local::AlwaysTrue::Hash',
    <<'PERL',
use Modern::Perl::Prelude {
    class       => 1,
    utf8        => 1,
    always_true => 1,
};

class Local::AlwaysTrue::Hash {
    field $name :param;

    method greet {
        return "Hi, $name";
    }
}

0;
PERL
);

my ($ok_hash, $err_hash) = _require_module('Local::AlwaysTrue::Hash');
ok($ok_hash, 'hash-style always_true lets a module load without trailing 1')
    or diag $err_hash;

if ($ok_hash) {
    is(
        Local::AlwaysTrue::Hash->new(name => 'José')->greet,
        'Hi, José',
        'hash-style always_true works for a class module',
    );
}

_write_module(
    $tmp,
    'Local::AlwaysTrue::Disabled',
    <<'PERL',
use Modern::Perl::Prelude {
    class       => 1,
    always_true => 1,
};

no Modern::Perl::Prelude { always_true => 1 };

class Local::AlwaysTrue::Disabled {
    field $name :param;
}

0;
PERL
);

my ($ok_disabled, $err_disabled) = _require_module('Local::AlwaysTrue::Disabled');
ok(!$ok_disabled, 'no Modern::Perl::Prelude { always_true => 1 } restores normal require behavior');
like(
    $err_disabled,
    qr/did not return a true value/,
    'disabled always_true makes the module fail without trailing 1',
);

done_testing;
