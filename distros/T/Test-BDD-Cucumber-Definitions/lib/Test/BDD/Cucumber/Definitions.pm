package Test::BDD::Cucumber::Definitions;

use 5.006;
use strict;
use warnings;

use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Moose::Util::TypeConstraints;
use Params::ValidationCompiler qw(validation_for);
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Test::More;
use Try::Tiny;

=head1 NAME

Test::BDD::Cucumber::Definitions - a collection of step definitions for Test
Driven Development

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

=head1 SYNOPSIS

In file B<features/step_definitions/tbcd_steps.pl>:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::BDD::Cucumber::Definitions::TBCD::In;

In file B<features/site.feature>:

    Feature: Site
        Site tests

    Scenario: Loading the page
        When http request "GET" send "http://metacpan.org"
        Then http response code eq "200"

... and, finally, in the terminal:

    $ pherkin

      Site
        Site tests

        Scenario: Loading the page
          When http request "GET" send "http://metacpan.org"
          Then http response code eq "200"


=head1 EXPORT

The module exports functions C<S>, C<C>, C<Given>, C<When> and C<Then>.
These functions are identical to the same functions from the module
L<Test::BDD::Cucumber>.

Additionally, the module exports several functions for parameter validation.
These functions are exported by the C<:validator> tag.

By default, no functions are exported. All functions must be imported
explicitly.

=cut

our @EXPORT_OK = qw(
    S C Given When Then
    validator_i
    validator_n
    validator_s
    validator_r
    validator_ni
    validator_ns
    validator_nn
    validator_nr
);

our %EXPORT_TAGS = (
    validator => [
        qw(
            validator_i
            validator_n
            validator_s
            validator_r
            validator_ni
            validator_ns
            validator_nn
            validator_nr
            )
    ]
);

sub S { return Test::BDD::Cucumber::StepFile::S }
sub C { return Test::BDD::Cucumber::StepFile::C }

# Interpolation of variables (scenario and environment)
sub _interpolate {
    my ($value) = @_;

    my $orig = $value;

    # Scenario variables
    my $is = $value =~ s| S\{ (.+?) \} |
        S->{Var}->scenario($1) // q{};
    |gxe;

    # Environment variables
    my $ie = $value =~ s/ \$\{ (.+?) \} /
        $ENV{$1} || '';
    /gxe;

    if ( $is || $ie ) {
        diag( sprintf( q{Inteprolated value "%s" = %s}, $orig, np $value) );
    }

    return $value;
}

# TbcdInt
subtype(
    'TbcdInt',
    as 'Int',
    message {
        sprintf( '%s is not a valid TBCD Int', np $_);
    }
);

coerce(
    'TbcdInt',
    from 'Str',
    via { _interpolate $_ }
);

# TbcdStr
subtype(
    'TbcdStr',
    as 'Str',
    message {
        sprintf( '%s is not a valid TBCD Str', np $_);
    }
);

coerce(
    'TbcdStr',
    from 'Str',
    via { _interpolate $_}
);

# TbcdNonEmptyStr
subtype(
    'TbcdNonEmptyStr',
    as 'Str',
    where { length($_) > 0 },
    message {
        sprintf( '%s is not a valid TBCD NonEmptyStr', np $_);
    }
);

coerce(
    'TbcdNonEmptyStr',
    from 'Str',
    via { _interpolate $_}
);

# TbcdRegexpRef
subtype(
    'TbcdRegexpRef',
    as 'RegexpRef',
    message {
        sprintf( '%s is not a valid TBCD RegexpRef', np $_);
    }
);

coerce(
    'TbcdRegexpRef',
    from 'Str',
    via {
        my $value = _interpolate $_;

        try {
            qr/$value/;    ## no critic [RegularExpressions::RequireExtendedFormatting]
        }
        catch {
            return $value;
        };
    }
);

my $validator_i = validation_for(
    params => [

        # value integer
        { type => find_type_constraint('TbcdInt') },
    ]
);

sub validator_i {
    return $validator_i;
}

my $validator_n = validation_for(
    params => [

        # name
        { type => find_type_constraint('TbcdNonEmptyStr') },
    ]
);

sub validator_n {
    return $validator_n;
}

my $validator_s = validation_for(
    params => [

        # value string
        { type => find_type_constraint('TbcdStr') },
    ]
);

sub validator_s {
    return $validator_s;
}

my $validator_r = validation_for(
    params => [

        # value regexp
        { type => find_type_constraint('TbcdRegexpRef') }
    ]
);

sub validator_r {
    return $validator_r;
}

my $validator_ni = validation_for(
    params => [

        # name
        { type => find_type_constraint('TbcdNonEmptyStr') },

        # value int
        { type => find_type_constraint('TbcdInt') },
    ]
);

sub validator_ni {
    return $validator_ni;
}

my $validator_ns = validation_for(
    params => [

        # name
        { type => find_type_constraint('TbcdNonEmptyStr') },

        # value string
        { type => find_type_constraint('TbcdStr') }
    ]
);

sub validator_ns {
    return $validator_ns;
}

my $validator_nn = validation_for(
    params => [

        # value non empty string
        { type => find_type_constraint('TbcdNonEmptyStr') },

        # value non empty string
        { type => find_type_constraint('TbcdNonEmptyStr') },
    ]
);

sub validator_nn {
    return $validator_nn;
}

my $validator_nr = validation_for(
    params => [

        # name
        { type => find_type_constraint('TbcdNonEmptyStr') },

        # value regexp
        { type => find_type_constraint('TbcdRegexpRef') }
    ]
);

sub validator_nr {
    return $validator_nr;
}

=head1 AUTHOR

Mikhail Ivanov C<< <m.ivanych@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

=cut

1;
