package Mojo::Darkpan::Util;
use v5.25;
use Moo;
use Mojo::Darkpan::Config;
use Data::Dumper;
use File::Temp;
use IO::Zlib;
use File::Spec;
use File::Basename;
use FindBin;
use Cwd;

has controller => (is => 'rw', required => 1);
has userinfo => (is => 'lazy');
has upload => (is => 'lazy');
has author => (is => 'lazy');
has indexer => (is => 'lazy');
has config => (is => 'lazy');


sub authorized {
    my $self = shift;
    if ($self->config->basic_auth) {

        my ($hash_ref, $auth_ok) = $self->controller->basic_auth(
            $self->config->basic_auth->{realm}
                => $self->config->basic_auth->{config}
        );

        if (!$auth_ok) {
            $self->controller->res->headers->www_authenticate('Basic');
            $self->controller->render(text => 'Authentication required!', status => 401);
            return undef;
        }
        else {
            return $auth_ok;
        }

    }
    else {
        return 1;
    }
}

sub publish {
    my $self = shift;
    my $module;
    my $author = $self->author;

    if ($self->upload) {
        # get a Mojo::Asset::File ref
        my $file = $self->upload->asset->to_file;

        # request from CPAN::Uploader
        my $tempdir = File::Temp::tempdir(CLEANUP => 1);

        $module = File::Spec->catfile($tempdir, $self->upload->filename);
        $file->move_to($module);
    }
    else {
        $module = $self->controller->param('module'); # can be a git repo.
    }

    if (!defined($module)) {
        die("no module provided in request")
    }

    my $injector = OrePAN2::Injector->new(
        directory => $self->config->directory,
        author    => $author,
    );

    $injector->inject($module);

    # reindex to create the modules file 
    $self->index();
}

sub index {
    my $self = shift;
    $self->indexer->make_index(
        no_compress => !$self->config->compressIndex,
    );
}

sub list {
    my $self = shift;
    my $no_compress = !$self->config->compressIndex;
    my $pkgfname = File::Spec->catfile(
        $self->config->directory,
        'modules',
        $no_compress ? '02packages.details.txt' : '02packages.details.txt.gz'
    );

    my $data;
    my $current;
    my $fh = IO::Zlib->new($pkgfname, "rb");
    while (<$fh>) {
        next if ($_ !~ m/\.tar\.gz$/);
        my ($name, $version, $file) = split('\s+', $_);
        if (eval($version)) {

            $current = $name;
            my $dir = File::Basename::dirname($file);
            my $archive = $file =~ s/$dir\///gr;
            $data->{$current}->{version} = $version;
            $data->{$current}->{archive} = $archive;
            $data->{$current}->{dir} = $dir;
            $data->{$current}->{other_versions} = $self->_getFileList($dir, $archive);
        }
        else {
            push(@{$data->{$current}->{provides}}, $name)
        }
    }

    return $data;
}

sub _getFileList {
    my $self = shift;
    my $path = shift;
    my $current = shift;

    my $base = getcwd;
    my $pkgdir = File::Spec->catfile(
        $self->config->directory,
        'authors',
        'id',
        $path
    );
    opendir my $dir, $pkgdir or die "Cannot open directory: $pkgdir";
    my @files = readdir $dir;
    closedir $dir;

    my $prefix = $current =~ s/-(.*)\.tar\.gz//r;
    
    my @data;
    for (@files) {
        next if $_ =~ m/^\./;
        next if $_ eq $current;
        next if $_ !~ m/^$prefix/;
        push(@data, $_);
    }

    return \@data;
}

sub _build_userinfo {
    my $self = shift;
    my ($username, $password) = split(':', $self->req->url->base->{userinfo});
    return {
        username => $username,
        password => $password
    }
}

sub _build_upload {
    my $self = shift;
    for my $file (@{$self->controller->req->uploads('files')}) {
        if ($file->name eq 'pause99_add_uri_httpupload') {
            return $file;
        }
    }
}

sub _build_author {
    my $self = shift;
    my $author = 'DUMMY';

    if ($self->controller->param("HIDDENNAME")) {
        $author = uc($self->controller->param("HIDDENNAME"));
    }
    elsif ($self->controller->param("author")) {
        $author = uc($self->controller->param("author"));
    }

    return $author;
}

sub _build_indexer {
    my $self = shift;
    return OrePAN2::Indexer->new(directory => $self->config->directory);
}

sub _build_config {
    return Mojo::Darkpan::Config->new;
}

1;