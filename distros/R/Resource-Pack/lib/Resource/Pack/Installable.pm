package Resource::Pack::Installable;
BEGIN {
  $Resource::Pack::Installable::VERSION = '0.03';
}
use Moose::Role;
use MooseX::Types::Path::Class qw(Dir);
# ABSTRACT: role for installable resources

use File::Copy::Recursive ();



has _install_to_dir => (
    is         => 'rw',
    isa        => Dir,
    coerce     => 1,
    predicate  => '_has_install_to_dir',
    init_arg   => 'install_to',
);

sub _install_to_parts {
    my $self = shift;
    if ($self->has_parent && $self->parent->does(__PACKAGE__)) {
        if ($self->_has_install_to_dir) {
            return ($self->parent->_install_to_parts, $self->_install_to_dir);
        }
        else {
            return $self->parent->_install_to_parts;
        }
    }
    else {
        if ($self->_has_install_to_dir) {
            return $self->_install_to_dir;
        }
        else {
            return;
        }
    }
}


sub install_to_dir {
    my $self = shift;
    $self->_install_to_dir(@_);
    return Path::Class::Dir->new($self->_install_to_parts);
}


sub install_to_absolute {
    my $self = shift;
    my $to = $self->install_to_dir;
    if ($self->can('get')) {
        $to = $self->isa('Resource::Pack::Dir')
            ? Path::Class::Dir->new($to, $self->get)
            : Path::Class::File->new($to, $self->get);
    }
    return $to;
}


sub install {
    my $self = shift;
    my $from = $self->install_from_absolute->stringify;
    my $to   = $self->install_to_absolute->stringify;
    File::Copy::Recursive::rcopy($from, $to)
        or die "Couldn't copy $from to $to: $!";
}

after install => sub {
    my $self = shift;
    if ($self->does('Bread::Board::Service::WithDependencies')) {
        for my $dep ($self->get_all_dependencies) {
            $dep->[1]->service->install(@_);
        }
    }
};


sub get { shift->install_as }

no Moose::Role;

1;

__END__
=pod

=head1 NAME

Resource::Pack::Installable - role for installable resources

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package My::New::Resource;
    use Moose;
    with 'Resource::Pack::Installable';

=head1 DESCRIPTION

This role implements various common bits of functionality for all installable
resources.

=head1 ATTRIBUTES

=head2 _install_to_dir

This is passed to the constructor as C<install_to>, and holds a path relative
to the C<_install_to_dir> of its parent, representing the directory to install
this resource into.

=head1 METHODS

=head2 install_to_dir

Returns the complete directory where this resource will be installed to. Can
also be used to set the C<_install_to_dir> attribute.

=head2 install_to_absolute

Returns the target path that will be installed by this resource.

=head2 install

Default implementation, which copies the file at C<install_from_absolute> to
C<install_to_absolute>.

After this method is run (either the default implementation or an overridden
implementation), it will call C<install> on each of the dependencies of this
resource.

=head2 get

Returns C<install_as>, to fulfill the requirements for the
L<Bread::Board::Service> role.

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

