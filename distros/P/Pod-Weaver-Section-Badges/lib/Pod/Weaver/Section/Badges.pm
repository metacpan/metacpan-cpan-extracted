use 5.10.0;
use strict;
use warnings;

package Pod::Weaver::Section::Badges;

# ABSTRACT: Add (or append) a section with badges
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0402';

use Moose;
use MooseX::AttributeDocumented;
use PerlX::Maybe qw/provided/;
use Types::Standard -types;
use namespace::autoclean;
use Pod::Weaver::Section::Badges::PluginSearcher;
with qw/
    Pod::Weaver::Role::Section
    Pod::Weaver::Role::AddTextToSection
    Pod::Weaver::Section::Badges::Utils
/;

sub mvp_multivalue_args { qw/badge/ }

has '+weaver' => (
    is => 'ro',
    documentation_order => 0,
    traits => ['Documented'],
);
has '+logger' => (
    is => 'ro',
    traits => ['Documented'],
    documentation_order => 0,
);
has '+plugin_name' => (
    is => 'ro',
    documentation_order => 0,
    traits => ['Documented'],
);

has badge => (
    is => 'ro',
    isa => ArrayRef[Str],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        all_badges => 'elements',
        find_badge => 'first',
        count_badges => 'count',
    },
    documentation => q{The name of the wanted badge, lowercased. Repeat for multiple badges. The name is everything after 'Badge::Depot::Plugin::'.},
    documentation_default => '[]',
);
has section => (
    is => 'ro',
    isa => Str,
    default => 'NAME',
    documentation => q{The section of pod to add the badges to, identified by its heading. The section will be created if it doesn't already exist.},
);
has formats => (
    is => 'ro',
    isa => ArrayRef[Enum[qw/html markdown/]],
    traits => ['Array'],
    required => 1,
    handles => {
        all_formats => 'elements',
        find_format => 'first',
        has_formats => 'count',
    },
    documentation => q{The formats to render the badges for. Comma separated list, not multiple rows.},
    documentation_default => '[]',
);
has skip_markdown_if_html => (
    is => 'ro',
    isa => Bool,
    default => 1,
    documentation => q{Some markdown renderers also renders '=begin html' blocks, which makes it unnecessary to set both html and markdown as output formats. Set this to a false value to produce both blocks.},
);

has badge_args => (
    is => 'ro',
    isa => HashRef[Str],
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        badge_args_kv => 'kv',
    },
    documentation_order => 0,
);
has plugin_searcher => (
    is => 'ro',
    isa => Any,
    init_arg => undef,
    default => sub { Pod::Weaver::Section::Badges::PluginSearcher->new },
    documentation_order => 0,
);
has main_module_only => (
    is => 'ro',
    isa => Bool,
    default => 1,
    documentation => 'If true, the badges will only be inserted in the main module (as defined by Dist::Zilla). If false, they will be included in all modules.',
);


around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;
    my $args = shift;
    $args->{'formats'} = exists $args->{'formats'} ? [ split /, ?/ => $args->{'formats'} ] : [];
    $args->{'badge_args'} = { map { $_ => delete $args->{ $_  } } grep { /^-/ } keys %$args };

    $class->$next($args);
};

sub main_module {
    my $self = shift;
    my $input = shift;

    # Use the main_module as defined by Dist::Zilla if it is available
    return $input->{'zilla'}->main_module->name if exists $input->{'zilla'};

    # Taken from Dist::Zilla
    # If your distribution is Foo-Bar, and lib/Foo/Bar.pm exists, that's the main_module.
    (my $guess = 'lib/' . $input->{'meta'}{'name'} . '.pm') =~ s{-}{/}g;
    return -e $guess ? $guess : undef;
}

