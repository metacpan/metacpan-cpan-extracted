package Perl::Critic::Policy::logicLAB::RequireParamsValidate;

# $Id: ProhibitShellDispatch.pm 8114 2013-07-25 12:57:04Z jonasbn $

use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw{ $SEVERITY_MEDIUM };
use Data::Dumper;
use List::MoreUtils qw(any);

use 5.006;

our $VERSION = '0.03';

Readonly::Scalar my $EXPL => q{Use Params::Validate for public facing APIs};
Readonly::Scalar my $warning =>
  q{Parameter validation not complying with required standard};

use constant supported_parameters => ();
use constant default_severity     => $SEVERITY_MEDIUM;
use constant default_themes       => qw(logiclab);

## no critic (RequireParamsValidate);

sub applies_to {
    return (
        qw(
          PPI::Statement::Sub
          )
    );
}

sub violates {
    my ( $self, $elem ) = @_;

    #For debugging removing all whitespace
    $elem->prune('PPI::Token::Whitespace');

    my $words = $elem->find('PPI::Token::Word');

    if (    $words->[0]->content eq 'sub'
        and $words->[1]->content !~ m/\b_\w+\b/xsm )
    {
        return $self->_assert_params_validate( $elem, $words );
    }

    return;
}

sub _assert_params_validate {
    my ( $self, $elem, $elements ) = @_;

    my @params_validate_keywords = qw(validate validate_pos validate_with);
    my $ok;

    foreach my $word ( @{$elements} ) {
        if ( any { $word->content eq $_ } @params_validate_keywords ) {
            $ok++;
            last;
        }
    }

    if ($ok) {
        return;
    }
    else {
        return $self->violation( $warning, $EXPL, $elem );
    }
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequireParamsValidate.svg)](http://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequireParamsValidate)
[![Build Status](https://travis-ci.org/jonasbn/pcplrpv.svg?branch=master)](https://travis-ci.org/jonasbn/pcplrpv)
[![Coverage Status](https://coveralls.io/repos/jonasbn/pcplrpv/badge.png)](https://coveralls.io/r/jonasbn/pcplrpv)

=end markdown

=head1 NAME

Perl::Critic::Policy::logicLAB::RequireParamsValidate - simple policy for enforcing use of Params::Validate

=head1 AFFILIATION

This policy is a policy in the Perl::Critic::logicLAB distribution. The policy
is themed: logiclab.

=head1 VERSION

This documentation describes version 0.03

=head1 SYNOPSIS

    # ok
    sub foo {
        validate(
            @_, {
                foo => 1,    # mandatory
                bar => 0,    # optional
            }
        );

        #...
    }

    # not ok
    sub bar {
        return 1;
    }

    # ok
    sub _baz {
        return 1;
    }


Invocation of policy:

    $ perlcritic --single-policy logicLAB::RequireParamsValidate lib

Explanation:

    Use Params::Validate for public facing APIs

Description:

    Parameter validation not complying with required standard

=head1 CONFIGURATION AND ENVIRONMENT

No special requirements or environment required.

=head1 DEPENDENCIES AND REQUIREMENTS

=over

=item * L<Module::Build>

=item * L<Perl::Critic>

=item * L<Perl::Critic::Utils>

=item * L<Perl::Critic::Policy>

=item * L<Test::More>

=item * L<Test::Class>

=item * L<Test::Perl::Critic>

=item * L<Data::Dumper>

=item * L<File::Spec>

=item * L<List::MoreUtils>

=item * L<Params::Validate>

=back

=head1 INCOMPATIBILITIES

This distribution has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

There are no known bugs or limitations

=head1 TEST AND QUALITY

The following policies have been disabled for this distribution

=over

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>

Constants are good, - see the link below.

=over

=item * L<https://logiclab.jira.com/wiki/display/OPEN/Perl-Critic-Policy-ValuesAndExpressions-ProhibitConstantPragma>

=back

=item * L<Perl::Critic::Policy::NamingConventions::Capitalization>

=back

See also F<t/perlcriticrc>

=head2 TEST COVERAGE

Coverage test executed the following way, the coverage report is based on the
version described in this documentation (see L</VERSION>).

    ./Build testcover

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    .../RequireParamsValidate.pm  100.0  100.0   66.7  100.0  100.0  100.0   98.6
    Total                         100.0  100.0   66.7  100.0  100.0  100.0   98.6
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over

=item * L<Perl::Critic>

=item * L<https://metacpan.org/pod/Params::Validate>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, jonasbn C<< <jonasbn@cpan.org> >>

=back

=head1 ACKNOWLEDGEMENT

=over

=item * Jeffrey Ryan Thalhammer (THALJEF) and the Perl::Critic contributors for
Perl::Critic

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2015 Jonas B. Nielsen, jonasbn. All rights reserved.

Perl::Critic::Policy::logicLAB::RequirePackageNamePattern;  is released under
the Artistic License 2.0

The distribution is licensed under the Artistic License 2.0, as specified by
the license file included in this distribution.

=cut
