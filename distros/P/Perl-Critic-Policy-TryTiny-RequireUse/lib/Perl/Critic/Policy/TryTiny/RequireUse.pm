package Perl::Critic::Policy::TryTiny::RequireUse;
$Perl::Critic::Policy::TryTiny::RequireUse::VERSION = '0.03';
use strict;
use warnings;

use Readonly;
use Perl::Critic::Utils qw{ :severities :classification :ppi };

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => q{Missing "use Try::Tiny"};
Readonly::Scalar my $EXPL => q{Try::Tiny blocks will execute even if the try/catch/finally functions have not been imported};

sub supported_parameters { return() }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw( bugs ) }
sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
    my ($self, $try, $doc) = @_;

    return
        unless $try->content() eq 'try'
        and $try->snext_sibling()
        and $try->snext_sibling->isa('PPI::Structure::Block');

    my $try_package = _find_package( $try );

    my $included = $doc->find_any(sub{
        $_[1]->isa('PPI::Statement::Include')
            and
        defined( $_[1]->module() )
            and (
                $_[1]->module() eq 'Error'
                    or
                $_[1]->module() eq 'Syntax::Feature::Try'
                    or
                $_[1]->module() eq 'Try'
                    or
                $_[1]->module() eq 'Try::Catch'
                    or
                $_[1]->module() eq 'Try::Tiny'
                    or
                $_[1]->module() eq 'TryCatch'
            ) and
        $_[1]->type() eq 'use'
            and
        _find_package( $_[1] ) eq $try_package
    });

    return if $included;

    return $self->violation( $DESC, $EXPL, $try );
}

sub _find_package {
    my ($element) = @_;

    my $original = $element;

    while ($element) {
        if ($element->isa('PPI::Statement::Package')) {
            # If this package statements is a block package, meaning: package { # stuff in package }
            # then if we're a descendant of it its our package.
            return $element->namespace() if $element->ancestor_of( $original );

            # If we've hit a non-block package then thats our package.
            my $blocks = $element->find_any('PPI::Structure::Block');
            return $element->namespace() if !$blocks;
        }

        # Keep walking backwards until we match the above logic or we get to
        # the document root (main).
        $element = $element->sprevious_sibling() || $element->parent();
    }

    return 'main';
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::TryTiny::RequireUse - Requires that code which utilizes
Try::Tiny actually use()es it.

=head1 DESCRIPTION

A common problem with L<Try::Tiny> is forgetting to use the module in the first
place.  For example:

    perl -e 'try { print "hello" } catch { print "world" }'
    Can't call method "catch" without a package or object reference at -e line 1.
    helloworld

If you forget this then both code blocks will be run and an exception will be thrown.
While this seems like a rare issue, when I first implemented this policy I found
several cases of this issue in real live code and due to layers of exception handling
it had gotten lost and nobody realized that there was a bug happening due to the missing
use statements.

This policy is OK if you use L<Error>, L<Syntax::Feature::Try>, L<Try>, L<Try::Catch>,
and L<TryCatch> modules which also export the C<try> function.

=head1 SEE ALSO

=over

=item *

The L<Perl::Critic::Policy::Dynamic::NoIndirect> policy provides a more generic
solution to this problem (as the author has reported to me).  Consider it as an
alternative to this policy.

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 CONTRIBUTORS

=over

=item *

Graham TerMarsch <grahamE<64>howlingfrog.com>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

