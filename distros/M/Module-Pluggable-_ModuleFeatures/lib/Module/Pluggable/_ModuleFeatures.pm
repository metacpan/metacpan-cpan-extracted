## no critic: TestingAndDebugging::RequireUseStrict
package Module::Pluggable::_ModuleFeatures;

#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-04-17'; # DATE
our $DIST = 'Module-Pluggable-_ModuleFeatures'; # DIST
our $VERSION = '0.003'; # VERSION

our %FEATURES = (
    module_v => 5.2,
    set_v => {
        PluginSystem => 2,
    },
    features => {
        PluginSystem => {
            can_let_plugin_contain_multiple_handlers => 1,

            can_let_plugin_skip_hook => 0,
            can_let_plugin_skip_other_plugins => 0,
            can_let_plugin_repeat_hook => 0,
            can_let_plugin_repeat_other_plugins => 0,

            can_put_handler_in_other_hook => 0,
            can_handler_priority => 0,
            can_customize_handler_priority => 0,
            can_plugin_configuration => 1,
            can_add_multiple_handlers_from_a_plugin => 0,
        },
    },
);

1;
# ABSTRACT: Features declaration for Module::Pluggable

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Pluggable::_ModuleFeatures - Features declaration for Module::Pluggable

=head1 VERSION

This document describes version 0.003 of Module::Pluggable::_ModuleFeatures (from Perl distribution Module-Pluggable-_ModuleFeatures), released on 2024-04-17.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Pluggable-_ModuleFeatures>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Pluggable-_ModuleFeatures>.

=head1 SEE ALSO

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Pluggable-_ModuleFeatures>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
