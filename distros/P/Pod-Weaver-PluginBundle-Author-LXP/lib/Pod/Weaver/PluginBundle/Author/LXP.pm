use strict;
use warnings;

package Pod::Weaver::PluginBundle::Author::LXP;
{
  $Pod::Weaver::PluginBundle::Author::LXP::VERSION = '1.0.0';
}
# ABSTRACT: configure Pod::Weaver like LXP


use Pod::Elemental::Transformer::List 0.101610 ();
use Pod::Weaver 3.101634 (); # for Legal "license" attribute
use Pod::Weaver::Plugin::StopWords 1.003 ();
use Pod::Weaver::Section::SeeAlso 1.001 (); # for "header" attribute
use Pod::Weaver::Section::Support 1.001 (); # for repository attributes

use constant VERSION_FORMAT_STR =>
    'This module is part of distribution %r v%v.%n%n'
    . "This distribution's version numbering follows the conventions "
    . 'defined at L<semver.org|http://semver.org/>.';

use constant REPOSITORY_CONTENT_STR =>
    'The source code for this distribution is available online in a '
    . 'L<Git|http://git-scm.com/> repository.  Please feel welcome '
    . "to contribute patches.\n\n";

use Pod::Weaver::Config::Assembler ();
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }


sub mvp_bundle_config { (

    [ '@Author::LXP/CorePrep', _exp('@CorePrep'), {} ],
    [ '@Author::LXP/StopWords', _exp('-StopWords'), {} ],
    [
        '@Author::LXP/List',
        _exp('-Transformer'),
        { transformer => 'List' },
    ],
    [ '@Author::LXP/Name', _exp('Name'), {} ],
    [
        '@Author::LXP/Version',
        _exp('Version'),
        { format => VERSION_FORMAT_STR },
    ],
    [ 'SYNOPSIS', _exp('Generic'), {} ],
    [ 'DESCRIPTION', _exp('Generic'), { required => 1 } ],
    [ '@Author::LXP/Leftovers', _exp('Leftovers'), {} ],
    [
        '@Author::LXP/Attributes',
        _exp('Collect'),
        { command => 'attr', header => 'ATTRIBUTES' },
    ],
    [
        '@Author::LXP/Methods',
        _exp('Collect'),
        { command => 'method', header => 'METHODS' },
    ],
    [
        '@Author::LXP/SeeAlso',
        _exp('SeeAlso'),
        { header => '', add_main_link => 0 },
    ],
    [
        '@Author::LXP/Support',
        _exp('Support'),
        {
            perldoc             => 0,
            websites            => 'none',
            repository_content  => REPOSITORY_CONTENT_STR,
        },
    ],
    [ '@Author::LXP/Authors', _exp('Authors'), {} ],
    [
        '@Author::LXP/Legal',
        _exp('Legal'),
        { license_file => 'LICENSE' },
    ],

) }

1;

__END__

=pod

=for :stopwords Alex Peters cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Pod::Weaver::PluginBundle::Author::LXP - configure Pod::Weaver like LXP

=head1 VERSION

This module is part of distribution Pod-Weaver-PluginBundle-Author-LXP v1.0.0.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 SYNOPSIS

In F<weaver.ini>:

    [@Author::LXP]

=head1 DESCRIPTION

This L<Pod::Weaver> plugin bundle configures Pod::Weaver the way CPAN
author C<LXP> uses it, achieving the same result as these entries in a
F<weaver.ini> file:

    ;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; "A bundle for the most commonly-needed prep work for a POD
    ; document."  Not sure what it actually does, but it's probably
    ; important.
    [@CorePrep]

    ; "Stopwords" are words that a spell checker might otherwise flag
    ; as misspelt.  This plugin adds some words based on the
    ; distribution's content and gathers explicitly defined ones at the
    ; top so that they are also honoured.
    [-StopWords]

    ; Provide a "list" POD formatter for easier definition of lists.
    [-Transformer]
    transformer = List

    ;; POD RENDERING AND ORDERING ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Emit a NAME section.
    [Name]

    ; Emit a VERSION section.  The version number is determined by
    ; Dist::Zilla.
    [Version]
    format = This module is part of distribution %r v%v.%n%nThis dis...

    ; Emit a SYNOPSIS section if it exists.
    [Generic / SYNOPSIS]

    ; Emit a DESCRIPTION section.  Enforce its existence for every
    ; module.
    [Generic / DESCRIPTION]
    required = 1

    ; Emit any other POD material that isn't handled elsewhere in this
    ; configuration, including further down.
    [Leftovers]

    ; Emit an ATTRIBUTES section for each attribute defined in the
    ; source.
    [Collect / ATTRIBUTES]
    command = attr

    ; Similar for METHODS.
    [Collect / METHODS]
    command = method

    ; Emit a SEE ALSO section, automatically formatting items as lists.
    ; Don't emit the default explanatory text above the links.
    [SeeAlso]
    header =
    add_main_link = 0

    ; Emit a SUPPORT section in the main module's documentation.
    [Support]
    perldoc = 0
    websites = none
    repository_content = The source code for this distribution is
    repository_content = available online in a
    repository_content = L<Git|http://git-scm.com/> repository.  Please
    repository_content = feel welcome to contribute patches.
    repository_content =

    ; Emit an AUTHOR section.
    [Authors]

    ; Emit a COPYRIGHT AND LICENSE section.  Refer the reader to a copy
    ; of the full license contained within the distribution.
    [Legal]
    license_file = LICENSE

=head1 ACKNOWLEDGEMENTS

In the absence of any real documentation on how to write a
L<Pod::Weaver> plugin bundle, the presence of such bundles previously
written by C<RJBS> and C<DOHERTY> was greatly appreciated:

=over 4

=item *

L<Pod::Weaver::PluginBundle::RJBS>

=item *

L<Pod::Weaver::PluginBundle::Author::DOHERTY>

=back

=head1 METHODS

=head2 mvp_bundle_config

See L<Config::MVP::Assembler::WithBundles>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-pod-weaver-pluginbundle-author-lxp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-PluginBundle-Author-LXP>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The source code for this distribution is available online in a L<Git|http://git-scm.com/> repository.  Please feel welcome to contribute patches.


L<https://github.com/lx/perl5-Pod-Weaver-PluginBundle-Author-LXP>

  git clone git://github.com/lx/perl5-Pod-Weaver-PluginBundle-Author-LXP

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
'LICENSE' file included with this distribution.

=cut
