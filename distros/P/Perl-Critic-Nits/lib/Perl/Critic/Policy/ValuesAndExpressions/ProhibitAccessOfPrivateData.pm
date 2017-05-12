package Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

use version; our $VERSION = qv('v1.0.0');

Readonly::Scalar my $DESC =>
    q(Private Member Data shouldn't be accessed directly.);
Readonly::Scalar my $EXPL =>
    q(Accessing an objects data directly breaks encapsulation and )
    . q(should be avoided.  Example: $object->{ some_key });

sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_HIGHEST; }
sub default_themes       { return qw/nits maintenance/; }
sub applies_to           { return qw/PPI::Token::Symbol/; }

sub violates {
    my( $self, $element, $document ) = @_;
    return unless $element->isa('PPI::Token::Symbol');

    my $sibling = $element->snext_sibling();
    return unless $sibling;
    return
        unless(    $sibling->isa('PPI::Token::Operator')
                && $sibling eq '->' );

    while( my $next_sibling = $sibling->snext_sibling() ) {
        return
            if $next_sibling->isa('PPI::Token::Structure')
            && $next_sibling eq q(;);
        if(    $next_sibling->isa('PPI::Structure::Subscript')
            && $element !~ m/(?:self|class|package)/ ) {
            return $self->violation( $DESC, $EXPL, $element, );
        }
        $sibling = $next_sibling;
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Nits>.

=head1 VERSION

This document describes Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData version 1.0.0

=head1 SYNOPSIS

Requires that modules and scripts do not break encapsulation by directly
accessing the contents of hash-based objects.

=head1 DESCRIPTION

Accessing an objects data directly breaks encapsulation and
should be avoided.  Example: $object->{ some_key }.

Care should be taken to only access private data via the getter and
setter methods provided by the class.

=head1 INTERFACE

Stadard for a L<Perl::Critic::Policy>.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

This policy has no configuration options beyond the standard ones.

=head1 DEPENDENCIES

L<Perl::Critic>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

False positives may be encountered if, internal to a module, the code does
not use $self, $class, or $package to refer to the object it represents.

Please report any bugs or feature requests to
C<bug-perl-critic-nits@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kent Cowgill, C<< <kent@c2group.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Kent Cowgill C<< <kent@c2group.net> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=3 textwidth=78 nowrap autoindent :
