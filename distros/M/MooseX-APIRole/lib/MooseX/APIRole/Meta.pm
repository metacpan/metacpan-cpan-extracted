package MooseX::APIRole::Meta;
BEGIN {
  $MooseX::APIRole::Meta::VERSION = '0.01';
}
# ABSTRACT: metarole for classes and roles that have API roles
use Moose::Role;

use true;
use namespace::autoclean;

use MooseX::APIRole::Internals qw(create_role_for);

has 'api_role_name' => (
    reader    => 'api_role_name',
    writer    => 'set_api_role_name',
    predicate => 'has_api_role_name',
    lazy      => 1,
    builder   => '_build_api_role_name',
);

sub _build_api_role_name {
    my ($self) = @_;
    return $self->api_role->name;
}

has 'api_role' => (
    reader    => 'get_api_role',
    predicate => 'has_api_role',
    lazy      => 1,
    builder   => '_build_api_role',
);

sub api_role { goto($_[0]->can('get_api_role')) }

sub _build_api_role {
    my ($self) = @_;
    my $has_name = $self->has_api_role_name;
    my $role = $has_name ? create_role_for($self, $self->api_role_name)
                         : create_role_for($self);
    return $role;
}



=pod

=head1 NAME

MooseX::APIRole::Meta - metarole for classes and roles that have API roles

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 api_role_name

The name of the API role.  If you set this before the API role is
lazily built, then this will be the package that the role is installed
into.

=head3 get_api_role_name

=head3 set_api_role_name

=head3 has_api_role_name

=head2 api_role

The API role.  Built when needed, usually by L<MooseX::APIRole>'s
C<make_api_role> method.

=head3 get_api_role

=head3 api_role

api_role is an alias for get_api_role.

=head3 has_api_role

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

