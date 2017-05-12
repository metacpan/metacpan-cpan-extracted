# -*- perl -*-
#############################################################################
# Pod/objects.pm -- objects representing POD
#
# Copyright (C) 2001 by Marek Rouchal. All rights reserved.
# This package is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#############################################################################

use strict;

package Pod::objects;

# for CPAN
$Pod::objects::VERSION = '1.02';

=head1 NAME

Pod::objects - package with objects for representing POD documents

=head1 SYNOPSIS

  require Pod::objects;
  my $root = Pod::root->new;

=head1 DESCRIPTION

The following section describes the objects returned by
L<Pod::Compiler|Pod::Compiler> and their methods. These objects all
inherit from L<Tree::DAG_Node|Tree::DAG_Node>, so all methods described
there are valid as well.

The set/retrieve methods all work in the following way: If no argument
is specified, the corresponding value is returned. Otherwise the
object's value is set to the given argument and returned.

=head2 Common methods

The following methods are common for all the classes:

=over 4

=item class->B<new>( @parameters )

Create a new object instance of C<class>. See the individual classes for
valid parameters.

=cut

# base class for all POD objects

package Pod::_obj;

require Tree::DAG_Node;

@Pod::_obj::ISA = qw(Tree::DAG_Node);

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my @params = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;
    $self->initialize(@params);
    return $self;
}

# stub to be overridden
sub initialize
{
  1;
}

=item $obj->B<line>( $num )

Store/retrieve the line number where this object occurred in the source
file. Sets and returns the new value if I<$num> is defined and simply
returns the value otherwise.

=cut

sub line
{
  return (@_ > 1) ? ($_[0]->{_line} = $_[1]) : $_[0]->{_line};
}

=item $obj->B<as_pod>()

This method returns the object in POD syntax, including its child
objects. Basically this gives you the same code as in the input file.

=item $obj->B<contents_as_pod>()

Return this object's children in POD format.

=cut

sub contents_as_pod($)
{
  shift->_as_pod;
}

sub _as_pod($;$$)
{
  my ($self,$first,$last) = @_;
  my $str = defined $first ? $first : '';
  foreach($self->daughters) {
    $str .= $_->as_pod;
  }
  $str .= defined $last ? $last : '';
  $str;
}

=item $obj->B<as_text>()

This method returns the object as simple text in ISO-8859-1 encoding.
All POD markup is discarded.

=item $obj->B<contents_as_text>()

Return this object's children as simple text in ISO-8859-1 encoding.
This strips all POD markup.

=back

=cut

sub contents_as_text($)
{
  my $text = $_[0]->_as_text;
  $text =~ s/^\s+|\s+$//sg;
  $text =~ s/\s+/ /sg;
  $text;
}

sub _as_text($$)
{
  my ($self,$first,$last) = @_;
  my $text = $first || '';
  foreach($self->daughters) {
    $text .= $_->as_text;
  }
  $text .= $last || '';
  $text;
}

##############################################################################

=head2 Pod::root

This object represents the root of the POD document and thus serves
mainly as a storage for the following classes. It inherits from
L<Storable|Storable>, so that it can easily be stored to and retrived
from the file system.

=over 4

=item Pod::root->B<new>( %params )

The creation method takes an optional argument C<-linelength =E<gt>
num>. If this is set to a non-zero value, the B<as_pod> method of
B<Pod::para> will reformat the POD to use as much of each line up
to I<num> characters.

=cut

package Pod::root;

require Storable;
@Pod::root::ISA = qw(Pod::_obj Storable);

use Carp;

sub initialize
{
  my ($self, %params) = @_;
  map { $self->{$_} = $params{$_} } keys %params;
  $self->{_nodes} = Pod::node::collection->new;
  $self->{_line} = 0;
  1;
}

sub as_pod($)
{
  my $self = shift;
  my $last = ($self->daughters)[-1];
  $self->_as_pod().
    ($last && !$last->isa('Pod::perlcode') ? "=cut\n" : '');
}

sub as_text($)
{
  shift->_as_text('');
}

=item $root->B<store>( $file )

=item $root->B<store_fd>( $filehandle )

Store the object (and all its contents) to the given file name/handle using
L<Storable|Storable> for subsequent retrieval.

=item Pod::root->B<read>( $file )

=item Pod::root->B<read_fd>( $filehandle )

Read the given file/handle into a B<Pod::root> object. I<$file> must contain a
B<Pod::root> object stored by L<Storable|Storable>, otherwise a fatal
error is raised.

=cut

sub read($$)
{
  my ($class,$file) = @_;
  my $obj = Storable::retrieve($file);
  # check obj against class
  if(!$obj || !$obj->isa($class)) {
    $obj ||= 'undef';
    croak "Fatal: file '$file' contains '$obj' instead of '$class'\n";
  }
  $obj;
}

sub read_fd($$)
{
  my ($class,$handle) = @_;
  my $obj = Storable::fd_retrieve($handle);
  # check obj against class
  if(!$obj || !$obj->isa($class)) {
    $obj ||= 'undef';
    croak "Fatal: handle '$handle' contains '$obj' instead of '$class'\n";
  }
  $obj;
}

=item $root->B<nodes>()

Retrieves this POD's node collection, which is maintained as a
B<Pod::node::collection> object.

=cut

sub nodes
{
  return (@_ > 1) ? ($_[0]->{_nodes} = $_[1]) : $_[0]->{_nodes};
}

=item $root->B<errors>()

Returns the number of errors occured during parsing.

=cut

sub errors
{
  return (@_ > 1) ? ($_[0]->{_errors} = $_[1]) : $_[0]->{_errors};
}

=item $root->B<warnings>()

Returns the number of warnings occured during parsing.

=cut

sub warnings
{
  return (@_ > 1) ? ($_[0]->{_errors} = $_[1]) : $_[0]->{_errors};
}

=item $root->B<links>()

Returns all B<Pod::link> objects within the parsed document.

=back

=cut

sub links
{
  my $self = shift;
  my $links = [];
  $self->walk_down({ callback => \&_get_links, _links => $links });
  @$links;
}

sub _get_links
{
  my ($node,$href) = @_;
  if($node->isa("Pod::link")) {
    push(@{$href->{_links}}, $node);
    return 0;
  }
  1;
}

##############################################################################

=head2 Pod::perlcode

