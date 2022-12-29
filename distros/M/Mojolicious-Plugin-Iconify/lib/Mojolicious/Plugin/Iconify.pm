package Mojolicious::Plugin::Iconify;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::DOM::HTML;
use Mojo::ByteStream;

our $VERSION = '1.20';

sub register {

    my ( $self, $app, $config ) = @_;

    $app->helper( 'iconify_icon' => \&_iconify_icon );
    $app->helper( 'iconify_js'   => \&_iconify_js );

    $app->helper( 'icon' => \&_iconify_icon );    # Alias

}

sub _iconify_icon {

    my ( $self, $icon, %params ) = @_;
    return if ( !$icon );

    my %iconify_params = (
        'class'     => 'iconify',
        'data-icon' => $icon,
    );

    foreach my $param ( keys %params ) {

        my $value = $params{$param};

        if ( $param eq 'size' ) {
            $iconify_params{'data-width'}  = $value;
            $iconify_params{'data-height'} = $value;
        }

        if ( $param eq 'inline' ) {
            $iconify_params{'data-inline'} = ( $value == 0 ) ? 'false' : 'true';
        }

        if ( $param eq 'block' ) {
            $iconify_params{'data-inline'} = ( $value == 0 ) ? 'true' : 'false';
        }

        if ( $param eq 'width' || $param eq 'height' || $param eq 'flip' || $param eq 'align' ) {
            $iconify_params{"data-$param"} = $value;
        }

        $iconify_params{'data-flip'} .= 'horizontal ' if ( $param eq 'flip_horizontal' );
        $iconify_params{'data-flip'} .= 'vertical '   if ( $param eq 'flip_vertical' );
        $iconify_params{'data-rotate'} = $value . 'deg' if ( $param eq 'rotate' );

        # Core HTML attributes

        if ( $param eq 'class' ) {
            $iconify_params{'class'} .= " $value";
        }

        if ( $param eq 'id' || $param eq 'title' || $param eq 'style' ) {
            $iconify_params{$param} = $value;
        }

    }

    if ( defined $iconify_params{'data-flip'} ) {
        $iconify_params{'data-flip'} =~ s/\s$//;
    }

    return _tag( 'span', %iconify_params );

}

sub _iconify_js {

    my ( $self, $url ) = @_;

    my $iconify_version = '3.0.1';
    my $iconify_release = substr $iconify_version, 0, 1;
    my $iconify_js_url  = $url || "https://code.iconify.design/$iconify_release/$iconify_version/iconify.min.js";

    return _tag( 'script', 'src' => $iconify_js_url );

}

sub _tag { Mojo::ByteStream->new( Mojo::DOM::HTML::tag_to_html(@_) ) }

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Iconify - Iconify helpers.


=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Iconify');

  # Mojolicious::Lite
  plugin 'Iconify';


=head1 DESCRIPTION

L<Mojolicious::Plugin::Iconify> is a L<Mojolicious> plugin to add Iconify support in your Mojolicious application.


=head1 HELPERS

L<Mojolicious::Plugin::Iconify> implements the following helpers.

=head2 iconify_js

  %= iconify_js
  %= iconify_js 'https://example.org/assets/js/iconify.min.js'
  %= iconify_js '/assets/js/iconify.min.js'

Generate C<script> tag for include Iconify script file in your template.

=head2 iconify_icon

  %= iconify_icon 'logos:perl'
  %= iconify_icon 'logos:perl', size => 32
  %= iconify_icon 'logos:perl', width => 32, height => 32
  %= iconify_icon 'logos:perl', rotate => 90
  %= iconify_icon 'logos:perl', flip_horizontal => 1
  %= iconify_icon 'logos:perl', flip => 'vertical'
  %= iconify_icon 'logos:perl', align => 'right top crop'

Generate C<span> tag with Iconify attributes.

B<NOTE>: You can use C<icon> alias instead of C<iconify_icon>.

=over

=item C<size>: the icon size (eg. C<16>, C<32px> or C<1em>)

This is an alias for C<width> and C<height> attributes.

=item C<width>, C<height>: the icon width and height (eg. C<16>, C<32px> or C<1em>)

=item C<rotate>: rotate the icon (supported values are: C<90>, C<180> C<270> degrees)

=item C<flip>: flip the icon in C<horizontal> and/or C<vertical> position

=item C<flip_horizontal>: flip the icon in horizontal position

This is an alias for C<flip =E<gt> "horizontal">.

=item C<flip_vertical>: flip the icon in vertical position

This is an alias for C<flip =E<gt> "vertical">.

=item C<inline>: set the layout to inline (below baseline alignment)

=item C<block>: set the layout to block (no vertical alignment)

=item C<align>: set the vertical / horizontal alignment and cropping

(You can mix those options by separating them with comma or space)


Horizontal:

=over

=item C<left>

=item C<center> (default)

=item C<right>

=back

Vertical:

=over

=item C<top>

=item C<middle> (default)

=item C<bottom>

=back

For cropping:

=over

=item C<crop>

=item C<meet> (default)

=back

=back


=head1 METHODS

L<Mojolicious::Plugin::Iconify> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register helpers in L<Mojolicious> application.


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://iconify.design/docs/>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify>

    git clone https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify.git


=head1 AUTHORS

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2021, Giuseppe Di Terlizzi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
