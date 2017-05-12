package Resource::Pack::Dir;
BEGIN {
  $Resource::Pack::Dir::VERSION = '0.03';
}
use Moose;
use MooseX::Types::Path::Class qw(Dir);
# ABSTRACT: a directory resource

with 'Resource::Pack::Installable',
     'Bread::Board::Service',
     'Bread::Board::Service::WithDependencies';



has dir => (
    is      => 'ro',
    isa     => Dir,
    coerce  => 1,
    lazy    => 1,
    default => sub { Path::Class::Dir->new(shift->name) },
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
            confess "install_from is required for Dir resources without a container";
        }
    },
);


has install_as => (
    is      => 'rw',
    isa     => Dir,
    coerce  => 1,
    lazy    => 1,
    default => sub { shift->dir },
);

sub BUILD {
    my $self = shift;
    $self->install_from_dir;
}


sub install_from_absolute {
    my $self = shift;
    $self->install_from_dir->subdir($self->dir);
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__
=pod

=head1 NAME

Resource::Pack::Dir - a directory resource

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $dir = Resource::Pack::Dir->new(
        name         => 'test',
        dir          => 'css',
        install_from => data_dir,
    );
    $dir->install;

=head1 DESCRIPTION

This class represents a directory to be installed. It can also be added as a
subresource to a L<Resource::Pack::Resource>. This class consumes the
L<Resource::Pack::Installable>, L<Bread::Board::Service>, and
L<Bread::Board::Service::WithDependencies> roles.

=head1 ATTRIBUTES

=head2 dir

Read-only attribute for the source directory. Defaults to the service name.

=head2 install_from_dir

Base dir, where C<dir> is located. Defaults to the C<install_from_dir> of the
parent resource. The associated constructor argument is C<install_from>.

=head2 install_as

The name to use for the installed directory. Defaults to C<dir>.

=head1 METHODS

=head2 install_from_absolute

Entire path to the source directory (concatenation of C<install_from_dir> and
C<dir>).

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

