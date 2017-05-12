package Perl::Critic::Policy::logicLAB::RequirePackageNamePattern;

use strict;
use warnings;
use 5.006;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw{ $SEVERITY_MEDIUM :booleans};
use Carp qw(carp);
use Data::Dumper;

our $VERSION = '0.05';

use constant supported_parameters => qw(names debug exempt_programs);
use constant default_severity     => $SEVERITY_MEDIUM;
use constant default_themes       => qw(logiclab);

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    if ( $self->{exempt_programs} && $document->is_program() ) {
        return $FALSE;
    }

    return $document->is_module();
}

sub applies_to {
    return (
        qw(
            PPI::Statement::Package
            )
    );
}

sub violates {
    my ( $self, $elem ) = @_;

    if ( not $self->{_names} ) {
        return;
    }

    my @children = $elem->children;

    if ( $children[0]->content eq 'package' ) {
        #TODO we might have to look for words here instead of using an array index
        #TODO and we should add exception in the case an actual package is not located
        my $package = $children[2]->content;

        if ($self->{debug}) {
            print STDERR "located package: $package\n";
        }

        my $no_of_patterns = scalar @{$self->{_names}};
        my $no_of_violations = 0;

        foreach my $name (@{$self->{_names}}) {
            #TODO investigate wht this is a regular expression and so are
            #actual evaluation in line 67, at least according to Perl::Critic
            #[RegularExpressions::RequireExtendedFormatting]
            my $regex = qr/$name/x;

            if ($self->{debug}) {
                print STDERR "Regex: $regex\n";
            }

            if ( $package !~ m/$regex/xs ) {
                if ($no_of_patterns > 1) {
                    $no_of_violations++;

                    if ($no_of_patterns == $no_of_violations) {
                        return $self->violation(
                            "Package name: $package is not complying with required standard",
                            "Use specified requirement for package naming for $package",
                            $elem
                        );
                    }

                } else {

                    return $self->violation(
                        "Package name: $package is not complying with required standard",
                        "Use specified requirement for package naming for $package",
                        $elem
                    );
                }
            }
        }

    } else {
        carp 'Unable to locate package keyword';
    }

    return;
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    #debug - order is significant, since we might need debugging
    $self->{debug} = $config->get('debug') || $FALSE;

    #Names:
    #fetching configured names
    my $names = $config->get('names');

    if ($self->{debug}) {
        warn "Requirements for package names are: $names\n";
    }

    #parsing configured names, see also _parse_names
    if ($names) {
        $self->{_names} = $self->_parse_names($names) || q{};
    }

    #exempt_programs
    $self->{exempt_programs} = $config->get('exempt_programs') || $TRUE;

    return $TRUE;
}

sub _parse_names {
    my ( $self, $config_string ) = @_;

    my @names = split /\s*\|\|\s*/x, $config_string;

    if ($self->{debug}) {
        print STDERR "our split line:\n";
        print STDERR Dumper \@names;
    }

    return \@names;
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequirePackageNamePattern.svg)](http://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequirePackageNamePattern)
[![Build Status](https://travis-ci.org/jonasbn/pcplrpnp.svg?branch=master)](https://travis-ci.org/jonasbn/pcplrpnp)
[![Coverage Status](https://coveralls.io/repos/jonasbn/pcplrpnp/badge.png)](https://coveralls.io/r/jonasbn/pcplrpnp)

=end markdown

=head1 NAME

Perl::Critic::Policy::logicLAB::RequirePackageNamePattern - simple policy for enforcing a package naming policy

=head1 AFFILIATION

This policy is a policy in the Perl::Critic::logicLAB distribution. The policy
is themed: logiclab.

=head1 VERSION

This documentation describes version 0.05.

=head1 DESCRIPTION

The policy can be used to enforced naming conventions for packages.

=head1 SYNOPSIS

Policy configuration:

    [logicLAB::RequirePackageNamePattern]
    names = Acme

Your package:

    package This::Is::A::Test;

        # code goes here

    1;

Invocation of policy:

    $ perlcritic --single-policy logicLAB::RequirePackageNamePattern lib

Explanation:

    Use specified requirement for package naming for This::Is::A::Test

Description:

    Package name: This::Is::A::Test is not complying with required standard

=head1 CONFIGURATION AND ENVIRONMENT

This policy allow you to configure the contents of the shebang lines you
want to allow using L</names>.

=head2 names

C<names>, is the configuration parameter used to specify the patterns you
want to enforce.

The different usage scenarios are documented below

=head3 Toplevel namespace

    [logicLAB::RequirePackageNamePattern]
    names = ^App::

=head3 Subclass

    [logicLAB::RequirePackageNamePattern]
    names = ::JONASBN$

=head3 Postfix

    [logicLAB::RequirePackageNamePattern]
    names = Utils$

=head3 Prefix

    [logicLAB::RequirePackageNamePattern]
    names = ^Acme

=head3 Contains

    [logicLAB::RequirePackageNamePattern]
    names = Tiny

=head3 Or

    [logicLAB::RequirePackageNamePattern]
    names = Acme || logicLAB

=head2 debug

Optionally and for development purposes I have added a debug flag. This can be set in
your L<Perl::Critic> configuration file as follows:

    [logicLAB::RequirePackageNamePattern]
    debug = 1

This enables more explicit output on what is going on during the actual processing of
the policy.

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
    ...uirePackageNamePattern.pm   89.2   68.2   36.4  100.0  100.0  100.0   82.5
    Total                          89.2   68.2   36.4  100.0  100.0  100.0   82.5
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over

=item * L<Perl::Critic>

=item * L<perlmod manpage|http://perldoc.perl.org/perlmod.html>

=item * L<http://logiclab.jira.com/wiki/display/PCPLRPNP/Home>

=item * L<http://logiclab.jira.com/wiki/display/PCLL/Home>

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
