use strict;
use warnings;

use Clone qw(clone);
use Params::Validate ();

use Test::More;
END { done_testing(); }

use Test::Differences;

my %old_export_tags = %{ clone(\%Params::Validate::EXPORT_TAGS) };
my @old_export      = @{ clone(\@Params::Validate::EXPORT     ) };
my @old_export_ok   = @{ clone(\@Params::Validate::EXPORT_OK  ) };

eval 'use Params::Validate::Dependencies';

eq_or_diff(
    \%Params::Validate::EXPORT_TAGS,
    \%old_export_tags,
    '%Params::Validate::EXPORT_TAGS was left alone'
);
eq_or_diff(
    \@Params::Validate::EXPORT,
    \@old_export,
    '@Params::Validate::EXPORT was left alone'
);
eq_or_diff(
    \@Params::Validate::EXPORT_OK,
    \@old_export_ok,
    '@Params::Validate::EXPORT_OK was left alone'
);

eq_or_diff(
    $Params::Validate::Dependencies::EXPORT_TAGS{all},
    [
        @{$Params::Validate::EXPORT_TAGS{all}}, 
        @{$Params::Validate::Dependencies::EXPORT_TAGS{_of}},
        'exclusively'
    ],
    '$Params::Validate::Dependencies::EXPORT_TAGS{all} contains *_of and \'exclusively\''
);
eq_or_diff(
    \@Params::Validate::Dependencies::EXPORT,
    [
        @Params::Validate::EXPORT,
        @{$Params::Validate::Dependencies::EXPORT_TAGS{_of}},
    ],
    '@Params::Validate::Dependencies::EXPORT contains *_of'
);
eq_or_diff(
    \@Params::Validate::Dependencies::EXPORT_OK,
    [
        @Params::Validate::EXPORT_OK,
        @{$Params::Validate::Dependencies::EXPORT_TAGS{_of}},
        'exclusively'
    ],
    '@Params::Validate::Dependencies::EXPORT_OK contains *_of and \'exclusively\''
);

