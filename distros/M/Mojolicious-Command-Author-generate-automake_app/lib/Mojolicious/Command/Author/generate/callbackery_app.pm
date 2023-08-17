package Mojolicious::Command::Author::generate::callbackery_app;

use Mojo::Base 'Mojolicious::Command::Author::generate::automake_app';
use File::Basename qw(basename dirname);
use Mojo::Util qw(class_to_file class_to_path);
use Mojo::File;

use POSIX qw(strftime);
use Cwd 'getcwd';
use File::Spec::Functions qw(catdir catfile);
our $VERSION = '0.7.4';
has description => 'Generate Callbackery web application with Automake';
has usage => sub { shift->extract_usage };

has defaultName => 'MyCallbackeryApp';
has package => 'callbackery';

sub file {
    my $self = shift;
   
    # Configure Main Dir
    return {
        'configure.ac' => 'configure.ac',
        'bootstrap' => 'bootstrap',
        'cpanfile' => 'cpanfile',
        'VERSION' => 'VERSION',
        'README.md' => 'README.md',
        'AUTHORS' => 'AUTHORS',
        '.gitignore' => '.gitignore',
        '.perlcritic' => '.perlcritic',
        '.github/workflows/unit-tests.yaml' => '.github/workflows/unit-tests.yaml',
        'LICENSE' => 'LICENSE',
        'COPYRIGHT' => 'COPYRIGHT',
        'CHANGES' => 'CHANGES',
        'Makefile.am' => 'Makefile.am',
        'bin/Makefile.am' => 'bin/Makefile.am',
        'thirdparty/Makefile.am' => 'thirdparty/Makefile.am',
        'etc/Makefile.am' => 'etc/Makefile.am',
        'etc/app.dist.yaml' => 'etc/'.$self->filename.'.dist.yaml',
        'bin/app.pl' => 'bin/'.$self->filename.'.pl',
        'bin/source-mode.sh' => 'bin/'.$self->filename.'-source-mode.sh',
        'lib/App.pm' => 'lib/'.$self->class_path,
        'lib/Makefile.am' => 'lib/Makefile.am',
        'lib/App/GuiPlugin/Song.pm' => 'lib/'.$self->class.'/GuiPlugin/Song.pm',
        'lib/App/GuiPlugin/SongForm.pm' => 'lib/'.$self->class.'/GuiPlugin/SongForm.pm',
        'frontend/Makefile.am' => 'frontend/Makefile.am',
        'frontend/Manifest.json' => 'frontend/Manifest.json',
        'frontend/compile.json' => 'frontend/compile.json',
        'frontend/compile.js' => 'frontend/compile.js',
        'frontend/package.json' => 'frontend/package.json',
        'frontend/source/boot/index.html' => 'frontend/source/boot/index.html',
        'frontend/source/class/app/Application.js' => 'frontend/source/class/'.$self->class_file.'/Application.js',
        'frontend/source/class/app/__init__.js' => 'frontend/source/class/'.$self->class_file.'/__init__.js',
        'frontend/source/class/app/theme/Theme.js' => 'frontend/source/class/'.$self->class_file.'/theme/Theme.js',
        't/basic.t' => 't/basic.t',
    };
}

sub finalize {
    my $self = shift;
    my $name = $self->filename;
    $self->chmod_rel_file("$name/bin/".$name."-source-mode.sh", 0755);
    $self->create_rel_dir("$name/frontend/source/resource/$name");
    $self->create_rel_dir("$name/frontend/source/translation");
    $self->SUPER::finalize($name);
}


has search_path => sub {
    my $self = shift;
    my $path = $self->SUPER::search_path();
    my $src = $INC{class_to_path __PACKAGE__};
    return [ dirname($src).'/'.basename($src,'.pm').'/', @$path ];
};

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::calbackery_app - Callbackery App generator command

=head1 SYNOPSIS

  Usage: mojo generate callbackery_app [OPTIONS] [NAME]

    mojo generate callbackery_app
    mojo generate callbackery_app [/full/path/]TestApp

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Authos::generate::callbackery_app> generates application directory structures for fully functional L<Callbackery> applications.

=head1 SEE ALSO

L<Callbackery>, L<https://www.gnu.org/software/automake/>.

=cut
