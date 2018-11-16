package Perl::Critic::Policy::TooMuchCode::ProhibitExcessiveColons;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Statement::Include' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @violations = $self->gather_violations_generic($elem, $doc);
    return @violations;
}

sub gather_violations_generic {
    my ( $self, $elem, undef ) = @_;

    # PPI::Statement::Include doesn't handle this weird case of `use Data::::Dumper`.
    # The `PPI::Statement::Include#module` method does not catch 'Data::::Dumper' as the
    # module name, but `Data::` instead.
    # So we are just use strings here.
    return unless index("$elem", "::::") > 0;

    return $self->violation(
        "Too many colons in the module name.",
        "The statement <$elem> contains so many colons to separate namespaces, while 2 colons is usually enough.",
        $elem,
    );
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitExcessiveColons - Finds '::::::::' in module names.

=head1 DESCRIPTION

In an include statement, it is possible to have a lot of colons:

    use Data::::Dumper;

... or

    use Data::::::::Dumper;

As long as the number of colons is a multiple of two.

However, just because it is doable, does not mean it is sensible.
C<use Data::::::Dumper> will make perl look for C<lib/Data///Dumper.pm>,
which is usually the same as C<lib/Data/Dumper.pm>.

This policy restrict you to use only two colons to delimit one layer of namespace.

=cut
