package OrePAN2::Indexer::Tiny;
use strict;
use warnings;
use utf8;

use Archive::Extract ();
use CPAN::Meta;
use Carp ();
use File::Basename ();
use File::Find qw(find);
use File::Spec ();
use File::Temp qw(tempdir);
use File::pushd qw(pushd);
use IO::Uncompress::Gunzip ('$GunzipError');
use IO::Zlib;
use Parse::LocalDistribution;

our $VERSION = "0.02";

sub new {
    my ($class, %args) = @_;
    unless ( defined $args{directory} ) {
        Carp::croak('Missing mandatory parameter: directory');
    }
    bless {
        index => {},
        %args,
    }, $class;
}

sub add_index {
    my ( $self, $archive_file ) = @_;

    my $archive = Archive::Extract->new( archive => $archive_file );
    my $tmpdir = tempdir( 'orepan2.XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    $archive->extract( to => $tmpdir );

    my $provides = $self->scan_provides( $tmpdir, $archive_file );
    my $path = $self->_orepan_archive_path($archive_file);

    for my $package ( sort keys %{$provides} ) {
        $self->_add_index(
            $package,
            $provides->{$package}->{version},
            $path,
        );
    }
}

# Order of preference is last updated. So if some modules maintain the same
# version number across multiple uploads, we'll point to the module in the
# latest archive.

sub _add_index {
    my ( $self, $package, $version, $archive_file ) = @_;

    if ( $self->{index}{$package} ) {
        my ($orig_ver) = @{ $self->{index}{$package} };

        if ( version->parse($orig_ver) > version->parse($version) ) {
            $version //= 'undef';
            print STDERR "[INFO] Not adding $package in $archive_file\n";
            print STDERR
                "[INFO] Existing version $orig_ver is greater than $version\n";
            return;
        }
    }
    $self->{index}->{$package} = [ $version, $archive_file ];
}

sub _orepan_archive_path {
    my ( $self, $archive_file ) = @_;
    my $path         = File::Spec->abs2rel(
        $archive_file,
        File::Spec->catfile( $self->{directory}, 'authors', 'id' )
    );
    $path =~ s!\\!/!g;
    return $path;
}

sub scan_provides {
    my ( $self, $dir, $archive_file ) = @_;

    my $guard = pushd( glob("$dir/*") );
    for my $mfile ( 'META.json', 'META.yml', 'META.yaml' ) {
        next unless -f $mfile;
        my $meta = eval { CPAN::Meta->load_file($mfile) };
        return $meta->{provides} if $meta && $meta->{provides};

        if ($@) {
            print STDERR "[WARN] Error using '$mfile' from '$archive_file'\n";
            print STDERR "[WARN] $@\n";
            print STDERR "[WARN] Attempting to continue...\n";
        }
    }

    print STDERR
        "[INFO] Found META file in '$archive_file' but it does not contain 'provides'\n";
    print STDERR "[INFO] Scanning for provided modules...\n";

    my $provides = eval { $self->_scan_provides('.') };
    return $provides if $provides;

    print STDERR "[WARN] Error scanning: $@\n";

    # Return empty provides.
    return {};
}

sub _scan_provides {
    my ( $self, $dir, $meta ) = @_;

    my $provides = Parse::LocalDistribution->new( { ALLOW_DEV_VERSION => 1 } )
        ->parse($dir);
    return $provides;
}

sub write_index {
    my ( $self ) = @_;

    my $pkgfname = $self->_package_file();
    mkdir( File::Basename::dirname($pkgfname) );
    my $fh = IO::Zlib->new( $pkgfname, 'w' )
        or die "Cannot open $pkgfname for writing: $!\n";
    print $fh $self->_as_string();
    close $fh;
}

sub _as_string {
    my ( $self ) = @_;

    my @buf;

    push @buf, <<"...";
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  DarkPAN
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   OrePAN2::Indexer::Tiny $OrePAN2::Indexer::Tiny::VERSION
Line-Count:   @{[ scalar(keys %{$self->{index}}) ]}
Last-Updated: @{[ scalar localtime ]}
...

    for my $pkg ( sort { lc $a cmp lc $b } keys %{ $self->{index} } ) {
        my $entry = $self->{index}{$pkg};

        # package name, version, path
        push @buf, sprintf '%-22s %-22s %s', $pkg, $entry->[0] || 'undef',
            $entry->[1];
    }
    return join( "\n", @buf ) . "\n";
}

sub load_index {
    my ( $self ) = @_;

    return unless -e $self->_package_file;

    my $fh = IO::Uncompress::Gunzip->new($self->_package_file)
        or die "gzip failed: $GunzipError\n";

    # skip headers
    while (<$fh>) {
        last unless /\S/;
    }

    while (<$fh>) {
        if (/^(\S+)\s+(\S+)\s+(.*)$/) {
            $self->_add_index( $1, $2 eq 'undef' ? undef : $2, $3 );
        }
    }

    close $fh;
}

sub _package_file {
    my ( $self ) = @_;

    return File::Spec->catfile(
        $self->{directory},
        'modules',
        '02packages.details.txt.gz'
    );
}

sub list_archive_files {
    my ( $self ) = @_;

    my $authors_dir = File::Spec->catfile( $self->{directory}, 'authors' );
    return () unless -d $authors_dir;

    my @files;
    find(
        {
            wanted => sub {
                return unless /
                    (?:
                        \.tar\.gz
                        | \.tgz
                        | \.zip
                        )
                        \z/x;
                push @files, $_;
            },
            no_chdir => 1,
        },
        $authors_dir
    );

    # Sort files by modication time so that we can index distributions from
    # earliest to latest version.

    return sort { -M $b <=> -M $a } @files;
}

1;
__END__

=encoding utf-8

=head1 NAME

OrePAN2::Indexer::Tiny - Minimal DarkPAN indexer

=head1 SYNOPSIS

    use OrePAN2::Indexer::Tiny;

    my $orepan = OrePAN2::Indexer::Tiny->new(
        directory => $directory,
    );
    $orepan->load_index();
    for my $archive_file ($self->list_archive_files()) {
        $self->add_index( $archive_file );
    }
    $self->write_index();

=head1 DESCRIPTION

OrePAN2::Indexer::Tiny is minimal L<OrePAN2> indexer which have less dependencies.

Original code is taken from L<OrePAN2>.

=head1 SEE ALSO

L<OrePAN2>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
