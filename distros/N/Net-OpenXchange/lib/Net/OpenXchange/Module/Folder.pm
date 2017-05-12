use Modern::Perl;
package Net::OpenXchange::Module::Folder;
BEGIN {
  $Net::OpenXchange::Module::Folder::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: OpenXchange folder module

use HTTP::Request::Common;
use Net::OpenXchange::X::NotFound;
use Net::OpenXchange::Object::Folder;

has 'path' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'folders',
);

has 'class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Net::OpenXchange::Object::Folder',
);

with 'Net::OpenXchange::Module';

sub root {
    my ($self) = @_;

    my $req = GET(
        $self->req_uri(
            action  => 'root',
            columns => $self->columns,
        )
    );

    my $res = $self->_send($req);
    return map { $self->class->thaw($_) } @{ $res->{data} };
}

sub list {
    my ($self, $folder) = @_;

    $folder = $folder->id if ref $folder;

    my $req = GET(
        $self->req_uri(
            action  => 'list',
            parent  => $folder,
            columns => $self->columns,
        )
    );

    my $res = $self->_send($req);
    return map { $self->class->thaw($_) } @{ $res->{data} };
}

sub resolve_path {
    my ($self, @path) = @_;

    my $folders_ref = [$self->root];
    return $self->_resolve_sub($folders_ref, \@path);
}

sub _resolve_sub {
    my ($self, $folders_ref, $path_ref) = @_;

    my %folders = map { $_->title => $_ } @{ $folders_ref };

    my $name   = shift @{ $path_ref };
    my $folder = $folders{$name};

    if (!$folder) {
        Net::OpenXchange::X::NotFound->throw(
            message => "No such folder: $name",
            type    => 'folder',
            name    => $name
        );
    }

    if (@{$path_ref}) {
        $folders_ref = [$self->list($folder)];
        return $self->_resolve_sub($folders_ref, $path_ref);
    }
    else {
        return $folder;
    }
}

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Module::Folder - OpenXchange folder module

=head1 VERSION

version 0.001

=head1 SYNOPSIS

L<Net::OpenXchange::Module::Folder|Net::OpenXchange::Module::Folder> interfaces
with the calendar API of OpenXchange. It works with instances of
L<Net::OpenXchange::Object::Folder|Net::OpenXchange::Object::Folder>.

When using L<Net::OpenXchange|Net::OpenXchange>, an instance of this class is
provided as the C<folder> attribute.

=head1 METHODS

=head2 root

    my @root_folders = $module_folder->root();

Fetch root folders and return as list.

=head2 list

    my @child_folders = $module_folder->list($folder);

Fetch children of given folder and return as list.

=head2 resolve_path

    my $folder = $module_folder->resolve_path('Public folders', 'Calendar');

Walk folder hierarchy recursively and return folder with given path. Throws
Net::OpenXchange::X::NotFound it a folder cannot be found along the path.

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

