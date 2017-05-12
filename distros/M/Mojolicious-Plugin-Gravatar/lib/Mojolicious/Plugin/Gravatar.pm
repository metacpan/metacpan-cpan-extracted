package Mojolicious::Plugin::Gravatar;

use warnings;
use strict;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';

our $VERSION = '0.04';

sub register {
    my ( $self, $app, $conf ) = @_;

    # Plugin config
    $conf ||= {};

    $self->check_options(%$conf);
    $conf->{'size'}   ||= 80;
    $conf->{'rating'} ||= 'PG';

    $app->helper( gravatar_url => sub {
        my $c = shift;
        my ( $email, %options ) = @_;
        $self->check_options(%options);

        my $default = $options{'default'} || $conf->{'default'};
        my $size    = $options{'size'}    || $conf->{'size'};
        my $rating  = $options{'rating'}  || $conf->{'rating'};
        my $scheme  = $options{'scheme'}  || $conf->{scheme} || $c->req->url->to_abs->scheme || 'http';

        my $url = $scheme . '://www.gravatar.com/avatar/';
        $url .= b( lc $email )->md5_sum;
        $url .= '?s=' . $size;
        $url .= '&r=' . $rating if $rating;
        $url .= '&d=' . b($default)->url_escape if $default;
        return $url;
    } );

    $app->helper( gravatar => sub {
        my $c = shift;
        my ( $email, %options ) = @_;
        $self->check_options(%options);

        my $size = $options{'size'} || $conf->{'size'};

        my $url = b($c->gravatar_url(@_))->xml_escape;

        return b "<img src='$url' alt='Gravatar' height='$size' width='$size' />";
    } );
}

sub check_options {
    my ($self) = shift;
    my %options = @_;

    if ( $options{size} && !( $options{size} >= 1 and $options{size} <= 512 ) ) {
        die "Gravatar size must be 1 .. 512\n";
    }

    if ( $options{rating} && $options{rating} !~ /^(?:g|pg|r|x)$/i ) {
        die "Gravatar rating can only be g, pg, r, or x\n";
    }

    if ( $options{scheme} && $options{scheme} !~ /^https?$/i ) {
        die "Http scheme can only be http, https\n";
    }

    return $self;
}

=head1 NAME

Mojolicious::Plugin::Gravatar - Globally Recognized Avatars for Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('gravatar'); 
  
  You can pass default size, rating, and default avatar url 
  $self->plugin('gravatar' => {
      size    => 60,   #default was 80
      rating  => 'X',  #default was PG
      default => 'http://example.com/default.png' # default was not value
      scheme  => 'https' # if omitted will look in request's url scheme.
  });

  # Mojolicious::Lite
  plugin 'gravatar';

  # Gravatars in templates
  <%= gravatar 'user@mail.com' %>
  will generate
  <img src="http://www.gravatar.com/avatar/6ad193f57f79ac444c3621370da955e9&amp;s=80&amp;r=PG" alt="Gravatar" height="80" width="80">

  <%= gravatar_url 'user@mail.com' %>  - if you need only url 
  
  Also you can overwrite any default config variables 
  <%= gravatar 'user@mail.com', size => 40, rating=> 'X' %>

  
  If you need some styling for img tag:
  <span class='gravatar'>  <%= gravatar $email %> </span>
  and describe in css - ".gravatar img {border: 1px solid white;}"
      

=head1 DESCRIPTION

This plugin adds gravatar ( L<http://gravatar.com> ) helpers to your application. 

=head1 CONFIG

=head2 default (optional)

The local (any valid absolute image URI) image to use if there is no Gravatar corresponding to the given email.

=head2 size (optional)

Gravatars are square. Size is 1 through 512 (pixels) and sets the width and the height.

=head2 rating (optional)

G|PG|R|X. The maximum rating of Gravatar you wish returned. If you have a family friendly forum, for example, you might set it to "G."

=head2 scheme (optional)

Gravatar URL scheme "http" or "https". If omitted will look in request's url scheme (if empty fill use "http").

=head1 HELPERS

=head2 gravatar $email [, %options ];

generate img tag for getting avatar from gravatar.com

$email (required) The key to using Gravatars is a hex hash of the user's email. This is generated automatically and sent to gravatar.com as the gravatar_id.

%options (optional) - you can override config parameters . Support all parameters that you have in config     
     

example <img src="http://www.gravatar.com/avatar/6ad193f57f79ac444c3621370da955e9&amp;s=80&amp;r=PG" alt="Gravatar" height="80" width="80"> 
    
=head2 gravatar_url $email [, %options ];

generate url for getting avatar from gravatar.com

$email (required) The key to using Gravatars is a hex hash of the user's email. This is generated automatically and sent to gravatar.com as the gravatar_id.

%options (optional) - you can override config parameters . Support all parameters that you have in config
    
=head1 VERSION

Version 0.02

=head1 AUTHOR
 
Viktor Turskyi <koorchik@cpan.org>

=head1 CONTRIBUTORS
 
Nils Diewald (Akron)

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-gravatar at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-Gravatar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Also you can report bugs to Github L<https://github.com/koorchik/Mojolicious-Plugin-Gravatar/>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Gravatar


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-Gravatar>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Gravatar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Gravatar>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Gravatar/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "koorchik".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Mojolicious::Plugin::Gravatar
