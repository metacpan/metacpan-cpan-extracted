use v5.10.0;
package Pod::Elemental::Transformer::SynHi;
# ABSTRACT: a role for transforming code into syntax highlighted HTML regions
$Pod::Elemental::Transformer::SynHi::VERSION = '0.101000';
use Moose::Role;
with 'Pod::Elemental::Transformer';

use Pod::Elemental::Types qw(FormatName);

use namespace::autoclean;

# =head1 OVERVIEW
#
# Pod::Elemental::Transformer::SynHi is a role to be included by transformers
# that replace parts of the Pod document with C<html> regions, presumably to be
# consumed by a downstream Pod-to-HTML transformer.
#
# If your class composes this role, you only need to write one method,
# C<build_html>.  It will be called like this:
#
#   sub build_html {
#     my ($self, $content, $param) = @_;
#
#     return Some::Syntax::Highlighter->javascript_to_html( $content );
#   }
#
# That will use the mythical Some::Syntax::Highlighter to turn the given content
# into HTML, acting on blocks like:
#
# You'll probably also want to specify a default format name indicating what
# regions to transform by doing this:
#
#   has '+format_name' => (default => 'js');
#
# With that done, the transformer will look for C<=begin js> or C<=for js>
# regions, or verbatim paragraphs beginning with C<#!js> and feed them to the
# syntax highlighter.
#
# =head2 How It Works
#
# This role provides a C<transform_node> method.  It will call
# C<synhi_params_for_para> for each paragraph under the node.  If that method
# returns false, nothing happens.  If it returns a true value, that value will be
# passed to the C<build_html> method, which should return HTML to be placed in an
# C<html> region and used to replace the node that was found.  C<build_html> is
# the one method you B<must> write for yourself!
#
# SynHi transformers have a C<format_name> attribute.  The default
# C<synhi_params_for_para> will look for begin/end or for regions with that
# format name, or for verbatim paragraphs that start with C<!#formatname>.  Any
# text following the format name will be passed to C<parse_synhi_param> and the
# result will be passed as the C<$param> argument seen above.  The rest of the
# content (excluding the shebang line, if one was used) will be the C<$content>
# argument.
#
# The default C<parse_synhi_param> will raise an exception if the param string is
# not empty.
#
# All the documentation of attributes and methods below will be of use primarily
# if you are trying to do something more complex than described above.
#
# =cut

requires 'build_html';

# =attr format_name
#
# This is the format name used to mark regions for syntax highlighting.  It must
# be a valid format name and must be provided.  Classes composing this role are
# expected (but not required) to provide a default.
#
# =cut

has format_name => (
  is  => 'ro',
  isa => FormatName,
  required => 1,
);

# =attr use_standard_wrapper
#
# This boolean, which defaults to true, controls whether the output of a SynHi
# transformer's C<build_html> method is automatically wrapped with
# C<L</standard_code_block>>.
#
# =cut

has use_standard_wrapper => (
  is  => 'rw',
  isa => 'Bool',
  default => 1,
);

# =method synhi_params_for_para
#
#   my $maybe_result = $xformer->synhi_params_for_para($pod_para);
#
# This method is called for each paragraph the transformer considers.  It should
# return either false or an arrayref in the form:
#
#   [ $content_string, $parameters ]
#
# The behavior of the default C<synhi_params_for_para> is described above: it
# looks for regions with the proper format name or verbatim paragraphs starting
# with shebang lines.  It parses post-format-name line content with the
# C<parse_synhi_param> method below.
#
# =cut

