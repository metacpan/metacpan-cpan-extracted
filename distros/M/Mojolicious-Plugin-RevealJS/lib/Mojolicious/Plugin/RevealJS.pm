package Mojolicious::Plugin::RevealJS;

use Mojo::Base 'Mojolicious::Plugin';

use 5.12.0;

our $VERSION = '0.11';
$VERSION = eval $VERSION;

use Mojo::Home;
use Mojo::ByteStream 'b';
use Mojo::File;

use File::Basename 'dirname';
use File::Share ();

has home => sub { Mojo::Home->new(File::Share::dist_dir('Mojolicious-Plugin-RevealJS')) };

sub register {
  my ($plugin, $app, $conf) = @_;
  my $home = $plugin->home;
  push @{ $app->static->paths },   $home->child('public');
  push @{ $app->renderer->paths }, $home->child('templates');

  $app->defaults('revealjs.init' => {
    controls => \1,
    progress => \1,
    history  => \1,
    center   => \1,
    transition => 'slide', #none/fade/slide/convex/concave/zoom
  });

  $app->helper('include_code' => \&_include_code);
  $app->helper('revealjs.export' => \&_export);
}

sub _include_code {
  my ($c, $filename, %opts) = @_;
  my $file = $c->stash->{'revealjs.private.files'}{$filename}
    ||= $c->app->home->rel_file($filename)->slurp;
  my $mark = qr'^\h*(?:#+|-{2,}|/{2,}|<!--)\h*reveal'm;

  if (my $section = delete $opts{section}) {
    my @sections = split /$mark\h+(?:begin|end)\h+\Q$section\E\N*\R/ms, $file, 3;
    $file = Mojo::Util::trim($sections[1]) if @sections > 1;
  }

  $file =~ s/$mark\N*\R//mg;

  my $template = <<'  INCLUDE';
    % my $text = stash 'revealjs.private.text';
    % my $file = stash 'revealjs.private.file';
    % my $lang = stash 'revealjs.private.lang';
    <pre><code class="<%= $lang %>" data-trim>
      <%= $text =%>
    </code></pre>
    <p style="float: right; text-color: white; font-size: small;"><%= $file %></p>
  INCLUDE
  my $html = $c->render_to_string(
    inline => $template,
    'revealjs.private.text' => $file,
    'revealjs.private.file' => $filename,
    'revealjs.private.lang' => delete($opts{language}) // $c->stash('language') // 'perl',
    %opts
  );
  return b $html;
}

sub _export {
  my ($c, $page, $to) = @_;
  require Mojo::Util;
  require File::Copy::Recursive;
  File::Copy::Recursive->import('dircopy');
  File::Copy::Recursive::pathmk($to);

  my $body = $c->ua->get($page)->res->body;
  Mojo::File->new($to)->child('index.html')->spurt($body);
  for my $path( @{ $c->app->static->paths } ) {
    dircopy($path, $to);
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::RevealJS - Mojolicious ❤️ Reveal.js

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin 'RevealJS';

  any '/' => { template => 'mytalk', layout => 'revealjs' };

  app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::RevealJS> is yet another attempt at making presentations with L<Mojolicious>.
While the author's previous attempts have tried do too much, this one simply makes it easier to use L<Reveal.js|http://lab.hakim.se/reveal-js>.
It provides a layout (C<revealjs>) which contains the boilerplate and loads the bundled libraries.
It also provides a few simple helpers.
Future versions of the plugin will allow setting of configuration like themes.

The bundled version of Reveal.js is currently 3.0.0.

Note that this module is in an alpha form!
The author makes no compatibilty promises.

=head1 LAYOUTS

  # controller
  $c->layout('revealjs'); # or
  $c->stash(layout => 'revealjs');

  # or template
  % layout 'revealjs';

=head2 revealjs

This layout is essentially the standard template distributed as part of the Reveal.js tarball.
It is modified for use in a Mojolicious template.

=head3 stash paramters

It accepts the stash parameters:

=over

=item *

author - sets the metadata value

=item *

description - sets the metadata value

=item *

init - Reveal.js initialization options, a hashref for JSON conversion documented below

=item *

theme - a string representing a theme css to be included.
If the string ends in C<.css> it is included literally, otherwise it is assumed to be the name of a bundled Reveal.js theme.
Bundled themes are: black, white, league, beige, sky, night, serif, simple, solarized.
Defaults to black.
See more on the L<"Reveal.js page"|https://github.com/hakimel/reveal.js#theming>.

=item *

title - sets the window title, not used on the title slide

=back

=head3 initialization parameters

As mentioned above, the stash key C<init> is a hashref that is merge into a set of defaults and used to initialize Reveal.js.
Some RevealJS initialization options, specifically those that have a default are:

=over

=item *

center - enable slide centering (boolean, true by default)

=item *

controls - enable controls (boolean, true by default)

=item *

history - enable history (boolean, true by default)

=item *

progress - enable progress indicator (boolean, true by default)

=item *

transition - set the slide transition type (one of: none, fade, slide, convex, concave, zoom; default: slide)

=back

These defaults are set in the default stash value for C<revealjs.init>.
So they can be modified globally modifying that value (probably during setup).

  $app->defaults->{'revealjs.init'}{transition} = 'none';

Note that booleans are references to scalar values, C<true == \1>, C<false == \0>.
See more availalbe options on the L<"Reveal.js page"|https://github.com/hakimel/reveal.js#configuration>.

=head3 additional templates

In order to further customize the template the following unimplemented templates are included into the layout

=over

=item *

C<revealjs_head.html.ep> - included at the end of the C<< <head> >> tag.

=item *

C<revealjs_preinit.js.ep> - included just before initializing Reveal.js.
Especially useful to modify the javascript variable C<init>.

=item *

C<revealjs_body.html.ep> - included at the end of the C<< <body> >> tag.

=back

=head1 HELPERS

=head2 include_code

  %= include_code 'path/to/file.pl'

This helper does several things:

=over

=item *

localizes trailing arguments into the stash

=item *

slurps a file containing code

=item *

http escapes the content

=item *

applies some simple formatting

=item *

displays the relative path to the location of the file (for the benefit of repo cloners)

=back

The helper takes a file name and additional key-value pairs.
The following keys and their value are removed from the pairs, the remaining are localized into the stash:

=over

=item language

sets the language for the highlighting, defaults to the value of C<< stash('language') // 'perl' >>

=item section

limits the section to a given section name

=back

NOTE: This feature is experimental!

The section is definite by a line comment of the form C<#> or C<//> or C<--> or C<< <!-- >> followed by C<reveal begin $name> and ended with comment mark followed by C<reveal end $name>.

  %= include_code 'path/to/file', section => 'part1'

Then in the file

  Excluded content

  # reveal being part1
  Included content
  # reveal end part1

  Excluded content

=head2 revealjs->export

  $ ./myapp.pl eval 'app->revealjs->export("/" => "path/")'

Exports the rendered page and all of the files in the static directories to the designated path.
This is very crude, but effective for usual cases.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-RevealJS>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Reveal.js (bundled) is Copyright (C) 2015 Hakim El Hattab, http://hakim.se and released under the MIT license.
