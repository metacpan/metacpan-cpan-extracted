package Perl::Critic::Policy::logicLAB::RequireSheBang;

# $Id$

use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw{ $SEVERITY_MEDIUM :booleans };
use List::MoreUtils qw(none);
use Data::Dumper;
use 5.008;

$Data::Dumper::Useqq = 1;

our $VERSION = '0.07';

Readonly::Scalar my $EXPL  => q{she-bang line should adhere to requirement};
Readonly::Scalar my $DEBUG => q{DEBUG logicLAB::RequireSheBang};

use constant default_severity     => $SEVERITY_MEDIUM;
use constant default_themes       => qw(logiclab);
use constant supported_parameters => qw(formats debug);

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    if ( $self->{exempt_modules} && $document->is_module() ) {
        return 0;
    }

    return $document->is_program();
}

sub violates {
    my ( $self, $element, $doc ) = @_;

    my $statement = $doc->find_first('PPI::Token::Comment');

    if ( not $statement->location()->[0] ) {
        return $self->violation( q{she-bang line not located as first line},
            $EXPL, $statement );
    }

    if ( $self->{debug} ) {
        print {*STDERR} "$DEBUG: we got statement:\n";
        print {*STDERR} Dumper $statement;
    }

    my ( $shebang, $cli ) = $element =~ m{
            \A  #beginning of string
            (\#!) #actual she-bang
            #([^\r\n]*?) #the path and possible flags
            ([/\-\w ]+?) #the path and possible flags, note the space character
            \s* #possible left over whitespace (PPI?)
            \Z #indication of end of string to assist above capture
    }xsm;

    if ($cli) {
        $cli =~ s{
            \s+ #one or more whitespace character, PCPLRSB-9 / http://logiclab.jira.com/browse/PCPLRSB-9
            $ #end of string
        }{}xsm;
    }

    if ( $self->{debug} && $shebang && $cli ) {
        print {*STDERR} "$DEBUG: we got a shebang line:\n";
        print {*STDERR} '>' . $shebang . $cli . "<\n";

        print {*STDERR} "$DEBUG: comparing against formats:\n";
        print {*STDERR} Dumper $self->{_formats};
        print {*STDERR} "\n";

    }
    elsif ( $self->{debug} ) {
        print {*STDERR} "$DEBUG: not a shebang, ignoring...\n";
    }

    if ( $shebang && none { ( $shebang . $cli ) eq $_ } @{ $self->{_formats} } )
    {

        if ( $self->{debug} ) {
            print {*STDERR} "$DEBUG: we got a violation:\n";
            print {*STDERR} '>' . $shebang . $cli . "<\n";
        }

        return $self->violation(
            q{she-bang line not conforming with requirement},
            $EXPL, $element );
    }

    return;
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    #Formats:
    #Setting the default
    $self->{_formats} = [ ('#!/usr/local/bin/perl') ];

    #fetching configured formats
    my $formats = $config->get('formats');

    #parsing configured formats, see also _parse_formats
    if ($formats) {
        $self->{_formats} = $self->_parse_formats($formats);
    }

    #debug
    $self->{debug} = $config->get('debug') || 0;

    #exempt_modules
    $self->{exempt_modules} = $config->get('exempt_modules') || 1;

    return $TRUE;
}

sub _parse_formats {
    my ( $self, $config_string ) = @_;

    my @formats = split m{ \s* [||]+ \s* }xsm, $config_string;

    return \@formats;
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequireSheBang.svg)](http://badge.fury.io/pl/Perl-Critic-Policy-logicLAB-RequireSheBang)
[![Build Status](https://travis-ci.org/jonasbn/pcplrsb.svg?branch=master)](https://travis-ci.org/jonasbn/pcplrsb)
[![Coverage Status](https://coveralls.io/repos/jonasbn/pcplrsb/badge.png)](https://coveralls.io/r/jonasbn/pcplrsb)

=end markdown

=head1 NAME

Perl::Critic::Policy::logicLAB::RequireSheBang - simple policy for keeping your shebang line uniform

=head1 AFFILIATION

This policy is a policy in the Perl::Critic::logicLAB distribution. The policy
is themed: logiclab.

=head1 VERSION

This documentation describes version 0.07.

=head1 DESCRIPTION

This policy is intended in guarding your use of the shebang line. It assists
in making sure that your shebang line adheres to certain formats.

The default format is

    #!/usr/local/bin/perl

You can however specify another or define your own in the configuration of the
policy.

B<NB> this policy does currently not warn about missing shebang lines, it only
checks shebang lines encountered.

=head1 CONFIGURATION AND ENVIRONMENT

This policy allow you to configure the contents of the shebang lines you
want to allow using L</formats>.

=head2 formats

    [logicLAB::RequireSheBang]
    formats = #!/usr/local/bin/perl || #!/usr/bin/perl || #!perl || #!env perl

Since the default shebang line enforced by the policy is:

    #!/usr/local/bin/perl

Please note that if you however what to extend the pattern, you also have
to specify was is normally the default pattern since configuration
overwrites the default even for extensions.

This mean that if you want to allow:

    #!/usr/local/bin/perl

    #!/usr/local/bin/perl -w

    #!/usr/local/bin/perl -wT

Your format should look like the following:

    [logicLAB::RequireSheBang]
    formats = #!/usr/local/bin/perl || #!/usr/local/bin/perl -w || #!/usr/local/bin/perl -wT

=head2 exempt_modules

You can specify if you want to check modules also. The default is to exempt from checking
shebang lines in modules.

    [logicLAB::RequireSheBang]
    exempt_modules = 0

=head2 debug

Optionally and for development purposes I have added a debug flag. This can be set in
your L<Perl::Critic> configuration file as follows:

    [logicLAB::RequireSheBang]
    debug = 1

This enables more explicit output on what is going on during the actual processing of
the policy.

=head1 DEPENDENCIES AND REQUIREMENTS

=over

=item * L<Perl::Critic>

=item * L<Perl::Critic::Utils>

=item * L<Readonly>

=item * L<Test::More>

=item * L<Test::Perl::Critic>

=item * L<List::MoreUtils>

=back

=head1 INCOMPATIBILITIES

This distribution has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The distribution has now known bugs or limitations. It locates shebang lines
through out the source code, not limiting itself to the first line. This might
however change in the future, but will propably be made configurable if possible.

=head1 BUG REPORTING

Please use Request Tracker for bug reporting:

=over

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-logicLAB-RequireSheBang>

=back

=head1 TEST AND QUALITY

The following policies have been disabled for this distribution

=over

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>

Constants are good, - see the link below.

=over

=item * L<https://logiclab.jira.com/wiki/display/OPEN/Perl-Critic-Policy-ValuesAndExpressions-ProhibitConstantPragma>

=back

=item * L<Perl::Critic::Policy::NamingConventions::Capitalization>

=item * L<Data::Dumper>

=back

See also F<t/perlcriticrc>

=head2 TEST COVERAGE

Coverage test executed the following way, the coverage report is based on the
version described in this documentation (see L</VERSION>).

    ./Build testcover

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...ogicLAB/RequireSheBang.pm   70.4   64.3   44.4  100.0  100.0  100.0   72.1
    Total                          70.4   64.3   44.4  100.0  100.0  100.0   72.1
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over

=item * L<Perl::Critic>

=item * L<http://perldoc.perl.org/perlrun.html>

=item * L<http://logiclab.jira.com/wiki/display/OPEN/Development#Development-MakeyourComponentsEnvironmentAgnostic>

=item * L<http://logiclab.jira.com/wiki/display/PCPLRSB/Home>

=item * L<http://logiclab.jira.com/wiki/display/PCLL/Home>

=back

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, jonasbn C<< <jonasbn@cpan.org> >>

=back

=head1 ACKNOWLEDGEMENT

=over

=item * Erik Johansen (uniejo), feedback to version 0.01

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2015 Jonas B. Nielsen, jonasbn. All rights reserved.

Perl::Critic::Policy::logicLAB::RequireSheBang is released under
the Artistic License 2.0

The distribution is licensed under the Artistic License 2.0, as specified by
the license file included in this distribution.

=cut