If the B<-perlcode> option was true for B<Pod::Compiler>, then these
objects represent Perl code blocks in the parsed file.

The B<as_text> method returns the empty string, B<as_pod> the contents.

=cut

package Pod::perlcode;

@Pod::perlcode::ISA = qw(Pod::_obj);

=over 4

=item Pod::perlcode->B<new>( $text )

The B<new> constructor takes an optional parameter, which is the string
representing the code block. This string may contain newlines.

=cut

sub initialize
{
  my ($self,$text) = @_;
  $self->{_contents} = defined $text ? $text : '';
  1;
}

=item $perlcode->B<contents>( $string )

This methods sets/retrieves the code block.

=cut

sub contents
{
  return (@_ > 1) ? ($_[0]->{_contents} = $_[1]) : $_[0]->{_contents};
}

=item $perlcode->B<append>( $code )

This methods appends I<$code> to the contents.

=back

=cut

sub append
{
  my ($self,$text) = @_;
  if(defined $text) {
    $self->{_contents} .= $text;
  }
  $self->{_contents};
}

sub as_pod($)
{
  my $self = shift;
  my $pre = $self->left_sister;
  if($pre && !$pre->isa('Pod::perlcode')) {
    return "=cut\n\n".$self->{_contents};
  }
  $self->{_contents};
}

sub as_text($)
{
  # not applicable
  '';
}

##############################################################################

=head2 Pod::para

This represents a simple text paragraph. See B<Pod::root> above for an
option that forces the reformatting of the POD code of a paragraph to a
certain line length. Forced line breaks, i.e. a newline followed by
whitespace is I<not> affected.

=cut

package Pod::para;

@Pod::para::ISA = qw(Pod::_obj);

sub as_pod($)
{
  my $self = shift;
  my $pre = $self->left_sister;
  my $mom = $self->mother;
  # print =pod if
  # - no preceding node and mother is not a list
  # - preceding node
  my $p = '';
  if(!$pre && (!$mom || !$mom->isa('Pod::clist'))) {
    $p = "=pod\n\n";
  }
  if($pre && $pre->isa('Pod::perlcode')) {
    $p = "=pod\n\n";
  }
  my $root = $self->root;
  my $maxlen;
  if($root && ($maxlen = $root->{-linelength})) {
    my @chunks = split(/[ \t]*\n([ \t]+)/, $self->_as_pod());
    unshift @chunks, '';
    my $pod = '';
    do {
      my ($prefix,$chunk) = splice(@chunks,0,2);
      $chunk =~ s/\s+/ /gs;
      $chunk = $prefix.$chunk;
      $chunk =~ s/(.{1,$maxlen})( |$)/$1.(length $2 ? "\n" : '')/sge;
      $pod .= $chunk."\n";
    } while(@chunks);
    return "$pod\n";
  }
  $self->_as_pod($p)."\n\n";
}

sub as_text($)
{
  my $self = shift;
  $self->_as_text('');
}

##############################################################################

=head2 Pod::verbatim

This represents a verbatim paragraph, i.e. a block that has leading
whitespace on its first line.

=cut

package Pod::verbatim;

@Pod::verbatim::ISA = qw(Pod::_obj);

sub initialize
{
  shift->{_content} = [];
}

=over 4

=item $verbatim->B<addline>( $line )

Adds one line to this verbatim paragraph. I<$line> should not
contain carriage returns nor newlines.

=cut

sub addline($$)
{
  push(@{$_[0]->{_content}}, $_[1]);
}

=item $verbatim->B<content>( @lines )

Set this verbatim paragraph's contents to I<@lines>. If I<@lines> is
omitted, this method simply returns the current contents, i.e. an array
of strings that reresent the individual lines.
The contents can be cleared completely by saying 
C<$verbatim-E<gt>content( undef )>.

=back

=cut

sub content($@)
{
  my $self = shift;
  if(@_) {
    if(defined $_[0]) {
      @{$self->{_content}} = @_;
    } else {
      $self->{_content} = [];
    }
  }
  @{$self->{_content}};
}

sub as_pod($)
{
  my $self = shift;
  my $pre = $self->left_sister;
  ( (!$pre || $pre->isa('Pod::perlcode')) ?  "=pod\n\n" : '').
  join("\n",$self->content)."\n\n";
}

sub as_text($)
{
  my $self = shift;
  join("\n",$self->content);
}

##############################################################################

=head2 Pod::head

This class represents C<=headX> directives. The B<new> method accepts a
single argument which denotes the heading level, default is 1.

=cut

package Pod::head;

@Pod::head::ISA = qw(Pod::_obj);

sub initialize
{
  $_[0]->{_level} = $_[1] || 1;
}

=over 4

=item $head->B<level>( $num )

This sets/retrieves the heading level. Officially supported are only 1
and 2, but higher numbers are not rejected here.

=cut

sub level($$)
{
  return (@_ > 1) ? ($_[0]->{_level} = $_[1]) : $_[0]->{_level};
}

=item $head->B<node>( $node )

This sets/retrieves the heading's node information. I<$node> and the
return value are instances of B<Pod::node> or I<undef>.

=cut

sub node($$)
{
  return (@_ > 1) ? ($_[0]->{_node} = $_[1]) : $_[0]->{_node};
}

=item $head->B<nodeid>()

This retrieves the heading's node id from B<node> above. Just a shortcut
for C<$head-E<gt>node-E<gt>id>, and safe in case the node is not
defined. Returns the id string or I<undef>.

=cut

sub nodeid($)
{
  my $self = shift;
  $self->{_node} ? $self->{_node}->id : undef;
}

=item $head->B<nodetext>()

This retrieves the heading's node text from B<node> above. Just a shortcut
for C<$head-E<gt>node-E<gt>text>, and safe in case the node is not
defined. Returns the node text or I<undef>. The node text is derived
from what comes after C<=item>, stripping C<*> (bullets) and C<\d.?>
(numbers) as well as all POD markup. The result is what POD links can
link to from other documents.

=back

=cut

sub nodetext($)
{
  my $self = shift;
  $self->{_node} ? $self->{_node}->text : undef;
}

sub as_pod($)
{
  my $self = shift;
  $self->_as_pod("=head".$self->level." ","\n\n");
}

sub as_text($)
{
  my $self = shift;
  $self->_as_text('');
}

