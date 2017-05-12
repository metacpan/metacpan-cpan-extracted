package Perl::Critic::Policy::logicLAB::RequireVersionFormat;

# $Id$

use strict;
use warnings;
use base
  qw(Perl::Critic::Policy::Modules::RequireVersionVar Perl::Critic::Policy);
use Perl::Critic::Utils qw{ $SEVERITY_MEDIUM :booleans };
use List::MoreUtils qw(any);
use Carp qw(carp croak);
use 5.008;

our $VERSION = '0.08';

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $EXPL =>
  q{"$VERSION" variable should conform with the configured};
Readonly::Scalar my $DESC => q{"$VERSION" variable not conforming};
## critic [ValuesAndExpressions::RequireInterpolationOfMetachars]
use constant supported_parameters => qw(strict_quotes ignore_quotes formats);
use constant default_severity     => $SEVERITY_MEDIUM;
use constant default_themes       => qw(logiclab);
use constant applies_to           => 'PPI::Document';

my @strip_tokens = qw(
  PPI::Token::Structure
  PPI::Token::Whitespace
);

my @parsable_tokens = qw(
  PPI::Token::Quote::Double
  PPI::Token::Quote::Single
  PPI::Token::Number::Float
  PPI::Token::Number::Version
);

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $version_spec = q{};
    my $separator;

    if ( my $stmt = $doc->find_first( \&_is_version_declaration_statement ) ) {

        my $tokenizer = PPI::Tokenizer->new( \$stmt );
        my $tokens    = $tokenizer->all_tokens;

        ( $version_spec, $separator ) = $self->_extract_version($tokens);
    }

    if ( $version_spec and $self->{_strict_quotes} and $separator ) {
        if ( $separator ne q{'} ) {
            return $self->violation( $DESC, $EXPL, $doc );
        }
    }

    if ( $version_spec and $self->{_ignore_quotes} and $separator ) {
        $version_spec =~ s/$separator//xsmg;
    }

    my $ok;

    foreach my $format ( @{ $self->{_formats} } ) {
        if ( $version_spec and $version_spec =~ m/$format/xsm ) {
            $ok++;
        }
    }

    if ( $version_spec and not $ok ) {
        return $self->violation( $DESC, $EXPL, $doc );
    }

    return;
}

sub _parse_formats {
    my ( $self, $config_string ) = @_;

    my @formats = split m{ \s* [||] \s* }xms, $config_string;

    return \@formats;
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    #Setting the default
    $self->{_formats} = [qw(\A\d+\.\d+(_\d+)?\z)];

    $self->{_strict_quotes} = $config->get('strict_quotes') || 0;
    $self->{_ignore_quotes} = $config->get('ignore_quotes') || 1;

    my $formats = $config->get('formats');

    if ($formats) {
        $self->{_formats} = $self->_parse_formats($formats);
    }

    return $TRUE;
}

sub _extract_version {
    my ( $self, $tokens ) = @_;

    ##stripping whitespace and structure tokens
    my $i = 0;
    foreach my $t ( @{$tokens} ) {
        if ( any { ref $t eq $_ } @strip_tokens ) {
            splice @{$tokens}, $i, 1;
        }
        $i++;
    }

    #Trying to locate and match version containing token
    foreach my $t ( @{$tokens} ) {
        if ( any { ref $t eq $_ } @parsable_tokens ) {
            if ( $t->{separator} ) {
                return ( $t->content, $t->{separator} );
            }
            else {
                return $t->content;
            }
        }
    }

    return;
}

sub _is_version_declaration_statement {    ## no critic (ArgUnpacking)
    return 1 if _is_our_version(@_);
    return 1 if _is_vars_package_version(@_);
    return 0;
}

sub _is_our_version {
    my ( undef, $elem ) = @_;
    return if not $elem;
    $elem->isa('PPI::Statement::Variable') || return 0;
    $elem->type() eq 'our' || return 0;
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    return any { $_ eq '$VERSION' } $elem->variables();
}

