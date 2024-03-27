package Module::Features::PluginSystem;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-17'; # DATE
our $DIST = 'Module-Features-PluginSystem'; # DIST
our $VERSION = '0.002'; # VERSION

our %FEATURES_DEF = (
    v => 2,
    summary => 'Features of plugin systems',
    description => <<'MARKDOWN',

**Glossary**

*Hook*: a named execution point where plugins' handlers get the chance to add
behaviors.

*Plugin*: a code packaged in a Perl module that contains extra behaviors in one
or more of /handler/s.

*Handler*: A subroutine (or method) in a /plugin/ that will get called in a
 /hook/.

*Priority*: a number between 0 and 100 signifying the order of execution of a
handler compared to handlers for the same hook from other plugins. Lower number
means a higher priority (executed first). Default priority if unspecified is 50.

MARKDOWN
    features => {
        can_let_plugin_contain_multiple_handlers => {
            summary => 'Whether a single plugin module (or class) can contain handlers for more than one hook',
            tags => ['category:packaging'],
        },

        can_let_plugin_skip_hook            => {tags=>['category:flow']},
        can_let_plugin_skip_other_plugins   => {tags=>['category:flow']},
        can_let_plugin_repeat_hook          => {tags=>['category:flow']},
        can_let_plugin_repeat_other_plugins => {tags=>['category:flow']},

        can_put_handler_in_other_hook       => {
            summary=>'Allow a plugin handler for a hook to be assigned to another hook',
            tags=>['category:flow'],
        },

        can_handler_priority                => {},
        can_customize_handler_priority      => {summary=>"Allow application user to customize the priority of a plugin's handler, without modifying source code"},
        can_plugin_configuration            => {summary=>'Allow plugin to have configuration; see also feature: '},
        can_add_multiple_handlers_from_a_plugin => {summary=>'Allow adding a plugin instance multiple times'},
        speed                               => {summary => 'Subjective speed rating, relative to other plugin system modules', schema=>['str', in=>[qw/slow medium fast/]], tags=>['category:speed']},
    },
);

1;
# ABSTRACT: Features of modules that generate text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features::PluginSystem - Features of modules that generate text tables

=head1 VERSION

This document describes version 0.002 of Module::Features::PluginSystem (from Perl distribution Module-Features-PluginSystem), released on 2024-03-17.

=head1 DESCRIPTION

B<Glossary>

I<Hook>: a named execution point where plugins' handlers get the chance to add
behaviors.

I<Plugin>: a code packaged in a Perl module that contains extra behaviors in one
or more of /handler/s.

I<Handler>: A subroutine (or method) in a /plugin/ that will get called in a
 /hook/.

I<Priority>: a number between 0 and 100 signifying the order of execution of a
handler compared to handlers for the same hook from other plugins. Lower number
means a higher priority (executed first). Default priority if unspecified is 50.

=head1 DEFINED FEATURES

Features defined by this module:

=over

=item * can_add_multiple_handlers_from_a_plugin

Optional. Type: bool. Allow adding a plugin instance multiple times. 

=item * can_customize_handler_priority

Optional. Type: bool. Allow application user to customize the priority of a plugin's handler, without modifying source code. 

=item * can_handler_priority

Optional. Type: bool. 

=item * can_let_plugin_contain_multiple_handlers

Optional. Type: bool. Whether a single plugin module (or class) can contain handlers for more than one hook. 

=item * can_let_plugin_repeat_hook

Optional. Type: bool. 

=item * can_let_plugin_repeat_other_plugins

Optional. Type: bool. 

=item * can_let_plugin_skip_hook

Optional. Type: bool. 

=item * can_let_plugin_skip_other_plugins

Optional. Type: bool. 

=item * can_plugin_configuration

Optional. Type: bool. Allow plugin to have configuration; see also feature: . 

=item * can_put_handler_in_other_hook

Optional. Type: bool. Allow a plugin handler for a hook to be assigned to another hook. 

=item * speed

Optional. Type: str. Subjective speed rating, relative to other plugin system modules. 

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Features-PluginSystem>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Features-PluginSystem>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Features-PluginSystem>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