##############################################################################

=head2 Pod::clist

This stores everything that is enclosed by C<=over ... =back>. Note that
such a brace may not span C<=head>s.

=cut

package Pod::clist;

@Pod::clist::ISA = qw(Pod::_obj);

sub initialize
{
  $_[0]->{_auto} = 0;
  $_[0]->{_type} = '';
  $_[0]->{_indent} = 4;
}

=over 4

=item $list->B<autoopen>( $flag )

This sets/retrieves the I<autoopen> property. A list gets this property
when the parser encounters an C<=item> without a previous C<=over>. The
parser then opens a (implicit) list which has the I<autoopen> property
set to true.

=cut

sub autoopen($$)
{
  return (@_ > 1) ? ($_[0]->{_auto} = $_[1]) : $_[0]->{_auto};
}

=item $list->B<indent>( $num )

This sets/retrieves the indent level of the list, i.e. the value that
follows C<=over>. Default is 4.

=cut

sub indent($$)
{
  return (@_ > 1) ? ($_[0]->{_indent} = $_[1]) : $_[0]->{_indent};
}

=item $list->B<type>( $string )

This sets/retrieves the list type. The parser tries to guess this type
from the C<=item>s it encounters. The three possible types are
C<bullet>, C<number>, and C<definition>. In case of doubt, C<definition>
wins.

=cut

sub type($$)
{
  return (@_ > 1) ? ($_[0]->{_type} = $_[1]) : $_[0]->{_type};
}

=item $list->B<has_items>()

This retrieves the number of C<=item>s in this list.

=back

=cut

sub has_items
{
  scalar(grep($_->isa('Pod::item'),shift->daughters));
}

sub as_pod($)
{
  my $self = shift;
  $self->_as_pod("=over ".$self->indent."\n\n","=back\n\n")
}

sub as_text($)
{
  my $self = shift;
  $self->_as_text('');
}

##############################################################################

=head2 Pod::item

This stores a list's C<=item>.

=cut

package Pod::item;

@Pod::item::ISA = qw(Pod::_obj);

sub initialize
{
  shift->{_prefix} = '';
}

=over 4

=item $item->B<prefix>( $string )

This sets the item's prefix. A prefix can be either 'C<*>' or 'C<o>' in
case of a bullet list or a number, optionally followed by a dot for
numbered lists. This is stored separately because links to such nodes do
not contain the prefix.

In case of a numbered list this method returns subsequent numbers for
each item independent of what was parsed.

=cut

sub prefix
{
  return (@_ > 1) ? ($_[0]->{_prefix} = $_[1]) : $_[0]->{_prefix};
}

=item $item->B<node>()

=item $item->B<nodeid>()

=item $item->B<nodetext>()

See L<"Pod::head"> for the description of these methods.

=back

=cut

sub node($$)
{
  return (@_ > 1) ? ($_[0]->{_node} = $_[1]) : $_[0]->{_node};
}

sub nodeid($)
{
  my $self = shift;
  $self->{_node} ? $self->{_node}->id : undef;
}

sub nodetext($)
{
  my $self = shift;
  $self->{_node} ? $self->{_node}->text : undef;
}

sub _prefix
{
  my $self = shift;
  my $prefix = $self->{_prefix};
  my $mum = $self->mother;
  if($mum) {
    my $type = $mum->type;
    if($type =~ /^bullet/) {
      $prefix = '*';
    }
    elsif($type =~ /^number/) {
      my $num = scalar(grep($_->isa('Pod::item'), $self->left_sisters))+1;
      $prefix = "$num.";
    }
    else { # definition
      $prefix = 'Z<>'.$prefix if(length $prefix);
    }
  }
  $prefix;
}

sub _nodetext
{
  my $self = shift;
  my $text = $self->contents_as_text();
  my $mum = $self->mother;
  my $pf = '';
  if(!$mum || $mum->type() =~ /^definition/) {
    $pf = $self->{_prefix};
  }
  $pf.(length($pf) && length($text) ? ' ' : '').$text;
}

sub as_pod($)
{
  my $self = shift;
  my $prefix = $self->_prefix();
  my $contents = $self->contents_as_pod || '';
  '=item'.($prefix?" $prefix":'').($contents?" $contents":'')."\n\n";
}

sub as_text($)
{
  my $self = shift;
  my $prefix = $self->_prefix();
  $self->_as_text($prefix?"$prefix ":'');
}

##############################################################################

=head2 Pod::begin

This stores everything between C<=begin ... =end>. It is unclear how POD
directives in such a block should be handled. The behaviour is undefined
and may change in the future.

B<as_pod> returns the original contents, B<as_text> returns the empty
string.

=cut

package Pod::begin;

@Pod::begin::ISA = qw(Pod::_obj);

sub initialize
{
  $_[0]->{_type} = 'unknown';
  $_[0]->{_args} = '';
  $_[0]->line(0);
  $_[0]->{_chunks} = [];
}

=over 4

=item $begin->B<type>( $string )

This set/retrieves the begin/end block type, i.e. the first argument
after C<=begin>.

=cut

sub type($$)
{
  return (@_ > 1) ? ($_[0]->{_type} = $_[1]) : $_[0]->{_type};
}

=item $begin->B<args>( $string )

This set/retrieves the begin/end block arguments, i.e. everything the
follows the first argument after C<=begin>.

=cut

sub args($$)
{
  return (@_ > 1) ? ($_[0]->{_args} = $_[1]) : $_[0]->{_args};
}

=item $begin->B<addchunk>( $string )

This adds a chunk to the begin/end block. A chunk is a paragraph.

=cut

sub addchunk($$)
{
  push(@{$_[0]->{_chunks}},$_[1]);
}

=item $begin->B<contents>()

Return the current contents, i.e. the array of all chunks.

=back

=cut

sub contents($)
{
  return @{shift->{_chunks}};
}

sub as_pod($)
{
  my $self = shift;
  "=begin ".$self->type.($self->args ? " ".$self->args:'')."\n\n".
  join("\n",@{$self->{_chunks}})."\n\n=end\n\n";
}

sub as_text($)
{
  # the individual formatters must redefine this if
  # this method is desired
  '';
}

##############################################################################

=head2 Pod::for

This stores C<=for> paragraphs. The B<as_pod> method return the original
contents, B<as_text> returns the empty string.

