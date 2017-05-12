package Mojolicious::Plugin::MoreHTMLHelpers;

# ABSTRACT: Some general helpers

use strict;
use warnings;

use parent 'Mojolicious::Plugin';

our $VERSION = 0.01;

sub register {
    my ($self, $app, $config) = @_;

    $app->helper( textcolor => sub {
        my $c = shift;

        my $color = shift // '#000000';

        my ($red, $green, $blue);

        if ( length $color == 7 ) {
            ($red, $green, $blue) = $color =~ m{\#(..)(..)(..)};
        }
        elsif ( length $color == 4 ) {
            ($red, $green, $blue) = $color =~ m{\#(.)(.)(.)};
            for ( $red, $green, $blue ) {
                $_ = $_ x 2;
            }
        }

        my $brightness = _perceived_brightness( $red, $green, $blue );

        return $brightness > 130 ? '#000000' : '#ffffff';
    } );
}

sub _perceived_brightness {
    my ($red, $green, $blue) = @_;

    $red   = hex $red;
    $green = hex $green;
    $blue  = hex $blue;

    my $brightness = int ( sqrt (
        ( $red   * $red   * .299 ) +
        ( $green * $green * .587 ) +
        ( $blue  * $blue  * .114 )
    ));

    return $brightness;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::MoreHTMLHelpers - Some general helpers

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your C<startup>:

    sub startup {
        my $self = shift;
  
        # do some Mojolicious stuff
        $self->plugin( 'MoreHTMLHelpers' );

        # more Mojolicious stuff
    }

In your template:

    <span style="color: <% textcolor('#135713') %>">Any text</span>

=head1 HELPERS

This plugin adds a helper method to your web application:

=head2 textcolor

This method requires at least one parameter: The color the text color is based on.
The text color should have a contrast to the background color. In web apps where
the user can define its own color set, it's necessary to calculate the textcolor
on the fly. This is what this helper is for.

    <span style="background-color: #135713; color: <% textcolor('#135713') %>">Any text</span>

=back

=head1 METHODS

=head2 register

Called when registering the plugin. On creation, the plugin accepts a hashref to configure the plugin.

    # load plugin, alerts are dismissable by default
    $self->plugin( 'MoreHTMLHelpers' );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
