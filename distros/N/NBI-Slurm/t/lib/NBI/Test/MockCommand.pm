package NBI::Test::MockCommand;

use strict;
use warnings;
use Config qw(%Config);
use Exporter qw(import);
use File::Spec;
use File::Path qw(make_path);

our @EXPORT_OK = qw(prepend_mock_path write_mock_command);

sub prepend_mock_path {
    my ($dir) = @_;
    my $sep = $Config{path_sep} || ($^O eq 'MSWin32' ? ';' : ':');
    return join $sep, $dir, ($ENV{PATH} // '');
}

sub write_mock_command {
    my (%args) = @_;
    my $dir    = $args{dir}    or die "dir is required";
    my $name   = $args{name}   or die "name is required";
    my $source = $args{source} or die "source is required";

    make_path($dir) unless -d $dir;

    if ($^O eq 'MSWin32') {
        my $script = File::Spec->catfile($dir, "$name-helper.pl");
        _write_perl_script($script, $source);

        my $wrapper = File::Spec->catfile($dir, "$name.bat");
        open(my $fh, '>', $wrapper) or die "Cannot write $wrapper: $!";
        print {$fh} "\@echo off\r\n";
        print {$fh} '"' . $^X . '" "' . $script . '" %*' . "\r\n";
        close $fh;
        return $wrapper;
    }

    my $script = File::Spec->catfile($dir, $name);
    _write_perl_script($script, $source);
    chmod 0755, $script;
    return $script;
}

sub _write_perl_script {
    my ($path, $source) = @_;
    open(my $fh, '>', $path) or die "Cannot write $path: $!";
    print {$fh} "#!$^X\n";
    print {$fh} "use strict;\nuse warnings;\n";
    print {$fh} $source;
    close $fh;
}

1;