=cut

package Pod::for;

@Pod::for::ISA = qw(Pod::_obj);

sub initialize
{
  $_[0]->{_type} = 'unknown';
  $_[0]->{_args} = '';
  $_[0]->line(0);
  $_[0]->{_chunks} = [];
}

=over 4

=item $for->B<type>( $string )

This sets/retrieves the formatter specification of the C<=for> pargraph.

=cut

sub type($$)
{
  return (@_ > 1) ? ($_[0]->{_type} = $_[1]) : $_[0]->{_type};
}

=item $for->B<args>( $string )

This sets/retrieves everything following the formatter specification
up to the next newline.

=cut

sub args($$)
{
  return (@_ > 1) ? ($_[0]->{_args} = $_[1]) : $_[0]->{_args};
}

=item $for->B<content>( $string )

This sets/retrieves the C<=for> paragraph's contents, i.e. everything
following the first newline after the C<=for> directive.

=back

=cut

sub content($)
{
  return (@_ > 1) ? ($_[0]->{_content} = $_[1]) : $_[0]->{_content};
}

sub as_pod($)
{
  my $self = shift;
  $self->_as_pod("=for ".$self->type.($self->args ? " ".$self->args:'')."\n".
    $self->content)."\n\n";
}

sub as_text($)
{
  # the individual formatters must redefine this if
  # this method is desired
  '';
}

##############################################################################

=head2 Textual Objects

The following sections describe objects that represent text. They have some
common methods:

=cut

package Pod::_text;

# base class for all textual objects

@Pod::_text::ISA = qw(Pod::_obj);

=over 4

=item $textobj->B<nested>()

Gives a string that contains the interior sequence codes in which this
object is nested. A string object XXX inside C<BE<lt>...IE<lt>XXXE<gt>...E<gt>>
would thus return C<BI>.

=cut

sub nested
{
  my $mom = shift->mother;
  if($mom && $mom->can('_code')) {
    return $mom->nested.$mom->_code;
  }
  '';
}

=item $textobj->B<as_pod>()

Gives the POD code of this object, including its children.

=cut

# stubs
sub as_pod($)
{
   my $self = shift;
   $self->_code.'<'.($self->contents_as_pod).'>';
}
# for Pod::Parser
*raw_text = \&as_pod;

=item $textobj->B<as_text>()

Gives the objects text contents. No POD markup will be returned.

=back

=cut

sub as_text($)
{
  shift->contents_as_text;
}

sub _code
{
  '';
}

##############################################################################

=head2 Pod::string

This object contains plain ASCII strings. Note that the contents can well
include angle brackets (C<E<lt>E<gt>>). When converted into POD code, these
are automatically escaped where necesary.

The B<new> constructor takes an optional argument: the string.

=cut

package Pod::string;

@Pod::string::ISA = qw(Pod::_text);

sub initialize
{
  $_[0]->content(defined $_[1] ? $_[1] : '');
}

=over 4

=item $string->B<content>( $text )

Set/retrieve the string's contents.

=back

=cut

sub content($$)
{
  return (@_ > 1) ? ($_[0]->{_content} = $_[1]) : $_[0]->{_content};
}

sub as_pod($)
{
  my $self = shift;
  # deal with <>
  my $str = $self->{_content};
  my $mum;
  $str =~ s{((^|[A-Z])<|>)}{
    if($1 eq '>') {
      if(($mum = $self->mother) && $mum->isa('Pod::_text')) {
        # I am nested, so quote the closing >
        'E<gt>';
      } else {
        '>';
      }
    } else {
      "$2E<lt>";
    }
  }ge;
  $str;
}
# for Pod::Parser
*raw_text = \&as_pod;

sub as_text($)
{
  shift->content;
}

##############################################################################

=head2 Pod::bold

This class represents the C<BE<lt>...E<gt>> (bold) interior sequence.

=cut

package Pod::bold;

@Pod::bold::ISA = qw(Pod::_text);

sub _code { 'B'; }

##############################################################################

=head2 Pod::italic

This class represents the C<IE<lt>...E<gt>> (italic) interior sequence.

=cut

package Pod::italic;

@Pod::italic::ISA = qw(Pod::_text);

sub _code { 'I'; }

##############################################################################

=head2 Pod::code

This class represents the C<CE<lt>...E<gt>> (code/courier) interior sequence.

=cut

package Pod::code;

@Pod::code::ISA = qw(Pod::_text);

sub _code { 'C'; }

##############################################################################

=head2 Pod::file

This class represents the C<FE<lt>...E<gt>> (file) interior sequence.

=cut

package Pod::file;

@Pod::file::ISA = qw(Pod::_text);

sub _code { 'F'; }

##############################################################################

=head2 Pod::nonbreaking

This class represents the C<SE<lt>...E<gt>> (nonbreaking space)
interior sequence.

=cut

package Pod::nonbreaking;

@Pod::nonbreaking::ISA = qw(Pod::_text);

sub _code { 'S'; }

##############################################################################

=head2 Pod::zero

This class represents the C<ZE<lt>E<gt>> (zero width character)
interior sequence. Note that this sequence cannot have children.

=cut

package Pod::zero;

@Pod::zero::ISA = qw(Pod::_text);

sub _code { 'Z'; }

sub as_pod($)
{
  'Z<>';
}
# for Pod::Parser
*raw_text = \&as_pod;

sub as_text($)
{
  '';
}

##############################################################################

=head2 Pod::idx

This class represents the C<XE<lt>...E<gt>> (index) interior sequence.
The text therein is not printed in the resulting manpage, but is supposed to
appear in an index with a hyperlink to the place where it occurred.

=cut

package Pod::idx;

@Pod::idx::ISA = qw(Pod::_text);

sub _code { 'X'; }

=over 4

=item $idx->B<node>()

=item $idx->B<nodeid>()

=item $idx->B<nodetext>()

See L<"Pod::head"> for the description of these methods.

=back

=cut

sub node($$)
{
  return (@_ > 1) ? ($_[0]->{_node} = $_[1]) : $_[0]->{_node};
}

sub nodeid($)
{
  my $self = shift;
  $self->{_node} ? $self->{_node}->id : undef;
}

sub nodetext($)
{
  my $self = shift;
  $self->{_node} ? $self->{_node}->text : undef;
}

