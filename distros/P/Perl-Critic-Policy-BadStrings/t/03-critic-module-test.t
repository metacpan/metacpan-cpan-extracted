#!/usr/bin/perl

#
# Copyright (C) 2017 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended 0.000058;
use File::FindStrings::Boilerplate 'script';

use Perl::Critic 1.130;
use Perl6::Slurp;

# Monkey patch known bad policies that might be on smoke tester machines
#
MONKEYPATCH: {
    use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
    use Perl::Critic::PolicyFactory;
    use Perl::Critic::Utils qw{ policy_long_name };

    my (@BADPOLICIES) = qw(
      Perl::Critic::Policy::ProhibitSmartmatch
    );

    no warnings qw( redefine );
    # This is basically 1.130 Perl::Critic's create_policy.  VERY ugly.
    sub Perl::Critic::PolicyFactory::create_policy {
        my ( $self, %args ) = @_;

        my $policy_name = $args{-name} or throw_internal q{The -name argument is required};

        # The only line not in Perl::Critic's original create_policy
        if ( grep { $_ eq $args{-name} } @BADPOLICIES ) {
            return;
        }

        # Normalize policy name to a fully-qualified package name
        $policy_name = Perl::Critic::PolicyFactory::policy_long_name($policy_name);
        my $policy_short_name = Perl::Critic::PolicyFactory::policy_short_name($policy_name);

        # Get the policy parameters from the user profile if they were
        # not given to us directly.  If none exist, use an empty hash.
        my $profile = $self->_profile();
        my $policy_config;
        if ( $args{-params} ) {
            $policy_config = Perl::Critic::PolicyConfig->new( $policy_short_name, $args{-params} );
        } else {
            $policy_config = $profile->policy_params($policy_name);
            $policy_config ||= Perl::Critic::PolicyConfig->new($policy_short_name);
        }

        # Pull out base parameters.
        return $self->_instantiate_policy( $policy_name, $policy_config );
    }
}

MAIN: {
    my (@tests) = (
        {
            file       => 't/data/Boilerplate.txt',
            conf       => 't/data/03.01.conf',
            violations => ['Bad string in source file: "Joelle Maslak"'],
            note       => 'Perl file search with found word',
        },
        {
            file       => 't/data/Boilerplate.txt',
            conf       => 't/data/03.02.conf',
            violations => ['Bad string in source file: "Joelle Maslak"'],
            note       => 'Perl file search with some found words',
        },
        {
            file       => 't/data/Boilerplate.txt',
            conf       => 't/data/03.03.conf',
            violations => [],
            note       => 'Perl file search without found word',
        },
        {
            file       => 't/data/Boilerplate.txt',
            conf       => 't/data/03.03.conf',
            violations => [],
            note       => 'Perl file search without any found word',
        },
    );

    foreach my $test (@tests) {
        my $str = slurp( $test->{file} );

        my $critic = Perl::Critic->new(
            '-profile'       => $test->{conf},
            '-single-policy' => 'BadStrings',
        );
        my (@violations) = $critic->critique( \$str );
        my (@descriptions) = map { $_->description } @violations;

        is( \@descriptions, $test->{violations}, $test->{note} );
    }

    done_testing;
}

1;