sub synhi_params_for_para {
  my ($self, $para) = @_;

  my $name = $self->format_name;

  if (
    $para->isa('Pod::Elemental::Element::Pod5::Region')
    and    $para->format_name eq $name
  ) {
    confess "=begin :$name makes no sense; must be non-Pod region"
      if $para->is_pod;

    confess "non-Pod region must exactly one child" unless
      @{ $para->children } == 1;

    my $content = $para->children->[0]->as_pod_string;
    my ($leading) = $content =~ /\A(?:^\h*$)*^(\h*)\S/m;
    $content =~ s/^$leading//gm;

    return [
      $content,
      $self->parse_synhi_param($para->content // ''),
    ];
  } elsif ($para->isa('Pod::Elemental::Element::Pod5::Verbatim')) {
    my $content = $para->content;

    return
      unless $content =~ s/\A(\h*)#!\Q$name\E(?:[\x20\t]+([^\n]+)?)?\n+//gm;

    my ($leading, $param) = ($1, $2);

    $content =~ s/^$leading//gm;

    return [
      $content,
      $self->parse_synhi_param($param // ''),
    ];
  }

  return;
}

# =method parse_synhi_param
#
# In the example lines:
#
#   =begin formatname parameter string
#
#   #!formatname parameter string
#
# The string "parameter string" can be any arbitrary string that may alter the
# way the SynHi tranformer will work.  This method parses that string and returns
# the result.  This will usually be done by individual syntax highlighting
# classes.  The default method provided will return an empty hashref if the
# parameter string is empty and will raise an exception otherwise.
#
# =cut

sub parse_synhi_param {
  my ($self, $str) = @_;

  confess "don't know how to parse synhi parameter '$str'" if $str =~ /\S/;
  return {};
}

# =method build_html_para
#
# Whenever the C<synhi_params_for_para> method returns true, this method is
# called with the result (array-dereferenced) and the result of I<this> method is
# used to replace the original paragraph.  The default implementation of this
# method is probably suitable for everyone: it passes its parameters along to the
# C<build_html> method, constructs a C<html> region containing the resultant
# string, and returns that.
#
# =cut

sub build_html_para {
  my ($self, $content, $param) = @_;

  my $html = $self->build_html($content, $param);
  $html = $self->standard_code_block($html) if $self->use_standard_wrapper;

  my $new = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'html',
    is_pod      => 0,
    content     => '',
    children    => [
      Pod::Elemental::Element::Pod5::Data->new({ content => $html }),
    ],
  });

  return $new;
}

# =method standard_code_block
#
#   my $html = $xform->standard_code_block( $in_html );
#
# Given a hunk of HTML representing the syntax highlighted code, this rips the
# HTML apart and re-wraps it in a table with line numbers.  It assumes the code's
# actual lines are broken by newlines or C<< <br> >> elements.
#
# The standard code block emitted by this role is table with the class
# C<code-listing>.  It will have one row with two cells; the first has class
# C<line-numbers> and the second has class C<code>.  The table is used to make
# it easy to copy only the code without the line numbers.
#
# Some other minor changes are made, and these may change over time, to make the
# code blocks "better" displayed.  If your needs are very specific, replace this
# method.
#
# =cut

sub standard_code_block {
  my ($self, $html) = @_;

  my @lines = split m{<br(?:\s*/)>|\n}, $html;

  # The leading nbsp below, in generating $code, is to try to get indentation
  # to appear in feed readers, which to not respect white-space:pre or the pre
  # element. The use of <br> instead of newlines is for the same reason.
  # -- rjbs, 2009-12-10
  my $nums  = join "<br />", map {; "$_:&nbsp;" } (1 .. @lines);
  my $code  = join "<br />",
              map {; s/^(\s+)/'&nbsp;' x length $1/me; $_ }
              @lines;

  # Another stupid hack: the <code> blocks below force monospace font.  It
  # can't wrap the whole table, though, because it would cause styling issues
  # in the rendered XHTML. -- rjbs, 2009-12-10
  $html = "<table class='code-listing'><tr>"
        . "<td class='line-numbers'><br /><code>$nums</code><br />&nbsp;</td>"
        . "<td class='code'><br /><code>$code</code><br />&nbsp;</td>"
        . "</table>";

  return $html;
}

sub transform_node {
  my ($self, $node) = @_;

  for my $i (0 .. (@{ $node->children } - 1)) {
    my $para = $node->children->[ $i ];

    next unless my $arg = $self->synhi_params_for_para($para);
    my $new = $self->build_html_para(@$arg);

    die "couldn't produce new html" unless $new;
    $node->children->[ $i ] = $new;
  }

  return $node;
}

# =head1 SEE ALSO
#
# =for :list
# * L<Pod::Elemental::Transformer::SynMux>
#
# =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::SynHi - a role for transforming code into syntax highlighted HTML regions