sub as_text($)
{
  # index entry is not shown in text
  '';
}

##############################################################################

=head2 Pod::entity

This class represents the C<EE<lt>...E<gt>> (entity) interior sequence.
This object has no children, just a value. Entities encountered in the POD
source that map to standard ASCII characters (most notably C<lt>, C<gt>,
C<sol> and C<verbar>) are not kept as entities, but converted into or appended
to the preceding B<Pod::string>, but only if the nesting of this entity permits.

Entities may be specified as textual entities (C<auml>, C<szlig>, etc.),
or a numeric. The usual Perl encodings are valid here: C<123> is decimal,
C<0x3a> is hexadecimal, C<0177> is octal.

The B<new> constructor takes an optional argument, namely the numeric code 
of the entity to create.

The B<as_text> method returns the corresponding ISO-8859-1 (Latin-1)
character. Sorry, no unicode support yet.

=cut

package Pod::entity;

@Pod::entity::ISA = qw(Pod::_text);

sub _code { 'E'; }

# stolen from HTML::Entities
my %ENTITIES = (
 # Some normal chars that have special meaning in SGML context
 amp    => '&',  # ampersand 
'gt'    => '>',  # greater than
'lt'    => '<',  # less than
 quot   => '"',  # double quote

 # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
 AElig	=> 'Æ',  # capital AE diphthong (ligature)
 Aacute	=> 'Á',  # capital A, acute accent
 Acirc	=> 'Â',  # capital A, circumflex accent
 Agrave	=> 'À',  # capital A, grave accent
 Aring	=> 'Å',  # capital A, ring
 Atilde	=> 'Ã',  # capital A, tilde
 Auml	=> 'Ä',  # capital A, dieresis or umlaut mark
 Ccedil	=> 'Ç',  # capital C, cedilla
 ETH	=> 'Ð',  # capital Eth, Icelandic
 Eacute	=> 'É',  # capital E, acute accent
 Ecirc	=> 'Ê',  # capital E, circumflex accent
 Egrave	=> 'È',  # capital E, grave accent
 Euml	=> 'Ë',  # capital E, dieresis or umlaut mark
 Iacute	=> 'Í',  # capital I, acute accent
 Icirc	=> 'Î',  # capital I, circumflex accent
 Igrave	=> 'Ì',  # capital I, grave accent
 Iuml	=> 'Ï',  # capital I, dieresis or umlaut mark
 Ntilde	=> 'Ñ',  # capital N, tilde
 Oacute	=> 'Ó',  # capital O, acute accent
 Ocirc	=> 'Ô',  # capital O, circumflex accent
 Ograve	=> 'Ò',  # capital O, grave accent
 Oslash	=> 'Ø',  # capital O, slash
 Otilde	=> 'Õ',  # capital O, tilde
 Ouml	=> 'Ö',  # capital O, dieresis or umlaut mark
 THORN	=> 'Þ',  # capital THORN, Icelandic
 Uacute	=> 'Ú',  # capital U, acute accent
 Ucirc	=> 'Û',  # capital U, circumflex accent
 Ugrave	=> 'Ù',  # capital U, grave accent
 Uuml	=> 'Ü',  # capital U, dieresis or umlaut mark
 Yacute	=> 'Ý',  # capital Y, acute accent
 aacute	=> 'á',  # small a, acute accent
 acirc	=> 'â',  # small a, circumflex accent
 aelig	=> 'æ',  # small ae diphthong (ligature)
 agrave	=> 'à',  # small a, grave accent
 aring	=> 'å',  # small a, ring
 atilde	=> 'ã',  # small a, tilde
 auml	=> 'ä',  # small a, dieresis or umlaut mark
 ccedil	=> 'ç',  # small c, cedilla
 eacute	=> 'é',  # small e, acute accent
 ecirc	=> 'ê',  # small e, circumflex accent
 egrave	=> 'è',  # small e, grave accent
 eth	=> 'ð',  # small eth, Icelandic
 euml	=> 'ë',  # small e, dieresis or umlaut mark
 iacute	=> 'í',  # small i, acute accent
 icirc	=> 'î',  # small i, circumflex accent
 igrave	=> 'ì',  # small i, grave accent
 iuml	=> 'ï',  # small i, dieresis or umlaut mark
 ntilde	=> 'ñ',  # small n, tilde
 oacute	=> 'ó',  # small o, acute accent
 ocirc	=> 'ô',  # small o, circumflex accent
 ograve	=> 'ò',  # small o, grave accent
 oslash	=> 'ø',  # small o, slash
 otilde	=> 'õ',  # small o, tilde
 ouml	=> 'ö',  # small o, dieresis or umlaut mark
 szlig	=> 'ß',  # small sharp s, German (sz ligature)
 thorn	=> 'þ',  # small thorn, Icelandic
 uacute	=> 'ú',  # small u, acute accent
 ucirc	=> 'û',  # small u, circumflex accent
 ugrave	=> 'ù',  # small u, grave accent
 uuml	=> 'ü',  # small u, dieresis or umlaut mark
 yacute	=> 'ý',  # small y, acute accent
 yuml	=> 'ÿ',  # small y, dieresis or umlaut mark

 # Some extra Latin 1 chars that are listed in the HTML3.2 draft (21-May-96)
 copy   => '©',  # copyright sign
 reg    => '®',  # registered sign
 nbsp   => "\240", # non breaking space

 # Additional ISO-8859/1 entities listed in rfc1866 (section 14)
 iexcl  => '¡',
 cent   => '¢',
 pound  => '£',
 curren => '¤',
 yen    => '¥',
 brvbar => '¦',
 sect   => '§',
 uml    => '¨',
 ordf   => 'ª',
 laquo  => '«',
'not'   => '¬',    # not is a keyword in perl
 shy    => '­',
 macr   => '¯',
 deg    => '°',
 plusmn => '±',
 sup1   => '¹',
 sup2   => '²',
 sup3   => '³',
 acute  => '´',
 micro  => 'µ',
 para   => '¶',
 middot => '·',
 cedil  => '¸',
 ordm   => 'º',
 raquo  => '»',
 frac14 => '¼',
 frac12 => '½',
 frac34 => '¾',
 iquest => '¿',
'times' => '×',    # times is a keyword in perl
 divide => '÷',

# some POD special entities
 verbar => '|',
 sol => '/'
);

