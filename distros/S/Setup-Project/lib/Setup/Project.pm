package Setup::Project;
use 5.008001;
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Path qw(mkpath);
use File::Find::Rule;
use File::Slurp qw(write_file);
use File::Spec::Functions qw(catfile rel2abs);
use Text::Xslate ();
use IO::Prompt::Simple qw(prompt);
use Setup::Project::Functions;
use Module::CPANfile;

use Class::Accessor::Lite (
    rw => [qw/dry_run force_run/],
    ro => [qw/xslate/]
);

our $VERSION = "0.01";

sub new {
    my ($class, %args) = @_;

    my $write_dir = rel2abs($args{write_dir} || '.');
    my $tmpl_dir  = $args{tmpl_dir};

    my $xslate = Text::Xslate->new(
        syntax     => 'Kolon',
        type       => 'text',
        tag_start  => '<%',
        tag_end    => '%>',
        line_start => '%%',
        cache      => 0,
        path       => [ $tmpl_dir ],
        module     => [
            'Text::Xslate::Bridge::Star',
        ],
        function   => {
            syntax => sub { "<% $_[0] %>" },
        }
    );

    my $self = bless {
        file_vars     => {},
        filename_vars => {},
        dry_run       => 0,
        tmpl_dir      => $tmpl_dir,
        write_dir     => $write_dir,
        xslate        => $xslate,
        force_run     => 0,
    }, $class;

}

sub safely_run {
    my ($self, $code) = @_;
    my $stored = $self->dry_run;
    $self->dry_run(1);
    $code->();

    unless ( prompt "Do you want to do?" => { yn => 1, default => 'n' } ) {
        $self->infof('abort');
        return;
    }

    $self->dry_run(0);
    $code->();
    $self->dry_run($stored);
}

sub file_vars {
    my ($self, %args) = @_;
    $self->{file_vars} = {
        time => date(),
        %args,
    };
}

sub filename_vars {
    my ($self, %args) = @_;
    $self->{filename_vars} = {
        %args,
    };
}

sub run_cmd {
    my ($self, @args) = @_;
    $self->infof('[%s] %s', $self->{write_dir}, join q{ }, @args);
    return if $self->dry_run;
    chdir $self->{write_dir};
    !system @args or die "command failed: $?";
}

sub infof {
    my ($self, @args) = @_;
    print "[dry-run] " if $self->dry_run;
    @args==1 ? print(@args) : printf(@args);
    print "\n";
}

sub chmod_recursive {
    my ($self, $mode, $path) = @_;

    $path = $self->_to_dst_file($path);

    if ($self->dry_run) {
        $self->infof("chmod_recursive $path");
        return;
    }

    File::Find::find(sub {
        my $name = $File::Find::name;
        return unless -f $name;
        $self->infof("chmod $mode $name");
        return if $self->dry_run;
        chmod oct($mode), $name;
    }, $path);
}

sub render_file {
    my ($self, $src_filename) = @_;
    my $content = $self->_render_content($src_filename);
    my $dst_filename = $self->_to_dst_file($src_filename);
    $self->_write_file($dst_filename, $content);
}

sub render_all_files {
    my $self = shift;
    my $dir = $self->{tmpl_dir};

    my @files = File::Find::Rule->file()->in($dir);
    for my $file (@files) {
        $file =~ s|$dir/||g;
        $self->render_file($file);
    }
}

sub cpanfile {
    my ($self, $filename, $args) = @_;


    my $dst_cpanfile = $self->_to_dst_file($filename);
    my $cpanfile;
    if ( -f $dst_cpanfile ) {
        $cpanfile = Module::CPANfile->load($dst_cpanfile);
    } else {
        $cpanfile = Module::CPANfile->from_prereqs();
    }

    my $prereqs = $cpanfile->{_prereqs};
    for my $phase (qw/runtime configure build test develop/) {

        while (my($module, $version) = each %{ $args->{$phase} }) {
            $prereqs->add_prereq(
                phase => $phase,
                type  => 'requires',
                module => $module,
                requirement => Module::CPANfile::Requirement->new(name => $module, version => $version),
            );
        }
    }

    if (!$self->dry_run && -f $filename && !$self->force_run) {
        unless ( prompt "Do you want to concat? : $filename" => { yn => 1, default => 'n' } ) {
            return;
        }
    }
    $self->_mkdir(dirname($dst_cpanfile));
    $self->_write($dst_cpanfile, $cpanfile->to_string);
}

sub _write_file {
    my ($self, $filename, $content, $input_mode) = @_;

    if (!$self->dry_run && -f $filename && !$self->force_run) {
        unless ( prompt "Do you want to override? : $filename" => { yn => 1, default => 'n' } ) {
            return;
        }
    }

    $self->_mkdir(dirname($filename));
    $self->_write($filename, $content, $input_mode);

}

sub _to_dst_file {
    my ($self, $filename) = @_;
    my $dst_filename = $self->_render_filename($filename);
    my $abs_dst_filename = catfile($self->{write_dir}, $dst_filename);
    return $abs_dst_filename;
}

sub _render_filename {
    my ($self, $filename) = @_;

    my $dst_filename = $filename;
    for my $key (keys %{$self->{filename_vars}}) {
        my $value = $self->{filename_vars}->{$key};
        $dst_filename =~ s|$key|$value|g;
    }

    return $dst_filename;
}

sub _render_content {
    my ($self, $filename, $params) = @_;
    my $content = $self->xslate->render($filename, {
        %{ $self->{file_vars} },
    });
    return $content;
}

sub _write {
    my ($self, $filename, $content) = @_;
    return unless $filename;

    $self->infof("writing $filename");
    return if $self->dry_run;

    write_file($filename, {binmode => ':utf8'}, $content);
}

sub _mkdir {
    my ($self, $dirname) = @_;
    return unless $dirname;

    #$self->infof("mkdir -p $dirname");
    return if $self->dry_run;

    File::Path::make_path($dirname) if $dirname;
}

1;
__END__

=encoding utf-8

=head1 NAME

Setup::Project - setup project tool

=head1 SYNOPSIS

=head2 Generate Sample

    cpanm Setup::Project;
    setup-project -p Setup::Project::Template::Amon2Sample package=Sample author=yourname
    cd Sample
    cpanm --installdeps .
    perl -Ilib ./script/run-server

=head2 How to use (using cli)

    cpanm --look Setup::Project;

    cpanm Setup::Project;
    setup-project -p Setup::Project::Template::MyTemplate package=Sample name=Light author=yourname

    tree
    .
    ├── lib
    │   └── Sample
    │       └── Template
    │           └── Light.pm
    └── share
        └── tmpl
                └── Light
                      └── cpanfile
    cpanm -n .
    setup-project -p Sample::Template::Lite ........

=head2 How to use (using sharedir)

    cpanm Setup::Project;
    setup-project -p Setup::Project::Template::MyTemplate package=Sample name=Light author=yourname

    tree
    .
    ├── lib
    │   └── Sample
    │       └── Template
    │           └── Light.pm
    └── share
        └── tmpl
                └── Light
                      └── cpanfile
    cpanm -n .
    setup-project -p Sample::Template::Lite ........

please show

    cpanm --look Setup::Project
    less lib/Setup/Project/Template/Amon2Sample.pm
    tree share/tmpl/Amon2Sample

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>git@hixi-hyi.comE<gt>

=cut