sub _is_vars_package_version {
    my ( undef, $elem ) = @_;
    return if not $elem;
    $elem->isa('PPI::Statement') || return 0;
    return any {
        $_->isa('PPI::Token::Symbol')
          and $_->content =~ m{ \A \$(\S+::)*VERSION \z }xms;
    }
    $elem->children();
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequireVersionFormat.svg)](http://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequireVersionFormat)
[![Build Status](https://travis-ci.org/jonasbn/pcpmrvf.svg?branch=master)](https://travis-ci.org/jonasbn/pcpmrvf)
[![Coverage Status](https://coveralls.io/repos/jonasbn/pcpmrvf/badge.png)](https://coveralls.io/r/jonasbn/pcpmrvf)

=end markdown

=head1 NAME

Perl::Critic::Policy::logicLAB::RequireVersionFormat - assert version number formats

=head1 AFFILIATION

This policy is part of L<Perl::Critic::logicLAB> distribution.

=head1 VERSION

This documentation describes version 0.05

=head1 DESCRIPTION

This policy asserts that a specified version number conforms to a specified
format.

The default format is the defacto format used on CPAN. X.X and X.X_X where X
is an arbitrary integer, in the code this is expressed using the following
regular expression:

    \A\d+\.\d+(_\d+)?\z

The following example lines would adhere to this format:

=over

=item * 0.01, a regular release

=item * 0.01_1, a developer release

=back

Scope, quoting and representation does not matter. If the version specification
is lazy please see L</EXCEPTIONS>.

The following example lines would not adhere to this format and would result in
a violation.

=over

=item * our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;

=item * $VERSION = '0.0.1';

=item * $MyPackage::VERSION = 1.0.61;

=item * use version; our $VERSION = qv(1.0.611);

=item * $VERSION = "0.01a";

=back

In addition to the above examples, there are variations in quoting etc. all
would cause a violation.

=head2 EXCEPTIONS

In addition there are some special cases, were we simply ignore the version,
since we cannot assert it in a reasonable manner. 

=over

=item * our $VERSION = $Other::VERSION;

We hope that $Other::VERSION conforms where defined, so we ignore for now.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head2 strict_quotes

Strict quotes is off by default.

Strict quotes enforces that you version number must be quoted, like so:
'0.01' and "0.01". 0.01 would in this case cause a violation. This
would also go for any additional formats you could configure as valid using
the L</formats> parameter below.

    [logicLAB::RequireVersionFormat]
    strict_quotes = 1

=head2 ignore_quotes

Ignore quotes is on by default.

0.01, '0.01' and "0.01" would be interpreted as the same.

Disabling ignore quotes, would mean that: '0.01' and "0.01" would violate the
default format since quotes are not specifed as part of the pattern. This
would also go for any additional formats you could configure as valid using
the L</formats> parameter below.

    [logicLAB::RequireVersionFormat]
    ignore_quotes = 0

=head2 formats

If no formats are specified, the policy only enforces the default format
mentioned in L</DESCRIPTION> in combination with the above two configuration
parameters of course.

    [logicLAB::RequireVersionFormat]
    formats = \A\d+\.\d+(_\d+)?\z || \Av\d+\.\d+\.\d+\z

=head1 DEPENDENCIES AND REQUIREMENTS

=over

=item * L<Perl::Critic>

=item * L<Perl::Critic::Utils>

=item * L<Readonly>

=item * L<Test::More>

=item * L<Test::Perl::Critic>

=back

=head1 INCOMPATIBILITIES

This distribution has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

I think it would be a good idea to ignore this particular version string and versions thereof:

    our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;

I am however still undecided.

=head1 BUG REPORTING

Please use Requets Tracker for bug reporting:

        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-logicLAB-Prohibit-RequireVersionFormat

=head1 TEST AND QUALITY

The following policies have been disabled for this distribution

=over

=item * L<Perl::Crititc::Policy::ValuesAndExpressions::ProhibitConstantPragma>

=item * L<Perl::Crititc::Policy::NamingConventions::Capitalization>

=back

=head2 TEST COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...B/RequireVersionFormat.pm   97.9   75.0   68.2  100.0  100.0  100.0   89.8
    Total                          97.9   75.0   68.2  100.0  100.0  100.0   89.8
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 TODO

=over

=item * I would like to integrate the features of this policy into L<Perl::Critic::Policy::Modules::RequireVersionVar>, but I was aiming for a proof of concept first - so this planned patch is still in the pipeline.

=item * Address the limitation listed in L</BUGS AND LIMITATIONS>.

=back

=head1 SEE ALSO

=over

=item * L<http://logiclab.jira.com/wiki/display/OPEN/Versioning>

=item * L<version>

=item * L<http://search.cpan.org/dist/Perl-Critic/lib/Perl/Critic/Policy/Modules/RequireVersionVar.pm>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, jonasbn C<< <jonasbn@cpan.org> >>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2015 Jonas B. Nielsen. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
