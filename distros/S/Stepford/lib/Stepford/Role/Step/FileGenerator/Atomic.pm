package Stepford::Role::Step::FileGenerator::Atomic;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.005000';

use Carp qw( croak );
use Path::Class qw( file );
use Scope::Guard qw( guard );
use Stepford::Types qw( File );

use Moose::Role;

with 'Stepford::Role::Step::FileGenerator';

has pre_commit_file => (
    is      => 'ro',
    isa     => File,
    lazy    => 1,
    builder => '_build_pre_commit_file',
);

sub BUILD { }
before BUILD => sub {
    my $self = shift;

    my @production_names = sort map { $_->name } $self->productions;

    croak 'The '
        . ( ref $self )
        . ' class consumed the Stepford::Role::Step::FileGenerator::Atomic'
        . " role but contains more than one production: @production_names"
        if @production_names > 1;

    return;
};

sub _build_pre_commit_file {
    my $self = shift;

    my $final_file = ( $self->productions )[0];
    my $reader     = $final_file->get_read_method;

    return file( $self->$reader . '.tmp' );
}

around run => sub {
    my $orig = shift;
    my $self = shift;

    my $pre_commit = $self->pre_commit_file;
    my $guard = guard { $pre_commit->remove if -f $pre_commit };

    $self->$orig(@_);

    my $read_method = ( $self->productions )[0]->get_read_method;
    my $post_commit = $self->$read_method;

    # The step's run method may decide to simply not do anything if the
    # post-commit file already exists, and that's ok.
    return if -f $post_commit && !-f $pre_commit;

    croak 'The '
        . ( ref $self )
        . ' class consumed the Stepford::Role::Step::FileGenerator::Atomic'
        . ' role but run produced no pre-commit production file at:'
        . " $pre_commit"
        unless -f $pre_commit;

    $self->logger->debug("Renaming $pre_commit to $post_commit");
    rename( $pre_commit, $post_commit )
        or croak "Failed renaming $pre_commit -> $post_commit: $!";
};

1;

# ABSTRACT: A role for steps that generate a file atomically

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Role::Step::FileGenerator::Atomic - A role for steps that generate a file atomically

=head1 VERSION

version 0.005000

=head1 DESCRIPTION

This role consumes the L<Stepford::Role::Step::FileGenerator> role. It allows
only one file production, but makes sure it is written atomically - the file
will not exist if the step aborts. The file will only be committed to its
final destination when C<run> completes successfully.

Instead of manipulating the file production directly, you work with the file
given by C<< $step->pre_commit_file >>. This role will make sure it gets
committed after C<run>.

=head1 METHODS

This role provides the following methods:

=head2 $step->BUILD

This method adds a wrapper to the BUILD method which ensures that there is
only one production.

=head2 $step->pre_commit_file

This returns a temporary file in a temporary directory that you can manipulate
inside C<run>. It will be removed if the step fails, or renamed to the final
file production if the step succeeds.

=head1 CAVEATS

When running steps in parallel, it is important to ensure that you do not call
the C<< $step->pre_commit_file >> method outside of the C<< $step->run >>
method. If you call this at object creation time, this can cause the tempdir
containing the C< pre_commit_file > file to be created and destroyed before
the run method ever gets a chance to run.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford/issues>.

=head1 AUTHOR

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
