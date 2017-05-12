package Path::Maker;
use 5.008005;
use strict;
use warnings;
use Carp qw(croak);
use Cwd qw(getcwd);
use File::Path qw(mkpath);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir catfile file_name_is_absolute);

our $VERSION = "0.004";

{
    package
        Text::MicroTemplate::DataSection::WithHeader;
    use Carp 'croak';
    use Data::Section::Simple;
    use File::Spec::Functions qw(catfile);
    use parent 'Text::MicroTemplate::File';

    sub new {
        my ($class, @arg) = @_;
        my $self = $class->SUPER::new(@arg);
        $self->{package} ||= scalar caller;
        $self->{section} = Data::Section::Simple->new( $self->{package} );
        $self;
    }
    sub _find_data {
        my ($self, $file) = @_;
        if (my $data = $self->{section}->get_data_section($file)) {
            $data =~ s{\n{2}$}{\n};
            return $data;
        } elsif ($self->{template_dir}) {
            return $self->_slurp( catfile($self->{template_dir}, $file) );
        } else {
            return;
        }
    }
    # taken from Text::MicroTemplate::DataSection::build_file()
    sub build_file {
        my ($self, $file) = @_;
        if (my $e = $self->{cache}{$file}) {
            return $e;
        }
        my $data = $self->_find_data($file);
        if (!$data) {
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            croak "could not find template file '$file'"
                . " in __DATA__ section of $self->{package}"
                . ($self->{template_dir} ? ' nor in ' . $self->{template_dir} : '');
        }
        $data = $self->{template_header} . $data if $self->{template_header};
        $self->parse($data); # XXX assume $data is decoded
        local $Text::MicroTemplate::_mt_setter = 'my $_mt = shift;';
        my $f = $self->build;
        $self->{cache}{$file} = $f if $self->{use_cache};
        return $f;
    }
    sub _slurp {
        my (undef, $file) = @_;
        open my $fh, "<:utf8", $file or return;
        local $/;
        scalar <$fh>;
    }
}

sub new {
    my $class = shift;
    my %opt   = ref $_[0] ? %{ $_[0] } : @_;
    my $base_dir = delete $opt{base_dir};
    my $data_section = Text::MicroTemplate::DataSection::WithHeader->new(
        package => scalar(caller),
        %opt,
    );
    bless {
        base_dir => $base_dir,
        data_section => $data_section
    }, $class;
}

sub _abs_path {
    my ($self, $path) = @_;
    return $path if file_name_is_absolute $path;
    return catdir( $self->{base_dir} || getcwd, $path );
}

sub render {
    my ($self, $template_name, @arg) = @_;
    $self->{data_section}->render_file($template_name, @arg);
}
sub chmod : method {
    my ($self, $path, $mod) = @_;
    $path = $self->_abs_path($path);
    my $oct_mod = sprintf '%lo', $mod;
    chmod $mod, $path or croak "chmod $oct_mod $path: $!";
}
sub create_dir {
    my ($self, $dir) = @_;
    $dir = $self->_abs_path($dir);
    return if -d $dir;
    mkpath $dir or croak "mkpath $dir: $!";
}
sub render_to_file {
    my ($self, $template_name, $file, @arg) = @_;
    $file = $self->_abs_path($file);
    my $dir = dirname $file;
    $self->create_dir($dir);
    $self->write_file( $file, $self->render($template_name, @arg) );
}
sub write_file {
    my ($self, $file, $string) = @_;
    $file = $self->_abs_path($file);
    open my $fh, ">:utf8", $file or croak "open $file: $!";
    print {$fh} $string;
}

1;
__END__

=encoding utf-8

=head1 NAME

Path::Maker - make files and directories as scaffolding

=head1 SYNOPSIS

    use Path::Maker;

    my $maker = Path::Maker->new(base_dir => $ENV{HOME});
    $maker->render_to_file('gitconfig.mt' => '.gitconfig', $ENV{USER});
    $maker->create_dir('.swap');
    $maker->write_file('.vimrc', "set directory=~/.swap\n");
    $maker->chmod('.ssh/id_rsa', 0400);

    __DATA__

    @@ gitconfig.mt
    [user]
        name = <?= $_[0] ?>

=head1 DESCRIPTION

Path::Maker helps you make files or directories
as scaffolding.
When I wrote a CLI script for mojo,
I found that L<Mojolicious::Command> is very useful.
This module provides some functionality of that module with
template syntax L<Text::MicroTemplate>.

=head2 CONSTRUCTOR

Constructor C<< $maker = Path::Maker->new(%options) >> accepts following options:

=over 4

=item base_dir

If relative path is specified to methods C<chmod>, C<create_dir>,
C<render_to_file> or C<write_file>, then it is assumed to relative to the C<base_dir>.
Default: current working directory.

=item package

Whose C<__DATA__> section to be read.
Default: C<caller>.

=item template_header

If C<template_header> is provided, it is inserted to every template files.
See C<eg/template-header.pl> for example.

=item template_dir

By default, Path::Maker searches for template files in
C<__DATA__> section.
If C<template_dir> is provided, it also searches for template files in
C<template_dir>. See C<eg/module-scaffold.pl> for example.

=back

=head2 METHOD

=over 4

=item C<< $maker->chmod($path, $mode) >>

Change permission of C<$path>.

=item C<< $maker->create_dir($dir) >>

Create directory C<$dir>.

=item C<< $string = $maker->render($template_name, @arg) >>

Render C<$template_name> with C<@arg>.

=item C<< $maker->render_to_file($template_name, $file, @arg) >>

Render C<$template_name> to C<$file> with C<@arg>.

=item C<< $maker->write_file($file, $string) >>

Write C<$string> to C<$file>.

=back

=head1 SEE ALSO

L<Mojolicious::Command>

L<Text::MicroTemplate>

L<Text::MicroTemplate::DataSection>

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

