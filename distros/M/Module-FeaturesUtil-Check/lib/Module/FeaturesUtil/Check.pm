package Module::FeaturesUtil::Check;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Module-FeaturesUtil-Check'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       check_feature_set_spec
                       check_features_decl
               );

our %SPEC;

$SPEC{check_feature_set_spec} = {
    v => 1.1,
    summary => 'Check feature set specification',
    args => {
        feature_set_spec => {
            schema => 'hash*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
};
sub check_feature_set_spec {
    require Data::Sah;
    require Hash::DefHash;

    my $spec = shift;
    my @warnings;

    my $dh;
    eval { $dh = Hash::DefHash->new($spec) }
        or return [500, "Spec is not a valid defhash: $@"];
    ref $spec->{features} eq 'HASH'
        or return [500, "Features properties is not defined or not a hash"];

    for my $fname (sort keys %{ $spec->{features} }) {
        length $fname
            or return [500, "Feature name cannot be empty"];
        $fname =~ /\A\w+\z/
            or push @warnings, "Feature name '$fname' does not match preferred pattern /\\w+/";
        my $fspec = $spec->{features}{$fname};
        eval { $dh = Hash::DefHash->new($fspec) }
            or return [500, "Spec for feature '$fname' is not a valid defhash: $@"];
        if ($fspec->{schema}) {
            eval { Data::Sah::gen_validator($fspec->{schema}) }
                or return [500, "Schema for feature '$fname' is invalid: $@"];
        }
    } # for fname

    # XXX check known properties

    [200, "OK", undef, {"func.warnings"=>\@warnings}];
}

$SPEC{check_features_decl} = {
    v => 1.1,
    summary => 'Check features declaration',
    args => {
        features_decl => {
            schema => 'hash*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
};
sub check_features_decl {
    require Data::Sah;
    require Hash::DefHash;

    my $features_decl = shift;

    ref $features_decl eq 'HASH'
        or return [500, "Features declaration is not a hash"];

    ref $features_decl->{features} eq 'HASH'
        or return [500, "Features declaration does not have 'features' property or it is not a hash"];

    my $set_v = $features_decl->{set_v} // {};
    ref $set_v eq 'HASH' or return [500, "set_v must be a hash"];

    for my $fsetname (sort keys %{ $features_decl->{features} }) {
        $fsetname =~ /\A\w+(::\w+)*\z/
            or return [500, "Feature set name '$fsetname' is invalid, please use regular Perl namespace e.g. Foo::Bar"];

        # retrieve feature set spec from definer module
        my $mod = "Module::Features::$fsetname";
        (my $modpm = "$mod.pm") =~ s!::!/!g;
        eval { require $modpm; 1 }
            or return [500, "Cannot get specification for feature set '$fsetname': $@"];
        my $feature_set_spec = \%{"$mod\::FEATURES_DEF"};
        my $res = check_feature_set_spec($feature_set_spec);
        $res->[0] == 200
            or return [500, "Specification for feature set '$fsetname' is invalid: $res->[1]"];

        my $set_features = $features_decl->{features}{$fsetname};
        ref $set_features eq 'HASH'
            or return [500, "Features for set '$fsetname' is not a hash"];

        # check versions
        {
            my $set_v_in_spec = $feature_set_spec->{v} // 1;
            my $set_v_in_decl = $set_v->{$fsetname} // 1;
            $set_v_in_decl == $set_v_in_spec
                or return [500, "Features declaration uses version $set_v_in_decl of feature set, while feature set specification is at version $set_v_in_spec"];
        }

        # check required features
        for my $fname (sort keys %{ $feature_set_spec->{features} }) {
            my $fspec = $feature_set_spec->{features}{$fname};
            next unless $fspec->{req};
            exists $set_features->{$fname}
                or return [500, "Missing declaration of required feature '$fname' in set '$fsetname'"];
        }

        for my $fname (sort keys %$set_features) {
            my $fspec = $feature_set_spec->{features}{$fname}
                or return [500, "Feature '$fname' is unknown in set '$fsetname'"];

            my $fschema = $fspec->{schema};
            if ($fschema) {
                my $vdr = Data::Sah::gen_validator($fschema, {return_type=>'str_errmsg+val'});
                my $fvalue = $set_features->{$fname};
                $fvalue = ref $fvalue eq 'HASH' ? $fvalue->{value} : $fvalue;
                my $res = $vdr->($fvalue);
                !$res->[0]
                    or return [500, "Invalid value for feature '$fname' in set '$fsetname': $res->[0]"];
            }
        } # for fname
    } # for fsetname

    # XXX check known properties

    [200];
}

1;
# ABSTRACT: Check feature set specification and feature declaration (following Module::Features specification)

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::FeaturesUtil::Check - Check feature set specification and feature declaration (following Module::Features specification)

=head1 VERSION

This document describes version 0.006 of Module::FeaturesUtil::Check (from Perl distribution Module-FeaturesUtil-Check), released on 2021-07-31.

=head1 DESCRIPTION

See L<Module::Features/"GLOSSARY"> for terminology.

=head1 FUNCTIONS


=head2 check_feature_set_spec

Usage:

 check_feature_set_spec($feature_set_spec) -> [$status_code, $reason, $payload, \%result_meta]

Check feature set specification.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$feature_set_spec>* => I<hash>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_features_decl

Usage:

 check_features_decl($features_decl) -> [$status_code, $reason, $payload, \%result_meta]

Check features declaration.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$features_decl>* => I<hash>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-FeaturesUtil-Check>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-FeaturesUtil-Check>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-FeaturesUtil-Check>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
