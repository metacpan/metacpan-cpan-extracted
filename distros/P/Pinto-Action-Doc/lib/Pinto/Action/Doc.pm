# ABSTRACT: Generate html docs from the dists in a stack

package Pinto::Action::Doc;
{
  $Pinto::Action::Doc::VERSION = '0.004';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(HashRef Str Bool);

use Pinto::Constants qw(:color);
use Pinto::Types qw(AuthorID StackName StackDefault StackObject);
use Pinto::Util qw(throw);
use Pinto::ArchiveUnpacker;
use Pod::ProjectDocs;

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName | StackDefault | StackObject,
    default => undef,
);

has pinned => (
    is  => 'ro',
    isa => Bool,
);

has author => (
    is     => 'ro',
    isa    => AuthorID,
    coerce => 1,
);

has packages => (
    is  => 'ro',
    isa => Str,
);

has distributions => (
    is  => 'ro',
    isa => Str,
);

has local => (
    is  => 'ro',
    isa => Bool,
);

has out => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has title => (
    is      => 'ro',
    isa     => Str,
    default => "MyProject's Libraries",
);

has desc => (
    is      => 'ro',
    isa     => Str,
    default => 'manuals and libraries',
);

has charset => (
    is      => 'ro',
    isa     => Str,
    default => 'UTF-8',
);

has noindex => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has forcegen => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has lang => (
    is      => 'ro',
    isa     => Str,
    default => 'en',
);

has where => (
    is      => 'ro',
    isa     => HashRef,
    builder => '_build_where',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub _build_where {
    my ($self) = @_;

    my $where = {};
    my $stack = $self->repo->get_stack( $self->stack );
    $where = { revision => $stack->head->id };

    if ( my $pkg_name = $self->packages ) {
        $where->{'package.name'} = { like => "%$pkg_name%" };
    }

    if ( my $dist_name = $self->distributions ) {
        $where->{'distribution.archive'} = { like => "%$dist_name%" };
    }

    if ( my $author = $self->author ) {
        $where->{'distribution.author'} = uc $author;
    }

    if ( my $pinned = $self->pinned ) {
        $where->{is_pinned} = 1;
    }
    
    if ( $self->local ) {
        $where->{'distribution.source'} = 'LOCAL';
    }

    return $where;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where = $self->where;
    my $attrs = {
        prefetch => [qw(revision package distribution)],
        group_by => 'distribution.archive',
    };
    my $rs = $self->repo->db->schema->search_registration( $where, $attrs );

    my @dirs;
    my @unpackers;
    while ( my $reg = $rs->next ) {
        my $unpacker = Pinto::ArchiveUnpacker->new(
            archive => $reg->distribution->native_path,
        );
        
        # keep it in scope so it doesn't get cleaned up too soon
        push @unpackers, $unpacker;
        
        my $temp_dir = $unpacker->unpack;
        push @dirs, "$temp_dir/lib"    if -e "$temp_dir/lib";
        push @dirs, "$temp_dir/bin"    if -e "$temp_dir/bin";
    }

    my $pd = Pod::ProjectDocs->new(
        outroot  => $self->out,
        libroot  => [ @dirs ],
        title    => $self->title,
        desc     => $self->desc,
        charset  => $self->charset,
        index    => !$self->noindex,
        lang     => $self->lang,
        forcegen => $self->forcegen,
    );
    $pd->gen;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Pinto::Action::Doc - Generate html docs from the dists in a stack

=head1 VERSION

version 0.004

=head1 DESCRIPTION

A plugin for Pinto that adds an easy way to generate HTML documents from the
distributions on a stack. See L<App::Pinto::Command::doc> for details.

=head1 WARNING

The Pinto API is not yet stable so it's entirely possible that changes to Pinto
will break this module.

This module doesn't work with remote Pinto repositories.

=head1 AUTHOR

Andy Gorman <agorman@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andy Gorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
