package Mojolicious::Plugin::SassRenderer;

our $VERSION = '0.02';

use warnings;
use strict;

use Mojo::Base 'Mojolicious::Plugin';
use IO::File;
use Text::Sass;


sub register {
  my ($self, $app, $options) = @_;

  $options ||= {};

  # Add "sass" handler
  $app->renderer->add_handler(sass => sub {
      my ($r, $c, $output, $options) = @_;

      # Read the Sass file
      my $fname = $r->template_path($options);
      my $fh    = IO::File->new($fname, 'r') or die "Couldn't open $fname: $!";
      my $sass  = do{ local $/ = undef; <$fh>; };
      undef $fh;

      # Generate CSS
      my $oSass = Text::Sass->new;
      my $css   = $oSass->sass2css($sass);

      $$output  = $css;
  });
}


1; # End of Mojolicious::Plugin::SassRenderer
__END__

=head1 NAME

Mojolicious::Plugin::SassRenderer - Sass Renderer Plugin for Mojolicious

=head1 SYNOPSIS

Renders Sass files into CSS for your Mojolicious web-apps

  package MyApp;
  use Mojo::Base 'Mojolicious';
  
  sub startup {
      $self = shift;
      $self->plugin('sass_renderer'); 
  }

  1;


  # template
  <!doctype html><html>
    <head>
      <style type="text/css">
        <%== include 'stylesheets/main', format => 'txt', handler => 'sass' %>
      </style>
    </head>
    <body>
    </body>
  </html>


  # sass: MOJO_HOME/templates/stylesheets/main.txt.sass
  $menuColor: #eee

  #menubar
    background-color: $menuColor
    width: 75%


=head1 DESCRIPTION

Takes Sass formatted files and renderers them in CSS for your web-app.

=head1 VERSION

Version 0.02

=head1 AUTHOR

Byron Hammond, C<< <byron_hammond <at> yahoo.com.au> >>

=head1 BUGS

Since this simply uses Text::Sass, it's limited by it's bugs.

Please report any bugs or feature requests to C<bug-mojolicious-plugin-sassrenderer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-SassRenderer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::SassRenderer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-SassRenderer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-SassRenderer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-SassRenderer>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-SassRenderer/>

=back


=head1 ACKNOWLEDGEMENTS

Sebastian Riedel <sri> for Mojolicious and the suggestion to put this on CPAN


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Byron Hammond.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

