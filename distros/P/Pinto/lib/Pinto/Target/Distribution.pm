# ABSTRACT: Specifies a distribution by author and archive

package Pinto::Target::Distribution;

use Moose;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(ArrayRef Str);

use Pinto::Types qw(AuthorID);
use Pinto::Util qw(throw author_dir);

use overload ( '""' => 'to_string' );

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

has author => (
    is       => 'ro',
    isa      => AuthorID,
    coerce   => 1,
    required => 1,
);

has archive => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has subdirs => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my @args = @_;
    if ( @args == 1 and not ref $args[0] ) {
        my @path_parts = split m{/+}x, $args[0];

        my $author  = shift @path_parts;    # First element
        my $archive = pop @path_parts;      # Last element
        my $subdirs = [@path_parts];        # Everything else

        throw "Invalid distribution target: $args[0]"
            if not( $author and $archive );

        @args = ( author => $author, subdirs => $subdirs, archive => $archive );
    }

    return $class->$orig(@args);
};

#------------------------------------------------------------------------------


sub path {
    my ($self) = @_;

    my $author_dir = author_dir($self->author);
    my @subdirs    = @{ $self->subdirs };
    my $archive    = $self->archive;

    return join '/', $author_dir, @subdirs, $archive;
}

#------------------------------------------------------------------------------


sub to_string {
    my ($self) = @_;

    my $author  = $self->author;
    my @subdirs = @{ $self->subdirs };
    my $archive = $self->archive;

    return join '/', $author, @subdirs, $archive;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Target::Distribution - Specifies a distribution by author and archive

=head1 VERSION

version 0.12

=head1 METHODS

=head2 path()

Returns the canonical string form of this DistributionSpec, which is suitable
for constructing a URI.

=head2 to_string

Serializes this Target to its string form.  This method is called whenever the
Target is evaluated in string context.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