=head1 VERSION

version 0.101000

=head1 OVERVIEW

Pod::Elemental::Transformer::SynHi is a role to be included by transformers
that replace parts of the Pod document with C<html> regions, presumably to be
consumed by a downstream Pod-to-HTML transformer.

If your class composes this role, you only need to write one method,
C<build_html>.  It will be called like this:

  sub build_html {
    my ($self, $content, $param) = @_;

    return Some::Syntax::Highlighter->javascript_to_html( $content );
  }

That will use the mythical Some::Syntax::Highlighter to turn the given content
into HTML, acting on blocks like:

You'll probably also want to specify a default format name indicating what
regions to transform by doing this:

  has '+format_name' => (default => 'js');

With that done, the transformer will look for C<=begin js> or C<=for js>
regions, or verbatim paragraphs beginning with C<#!js> and feed them to the
syntax highlighter.

=head2 How It Works

This role provides a C<transform_node> method.  It will call
C<synhi_params_for_para> for each paragraph under the node.  If that method
returns false, nothing happens.  If it returns a true value, that value will be
passed to the C<build_html> method, which should return HTML to be placed in an
C<html> region and used to replace the node that was found.  C<build_html> is
the one method you B<must> write for yourself!

SynHi transformers have a C<format_name> attribute.  The default
C<synhi_params_for_para> will look for begin/end or for regions with that
format name, or for verbatim paragraphs that start with C<!#formatname>.  Any
text following the format name will be passed to C<parse_synhi_param> and the
result will be passed as the C<$param> argument seen above.  The rest of the
content (excluding the shebang line, if one was used) will be the C<$content>
argument.

The default C<parse_synhi_param> will raise an exception if the param string is
not empty.

All the documentation of attributes and methods below will be of use primarily
if you are trying to do something more complex than described above.

=head1 ATTRIBUTES

=head2 format_name

This is the format name used to mark regions for syntax highlighting.  It must
be a valid format name and must be provided.  Classes composing this role are
expected (but not required) to provide a default.

=head2 use_standard_wrapper

This boolean, which defaults to true, controls whether the output of a SynHi
transformer's C<build_html> method is automatically wrapped with
C<L</standard_code_block>>.

=head1 METHODS

=head2 synhi_params_for_para

  my $maybe_result = $xformer->synhi_params_for_para($pod_para);

This method is called for each paragraph the transformer considers.  It should
return either false or an arrayref in the form:

  [ $content_string, $parameters ]

The behavior of the default C<synhi_params_for_para> is described above: it
looks for regions with the proper format name or verbatim paragraphs starting
with shebang lines.  It parses post-format-name line content with the
C<parse_synhi_param> method below.

=head2 parse_synhi_param

In the example lines:

  =begin formatname parameter string

  #!formatname parameter string

The string "parameter string" can be any arbitrary string that may alter the
way the SynHi tranformer will work.  This method parses that string and returns
the result.  This will usually be done by individual syntax highlighting
classes.  The default method provided will return an empty hashref if the
parameter string is empty and will raise an exception otherwise.

=head2 build_html_para

Whenever the C<synhi_params_for_para> method returns true, this method is
called with the result (array-dereferenced) and the result of I<this> method is
used to replace the original paragraph.  The default implementation of this
method is probably suitable for everyone: it passes its parameters along to the
C<build_html> method, constructs a C<html> region containing the resultant
string, and returns that.

=head2 standard_code_block

  my $html = $xform->standard_code_block( $in_html );

Given a hunk of HTML representing the syntax highlighted code, this rips the
HTML apart and re-wraps it in a table with line numbers.  It assumes the code's
actual lines are broken by newlines or C<< <br> >> elements.

The standard code block emitted by this role is table with the class
C<code-listing>.  It will have one row with two cells; the first has class
C<line-numbers> and the second has class C<code>.  The table is used to make
it easy to copy only the code without the line numbers.

Some other minor changes are made, and these may change over time, to make the
code blocks "better" displayed.  If your needs are very specific, replace this
method.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Elemental::Transformer::SynMux>

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
