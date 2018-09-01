package Mojolicious::Plugin::RevealJS;

use Mojo::Base 'Mojolicious::Plugin';

use 5.12.0;

our $VERSION = '0.17';
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

  $app->helper('revealjs.export' => \&_export);

  $app->helper(include_code => \&_include_code);
  $app->helper(include_sample => \&_include_sample);
  $app->helper(section => sub { shift->tag(section => @_) });
  $app->helper(markdown_section => sub {
    my ($c, @args) = @_;
    return $c->tag(section => data => { markdown => undef } => sub {
      return $c->tag(script => (type => 'text/template') => @args);
    });
  });
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
    % if (defined $file) {
    <p class="filename" style="float: right; text-color: white; font-size: small;"><%= $file %></p>
    % }
  INCLUDE

  $filename = undef if exists $opts{include_filename} && !$opts{include_filename};

  my $html = $c->render_to_string(
    inline => $template,
    'revealjs.private.text' => $file,
    'revealjs.private.file' => $filename,
    'revealjs.private.lang' => delete($opts{language}) // $c->stash('language') // 'perl',
    %opts
  );
  return b $html;
}

sub _include_sample {
  my ($c, $sample, %opts) = @_;
  my $template = <<'  INCLUDE';
    <pre><%= t code => @$code %></pre>
    % if (defined $annotation) {
    <p class="sample-annotation" style="float: right; text-color: white; font-size: small;"><%= $annotation %></p>
    % }
  INCLUDE

  my (@code, %data);
  my $lang = $opts{language} // $opts{lang} // $c->stash('language');
  if (defined $lang) {
    $lang = "lang-$lang" unless $lang =~ /^lang-/;
    push @code, class => $lang;
  }

  $data{sample}        = $sample;
  $data{trim}          = $opts{trim}     if exists $opts{trim};
  $data{noescape}      = $opts{noescape} if exists $opts{noescape};
  $data{'sample-mark'} = $opts{mark}     if exists $opts{mark};
  push @code, data => \%data;

  my $anno_default = $sample;
  $anno_default =~ s/\#.*$//;

  my $html = $c->render_to_string(
    inline   => $template,
    code     => \@code,
    annotation => exists $opts{annotation} ? $opts{annotation} : $anno_default,
  );
  return $html;
}

sub _export {
  my ($c, $page, $to, $opts) = @_;
  require Mojo::Util;
  require File::Copy::Recursive;
  File::Copy::Recursive->import('dircopy');
  File::Copy::Recursive::pathmk($to);

  my $body = $c->ua->get($page)->res->body;

  # handle munging the base tag
  if (my $base = $opts->{base}) {
    require Mojo::DOM;
    require Mojo::Util;
    $base = Mojo::Util::xml_escape($base);
    my $dom = Mojo::DOM->new($body);
    $dom->at('base')->remove;
    $dom->at('head')->child_nodes->first->prepend(qq[<base href="$base">]);
    $body = $dom->to_string;
  }

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

The bundled version of Reveal.js is currently 3.7.0.
The bundled version of reveal-sampler is currently b04a34e.

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

=item *

base - sets the C<< <base> >> tag for the document.
Useful for hosting static pages at a location other than C</>.
Defaults to C</>, if explicitly set to C<undef> the tag is not included.

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

NOTE this helper is mildly-deprecated in favor of the reveal-sampler plugin and L</include_sample>.
It isn't going away yet, but if things work out with that functionality this method may eventually be implemented via it or removed entirely.

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

=item include_filename

if true (default) include the filename when the code is included

=back

NOTE: This feature is experimental!

The section is definite by a line comment of the form C<#> or C<//> or C<--> or C<< <!-- >> followed by C<reveal begin $name> and ended with comment mark followed by C<reveal end $name>.

  %= include_code 'path/to/file', section => 'part1'

Then in the file

  Excluded content

  # reveal begin part1
  Included content
  # reveal end part1

  Excluded content

=head2 include_sample

  %= include_sample 'path/to/file.pl'

The spiritual successor (and possbily actually the sucessor) to L</include_code>.
The heavy lifting is done in the client via the reveal-sampler plugin which is bundled.
It is much simpler than L</include_code>.

It takes the url of the file to render, which must be in a publicly available via static render.
This file path may also contain a url fragment designating the section or line numbers to display.
Read more at L<https://github.com/ldionne/reveal-sampler>.

After the file url, the following trailing key-value pair options are available.

=over

=item language

Sets the language for the highlighting.
Note that the alias C<lang> is also allowed and defaults to the value of the C<language> stash value.
If this is not set, the client-side code will also attempt to set it based on the file extension.

=item mark

Sets lines to be marked by the client.
This follows the documentation at L<https://github.com/ldionne/reveal-sampler>.

=item trim

Sets the C<data-trim> attribute for revealjs.

=item noescape

Sets the C<data-noescape> attribute for revealjs.
Note that if the L</mark> option is used, the front-end will automatically apply this attribute.

=item annotation

A text line to be rendered below the code section.
This is normally used to display the file name/path.
If not explicitly given it will default to the url of the file (without any fragment).
If explicitly undefined, the annotation will not be rendered.

=back

=head2 section

  %= section begin
  ...
  % end

A shortcut for creating a section tag.

  %# longer form
  %= tag section => ...

=head2 markdown_section

  %= markdown_section begin
  ...
  % end

Build a section tag and script/template tag to properly use the built-in markdown handling within this slide.

=head2 revealjs->export

  $ ./myapp.pl eval 'app->revealjs->export("/" => "path/", \%options)'

Exports the rendered page and all of the files in the static directories to the designated path.
This is very crude, but effective for usual cases.

Allowed options are:

=over

=item base

Override the base tag by removing the original and inserting a new one just inside the C<< <head> >> tag with the given value as the href target.
This feature is cludgy (as is this whole helper), consider it experimental, its behavior may change.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-RevealJS>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Reveal.js (bundled) is Copyright (C) 2015 Hakim El Hattab, http://hakim.se and released under the MIT license.
reveal-sampler (bundled) is Copyright (C) 2017 Louis Dionne and released under the MIT license.
