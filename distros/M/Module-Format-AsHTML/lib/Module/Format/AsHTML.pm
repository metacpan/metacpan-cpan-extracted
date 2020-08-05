package Module::Format::AsHTML;
$Module::Format::AsHTML::VERSION = '0.0.2';
use strict;
use warnings;

use Moo;

sub dist
{
    my ( $self, $args ) = @_;
    return
        qq#<a href="https://metacpan.org/release/$args->{d}">$args->{body}</a>#;
}

sub homepage
{
    my ( $self, $args ) = @_;
    return qq#https://metacpan.org/author/\U$args->{who}\E#;
}

sub mod
{
    my ( $self, $args ) = @_;
    return
        qq#<a href="https://metacpan.org/module/$args->{m}">$args->{body}</a>#;
}

sub module
{
    my ( $self, $args ) = @_;
    return $self->mod($args);
}

sub b_self_dist
{
    my ( $self, $args ) = @_;
    return $self->dist( { body => "<b>$args->{d}</b>", %$args, } );
}

sub self_dist
{
    my ( $self, $args ) = @_;
    return $self->dist( { body => $args->{d}, %$args, } );
}

sub self_mod
{
    my ( $self, $args ) = @_;
    return $self->mod( { body => $args->{'m'}, %$args, } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Format::AsHTML - generate HTML links to metacpan module/dists pages.

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Module::Format::AsHTML ();
    my $cpan = Module::Format::AsHTML->new();

    $html .= $cpan->self_mod({ 'm'=> "Path::Tiny"});

=head1 DESCRIPTION

Module::Format::AsHTML is a module to generate HTML hyperlinks and other HTML fragments
for CPAN modules and distributions.

It grew out of some incarnations of source codes used by some
of my (= SHLOMIF) sites.

One for example can pass:

    'cpan' => Module::Format::AsHTML->new(),

As a variable to L<https://metacpan.org/release/Template-Toolkit> and then use it
in templates:

    [% cpan.self_mod('m'=>"List::Util") %]

=head1 SECURITY WARNING!

This module does not validate or sanitize its input and so may be susceptible to
HTML injection / XSS issues (see L<https://perl-begin.org/topics/security/code-markup-injection/> ).
This is expected given its origin as utility code for generating static sites.

Please do not use it with input from possibly malicious sources or without sanitising it.
In the future, this issue may be fixed.

=head1 METHODS

=head2 my $cpan = Module::Format::AsHTML->new()

Returns a new object.

=head2 $cpan->b_self_dist({d=>"Path-Tiny"})

Returns a link to 'd' with bolded text.

=head2 $cpan->self_dist({d=>"Path-Tiny"})

Returns a link to 'd' with its text defaulting to its name.

=head2 $cpan->dist({d=>"Path-Tiny", body=>"$html"})

Returns a link to 'd' with the text 'body'.

=head2 $cpan->homepage({'who'=>"SHLOMIF"})

Homepage url to 'who'.

=head2 $cpan->module ({'m'=>"List::Util", body=>"$html"})

Returns a link to 'm' with the text 'body'. (aliased for tt2/etc. friendliness).

=head2 $cpan->self_mod ({'m'=>"Path::Tiny"})

Returns a link to 'm' with its text defaulting to its name.

=head2 $cpan->mod ({"m"=>"List::Util", body=>"$html"})

Returns a link to 'm' with the text 'body'. (aliased for tt2/etc. friendliness).

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Module-Format-AsHTML>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Format-AsHTML>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Module-Format-AsHTML>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/Module-Format-AsHTML>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Module-Format-AsHTML>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Module::Format::AsHTML>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-module-format-ashtml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Module-Format-AsHTML>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Module-Format-AsHTML>

  git clone https://github.com/shlomif/perl-Module-Format-AsHTML.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/module-format-ashtml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