=over 4

=item $entity->B<decode>( $string )

This method can be given any type of entity encoding and sets the entity
value to the resulting code. This code is I<undef> if the given string was
not recognized.

=cut

sub decode
{
  my ($class,$str) = @_;
  my $ent = $class->new;
  $str =~ s/^\s+|\s+$//sg;
  my $value;
  if($str =~ /^(0x[0-9a-f]+)$/i) {
    # hexadecimal
    $value = hex($1);
  }
  elsif($str =~ /^(0[0-7]+)$/) {
    # octal
    $value = oct($1);
  }
  elsif($str =~ /^(\d+)$/) {
    # decimal
    $value = $1;
  }
  elsif($str =~ /^(\w+)$/i) {
    $value = defined $ENTITIES{$1} ? ord($ENTITIES{$1}) : undef;
  }
  return undef unless($value);
  $ent->value($value);
  $ent;
}

sub initialize
{
  $_[0]->{_value} = defined $_[1] ? $_[1] : '';
}

=item $entity->B<value>( $num )

Sets/retrieves the numeric value of this entity.

=cut

sub value($$)
{
  # value is number in ISO-8859-1
  return (@_ > 1) ? ($_[0]->{_value} = $_[1]) : $_[0]->{_value};
}

=item $entity->B<as_pod>()

Returns the POD representation of this entity. If a textual encoding like
C<auml> is known for the value it is used, otherwise decimal encoding.

=back

=cut

sub as_pod($)
{
  my $self = shift;
  my $value = $self->value;
  my $chr = chr($value);
  # deal with nonbreaking space entity
  return 'S< >' if($chr eq $ENTITIES{nbsp});
  my ($ent) = grep($_->[1] eq $chr, map { [ $_ => $ENTITIES{$_} ] }
    keys %ENTITIES);
  # TODO global parameter for dec/hex/oct encoding
  # this is dec
  $ent = $ent ? $ent->[0] : $value;
  "E<$ent>";
}
# for Pod::Parser
*raw_text = \&as_pod;

sub as_text($)
{
  my $self = shift;
  chr($self->{_value});
}

##############################################################################

=head2 Pod::link

This is a class for representation of POD hyperlinks. The code to parse the
corresponding POD code is entirely in B<Pod::Compiler>.

=cut

package Pod::link;

@Pod::link::ISA = qw(Pod::_text);

sub _code { 'L'; }

=over 4

=item Pod::link->B<new>()

The B<new()> method can be passed a set of key/value pairs for one-stop
initialization.

=cut

use Carp;

sub initialize {
  my $self = shift;
  #$self->{_line} ||= '';
  #$self->{_file} ||= '';
  #$self->{_page} ||= '';
  #$self->{_node} ||= '';
  #$self->{_type} ||= '';
  $self->{_mansect} ||= '';
  $self->{_alttext} ||= [];
  if(defined $_[0] && ref($_[0]) && ref($_[0]) eq 'HASH') {
    # called with a list of parameters
    %$self = (%$self, %{$_[0]});
  }
  $self;
}

=item $link->B<as_text>()

This method returns the textual representation of the hyperlink as above,
but without markers (read only). Depending on the link type this is one of
the following alternatives (links to same or other POD document):

 page:    L<perl>              the perl manpage
 item:    L<perlvar/$!>        the $! entry in the perlvar manpage
 item:    L</DESTROY>          the DESTOY entry elsewhere in this
                               document
 head:    L<perldoc/"OPTIONS"> the section on OPTIONS in the perldoc
                               manpage
 head:    L<"DESCRIPTION">     the section on DESCRIPTION elsewhere
                               in this document

The following are not offical, but are supported:

 man:     L<sed(1)>              the sed(1) manpage
 url:     L<http://www.perl.com> http://www.perl.com
          (same for ftp: news: mailto:)

If an alternative text (C<LE<lt>alttext|...E<gt>>) was specified, this
text (without POD markup) is returned.

All POD formatters should use the same text for the different types
of links. Clever formatters create two hyperlinks for item or section links to
another page: one to the top of the page (the page name) and one to the
node within the page (the node name).

=cut

# The complete link's text
sub as_text {
  my $self = shift;
  my @alttext = @{$self->{_alttext}};
  if(@alttext) {
    my $s = join('', map { $_->as_text } @alttext);
    $s =~ s/\s+/ /gs;
    $s =~ s/^\s+|\s+$//gs;
    return $s;
  }
  my $type = $self->{_type};
  my $node = $self->{_node};
  my $page = $self->{_page}.
    (length $self->{_mansect} ? '('.$self->{_mansect}.')' : '');
  if($type eq 'url') {
    return $node;
  }
  (!$node ? '' : $type eq 'item' ?
    "the $node entry" : "the section on $node" ) .
    ($page ? ($node ? ' in ':'') . "the $page manpage" :
    ' elsewhere in this document');
}

=item $link->B<page>()

This method sets or returns the POD page this link points to. If empty,
the link points to the current document itself.

=cut

# The POD page the link appears on
sub page {
  return (@_ > 1) ? ($_[0]->{_page} = $_[1]) : $_[0]->{_page};
}

=item $link->B<node>()

As above, but the destination node text (either head or item) of the link.

=cut

# The link destination
sub node {
  return (@_ > 1) ? ($_[0]->{_node} = $_[1]) : $_[0]->{_node};
}

=item $link->B<alttext>()

Sets or returns an alternative text specified in the link.

=cut

# Potential alternative text
sub alttext {
  my $self = shift;
  if (@_) {
    $self->{_alttext} = [ @_ ];
  }
  @{$self->{_alttext}};
}

=item $link->B<type>()

The node type, either C<page>, C<man>, C<head> or C<item>. As an
unofficial type, there is also C<url>, derived from e.g.
C<LE<lt>http://perl.comE<gt>>

=cut

# The type: item or headn
sub type {
  return (@_ > 1) ? ($_[0]->{_type} = $_[1]) : $_[0]->{_type};
}

=item $link->B<mansect>()

The node type, either C<page>, C<man>, C<head> or C<item>.
As an unofficial type,
there is also C<url>, derived from e.g. C<LE<lt>http://perl.comE<gt>>

=cut

# manual section of page
sub mansect {
  return (@_ > 1) ? ($_[0]->{_mansect} = $_[1]) : $_[0]->{_mansect};
}

