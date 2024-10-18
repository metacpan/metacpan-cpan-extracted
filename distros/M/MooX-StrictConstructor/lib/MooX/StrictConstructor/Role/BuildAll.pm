use strict;                     # redundant, but quiets perlcritic
use warnings;
package MooX::StrictConstructor::Role::BuildAll;

our $VERSION = '0.013';

use Moo::Role;

has _constructor_generator => (
    is => 'rw',
    weaken => 1,
);

around buildall_body_for => sub {
    my ($orig, $self, $into, $me, $args, @extra) = @_;

    my $con = $self->_constructor_generator;
    my $fake_BUILD = $con->can('_fake_BUILD');
    my $real_build = ! do {
        no strict 'refs';
        defined &{"${into}::BUILD"} && \&{"${into}::BUILD"} == $fake_BUILD;
    };

    my $code = '';
    if ($real_build) {
        $code .= $self->$orig($into, $me, $args, @extra);
    }
    my $arg = $args =~ /^\$\w+(?:\[[0-9]+\])?$/ ? $args : "($args)[0]";
    $code .= "do {\n" . $con->_cap_call($con->_check_strict($con->all_attribute_specs, $arg)) . "},\n";
    return $code;
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords George Hartzell

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
