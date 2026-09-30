package Perl::Critic::Policy::Subroutines::ProhibitUnderscorePrivateSubs 0.001;

# ABSTRACT: Make a private sub lexical, rather than private by a leading underscore.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Private sub named with a leading underscore};
Readonly::Scalar my $EXPL => q{Make it a lexical sub: "my sub" or "my $name = sub"};

# The kinds of declaration that are scoped to a block, as PPI::Statement::Sub
# reports them.
Readonly::Hash my %LEXICAL => map { $_ => 1 } qw{ my state };


sub supported_parameters {
    return (
        {
            name           => 'allow',
            description    => 'Names of subs that another module requires to be package subs.',
            default_string => q{},
            behavior       => 'string list',
        },
    );
}
sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw{ maintenance } }
sub applies_to       { return 'PPI::Statement::Sub' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    my $type = $elem->type // q{};
    return if $LEXICAL{$type} || $elem->reserved;

    my $name = $elem->name // return;
    my ($last) = $name =~ m/(\w+)\z/sx;
    return unless defined $last && substr( $last, 0, 1 ) eq '_';
    return if $self->{_allow}{$last};

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitUnderscorePrivateSubs - Make a private sub lexical, rather than private by a leading underscore.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::Subroutines::ProhibitUnderscorePrivateSubs

It's a common convention in perl to have a leading underscore mean that a sub is private,
but nothing enforces it.  Any code can call C<Some::Module::_helper>,
a subclass can override it without knowing, and a test that calls it tests the
implementation instead of the documented interface.
A lexical sub is private in fact: nothing outside its scope can use it.

    sub _helper { ... }                  # reported
    _helper(@args);

    my sub helper { ... }                # perl 5.26 and later
    helper(@args);

    my $helper = sub { ... };            # any perl
    $helper->(@args);
    $self->$helper(@args);               # called as a method

=head2 PROHIBITED

    sub _helper { ... }
    sub _helper;                         # a forward declaration
    sub Some::Module::_helper { ... }    # the last part of the name counts
    our sub _helper { ... }              # our is a package sub

=head2 ALLOWED

    my sub helper { ... }
    state sub helper { ... }
    my $helper = sub { ... };
    sub helper { ... }                   # public, and named so
    sub _build_thing { ... }             # when allow names it, see PARAMETERS

=head1 PARAMETERS

C<allow> is a list of names, separated by whitespace, that the policy leaves
alone.  Use it for a name that another module requires to be a package sub,
such as a builder that an object system looks up by name:

    [Subroutines::ProhibitUnderscorePrivateSubs]
    allow = _build_thing _trigger_thing

=head1 CAVEATS

A method that a subclass overrides is not private, whatever its name says.
Give it a name without the underscore, and document it as the interface
between the class and its subclasses.

A lexical sub cannot be tested from outside its scope.  That is the point: test
the public sub that calls it.

A sub installed through a glob, such as C<*_helper = sub { ... }>, is not
seen.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitunderscoreprivatesubs/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