=item $link->B<as_pod>()

Returns the link as C<LE<lt>...E<gt>>.

=back

=cut

sub _escape_brackets
{
  $_[0] =~ s{((^|[A-Z])<|>)}{
    if($1 eq '>') {
      "E<gt>";
    }
    else {
      "$2E<lt>";
    }
  }ge;
}

# The link itself
sub as_pod {
  my $self = shift;
  my $link = ($self->page() || '').
    (length $self->{_mansect} ? '('.$self->{_mansect}.')' : '');
  my $node = $self->node();
  my $type = $self->type() || '';
  if($type eq 'url') {
    $link = $node unless length $link;
    _escape_brackets($link);
  }
  elsif($node) {
    _escape_brackets($node);
    $node =~ s/\|/E<verbar>/g;
    $node =~ s:/:E<sol>:g;
    if($self->type() eq 'head') {
      $link .= ($link ? '/' : '') . qq{"$node"};
    }
    else { # item
      $link .= '/' . $node;
    }
  }
  my @txt = $self->alttext();
  if(@txt) {
    my $text = join('', map { $_->as_pod } @txt);
    $text =~ s/\|/E<verbar>/g;
    $text =~ s:/:E<sol>:g;
    $link = "$text|$link";
  }
  "L<$link>";
}
# for Pod::Parser
*raw_text = \&as_pod;

##############################################################################

=head1 ADDITIONAL CLASSES

The following classes to not inherit from any other package and serve as
a convenience storage for POD-related data.

=head2 Pod::node

This class stores information about a POD node, i.e. a potential
hyperlink destination. This is derived from C<=headX>, C<=item> and
C<XE<lt>...E<gt>> entries. See also L<"Pod::node::collection">.

=cut

package Pod::node;

# This class uses an array as storage - it does not
# consume as much memory as hashes. Reason: This is stored
# in memory for most many-POD translators for resolving
# links.

=over 4

=item Pod::node->B<new>( %params )

Creates a new instance of B<Pod::node>. Optional parameters are
B<text>, B<id>, B<type>. See below.

=cut

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = [];
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

sub initialize
{
   my ($self,%params) = @_;
   foreach(keys %params) {
     unless($self->can($_)) {
       warn "Internal error: illegal property '$_' for class '".
         ref($self)."'\n";
       next;
     }
     $self->[0] = $params{text};
     $self->[1] = $params{id};
     $self->[2] = $params{type};
   }
   $self->[3] = 0; # number of hits
   $self;
}

=item $node->B<text>( $string )

Sets/retrieves the node's text. The text is a plain string without any
POD markup in ISO-8859-1 encoding.

=cut

sub text
{
  # stored in #0
  return (@_ > 1) ? ($_[0]->[0] = $_[1]) : $_[0]->[0];
}

=item $node->B<id>( $string )

Sets/retrieves the node's unique id. The id is a string that is unique
in the POD document and can be used as a hyperlink anchor.

=cut

sub id
{
  # stored in #1
  return (@_ > 1) ? ($_[0]->[0] = $_[1]) : $_[0]->[1];
}

=item $node->B<type>( $string )

Sets/retrieves the node's type, which is either C<headX> (X being a
number), C<item> or C<X>, depending on from which POD construct this
node was derived.

=cut

sub type
{
  # stored in #2
  return (@_ > 1) ? ($_[0]->[2] = $_[1]) : $_[0]->[2];
}

=item $node->B<was_hit>()

Increments the number of hits to this node. Should be called whenever a
link was resolved to this node.

=cut

sub was_hit
{
  $_[0]->[3]++;
}

=item $node->B<hits>()

Retrieves the number of hits on this node.

=back

=cut

sub hits
{
  $_[0]->[3];
}

##############################################################################

=head2 Pod::node::collection

This class is merely an array that holds B<Pod::node>s. It provides some
methods to search in this set of nodes.

=cut

package Pod::node::collection;

use Carp;

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = [];
    bless $self, $class;
    return $self;
}

=over 4

=item $ncollection->B<all>()

Return an array of all nodes. Nodes are instances of B<Pod::node>.

=cut

sub all
{
  my $self = shift;
  @$self;
}

=item $ncollection->B<add>( @nodes )

Add the given nodes to the collection. A fatal error occurs when trying
to add non-B<Pod::node>s to the collection. Returns true.

=cut

sub add
{
  my ($self, @new) = @_;
  foreach(@new) {
    unless($_->isa('Pod::node')) {
      croak "Fatal: Tried to add a non-Pod::node to Pod::node::collection";
    }
    push(@$self, $_);
  }
  1;
}

=item $ncollection->B<get_by_text>( $string )

Returns an array of nodes or the first matching node (depending on
context) that exactly matches the node text. The return value should
normally be either the empty array or I<undef> for no match and exactly
one element that matches, unless several nodes with the same text are in
the collection, which should never occur.

=cut

sub get_by_text
{
  my ($self,$text) = @_;
  my @res = grep($_->text eq $text, @$self);
  if(wantarray) {
    return @res;
  }
  $res[0];
}

=item $ncollection->B<get_by_rx>( $regexp )

Same as above, but get the node by matching the given I<$regexp> on the
node text. A fatal error occurs if the regexp has syntax errors.

=cut

sub get_by_rx
{
  my ($self,$rx) = @_;
  my @res = grep($_->text =~ /$rx/, @$self);
  if(wantarray) {
    return @res;
  }
  $res[0];
}

=item $ncollection->B<get_by_id>( $string )

Same as above, but get the node by its unique id.

=cut

sub get_by_id
{
  my ($self,$id) = @_;
  my @res = grep($_->id eq $id, @$self);
  if(wantarray) {
    return @res;
  }
  $res[0];
}

=item $ncollection->B<get_by_type>( $string )

Same as above, but get the node by its type. The string is treated as a
regexp, so you can get all C<=head> nodes by specifying C<"head"> or all
C<=head1> nodes by giving C<"head1">.

=cut

sub get_by_type
{
  my ($self,$type) = @_;
  my @res = grep($_->type =~ /^\Q$type\E/, @$self);
  if(wantarray) {
    return @res;
  }
  $res[0];
}

=item $ncollection->B<ids>()

Return an array of all node ids.

=cut

