package Sah::Schema::cpan::meta20;

our $schema = ['hash', {
    summary  => 'CPAN Meta specification 2.0',
    req_keys => [qw/abstract author dynamic_config generated_by license meta-spec name release_status version/],
    re_keys  => {

        # sorted alphabetically

        '^[Xx]_' => ['any', {}, {}],

        '^abstract$' => ['str', {req=>1}, {}],

        '^author$' => ['array', {
            req     => 1,
            min_len => 1,
            of      => ['str', {
                req => 1,

                match             => '^\S.* <.+@.+>$',
                "match.err_level" => "warn",
                "match.err_msg"   => "preferred format is author-name <email-address>",
            }, {}],
        }, {}],

        '^build_requires$' => ['cpan::meta20::prereq', {
            forbidden             => 1,
            "forbidden.err_level" => "warn",
            "forbidden.err_msg"   => "build_requires is deprecated in spec 2 and has been replaced by prereqs",
        }, {}],

        '^configure_requires$' => ['cpan::meta20::prereq', {
            forbidden             => 1,
            "forbidden.err_level" => "warn",
            "forbidden.err_msg"   => "configure_requires is deprecated in spec 2 and has been replaced by prereqs",
        }, {}],

        '^conflicts$' => ['cpan::meta20::prereq', {
            forbidden             => 1,
            "forbidden.err_level" => "warn",
            "forbidden.err_msg"   => "conflicts is deprecated in spec 2 and has been replaced by prereqs",
        }, {}],

        '^description$' => ['str', {req=>1}, {}],

        '^distribution_type$' => ['str', {
            req    => 1,
            in     => ['module', 'script'],

            forbidden             => 1,
            "forbidden.err_level" => 'warn',
            "forbidden.err_msg"   => 'distribution_type is deprecated in spec 2 since it is meaningless for many distributions which are hybrid or modules and scripts',
        }, {}],

        '^dynamic_config$' => ['bool', {req=>1}, {}],

        '^generated_by$' => ['str', {req=>1}, {}],

        '^keywords$' => ['array', {req=>1, of => ['str', {req=>1, match=>'^\S+$'}, {}]}, {}],

        '^license$' => ['array', {req=>1, of => ['cpan::meta20::license', {req=>1}, {}]}, {}],

        '^license_uri$' => ['str', {
            forbidden             => 1,
            "forbidden.err_level" => 'warn',
            "forbidden.err_msg"   => 'license_uri is deprecated in 1.2 and has been replaced by license in resources',
        }, {}],

        '^meta-spec$' => ['hash', {
            req => 1,
            req_keys => [qw/version/],
            keys => {
              version => ['float', {req=>1, is=>2}, {}],
              url     => ['str', {req=>1}, {}],
          },
        }, {}],

        '^name$' => ['perl::distname', {req=>1}, {}],

        '^no_index$' => ['cpan::meta20::no_index', {req=>1}, {}],

        '^optional_features$' => ['hash', {
            req => 1,
            each_value => ['cpan::meta20::optional_feature', {req=>1}, {}],
        }, {}],

        '^prereqs$' => ['cpan::meta20::prereqs', {req=>1}, {}],

        '^private$' => ['cpan::meta20::no_index', {
            forbidden             => 1,
            "forbidden.err_level" => 'warn',
            "forbidden.err_msg"   => "private is deprecated in spec 1.2 and has been renamed to no_index",
        }, {}],

        '^provides$' => ['hash', {
            req => 1,
            each_key => ['perl::modname', {req=>1}, {}],
            each_value => ['hash', {
                req => 1,
                req_keys => [qw/file version/],
                keys => {
                    file => ['str', {req=>1}, {}],
                    version => ['cpan::meta20::version', {req=>1}, {}],
                },
            }, {}],
        }, {}],

        '^recommends$' => ['cpan::meta20::prereq', {
            forbidden             => 1,
            "forbidden.err_level" => "warn",
            "forbidden.err_msg"   => "recommends is deprecated in spec 2 and has been replaced by prereqs",
        }, {}],

        '^release_status$' => ['cpan::meta20::release_status', {req=>1}, {}],

        '^requires$' => ['cpan::meta20::prereq', {
            forbidden             => 1,
            "forbidden.err_level" => "warn",
            "forbidden.err_msg"   => "requires is deprecated in spec 2 and has been replaced by prereqs",
        }, {}],

        '^resources$' => ['hash', {
            req => 1,
            allowed_keys => [qw/homepage license bugtracker repository/],
            each_value => ['cpan::meta20::resource'],
        }, {}],

        '^version$' => ['cpan::meta20::version', {req=>1}, {}],

    }, # re_keys

    # XXX if version contains underscore, release_status must not be stable
}, {}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cpan::meta20

=head1 VERSION

This document describes version 0.003 of Sah::Schema::cpan::meta20 (from Perl distribution Sah-Schemas-CPANMeta), released on 2017-01-08.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPANMeta>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPANMeta>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPANMeta>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Meta>, L<CPAN::Meta::Validator>

L<validate-cpan-meta-with-sah> from L<App::ValidateCPANMetaWithSah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
