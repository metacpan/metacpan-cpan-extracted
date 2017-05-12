#---------------------------------------------------------------------
package Pod::PluginCatalog;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Jul 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Format a catalog of plugin modules
#---------------------------------------------------------------------

use 5.010;
use Moose;
use namespace::autoclean;

our $VERSION = '0.02';
# This file is part of Pod-PluginCatalog 0.02 (January 3, 2015)

use autodie ':io';
use Encode ();
use Pod::PluginCatalog::Entry ();
use Pod::Elemental ();
use Pod::Elemental::Selectors qw(s_command s_flat);
use Pod::Elemental::Transformer::Nester ();
use Text::Template ();

#=====================================================================


has namespace_rewriter => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);

has pod_formatter => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);

has _plugins => (
  is      => 'ro',
  isa     => 'HashRef[Pod::PluginCatalog::Entry]',
  default => sub { {} },
);

has _tags => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  default => sub { {} },
  traits  => ['Hash'],
  handles => {
    tags    => 'keys',
  },
);

has _author_selector => (
  is   => 'ro',
  lazy => 1,
  builder => '_build_author_selector',
);

sub _build_author_selector { s_command('author') }

has _plugin_selector => (
  is   => 'ro',
  lazy => 1,
  builder => '_build_plugin_selector',
);

sub _build_plugin_selector { s_command('plugin') }

has _tag_selector => (
  is   => 'ro',
  lazy => 1,
  builder => '_build_tag_selector',
);

sub _build_tag_selector { s_command('tag') }

has _nester => (
  is   => 'ro',
  lazy => 1,
  builder => '_build_nester',
);

sub _build_nester
{
  Pod::Elemental::Transformer::Nester->new({
     top_selector      => s_command(['plugin', 'tag']),
     content_selectors => [
       s_command([ qw(head3 head4 over item back) ]),
       s_flat,
     ],
  });
}


has delimiters => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  default  => sub { [ qw(  {{  }}  ) ] },
);

has file_extension => (
  is      => 'ro',
  isa     => 'Str',
  default => '.html',
);

has perlio_layers => (
  is      => 'ro',
  isa     => 'Str',
  default => ':utf8',
);

#=====================================================================
sub _err
{
  my ($source, $node, $err) = @_;

  my $line = $node->start_line;
  $line = ($line ? "$line:" : '');
  confess "$source:$line $err";
} # end _err
#---------------------------------------------------------------------


sub add_file
{
  my ($self, $filename) = @_;

  $self->add_document($filename => Pod::Elemental->read_file($filename));
} # end add_file
#---------------------------------------------------------------------