sub ids
{
  my $self = shift;
  map { $_->id } @$self;
}

=item $ncollection->B<texts>()

Return an array of all node texts.

=back

=cut

sub texts
{
  my $self = shift;
  map { $_->text } @$self;
}

##############################################################################

=head2 Pod::doc

A convenience class for storing POD document information, especially by
converters. See also L<"Pod::doc::collection">.

=cut

package Pod::doc;

use Carp;

=over 4

=item Pod::doc->B<new>( %params )

Create a new instance of B<Pod::doc>, assigning the given optional
parameters. See below for the parameter names, they are identical with
the accessor methods.

=cut

sub new
{
    my ($this,%params) = @_;
    my $class = ref($this) || $this;
    my $self = +{%params};
    bless $self, $class;
    return $self;
}

=item $doc->B<name>( $string )

Set/retrieve the canonical name of the POD document, e.g. C<perldoc> or
C<Pod::Compiler>.

=cut

sub name
{
  return (@_ > 1) ? ($_[0]->{name} = $_[1]) : $_[0]->{name};
}

=item $doc->B<source>( $file )

Set/retrieve the source file name of the POD document, e.g.
F</usr/local/bin/perldoc> or
F</usr/local/lib/perl5/site_perl/Pod/Compiler.pm>.

=cut

sub source
{
  return (@_ > 1) ? ($_[0]->{source} = $_[1]) : $_[0]->{source};
}

=item $doc->B<temp>( $file )

Set/retrieve the temporary file name of the POD document (to be created
by (Pod::root object)->store), e.g. F</tmp/perldoc.tmp> or
F</tmp/Pod__Compiler.tmp>. You have to "invent" a method for generating
temp filenames yourself, see also L<File::Temp>.

=cut

sub temp
{
  return (@_ > 1) ? ($_[0]->{temp} = $_[1]) : $_[0]->{temp};
}

=item $doc->B<destination>( $file )

Set/retrieve the destination file name of the POD document, e.g.
F</usr/local/share/perl/html/perldoc.html> or
F</usr/local/share/perl/Pod/Compiler.html>.

=cut

sub destination
{
  return (@_ > 1) ? ($_[0]->{destination} = $_[1]) : $_[0]->{destination};
}

=item $doc->B<nodes>( $nodecollection )

Set/retrieve the this POD document's node collection. When setting, the
given argument must be a B<Pod::node::collection> object, otherwise a
fatal error occurs.

=back

=cut

sub nodes
{
  my ($self,$arg) = @_;
  # check for Pod::node::collection
  if(defined $arg) {
    unless(ref($arg) && $arg->isa('Pod::node::collection')) {
      croak "Fatal: tried to set a non-Pod::node::collection as Pod::doc::nodes";
    }
    $self->{nodes} = $arg;
  }
  $self->{nodes};
}

##############################################################################

=head2 Pod::doc::collection

This class serves as a container for a set of B<Pod::doc> objects and
defines some methods for such a collection. This object is simply a hash
with the canonical POD name as key and the corresponding B<Pod::doc>
object as value.

=cut

package Pod::doc::collection;

use Carp;

=over 4

=item Pod::doc::collection->B<new>()

Create a new collection instance.

=cut

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = +{};
    bless $self, $class;
    return $self;
}

=item $dcollection->B<all_names>()

Return an array of all sorted documents names in the collection.

=cut

sub all_names
{
  my $self = shift;
  sort keys %{$self};
}

=item $dcollection->B<all_objs>()

Return an array of all B<Pod::doc>s in the collection. There is no
specific sort order.

=cut

sub all_objs
{
  my $self = shift;
  values %{$self};
}

=item $dcollection->B<get>( $name )

Return the B<Pod::doc> object associated with the name I<$name> or
I<undef> if no such name is in the collection.

=cut

sub get
{
  $_[0]->{$_[1]};
}

=item $dcollection->B<add>( $name , $object )

=item $dcollection->B<add>( $object )

Add the given B<Pod::doc> object to the collection. The two-argument
form explicitely sets the name to I<$name>, otherwise the objects name
is used. Exceptions occur if arguments are missing or have the wrong
type or the name is empty.

=cut

sub add
{
  my ($self,$name,$obj) = @_;
  unless(defined $name) {
    croak "Error: missing argument for Pod::doc::collection::add";
  }
  if(ref($name) && $name->isa('Pod::doc')) {
    $obj = $name;
    $name = $obj->name();
  }
  unless(defined $name && length $name) {
    croak "Error: improper name specified for Pod::doc::collection::add (given Pod::doc does not have a proper name set?)";
  }
  unless(defined $obj && $obj->isa('Pod::doc')) {
    croak "Fatal: improper object specified for Pod::doc::collection::add";
  }
  $obj->name($name); # set this name, ensure consistency
  $self->{$name} = $obj;
}

=item $dcollection->B<resolve_link>( $link , $name )

This method tries to resolve the given link (object of class
B<Pod::link>) in the document named I<$name> within the document
collection. Returns the B<Pod::doc> and the B<Pod::node> in case of
success. If the node was found in the current POD (defined by I<$name>)
then the first return value will be the empty string. If a node was
found, its hit count is automatically incremented. Example:

  my ($page,$node) = $dcollection->resolve_link( $link, $myname );
  unless(defined $page) {
    warn "Error: Cannot resolve link.\n";
  }
  elsif(!$page) {
    # node is in the current POD $myname
  }
  else {
    # link to another POD
  }

=back

=cut

sub resolve_link
{
  my ($self,$link,$name) = @_;
  my $type = $link->type;
  unless($type =~ /^(page|head|item)$/) {
    return undef;
  }
  my $page = $link->page || $name;
  my $doc = $self->get($page);
  unless($doc) {
    return undef;
  }
  my $text = $link->node;
  my $ncoll = $doc->nodes;
  unless($ncoll) {
    return ($doc, undef);
  }
  my $node = $ncoll->get_by_rx("^\Q$text\E(\\s|$)");
  $node->was_hit if(defined $node);
  $doc = '' if($doc->name eq $name);
  ($doc,$node);
}

##############################################################################

=head1 SEE ALSO

L<Pod::Compiler>, L<Pod::Parser>, L<Pod::Find>, L<Pod::Checker>

=head1 AUTHOR

Marek Rouchal <marekr@cpan.org>

=cut

1;
