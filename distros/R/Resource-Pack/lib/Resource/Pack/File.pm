package Resource::Pack::File;
BEGIN {
  $Resource::Pack::File::VERSION = '0.03';
}
use Moose;
use MooseX::Types::Path::Class qw(File Dir);
# ABSTRACT: a file resource

with 'Resource::Pack::Installable',
     'Bread::Board::Service',
     'Bread::Board::Service::WithDependencies';



has file => (
    is      => 'ro',
    isa     => File,
    coerce  => 1,
    lazy    => 1,
    default => sub { Path::Class::File->new(shift->name) },
);


has install_from_dir => (
    is         => 'rw',
    isa        => Dir,
    coerce     => 1,
    init_arg   => 'install_from',
    predicate  => 'has_install_from_dir',
    lazy       => 1,
    default    => sub {
        my $self = shift;
        if ($self->has_parent && $self->parent->has_install_from_dir) {
            return $self->parent->install_from_dir;
        }
        else {
            confess "install_from is required for File resources without a container";
        }
    },
);


has install_as => (
    is      => 'rw',
    isa     => File,
    coerce  => 1,
    lazy    => 1,
    default => sub { shift->file },
);

sub BUILD {
    my $self = shift;
    $self->install_from_dir;
}


sub install_from_absolute {
    my $self = shift;
    $self->install_from_dir->file($self->file);
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__
=pod

=head1 NAME

Resource::Pack::File - a file resource

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $file = Resource::Pack::File->new(
        name         => 'test',
        file         => 'test.txt',
        install_from => data_dir,
    );
    $file->install;

=head1 DESCRIPTION

This class represents a file to be installed. It can also be added as a
subresource to a L<Resource::Pack::Resource>. This class consumes the
L<Resource::Pack::Installable>, L<Bread::Board::Service>, and
L<Bread::Board::Service::WithDependencies> roles.

=head1 ATTRIBUTES

=head2 file

Read-only attribute for the source file. Defaults to the service name.

=head2 install_from_dir

Base dir, where C<file> is located. Defaults to the C<install_from_dir> of the
parent resource. The associated constructor argument is C<install_from>.

=head2 install_as

The name to use for the installed file. Defaults to C<file>.

=head1 METHODS

=head2 install_from_absolute

Entire path to the source file (concatenation of C<install_from_dir> and
C<file>).

=for Pod::Coverage BUILD

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Resource::Pack|Resource::Pack>

=back

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy at tozt dot net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

