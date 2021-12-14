package Set::CSS;
$Set::CSS::VERSION = '0.2.0';
use 5.014;
use strict;
use warnings;

use parent 'Set::Object';

use HTML::Widgets::NavMenu::EscapeHtml qw/ escape_html /;

sub html_attrs
{
    my ( $self, $args ) = @_;

    if ( $args->{on_empty} or !( $self->is_null ) )
    {
        return { class => join( " ", @$self ) };
    }
    return +{};
}

sub as_html
{
    my ( $self, $args ) = @_;

    my $att = $self->html_attrs($args);
    my $ret = "";
    foreach my $k ( sort keys %$att )
    {
        $ret .= qq# $k="# . escape_html( $att->{$k} ) . qq#"#;
    }
    return $ret;
}

sub addClass
{
    my ( $self, @c ) = @_;

    $self->insert(@c);

    return;
}

sub removeClass
{
    my ( $self, @c ) = @_;

    $self->remove(@c);

    return;
}

sub toggleClass
{
    my ( $self, @c ) = @_;

    $self->invert(@c);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::CSS - set of CSS classes

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Set::CSS ();

    my $set = Set::CSS->new( "class1", );
    $set->insert("blast");
    # Avoiding duplicates
    $set->insert("class1");

    # Prints ' class="blast class1"'
    print $set->as_html(), "\n";

=head1 DESCRIPTION

Inheriting from L<Set::Object> this class provides methods for emitting
HTML.

If C<< $args{on_empty} >> is not true B<and> the set is empty, then no output
shall be emitted.

=head1 METHODS

=head2 $self->html_attrs(\%args)

Returns a hash reference of HTML attributes.

=head2 $self->as_html(\%args)

Returns a string of HTML attributes.

=head2 $self->addClass(@classes)

Wrapper for Set::Object 's insert() with an empty return value (for use
in L<Template> / etc.)

(Added in v0.2.0. )

=head2 $self->removeClass(@classes)

Wrapper for Set::Object 's remove() with an empty return value (for use
in L<Template> / etc.)

(Added in v0.2.0. )

=head2 $self->toggleClass(@classes)

Wrapper for Set::Object 's invert() with an empty return value (for use
in L<Template> / etc.)

(Added in v0.2.0. )

=head1 Media Recommendations

L<Hallelujah - Cover by Lucy Thomas|https://www.youtube.com/watch?v=4hjgkvuKES8>

=head1 SEE ALSO

L<Set::Object> - Set::CSS inherits its methods

L<HTML's 'class' attribute|https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/class>

L<jQuery’s class methods|https://api.jquery.com/category/manipulation/class-attribute/>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Set-CSS>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Set-CSS>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Set-CSS>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/Set-CSS>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Set-CSS>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Set::CSS>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-set-css at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Set-CSS>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Set-CSS>

  git clone git://github.com/shlomif/Set-CSS.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Set-CSS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
