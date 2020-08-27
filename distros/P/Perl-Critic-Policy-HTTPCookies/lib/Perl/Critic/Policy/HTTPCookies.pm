package Perl::Critic::Policy::HTTPCookies;
$Perl::Critic::Policy::HTTPCookies::VERSION = '0.54';
use strict;
use warnings;

use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw( :classification :severities );
use Readonly ();
use Scalar::Util 'blessed';

Readonly::Scalar my $DESC => 'Use of HTTP::Cookies';
Readonly::Scalar my $EXPL => 'HTTP::Cookies does not respect Public Suffix';

sub supported_parameters    {}
sub default_severity        { $SEVERITY_MEDIUM }
sub default_themes          { qw( http lwp ) }
# TODO: Review "applies_to"
sub applies_to              { 'PPI::Token::Word' }

sub violates {
    my ($self, $elem) = @_;

    # HTTP::Cookies->new
    my ($is_new_cookies) = _is_constructor($elem, 'HTTP::Cookies');
    if ($is_new_cookies) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    # LWP::UserAgent->new with default cookie jar
    else {
        my ( $is_new_ua, $args_elem ) = _is_constructor($elem, 'LWP::UserAgent');
        if ($is_new_ua) {
            if ( blessed $args_elem && $args_elem->isa('PPI::Structure::List') ) {
                foreach my $expression ($args_elem->schildren) {
                    # $expression isa PPI::Statement::Expression
                    if ( $self->_cookie_jar_violation($expression) ) {
                        return $self->violation( $DESC, $EXPL, $elem );
                    }
                }
            }
        }
    }

    return;
}

sub _cookie_jar_violation {
    my ( $self, $expression ) = @_;

    foreach my $token ($expression->schildren) {
        # TODO: Check the token's type, not just its content
        if ($token =~ /\bcookie_jar\b/) {
            my $possible_operator = $token->snext_sibling;
            if (
                blessed $possible_operator
                && $possible_operator->isa('PPI::Token::Operator')
                && $possible_operator =~ /^(?:=>|,)$/
            ) {
                my $possible_hashref = $possible_operator->snext_sibling;
                if (
                    blessed $possible_hashref
                    && $possible_hashref->isa('PPI::Structure')
                    && $possible_hashref->braces eq '{}'
                ) {
                    return 1;
                }
            }
        }
    }
    return 0;
}

sub _is_constructor {
    my ($elem, $class_name) = @_;

    my $is_constructor = 0;
    my $args_elem;

    # Detect "$class->new"
    if (
        $elem eq $class_name
        && is_class_name($elem)
        && $elem->snext_sibling eq '->'
        && $elem->snext_sibling->snext_sibling eq 'new'
    ) {
        $args_elem = $elem->snext_sibling->snext_sibling->snext_sibling;
        $is_constructor = 1;
    }
    # Detect "new $class"
    elsif (
        $elem eq 'new'
        && $elem->snext_sibling eq $class_name
    ) {
        $args_elem = $elem->snext_sibling->snext_sibling;
        $is_constructor = 1;
    }

    return ( $is_constructor, $args_elem );
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::HTTPCookies - Avoid using HTTP::Cookies

=head1 VERSION

version 0.54

=head1 DESCRIPTION

This module provides L<< Perl::Critic >> policies to detect the use of
L<< HTTP::Cookies >>.

HTTP::Cookies takes a very lenient approach to setting cookies that does
not work well with today's Internet, described in
L<< HTTP::Cookies/LIMITATIONS >>.

Consider using L<< HTTP::CookieJar >> or L<< HTTP::CookieJar::LWP >>
instead.

=head1 BUG REPORTS

Please submit bug reports to L<<
https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-HTTPCookies
>>.

If you would like to send patches, please send a git pull request to L<<
mailto:bug-Perl-Critic-Policy-HTTPCookies@rt.cpan.org >>.

=head1 AUTHOR

Tom Hukins
