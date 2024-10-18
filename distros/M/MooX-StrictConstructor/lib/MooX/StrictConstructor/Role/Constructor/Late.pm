use strict;                     # redundant, but quiets perlcritic
use warnings;
package MooX::StrictConstructor::Role::Constructor::Late;

our $VERSION = '0.013';

use Moo::Role;

with 'MooX::StrictConstructor::Role::Constructor::Base';

has _buildall_generator => ( is => 'rw' );

around buildall_generator => sub {
    my ($orig, $self, @args) = @_;
    my $gen = $self->_buildall_generator;
    return $gen
        if $gen;
    $gen = Moo::Role->apply_roles_to_object($self->$orig(@args),
        'MooX::StrictConstructor::Role::BuildAll'
    );
    $gen->_constructor_generator($self);
    return $self->_buildall_generator($gen);
};

sub _fake_BUILD {}

around generate_method => sub {
    my ($orig, $self, $into, @args) = @_;
    no strict 'refs';
    # this ensures BuildAll generation will always be done, but allows us to
    # identify when the BUILD calls aren't needed.
    local *{"${into}::BUILD"} = \&_fake_BUILD
        if !$into->can('BUILD');
    $self->$orig($into, @args);
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords George Hartzell

=head1 NAME

MooX::StrictConstructor::Role::Constructor::Late - a role to make Moo constructors strict at the end of construction

=head1 DESCRIPTION

This role wraps L<Method::Generate::Constructor> with a bit of code
that ensures that all arguments passed to the constructor are valid init_args
for the class. The check is done at the end of construction, allowing C<BUILD>
methods to delete parameters to exempt them from the strict checks.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-StrictConstructor>
or by email to
L<bug-MooX-StrictConstructor@rt.cpan.org|mailto:bug-MooX-StrictConstructor@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

George Hartzell <hartzell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