sub weave_section {
    my $self = shift;
    my $document = shift;
    my $input = shift;

    return if $self->main_module_only && $input->{'filename'} ne $self->main_module($input);

    my $badges_args = {
        provided ref $input eq 'HASH' && exists $input->{'zilla'}, zilla => $input->{'zilla'},
    };
    my $badge_objects = $self->create_badges($badges_args);
    return if !scalar @$badge_objects;

    if(!$self->has_formats) {
        $self->log(['!!! No formats defined in weaver.ini, no badges to create.']);
    }

    my $formats = [
        {
            name => 'html',
            before => '<p>',
            after => '</p>',
        },
        {
            name => 'markdown',
            before => undef,
            after => undef,
        }
    ];

    my @output = ();
    FORMAT:
    foreach my $format (@$formats) {
        # Optionally skip markdown if we also prints to html
        next FORMAT if $format->{'name'} eq 'markdown' && $self->find_format(sub { $_ eq 'html'}) && $self->skip_markdown_if_html;
        push @output => @{ $self->render_badges($format, $badge_objects) };
    }

    if(scalar @output) {
        my $output = join "\n" => '', @output, '';

        $self->add_text_to_section($document, $output, $self->section);
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Badges - Add (or append) a section with badges



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Badges"><img src="https://api.travis-ci.org/Csson/p5-Pod-Weaver-Section-Badges.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Pod-Weaver-Section-Badges-0.0402"><img src="https://badgedepot.code301.com/badge/kwalitee/Pod-Weaver-Section-Badges/0.0402" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Pod-Weaver-Section-Badges%200.0402"><img src="https://badgedepot.code301.com/badge/cpantesters/Pod-Weaver-Section-Badges/0.0402" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-81.0%-orange.svg" alt="coverage 81.0%" />
</p>

=end html

=head1 VERSION

Version 0.0402, released 2016-02-20.



=head1 SYNOPSIS

    ; in weaver.ini
    [Badges]
    section = BUILD STATUS
    formats = html
    badge = Travis
    badge = Gratipay
    -travis_user = MyGithubUser
    -travis_repo = the_repository
    -travis_branch = master
    -gratipay_user = ExampleName

=head1 DESCRIPTION

This inserts a section with status badges. The configuration in the synopsis would produce something similar to this:

    =head1 BUILD STATUS

    =begin HTML

    <p>
        <a href="https://travis-ci.org/MyGithubUser/the_repository"><img src="https://travis-ci.org/MyGithubUser/the_repository.svg?branch=master" /></a>
        <img src="https://img.shields.io/gratipay/ExampleName.svg" />
    </p>

    =end HTML

This module uses badges in the C<Badge::Depot::Plugin> namespace. See L<Task::Badge::Depot> for a list of available badges.
The synopsis uses the L<Badge::Depot::Plugin::Travis> and L<Badge::Depot::Plugin::Gratipay> badges.

Attributes starting with a dash (such as, in the synopsis, C<-travis_user> or C<-gratipay_user>) are given to each badge's constructor.

=head2 Badge rendering

As a comparison with using badges and L<Badge::Depot> directly, this is what C<Pod::Weaver::Section::Badges> does.

First, with this part of the synopsis:

    [Badges]
    badge = Gratipay
    -gratipay_user = ExampleName

C<badge = Gratipay> means that L<Badge::Depot::Plugin::Gratipay> is automatically C<used>.

Secondly, C<-gratipay_user = Example> means that this attribute is for the C<Gratipay> badge, so the prefix (C<-gratipay_>) is stripped and the attribute is given in the constructor:

    my $gratipay_badge = Badge::Depot::Plugin::Gratipay->new(user => 'ExampleName');

And then the given C<formats> is used to render the pod:

    my $rendered_badge = $gratipay_badge->to_html;

Which is then injected into the chosen C<section>.

=head1 ATTRIBUTES


=head2 formats

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Enum">Enum</a> [ "<a href="https://metacpan.org/pod/Types::Standard#html">html</a>","<a href="https://metacpan.org/pod/Types::Standard#markdown">markdown</a>" ] ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The formats to render the badges for. Comma separated list, not multiple rows.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Enum">Enum</a> [ "<a href="https://metacpan.org/pod/Types::Standard#html">html</a>","<a href="https://metacpan.org/pod/Types::Standard#markdown">markdown</a>" ] ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The formats to render the badges for. Comma separated list, not multiple rows.</p>

=end markdown

=head2 badge

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>[]</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The name of the wanted badge, lowercased. Repeat for multiple badges. The name is everything after 'Badge::Depot::Plugin::'.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>[]</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The name of the wanted badge, lowercased. Repeat for multiple badges. The name is everything after 'Badge::Depot::Plugin::'.</p>

=end markdown

=head2 main_module_only

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If true, the badges will only be inserted in the main module (as defined by Dist::Zilla). If false, they will be included in all modules.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If true, the badges will only be inserted in the main module (as defined by Dist::Zilla). If false, they will be included in all modules.</p>

=end markdown

=head2 section

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>NAME</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The section of pod to add the badges to, identified by its heading. The section will be created if it doesn't already exist.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>NAME</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The section of pod to add the badges to, identified by its heading. The section will be created if it doesn't already exist.</p>

=end markdown

=head2 skip_markdown_if_html

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Some markdown renderers also renders '=begin html' blocks, which makes it unnecessary to set both html and markdown as output formats. Set this to a false value to produce both blocks.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Some markdown renderers also renders '=begin html' blocks, which makes it unnecessary to set both html and markdown as output formats. Set this to a false value to produce both blocks.</p>

=end markdown

=head1 SEE ALSO

=over 4

=item *

L<Task::Badge::Depot>

=item *

L<Badge::Depot>

=back

=head1 BADGES

=for HTML <p>
    <img src="https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg" />
    <a href="https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Badges"><img src="https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Badges.svg?branch=master" /></a>
</p>

=for markdown     ![](https://img.shields.io/badge/perl-5.14+-brightgreen.svg)
    [![](https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Badges.svg?branch=master)](https://travis-ci.org/Csson/p5-Pod-Weaver-Section-Badges)

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Weaver-Section-Badges>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Weaver-Section-Badges>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
