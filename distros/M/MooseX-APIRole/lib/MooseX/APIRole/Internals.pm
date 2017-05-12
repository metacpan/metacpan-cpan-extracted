package MooseX::APIRole::Internals;
BEGIN {
  $MooseX::APIRole::Internals::VERSION = '0.01';
}
# ABSTRACT: utility functions for MooseX::APIRole
use strict;
use warnings;
use true;
use Moose::Meta::Role;

use Moose::Util qw(does_role);
use Hash::Util::FieldHash qw(fieldhash);

use Sub::Exporter -setup => {
    exports => [qw/role_for create_role_for/],
};

# fieldhash so that when a class goes away, so does the role
fieldhash my %ROLE_FOR;

sub role_for {
    my $meta = shift;
    return $ROLE_FOR{$meta} if exists $ROLE_FOR{$meta};
    return;
}

sub _analyze_metaclass {
    my $meta = shift;

    my @methods = $meta->get_method_list;
    push @methods, $meta->get_required_method_list if $meta->isa('Moose::Meta::Role');

    my @roles = @{ $meta->isa('Moose::Meta::Class') ? $meta->roles : $meta->get_roles };

    # we do this for both classes and roles, but roles do not have superclasses
    my @superclasses = $meta->isa('Moose::Meta::Class') ? $meta->superclasses : ();

    return {
        methods      => [grep { $_ ne 'meta' } @methods],
        roles        => \@roles,
        superclasses => [map { $_->meta } grep { $_ ne 'Moose::Object' } @superclasses],
    };
}

sub _name_role_for {
    my $meta = shift;
    my $name = $meta->name;

    $name =~ s/\|/::__AND__::/g;

    # this is so is_anon_role returns true.  hopefully it doesn't fuck
    # up destruction too much.
    return "Moose::Meta::Role::__ANON__::SERIAL::__AUTOGEN_FOR__::$name";
}

sub create_role_for {
    my ($meta, $name) = @_;

    # already cached?
    my $cached_role = role_for($meta);
    return $cached_role if $cached_role;

    # create and cache
    my $role = Moose::Meta::Role->create(
        $name || _name_role_for($meta),
    );
    $ROLE_FOR{$meta} = $role;

    # analyze the metaclass
    my $metainfo = _analyze_metaclass($meta);

    # any methods that this class/role requires, the new role requires
    $role->add_required_methods(@{$metainfo->{methods} || []});

    # role role role your boat, gently down the stream
    for(@{$metainfo->{roles} || []}, @{$metainfo->{superclasses} || []}){
        if(does_role($_, 'MooseX::APIRole::Meta')){
            # this will vivify the parent api_role; we do it here because
            # we don't want to vivify the current class's api_role while we are
            # vivifying the current class's api_role :)
            $_->api_role->apply($role);
        }
        else {
            create_role_for($_)->apply($role);
        }
    }

    return $role;
}

__END__
=pod

=head1 NAME

MooseX::APIRole::Internals - utility functions for MooseX::APIRole

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

