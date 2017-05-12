use inc::Module::Install;
use File::Spec;

name 'OptArgs';
version '0.1.20';
all_from 'lib/OptArgs.pm';
readme_from 'lib/OptArgs.pm';

build_requires 'File::Spec' => 0;

requires 'Carp'           => 0;
requires 'Encode'         => 2.24;
requires 'Exporter::Tidy' => 0;
requires 'Getopt::Long'   => 2.37;
requires 'I18N::Langinfo' => 0 if $^O ne 'MSWin32';
requires 'List::Util'     => 0;
requires 'Text::Abbrev'   => 0;

test_requires 'IO::Capture::Stdout';
test_requires 'POSIX';
test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::Output';

perl_version '5.006';

author_tests 'xt';

install_script 'bin/optargs';

no_index package => 'OptArgs::Usage';
no_index package => 'Getopt::Args::Usage';

repository 'https://github.com/mlawren/p5-OptArgs';

WriteAll;

# Duplicate OptArgs as Getopt::Args for easy discoverability

my $src;
{
    open my $fh, '<', File::Spec->catfile(qw/lib OptArgs.pm/);
    local $/ = undef;
    $src = <$fh>;
}

$src =~ s/Getopt::Args/GETOPT::ARGS/g;
$src =~ s/OptArgs/Getopt::Args/g;
$src =~ s/p5-Getopt::Args/p5-OptArgs/g;
$src =~ s/GETOPT::ARGS/OptArgs/g;

mkdir File::Spec->catdir(qw/lib Getopt/);
open my $fh, '>', File::Spec->catfile(qw/lib Getopt Args.pm/);
print $fh $src;
close $fh;
