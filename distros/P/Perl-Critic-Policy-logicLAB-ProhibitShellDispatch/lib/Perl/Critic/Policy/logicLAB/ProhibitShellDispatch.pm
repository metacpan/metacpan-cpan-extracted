package Perl::Critic::Policy::logicLAB::ProhibitShellDispatch;

use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw{ $SEVERITY_MEDIUM };
use 5.008;

our $VERSION = '0.05';

Readonly::Scalar my $EXPL => q{Use Perl builtin instead};

use constant supported_parameters => ();
use constant default_severity     => $SEVERITY_MEDIUM;
use constant default_themes       => qw(logiclab);

sub applies_to {

    return (
        qw(
            PPI::Statement
            PPI::Token::QuoteLike::Command
            PPI::Token::QuoteLike::Backtick
            )
    );
}

sub violates {
    my ( $self, $elem ) = @_;

    #first element PPI::Token::Word (system or exec)
    if ( ref $elem eq 'PPI::Statement' ) {

        my $word = $elem->find_first('PPI::Token::Word');

        if (    $word
            and $word =~ m{
            \A  #beginning of string
            (system|exec)
            \Z  #end of string
        }xsm
            )
        {

            #previous significant sibling
            my $sibling = $word->sprevious_sibling;

            if ( $sibling and $sibling eq '->' ) {
                return;
            } else {
                return $self->violation(
                    q{Do not use 'system' or 'exec' statements},
                    $EXPL, $elem );
            }
        }
        return;
    }

    if ( ref $elem eq 'PPI::Token::QuoteLike::Command' ) {
        return $self->violation( q{Do not use 'qx' statements}, $EXPL,
            $elem );
    }

    if ( ref $elem eq 'PPI::Token::QuoteLike::Backtick' ) {
        return $self->violation( q{Do not use 'backticks' statements},
            $EXPL, $elem );
    }

    return;
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-ProhibitShellDispatch.svg)](http://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-ProhibitShellDispatch)
[![Build Status](https://travis-ci.org/jonasbn/pcplpsd.svg?branch=master)](https://travis-ci.org/jonasbn/pcplpsd)
[![Coverage Status](https://coveralls.io/repos/jonasbn/pcplpsd/badge.png)](https://coveralls.io/r/jonasbn/pcplpsd)

=end markdown

=head1 NAME

Perl::Critic::Policy::logicLAB::ProhibitShellDispatch - simple policy prohibiting shell dispatching

=head1 AFFILIATION

This policy is a policy in the L<Perl::Critic::logicLAB> distribution.

=head1 VERSION

This documentation describes version 0.05

=head1 DESCRIPTION

Using Perl builtins to dispatch to external shell commands are not particularly
portable. This policy aims to assist the user in identifying these critical
spots in the code and exchange these for pure-perl solutions and CPAN
distributions.

The policy scans for: system, exec, qx and the use of backticks, some basic examples.

    system "touch $0.lock";
    
    exec "touch $0.lock";
    
    my $hostname = qx/hostname/;
    
    my $hostname = `hostname`;

Instead use the Perl builtins or CPAN distributions. This will make you distribution
easier to control and easier to distribute across platforms.

    #hostname
    use Net::Domain qw(hostname);

Using CPAN distributions and Perl builtins makes it easier to distribute your
code and defined you requirements to platforms in your build system.

Additional examples and remedies are most welcome, since I would love to write
a 101 demonstrating violations and their remedies.

=head1 CONFIGURATION AND ENVIRONMENT

This Policy is not configurable except for the standard options.
    
=head1 DEPENDENCIES AND REQUIREMENTS

=over

=item * L<Perl> version 5.8.0

=item * L<Perl::Critic>

=item * L<Perl::Critic::Utils>

=item * L<Readonly>

=item * L<Test::More>

=item * L<Test::Perl::Critic>

=back

=head1 INCOMPATIBILITIES

This distribution has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

This distribution has no known bugs or limitations.

As pointed out in bug report RT:91542, some modules and components might 
implement methods/routines holding names similar to the builtins C<system>, 
C<exec>, C<qx> and similar. I had not anticipated this when first implementing 
the policy and I expect there will be more cases where the current implementation 
does not handle this well, please file a bugreport if you run into one of these 
issues and I will investigate and address accordingly.

=head1 BUG REPORTING

Please use Requets Tracker for bug reporting:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-Policy-logicLAB-ProhibitShellDispatch

=head1 TEST AND QUALITY

The following policies have been disabled for this distribution

=over

=item * L<Perl::Crititc::Policy::ValuesAndExpressions::ProhibitConstantPragma>

=item * L<Perl::Crititc::Policy::NamingConventions::Capitalization>

=item * L<Documentation::RequirePodLinksIncludeText>

=back

See also F<t/perlcriticrc>

=head2 TEST COVERAGE
    
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    .../ProhibitShellDispatch.pm  100.0  100.0   83.3  100.0  100.0  100.0   98.5
    Total                         100.0  100.0   83.3  100.0  100.0  100.0   98.5
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over

=item * L<http://logiclab.jira.com/wiki/display/PCPLPSD/Home>, project Wiki

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, jonasbn C<< <jonasbn@cpan.org> >>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Johan the Olive, bug reporting on Net::OpenSSH's system (RT:91542)

=item * Adam Kennedy, author of PPI

=item * Jeffrey Ryan Thalhammer, author of Perl::Critic

=back

=head1 COPYRIGHT

Perl::Critic::Policy::logicLAB::ProhibitShellDispatch is (C) by Jonas B. Nielsen, (jonasbn) 2013-2015

Perl::Critic::Policy::logicLAB::ProhibitShellDispatch is released under the artistic license 2.0

=cut
