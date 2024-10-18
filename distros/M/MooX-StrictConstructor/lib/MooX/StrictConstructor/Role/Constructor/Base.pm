use strict;                     # redundant, but quiets perlcritic
use warnings;
package MooX::StrictConstructor::Role::Constructor::Base;

our $VERSION = '0.013';

use Moo::Role;

sub _check_strict {
    my ($self, $spec, $arg) = @_;
    my $captures = {
        '%MooX_StrictConstructor_attrs' => {
            map +($_ => 1),
            grep defined,
            map  $_->{init_arg},
            values %$spec,
        },
    };
    my $code = sprintf(<<'END_CODE', $arg);
    if ( my @bad = grep !exists $MooX_StrictConstructor_attrs{$_}, keys %%{%s} ) {
        require Carp;
        Carp::croak(
            "Found unknown attribute(s) passed to the constructor: " .
            join(", ", sort @bad)
        );
    }
END_CODE
    return ($code, $captures);
}

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