sub add_document
{
  my ($self, $source, $doc) = @_;

  my $plugins  = $self->_plugins;
  my $tags     = $self->_tags;
  my $rewriter = $self->namespace_rewriter;
  my $author_selector = $self->_author_selector;
  my $plugin_selector = $self->_plugin_selector;
  my $tag_selector    = $self->_tag_selector;

  $self->_nester->transform_node($doc);

  my @author;

  foreach my $node (@{ $doc->children }) {
    if ($author_selector->($node)) {
      my $author = $node->content;
      chomp $author;
      if (length $author) {
        @author = (author => $author);
      } else {
        @author = ();
      }
    } elsif ($tag_selector->($node)) {
      my $tag = $node->content;
      _err($source, $node, "=tag without tag name") unless length $tag;
      _err($source, $node, "Duplicate description for tag $tag")
          if defined $tags->{$tag};
      $tags->{$tag} = $self->format_description($node);
    } elsif ($plugin_selector->($node)) {
      my ($name, @tags) = split(' ', $node->content);

      _err($source, $node, "Plugin $name has no tags") unless @tags;

      _err($source, $node, "Plugin $name already seen in " .
           ($plugins->{$name}->source_file // 'unknown file'))
          if $plugins->{$name};

      $tags->{$_} //= undef for @tags;

      my $module = $rewriter->($name);

      $plugins->{$name} = Pod::PluginCatalog::Entry->new(
        name => $name, module => $module,
        description => $self->format_description($node),
        source_file => $source, tags => \@tags,
        @author,
      );
    }
  } # end foreach $node

} # end add_document
#---------------------------------------------------------------------

sub format_description
{
  my ($self, $node) = @_;

  my $pod = join('', map { $_->as_pod_string } @{ $node->children });

  $self->pod_formatter->("=pod\n\n$pod");
} # end format_description
#---------------------------------------------------------------------


sub generate_tag_pages
{
  my ($self, $header, $template, $footer) = @_;

  $self->compile_templates($header, $template, $footer);

  $self->generate_tag_page($_, $header, $template, $footer)
      for sort $self->tags;
} # end generate_tag_pages
#---------------------------------------------------------------------

sub generate_tag_page
{
  my ($self, $tag, $header, $template, $footer) = @_;

  confess "index is a reserved name" if $tag eq 'index';

  my %data = (tag => $tag, tag_description => $self->_tags->{$tag});

  warn "No description for tag $tag\n" unless $data{tag_description};

  my @plugins = sort { $a->name cmp $b->name }
                grep { $_->has_tag($tag) }
                values %{ $self->_plugins };

  unless (@plugins) {
    warn "No plugins for tag $tag\n";
    return;
  }

  open(my $out, '>' . $self->perlio_layers, $tag . $self->file_extension);

  $header->fill_in(HASH => \%data, OUTPUT => $out)
      or confess("Filling in the header template failed for $tag");

  for my $plugin (@plugins) {
    my %data = (
      %data,
      other_tags => [ $plugin->other_tags($tag) ],
      map { $_ => $plugin->$_() } qw(name module description author)
    );

    $template->fill_in(HASH => \%data, OUTPUT => $out)
        or confess("Filling in the entry template failed for $data{name}");
  }

  $footer->fill_in(HASH => \%data, OUTPUT => $out)
      or confess("Filling in the footer template failed for $tag");

  close $out;
} # end generate_tag_page
#---------------------------------------------------------------------


sub generate_index_page
{
  my ($self, $header, $template, $footer) = @_;

  $self->compile_templates($header, $template, $footer);

  open(my $out, '>' . $self->perlio_layers, 'index' . $self->file_extension);

  my %data = (tag => undef, tag_description => undef);

  $header->fill_in(HASH => \%data, OUTPUT => $out)
      or confess("Filling in the index header template failed");

  my $tags = $self->_tags;

  for my $tag (sort keys %$tags) {
    my %data = (tag => $tag, description => $tags->{$tag});

    $template->fill_in(HASH => \%data, OUTPUT => $out)
        or confess("Filling in the entry template failed for $tag");
  }

  $footer->fill_in(HASH => \%data, OUTPUT => $out)
      or confess("Filling in the index footer template failed");

  close $out;
} # end generate_index_page
#---------------------------------------------------------------------

sub compile_templates {
  my $self = shift;

  foreach my $string (@_) {
    confess("Cannot use undef as a template string") unless defined $string;

    my $tmpl = Text::Template->new(
      TYPE       => 'STRING',
      SOURCE     => $string,
      DELIMITERS => $self->delimiters,
      BROKEN     => sub { my %hash = @_; die $hash{error}; },
      STRICT     => 1,
    );

    confess("Could not create a Text::Template object from:\n$string")
      unless $tmpl;

    $string = $tmpl;            # Modify arguments in-place
  } # end for each $string in @_
} # end compile_templates

#=====================================================================
# Package Return Value:

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Pod::PluginCatalog - Format a catalog of plugin modules

=head1 VERSION

This document describes version 0.02 of
Pod::PluginCatalog, released January 3, 2015
as part of Pod-PluginCatalog version 0.02.

=head1 SYNOPSIS

  use Pod::PluginCatalog;

  my $catalog = Pod::PluginCatalog->new(
    namespace_rewriter => sub { 'My::Plugin::Namespace::' . shift },
    pod_formatter => sub {
      my $parser = Pod::Simple::XHTML->new;
      $parser->output_string(\my $html);
      $parser->html_header('');
      $parser->html_footer('');
      $parser->perldoc_url_prefix("https://metacpan.org/module/");
      $parser->parse_string_document( shift );
      $html;
    },
  );

  $catalog->add_file('catalog.pod');

  $catalog->generate_tag_pages($header, $entry, $footer);
  $catalog->generate_index_page($header, $entry, $footer);

=head1 DESCRIPTION

B<Warning:> This is still early code, not yet in production.
The API might change.

This module aids in formatting a tag-based catalog of plugins.  It
was written to create the catalog at L<http://dzil.org/plugins/> but
should also be useful for similar catalogs.
(That catalog is not yet live as of this writing; a preview is at
L<http://dzil.cjmweb.net/plugins/> and the code that generates it at
L<https://github.com/madsen/dzil.org/tree/plugin-catalog>.)

The catalog begins with one or more POD files defining the available
plugins and the tags used to categorize them.  You load each file into
the catalog with the C<add_file> method, and then call the
C<generate_tag_pages> and C<generate_index_page> methods to produce a
formatted page for each tag and an index page listing all the tags.

=head1 EXTENDED POD SYNTAX

This module defines three non-standard POD command paragraphs used to
create the catalog:

=head2 C<=author>

  =author CPANID

This sets the author for all following plugins (until the next
C<=author>).  If CPANID is omitted, it resets the author to the
default (which is no listed author, represented by C<undef>).

=head2 C<=plugin>

  =plugin PluginName tagname tagname...

This paragraph defines a plugin and associates it with the specifed
tags.  Neither PluginName nor the tag names may contain whitespace,
because the paragraph content is simply C<split(' ', ...)>.  The first
element is the name, and the rest are the tags.  (This means that a
single newline is equivalent to a space.)

The following paragraphs (if any) form the description of the
plugin.  The description may include ordinary paragraphs, verbatim
(indented) paragraphs, and the commands C<=head3>, C<=head4>,
C<=over>, C<=item>, and C<=back>.

=head2 C<=tag>

  =tag tagname

This defines a tag.  The following paragraphs (if any) form the
description of the tag (using the same rules as a plugin's
description).

You'll get a warning if any plugin uses a tag that was not defined by
a C<=tag> command, or if any tag is defined but never used by any
plugin.  (The warnings are generated only when you output the results;
the order C<=tag> and C<=plugin> occur doesn't matter.)

=for Pod::Coverage
compile_templates
format_description
generate_tag_page

=head1 ATTRIBUTES

=head2 delimiters

This is an arrayref of two strings: the opening and closing delimiters
for L<Text::Template>.  (default C<< {{ }} >>)


=head2 file_extension

This suffix is appended to the tag name to form the filename for each
generated page.  (default C<.html>)


=head2 namespace_rewriter

This is a coderef to a function that takes one argument (a plugin
name) and returns the corresponding module name.  (required)


=head2 perlio_layers

This string contains the PerlIO layers to be used when opening files
for output.  (default C<:utf8>)


=head2 pod_formatter

This is a coderef to a function that takes one argument (a string
containing POD) and returns the string formatted as it should appear
in the output.  That can be HTML or any other format.  The string is
guaranteed to start with a POD command paragraph.
(required)

=head1 METHODS

=head2 add_document

  $catalog->add_document($name => $doc);

This adds a L<Pod::Elemental::Document> to the catalog.  The C<$name>
is used for error messages.  May be called multiple times.


=head2 add_file

  $catalog->add_file($filename);

This is just a wrapper around C<add_document> to read a file on disk.


=head2 generate_index_page

  $catalog->generate_index_page($header, $entry, $footer);

This generates an index file listing each tag in the catalog.
The filename will be C<index> with the L</file_extension> appended.

C<$header>, C<$entry>, and C<$footer> are strings to be passed to
L<Text::Template> using the L</delimiters>.

The C<$header> and C<$footer> templates can refer to the following
variables (so that you can use the same header & footer for
C<generate_tag_pages> if you want to):

  $tag              Will be undef
  $tag_description  Will be undef

The C<$entry> template is printed once for each tag.  In addition
to the previous variables, it may also use these:

  $tag          The tag being listed (no longer undef)
  $description  The description of that tag


=head2 generate_tag_pages

  $catalog->generate_tag_pages($header, $entry, $footer);

This generates a file for each tag in the catalog.  It generates the
filenames by appending the L</file_extension> to each tag name.

C<$header>, C<$entry>, and C<$footer> are strings to be passed to
L<Text::Template> using the L</delimiters>.

The C<$header> and C<$footer> templates can refer to the following
variables:

  $tag              The name of the tag being processed
  $tag_description  The description of that tag (may be undef)

The C<$entry> template is printed once for each plugin.  In addition
to the previous variables, it may also use these:

  $author       The author of this plugin (may be undef)
  $name         The name of this plugin
  $module       The module name of the plugin
  $description  The description of the plugin
  @other_tags   The tags for this plugin (not including $tag)

=head1 CONFIGURATION AND ENVIRONMENT

Pod::PluginCatalog requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Pod-PluginCatalog AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-PluginCatalog >>.

You can follow or contribute to Pod-PluginCatalog's development at
L<< https://github.com/madsen/pod-plugincatalog >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
