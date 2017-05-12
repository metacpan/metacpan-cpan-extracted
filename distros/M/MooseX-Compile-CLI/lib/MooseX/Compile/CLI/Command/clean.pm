#!/usr/bin/perl

package MooseX::Compile::CLI::Command::clean;
use Moose;

extends qw(MooseX::Compile::CLI::Base);

use Path::Class;
use MooseX::Types::Path::Class;
use MooseX::AttributeHelpers;
use Prompt::ReadKey::Sequence;
use Tie::RefHash;

has '+force' => ( documentation => "Delete without prompting." );

has clean_includes => (
    documentation => "The dirs argument implicitly gets all the 'inc' dirs as well.",
    metaclass     => "Getopt",
    cmd_aliases   => ["C"],
    isa => "Bool",
    is  => "rw",
    default => 0,
);

has '+perl_inc' => (
    documentation => "Also include '\@INC' in the 'inc' dirs. Defaults to true when 'clean_includes' is false.",
    lazy    => 1,
    default => sub {
        my $self = shift;
        return not $self->clean_includes;
    },
);

augment run => sub {
    my ( $self, $opts, $args ) = @_;

    $self->usage->die unless @{$self->classes} or @{$self->dirs};

    $self->clean_all_files;
};

sub clean_all_files {
    my $self = shift;

    $self->clean_files( $self->all_files );
}

sub clean_files {
    my ( $self, @files ) = @_;

    my @delete = $self->should_delete(@files);

    $self->delete_file($_) for @delete;
}

sub should_delete {
    my ( $self, @files ) = @_;

    return @files if $self->force;

    my @ret;

    my @file_list = @files;

    my $file; # shared by while loop and these closures

    my $seq = $self->create_prompt_sequence(@file_list);

    my $answers = $seq->run;

    grep { $answers->{$_} eq 'yes' } @files;
}

sub create_prompt_sequence {
    my ( $self, @files ) = @_;

    my %options;
    my @options = (
        {
            name    => "yes",
            doc     => "delete this file and the associated .mopc file",
        },
        {
            name    => "no",
            doc     => "don't delete this file",
            default => 1,
        },
        {
            name => "rest",
            doc  => "delete all remaining files",
            key  => 'a',
            sequence_command => 1,
            callback => sub {
                my ( $self, @args ) = @_;
                $self->set_option_for_remaining_items( @args, option => $options{yes} );
            },
        },
        {
            name => "everything",
            doc  => "delete all files, including ones previously marked 'no'",
            sequence_command => 1,
            callback => sub {
                my ( $self, @args ) = @_;
                $self->set_option_for_all_items( @args, option => $options{yes} );
            },
        },
        {
            name => "none",
            key  => "d",
            doc  => "don't delete any more files, but do delete the ones specified so far",
            sequence_command => 1,
            callback => sub {
                my ( $self, @args ) = @_;
                $self->set_option_for_remaining_items( @args, option => $options{yes} );
            },
        },
        {
            name => "quit",
            doc  => "exit, without deleting any files",
            sequence_command => 1,
            callback => sub {
                my ( $self, @args ) = @_;
                $self->set_option_for_all_items( @args, option => $options{no} );
            },
        },
    );

    %options = map { $_->{name} => $_ } @options;

    tie my %file_args, 'Tie::RefHash';

    %file_args = map {
        my $file = $_;

        my $name = $file->{rel};
        $name =~ s/\.pmc$/.{pmc,mopc}/;

        $file => {
            %$file,
            filename => $name,
        };
    } @files;

    Prompt::ReadKey::Sequence->new(
        default_prompt  => "Clean up class '%(class)s' (%(filename)s in %(dir)s)?",
        items   => \@files,
        item_arguments => \%file_args,
        default_options => \@options,
    );
}

sub delete_file {
    my ( $self, $file ) = @_;

    foreach my $file ( @{ $file }{qw(file mopc)} ) {
        warn "Deleting $file\n" if $self->verbose;
        $file->remove or die "couldn't unlink $file: $!";
    }
}

sub pmc_to_mopc {
    my ( $self, $pmc_file ) = @_;

    my $pmc_basename = $pmc_file->basename;

    ( my $mopc_basename = $pmc_basename ) =~ s/\.pmc$/.mopc/ or return;

    my $mopc_file = $pmc_file->parent->file($mopc_basename);

    return $mopc_file if -f $mopc_file;

    return;
}

override file_in_dir => sub {
    my ( $self, %args ) = @_;

    my $entry = super();

    $entry->{mopc} = $self->pmc_to_mopc($entry->{file}) or return;

    return $entry;
};

override class_to_filename => sub {
    my ( $self, $class ) = @_;
    super() . "c"; # we are only interested in pmc files
};

sub filter_file {
    my ( $self, $file ) = @_;

    return $file if $file->basename =~ m/\.pmc$/ and -f $file;

    return;
}

augment build_from_opts => sub {
    my ( $self, $opts, $args ) = @_;

    $self->add_to_dirs( $self->inc ) if $self->clean_includes;
};

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Compile::CLI::Command::clean - Clean up .pmc and .mopc files

=head1 SYNOPSIS

    # clean all .pmcs from t/lib

    > mxcompile clean -tC 

=head1 DESCRIPTION

This command cleans out C<.pmc> and C<.mopc> files from directory trees, or
coresponding to certain class names.

=cut
