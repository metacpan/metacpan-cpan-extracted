package Pcore::Dist::Build::Temp;

use Pcore -class, -const;
use CPAN::Meta;

has dist => ( required => 1 );    # InstanceOf ['Pcore::Dist']

has cpanfile => ( is => 'lazy', init_arg => undef );
has prereqs  => ( is => 'lazy', init_arg => undef );

has module_build_tiny_ver => ( version->parse(v0.39.0)->normal, init_arg => undef );
has test_pod_ver          => ( version->parse(v1.51.0)->normal, init_arg => undef );

const our $XT_TEST => {
    author  => [ 'AUTHOR_TESTING',    '"smoke bot" testing' ],
    release => [ 'RELEASE_TESTING',   'release candidate testing' ],
    smoke   => [ 'AUTOMATED_TESTING', '"smoke bot" testing' ],
};

sub _build_cpanfile ($self) {
    return P->class->load('Module::CPANfile')->load("$self->{dist}->{root}/cpanfile");
}

sub _build_prereqs ($self) {
    return $self->cpanfile->prereqs;
}

sub run ( $self, $keep = 0 ) {

    # drop cached info
    $self->{dist}->clear;

    my $tree = $self->_gather_files;

    $self->_generate_build_pl($tree);

    $self->_generate_meta_json($tree);

    my $path;

    if ($keep) {
        $path = P->path( "$self->{dist}->{root}/data/.build/" . $self->{dist}->name . '-' . P->uuid->v4_hex );

        $path->mkpath;

        $tree->write_to( $path, manifest => 1 );
    }
    else {
        # $path = $tree->write_to_temp( manifest => 1, prefix => "$self->{dist}->{root}/data/.build", name => $self->{dist}->name . '-' . P->uuid->v4_hex );
        $path = $tree->write_to_temp( manifest => 1 );
    }

    return $path;
}

sub _gather_files ($self) {
    my $tree = Pcore::Lib::File::Tree->new;

    for my $dir (qw[bin lib share t xt]) {
        $tree->add_dir( "$self->{dist}->{root}/$dir", $dir );
    }

    # relocate files, apply cpan_manifest_skip
    my $cpan_manifest_skip = $self->{dist}->cfg->{cpan} && $self->{dist}->cfg->{cpan_manifest_skip} && $self->{dist}->cfg->{cpan_manifest_skip}->@* ? $self->{dist}->cfg->{cpan_manifest_skip} : undef;

    for my $file ( values $tree->{files}->%* ) {
        if ($cpan_manifest_skip) {
            my $skipped;

            for my $skip_re ( $cpan_manifest_skip->@* ) {
                if ( $file->{path} =~ $skip_re ) {
                    $skipped = 1;

                    $file->remove;

                    last;
                }
            }

            next if $skipped;
        }

        if ( $file->{path} =~ m[\Abin/(.+)\z]sm ) {

            # relocate scripts from the /bin/ to /script/
            my $name = $1;

            if ( $file->{path} !~ m[[.].+\z]sm ) {    # no extension
                $file->move("script/$name");
            }
            elsif ( $file->{path} =~ m[[.](?:pl|sh|cmd|bat)\z]sm ) {    # allowed extensions
                $file->move("script/$name");
            }
            else {
                $file->remove;
            }
        }
        elsif ( $file->{path} =~ m[\At/(.+)\z]sm && $file->{path} !~ m[[.]t\z]sm ) {

            # olny *.t files are allowed in /t/ dir
            $file->remove;
        }
        elsif ( $file->{path} =~ m[\Axt/(author|release|smoke)/(.+)\z]sm ) {

            # patch /xt/*/.t files and relocate to the /t/ dir
            my $test = $1;

            my $name = $2;

            # add common header to /xt/*.t file
            if ( $file->{path} =~ m[[.]t\z]sm ) {
                $file->move("t/$test-$name");

                $self->_patch_xt( $file, $test );
            }
            else {
                $file->remove;
            }
        }
    }

    for my $file (qw[CHANGES cpanfile LICENSE README.md]) {
        $tree->add_file( $file, "$self->{dist}->{root}/$file" );
    }

    # add dist-id.yaml
    $tree->add_file( 'share/dist-id.yaml', \P->data->to_yaml( $self->{dist}->id ) );

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
    for my $file ( values $tree->{files}->%* ) {
        $file->remove if $file->{path} =~ m[\A(?:bin|xt)/]sm;
    }

    return $tree;
}

sub _generate_build_pl ( $self, $tree ) {
    my $reqs = $self->prereqs->merged_requirements( [qw[configure build test runtime]], ['requires'] );

    my $mbt_version = $self->{module_build_tiny_ver};

    my $template = <<"BUILD_PL";
use strict;
use warnings;

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
            $self->{dist}->cfg->{author},
        ],
        dynamic_config => 0,
        license        => [ lc $self->{dist}->cfg->{license} ],
        name           => $self->{dist}->name,
        no_index       => {                                       #
            directory => [qw[share t]],
        },
        release_status => 'stable',
        version        => undef,
    };

    # version
    $meta->{version} = $self->{dist}->version;

    # abstract
    $meta->{abstract} = $self->{dist}->module->abstract if $self->{dist}->module->abstract;

    # resources
    my $upstream_meta;

    if ( $self->{dist}->git && $self->{dist}->git->upstream ) {
        $upstream_meta = $self->{dist}->git->upstream->get_cpan_meta;
    }
    else {
        $upstream_meta = {};
    }

    if ( my $val = $self->{dist}->cfg->{meta}->{homepage} || $upstream_meta->{homepage} ) {
        $meta->{resources}->{homepage} = $val;
    }

    if ( my $val = $self->{dist}->cfg->{meta}->{repository}->{web} || $upstream_meta->{repository}->{web} ) {
        $meta->{resources}->{repository}->{web} = $val;
    }

    if ( my $val = $self->{dist}->cfg->{meta}->{repository}->{url} || $upstream_meta->{repository}->{url} ) {
        $meta->{resources}->{repository}->{url} = $val;
    }

    if ( my $val = $self->{dist}->cfg->{meta}->{repository}->{type} || $upstream_meta->{repository}->{type} ) {
        $meta->{resources}->{repository}->{type} = $val;
    }

    if ( my $val = $self->{dist}->cfg->{meta}->{bugtracker}->{web} || $upstream_meta->{bugtracker}->{web} ) {
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
    $self->prereqs->requirements_for( 'configure', 'requires' )->add_minimum( 'Module::Build::Tiny' => $self->{module_build_tiny_ver} );

    $self->prereqs->requirements_for( 'develop', 'requires' )->add_minimum( 'Test::Pod' => $self->{test_pod_ver} );

    $meta->{prereqs} = $self->prereqs->as_string_hash;

    # add META.json
    $tree->add_file( 'META.json', \CPAN::Meta->create($meta)->as_string );

    # P->file->write_text( "$self->{dist}->{root}/META.json", { crlf => 0 }, CPAN::Meta->create($meta)->as_string );

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
## |    3 | 56                   | Subroutines::ProhibitExcessComplexity - Subroutine "_gather_files" with high complexity score (22)             |
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
