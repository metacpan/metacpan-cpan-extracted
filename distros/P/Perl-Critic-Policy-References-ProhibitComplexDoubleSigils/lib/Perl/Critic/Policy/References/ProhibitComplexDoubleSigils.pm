#
# Copyright (C) 2015 Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.20.1 or,
# at your option, any later version of Perl 5 you may have available.
#

package Perl::Critic::Policy::References::ProhibitComplexDoubleSigils;

use strict;
use warnings;

use Readonly;
use List::Util;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '0.2';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Complex double-sigil dereferences};
Readonly::Scalar my $EXPL => q{Found complex double-sigil dereference without curly braces.};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_LOW      }
sub default_themes       { return qw(cosmetic)       }
sub applies_to           { return 'PPI::Token::Cast' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem) = @_;

    return if $elem eq q{\\};

    my $sib = $elem->snext_sibling;

    return if !$sib;
    return if $sib->isa('PPI::Structure::Block');

    if ($sib->isa('PPI::Token::Symbol')) {
        my $next_sib = $sib->snext_sibling;
        return if !$next_sib;

        # e.g $$fobar[0]->{a} or $$foo{key}->[6]
        if ($next_sib->isa('PPI::Structure::Subscript')) {
            return $self->violation( $DESC, $EXPL, $elem );
        }
        # e.g. &$foobar(1, 2, 3)
        elsif ($next_sib->isa('PPI::Structure::List')) {
            return $self->violation( $DESC, $EXPL, $elem );
        }
        # e.g. @$foobar->{foo}->[0]
        elsif ($next_sib->isa('PPI::Token::Operator') && $next_sib eq q/->/) {
            return $self->violation( $DESC, $EXPL, $elem );
        }
    }

    return; #ok!
}

'Bei Mir Bistu Shein';

__END__

=head1 NAME

Perl::Critic::Policy::References::ProhibitComplexDoubleSigils - allow C<$$foo>
but not C<$$foo[1]-E<gt>{dadsdas}-E<gt>[7]>.

=head1 DESCRIPTION

This L<Perl::Critic> policy is very similar to
L<Perl::Critic::Policy::References::ProhibitDoubleSigils> but it allows
non-complex double sigil dereferences, for details see EXAMPLES and RATIONALE
sections.

=head1 EXAMPLES

    # These are allowed:
    my @array = @$arrayref;
    my %hash = %$hashref;
    my $scalar = $$scalarref;

    for (@$arrayref) {
        ...
    }

    # These are not:
    my $scalar = $$arrayref[0]->{foobar}; # use these instead:
                                          # $arrayref->[0]->{foobar}
                                          # ${$arrayref}[0]->{foobar}

    my $scalar = $$hashref{bar}->[1]; # use these instead:
                                      # $hashref->{bar}->[1]
                                      # ${$hashref}{bar}->[1]

    &$coderef()->{1234}->[1]; # use these instead:
                              # $coderef->()->{1234}->[1]
                              # &{$coderef}()->{1234}->[1]

    ...

=head1 RATIONALE

There are some cases when using braces in dereferences makes sense, I don't
deny it, but in my opinion it reduces code readability in most common cases.
L<Perl::Critic::Policy::References::ProhibitDoubleSigils> is simply too
strict. Consider following examples:

    # exhibit A:
    for (@{$foo}) {
        ...
    }

    # exhibit B:
    for (@$foo) {
        ...
    }

If you think that C<B> is more legible, this critic policy is for you.

=head1 CAVEATS

Enabling both L<Perl::Critic::Policy::References::ProhibitDoubleSigils> and
this policy is not a very wise choice.

=head1 EXPORT

None by default.

=head1 FOSSIL REPOSTIORY

Perl::Critic::policy::References::ProhibitComplexDoubleSigils Fossil repository
is hosted at xenu.tk:

    http://code.xenu.tk/repos.cgi/prohibit-complex-double-sigils

=head1 SEE ALSO

=over 4

=item *
L<Perl::Critic>

=item *
L<Perl::Critic::Policy::References::ProhibitDoubleSigils>

=back

=head1 AUTHOR

Tomasz Konojacki <me@xenu.tk>, http://xenu.tk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Tomasz Konojacki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
