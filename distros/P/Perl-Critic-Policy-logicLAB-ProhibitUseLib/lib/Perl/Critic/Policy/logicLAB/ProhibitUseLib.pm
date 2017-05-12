package Perl::Critic::Policy::logicLAB::ProhibitUseLib;

use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw{ $SEVERITY_MEDIUM };
use 5.008;    #5.8.0

our $VERSION = '0.04';

Readonly::Scalar my $EXPL => q{Use PERL5LIB environment instead};

use constant supported_parameters => ();
use constant default_severity     => $SEVERITY_MEDIUM;
use constant default_themes       => qw(logiclab);
use constant applies_to           => 'PPI::Statement::Include';

sub violates {
    my ( $self, $elem ) = @_;

    my $child = $elem->schild(1);    #second token
    return if !$child;    #return if no token, this will not be relevant to us

    #second token should read: lib
    #See t/test.t for examples of variations
    $child =~ m{
        \A  #beginning of string
        lib #the word 'lib'
        \Z  #end of string
    }xsm or return;

    return $self->violation( q{Do not use 'use lib' statements}, $EXPL,
        $child );
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-ProhibitUseLib.svg)](http://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-ProhibitUseLib)
[![Build Status](https://travis-ci.org/jonasbn/pcpmpul.svg?branch=master)](https://travis-ci.org/jonasbn/pcpmpul)
[![Coverage Status](https://coveralls.io/repos/jonasbn/pcpmpul/badge.png)](https://coveralls.io/r/jonasbn/pcpmpul)

=end markdown

=head1 NAME

Perl::Critic::Policy::logicLAB::ProhibitUseLib - simple policy prohibiting the use of 'use lib'

=head1 AFFILIATION

This policy is a policy in the L<Perl::Critic::logicLAB> distribution.

=head1 VERSION

This documentation describes version 0.03

=head1 DESCRIPTION

The 'use lib' statement, hardcodes the include path to be used. This can give
issues when moving modules and scripts between diverse environments.

    use lib '/some/path';                                       #not ok
    use lib qw(/you/do/not/want/to/go/down/this/path /or/this); #not ok

Instead use the environment variable PERL5LIB

    #bash
    export PERL5LIB='/some/path/some/where'

    #tcsh and csh
    setenv PERL5LIB '/some/path/some/where'

=head1 CONFIGURATION AND ENVIRONMENT

This Policy is not configurable except for the standard options.

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

Currently the policy has no special opinion on L<FindBin>. It only aims to
address messy, misleading, buggy and obscuring use of 'use lib'.

=head1 BUG REPORTING

Please use Requets Tracker for bug reporting:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-logicLAB-ProhibitUseLib

=head1 TEST AND QUALITY

The following policies have been disabled for this distribution

=over

=item * L<Perl::Crititc::Policy::ValuesAndExpressions::ProhibitConstantPragma>

=item * L<Perl::Crititc::Policy::NamingConventions::Capitalization>

=back

See also F<t/perlcriticrc>

=head2 TEST COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...ogicLAB/ProhibitUseLib.pm  100.0   50.0    n/a  100.0  100.0  100.0   95.3
    Total                         100.0   50.0    n/a  100.0  100.0  100.0   95.3
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over

=item * L<http://perldoc.perl.org/perlrun.html#ENVIRONMENT>

=item * L<http://logiclab.jira.com/wiki/display/OPEN/Development#Development-MakeyourComponentsEnvironmentAgnostic>

=item * L<http://logicLAB.jira.com/wiki/display/PCPMPUL/Home>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, jonasbn C<< <jonasbn@cpan.org> >>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2014 Jonas B. Nielsen. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
