package Pcore::Dist::Build::Temp;

use Pcore -class, -const;
use CPAN::Meta;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

has cpanfile => ( is => 'lazy', isa => Object, init_arg => undef );
has prereqs  => ( is => 'lazy', isa => Object, init_arg => undef );

has module_build_tiny_ver => ( is => 'ro', default => version->parse(v0.39.0)->normal, init_arg => undef );
has test_pod_ver          => ( is => 'ro', default => version->parse(v1.51.0)->normal, init_arg => undef );

const our $XT_TEST => {
    author  => [ 'AUTHOR_TESTING',    '"smoke bot" testing' ],
    release => [ 'RELEASE_TESTING',   'release candidate testing' ],
    smoke   => [ 'AUTOMATED_TESTING', '"smoke bot" testing' ],
};

sub _build_cpanfile ($self) {
    return P->class->load('Module::CPANfile')->load( $self->dist->root . 'cpanfile' );
}

sub _build_prereqs ($self) {
    return $self->cpanfile->prereqs;
}

sub run ( $self, $keep = 0 ) {

    # drop cached info
    $self->dist->clear;

    my $tree = $self->_gather_files;

    $self->_generate_build_pl($tree);

    $self->_generate_meta_json($tree);

    if ($keep) {
        my $path = P->file->temppath( base => $ENV->{PCORE_SYS_DIR} . 'build/', tmpl => $self->dist->name . '-XXXXXXXX' );

        $tree->write_to( $path, manifest => 1 );

        return $path;
    }
    else {
        return $tree->write_to_temp( base => $ENV->{PCORE_SYS_DIR} . 'build/', tmpl => $self->dist->name . '-XXXXXXXX', manifest => 1 );
    }
}

sub _gather_files ($self) {
    my $tree = Pcore::Util::File::Tree->new;

    for (qw[bin/ lib/ share/ t/ xt/]) {
        next if !-d $self->dist->root . $_;

        $tree->add_dir( $self->dist->root . $_, $_ );
    }

    # relocate files, apply cpan_manifest_skip
    my $cpan_manifest_skip = $self->dist->cfg->{cpan} && $self->dist->cfg->{cpan_manifest_skip} && $self->dist->cfg->{cpan_manifest_skip}->@* ? $self->dist->cfg->{cpan_manifest_skip} : undef;

    $tree->find_file(
        sub ($file) {
            if ($cpan_manifest_skip) {
                my $skipped;

                for my $skip_re ( $cpan_manifest_skip->@* ) {
                    if ( $file->path =~ $skip_re ) {
                        $skipped = 1;

                        $file->remove;

                        last;
                    }
                }

                return if $skipped;
            }

            if ( $file->path =~ m[\Abin/(.+)\z]sm ) {

                # relocate scripts from the /bin/ to /script/
                my $name = $1;

                if ( $file->path !~ m[[.].+\z]sm ) {    # no extension
                    $file->move( 'script/' . $name );
                }
                elsif ( $file->path =~ m[[.](?:pl|sh|cmd|bat)\z]sm ) {    # allowed extensions
                    $file->move( 'script/' . $name );
                }
                else {
                    $file->remove;
                }
            }
            elsif ( $file->path =~ m[\At/(.+)\z]sm && $file->path !~ m[[.]t\z]sm ) {

                # olny *.t files are allowed in /t/ dir
                $file->remove;
            }
            elsif ( $file->path =~ m[\Axt/(author|release|smoke)/(.+)\z]sm ) {

                # patch /xt/*/.t files and relocate to the /t/ dir
                my $test = $1;

                my $name = $2;

                # add common header to /xt/*.t file
                if ( $file->path =~ m[[.]t\z]sm ) {
                    $file->move("t/$test-$name");

                    $self->_patch_xt( $file, $test );
                }
                else {
                    $file->remove;
                }
            }

            return;
        }
    );

    for (qw[CHANGES cpanfile LICENSE README.md]) {
        $tree->add_file( $_, $self->dist->root . $_ );
    }

    # add dist-id.json
    $tree->add_file( 'share/dist-id.json', P->data->to_json( $self->dist->id, readable => 1 ) );

    # add "t/author-pod-syntax.t"
    my $t = <<'PERL';
#!perl

# This file was generated automatically.

use strict;
use warnings;
use Test::More;
use Test::Pod 1.41;

all_pod_files_ok();
PERL

    # add common header to "t/author-pod-syntax.t"
    $self->_patch_xt( $tree->add_file( 't/author-pod-syntax.t', \$t ), 'author' );

    # remove /bin, /xt
    $tree->find_file(
        sub ($file) {
            $file->remove if $file->path =~ m[\A(?:bin|xt)/]sm;

            return;
        }
    );

    return $tree;
}

