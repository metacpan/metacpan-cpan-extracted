package Test::Resource::Pack;
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose ();

use FindBin;
use Path::Class;
use File::Temp;
use Cwd;

use Sub::Exporter;
my $import = Sub::Exporter::build_exporter({
    exports => [qw(test_install data_dir exception)],
    groups  => { default => [qw(test_install data_dir exception)] }
});

sub test_install {
    my $installable = shift;
    my $code;
    $code = shift if ref($_[0]) eq 'CODE';
    my (@expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $olddir = getcwd;
    my $dir = File::Temp->newdir;
    chdir $dir;

    ok(!-e $_, "$_ doesn't exist yet") for @expected;
    $installable->install;
    ok(-e $_, "$_ exists!") for @expected;

    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $code->() if $code;
    }

    chdir $olddir;
}

sub data_dir {
    my $script = $0;
    $script =~ s/.*(\d{2})-[\w-]+\.t$/$1/;
    return dir($FindBin::Bin, 'data', $script);
}

sub import {
    Test::More->export_to_level(2);
    Test::Moose->import({into_level => 2});
    Path::Class->export_to_level(2);
    strict->import;
    warnings->import;
    goto $import;
}

1;
