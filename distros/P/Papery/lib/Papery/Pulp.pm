package Papery::Pulp;

use strict;
use warnings;

use Papery::Util;    # do not import merge_meta()
use Storable qw( dclone );
use File::Spec;
use File::Path;

sub new {
    my ( $class, $meta ) = @_;
    return bless { meta => $meta ? dclone($meta) : {} }, $class;
}

sub merge_meta { Papery::Util::merge_meta( $_[0]->{meta}, $_[1] ); }

#
# Steps handlers
#

# utility method
sub _class_args {
    my ( $self, $step_handler) = @_;

    # compute the base class name
    my $base = $step_handler;
    $base =~ s/^_//;
    $base = 'Papery::' . ucfirst $base;

    # get the values from the meta
    my $which = $self->{meta}{$step_handler};
    my ( $class, @args ) = ref $which eq 'ARRAY' ? @{$which} : $which;
    return $class ? "$base\::$class" : $base, @args;
}

sub analyze_file {
    my ( $self,  $file )    = @_;
    my ( $class, @options ) = $self->_class_args('_analyzer');
    return $self if !$class;
    eval "require $class" or die $@;
    return $class->analyze_file( $self, $file, @options );
}

sub process {
    my ($self) = @_;
    my ( $class, @options ) = $self->_class_args('_processor');
    return $self if !$class;
    eval "require $class" or die $@;
    return $class->process($self, @options);
}

sub render {
    my ($self) = @_;
    my ( $class, @options ) = $self->_class_args('_renderer');
    return $self if !$class;
    eval "require $class" or die $@;
    return $class->render($self, @options);
}

sub save {
    my ($self) = @_;
    my $meta = $self->{meta};

    # _permalink is relative to __destination
    $meta->{_permalink} = $meta->{__source_path}
        if !exists $meta->{_permalink};

    my $abspath
        = File::Spec->catfile( $meta->{__destination}, $meta->{_permalink} );
    my ( $volume, $directories, $file ) = File::Spec->splitpath($abspath);

    # portably compute the directory path
    my $dir = File::Spec->catpath( $volume, $directories, '' );
    mkpath($dir) if !-e $dir;

    # now create the file and dump the output
    open my $fh, '>', $abspath or die "Can't create $abspath: $!";
    print {$fh} $meta->{_output};
    close $fh;

    return $self;
}

1;

__END__

=head1 NAME

Papery::Pulp - The pulp of the Papery workflow

=head1 SYNOPSIS

    # the Papery workflow

    sub process_file {
        my ( $self, $meta, $file ) = @_;
        return
            map    { $_->save() }                 # will create final files
            map    { $_->render() }               # may insert Papery::Pulp
            map    { $_->process() }              # may insert Papery::Pulp
            map    { $_->analyze_file($file) }    # may insert Papery::Pulp
            Papery::Pulp->new($meta);             # clone $meta
    }

=head1 DESCRIPTION

The Papery workflow is basically passing around C<Papery::Pulp> objects.
The intermediate steps can insert C<Papery::Pulp> objects in the flow,
and each of them will be saved in a file at the end.

A C<Papery::Pulp> object carries around the metadata about the thing
(usually a file) being processed.  It is a simple hash of metadata, that
is process through the whole Papery process. It is initialized with the
current metadata (global configuration, plus all layers of directory
metadata). It is passed to C<Papery::Analyzer>, C<Papery::Processor>
and C<Papery::Renderer> objects.

=head1 METHODS

C<Papery::Pulp> provides the following methods:

=over 4

=item new( $meta )

Create a new C<Papery::Pulp> object, initialized with the metadata
in C<$meta>.

=item analyze_file( $file )

Analyze the C<$file> file (relative to the I<source> directory)
using the configured analyzer class and update the object accordingly.

=item process()

Process the object using the configured processor class
and update it accordingly.

=item render()

Render the object using the configured renderer class
and update it accordingly.

=item save()

Save the generated output to the C<_permalink> file.

=item merge_meta( $meta )

Merge the C<$meta> metadata into the object, using
C<Papery::Util::merge_meta()>.

=back


=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