sub _generate_build_pl ( $self, $tree ) {
    my $reqs = $self->prereqs->merged_requirements( [qw[configure build test runtime]], ['requires'] );

    my $perl_version = $reqs->requirements_for_module('perl') || $^V->normal;

    my $mbt_version = $self->module_build_tiny_ver;

    my $template = <<"BUILD_PL";
use strict;
use warnings;

use $perl_version;
use Module::Build::Tiny $mbt_version;
Build_PL();
BUILD_PL

    $tree->add_file( 'Build.PL', \$template );

    return;
}

sub _generate_meta_json ( $self, $tree ) {
    my $meta = {
        abstract => 'unknown',
        author   => [            #
            $self->dist->cfg->{author},
        ],
        dynamic_config => 0,
        license        => [ lc $self->dist->cfg->{license} ],
        name           => $self->dist->name,
        no_index       => {                                     #
            directory => [qw[share t]],
        },
        release_status => 'stable',
        version        => undef,
    };

    # version
    $meta->{version} = $self->dist->version;

    # abstract
    $meta->{abstract} = $self->dist->module->abstract if $self->dist->module->abstract;

    # resources
    my $upstream_meta;

    if ( $self->dist->scm && $self->dist->scm->upstream && $self->dist->scm->upstream->hosting_api_class ) {
        $upstream_meta = $self->dist->scm->upstream->hosting_api->cpan_meta;
    }
    else {
        $upstream_meta = {};
    }

    if ( my $val = $self->dist->cfg->{meta}->{homepage} || $upstream_meta->{homepage} ) {
        $meta->{resources}->{homepage} = $val;
    }

    if ( my $val = $self->dist->cfg->{meta}->{repository}->{web} || $upstream_meta->{repository}->{web} ) {
        $meta->{resources}->{repository}->{web} = $val;
    }

    if ( my $val = $self->dist->cfg->{meta}->{repository}->{url} || $upstream_meta->{repository}->{url} ) {
        $meta->{resources}->{repository}->{url} = $val;
    }

    if ( my $val = $self->dist->cfg->{meta}->{repository}->{type} || $upstream_meta->{repository}->{type} ) {
        $meta->{resources}->{repository}->{type} = $val;
    }

    if ( my $val = $self->dist->cfg->{meta}->{bugtracker}->{web} || $upstream_meta->{bugtracker}->{web} ) {
        $meta->{resources}->{bugtracker}->{web} = $val;
    }

    # optional features
    if ( my @features = $self->cpanfile->features ) {

        my $features = {};

        for my $feature (@features) {
            $features->{ $feature->identifier } = {
                description => $feature->description,
                prereqs     => $feature->prereqs->as_string_hash,
            };
        }

        $meta->{optional_features} = $features;
    }

    # prereqs
    $self->prereqs->requirements_for( 'configure', 'requires' )->add_minimum( 'Module::Build::Tiny' => $self->module_build_tiny_ver );

    $self->prereqs->requirements_for( 'develop', 'requires' )->add_minimum( 'Test::Pod' => $self->test_pod_ver );

    $meta->{prereqs} = $self->prereqs->as_string_hash;

    # add META.json
    $tree->add_file( 'META.json', \CPAN::Meta->create($meta)->as_string );

    # P->file->write_text( $self->dist->root . 'META.json', { crlf => 0 }, CPAN::Meta->create($meta)->as_string );

    return;
}

sub _patch_xt ( $self, $file, $test ) {
    my $content = $file->content;

    my $patch = <<"PERL";
BEGIN {
    unless ( \$ENV{$XT_TEST->{$test}->[0]} ) {
        require Test::More;

        Test::More::plan( skip_all => 'these tests are for $XT_TEST->{$test}->[1]' );
    }
}
PERL

    $content->$* =~ s/^use\s/$patch\nuse /sm;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 51                   | Subroutines::ProhibitExcessComplexity - Subroutine "_gather_files" with high complexity score (21)             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 |                      | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls                                                          |
## |      | 205                  | * Found method-call chain of length 4                                                                          |
## |      | 206                  | * Found method-call chain of length 5                                                                          |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Temp - create CPAN build the temporary dir

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
