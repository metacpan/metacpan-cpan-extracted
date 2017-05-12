# -*- perl -*-
#############################################################################
# Pod/Compiler.pm -- compiles POD into an object tree
#
# Copyright (C) 2001 by Marek Rouchal. All rights reserved.
# This package is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#############################################################################

#         In nova fert animus
#         mutatas dicere formas
#         corpora.          -- Ovid, Metamorphoses

package Pod::Compiler;

=head1 NAME

Pod::Compiler - compile POD into an object tree

=head1 SYNOPSIS

  use Pod::Compiler;

=head1 DESCRIPTION

This package, based on L<Pod::Parser|Pod::Parser>, compiles a given POD
document into an object tree (based on L<Tree::DAG_Node|Tree::DAG_Node>).
It prints errors and warnings about the POD it reads. The result can be
used to conveniently convert the POD into any other format.

The resulting objects have a variety of methods to ease the subsequent
conversion.

There are two script based on this package, namely 
L<podchecker2|podchecker2>, an enhanced POD syntax checker and 
L<podlint|podlint>, which beautifies the POD of a given file.

This package is object-oriented, which means that you can quite easily
build a derived package and override some methods in case the given
behaviour does not exactly suit your needs.

=cut

use strict;

require Exporter;
require Pod::Parser;
require Pod::objects;
#$Tree::DAG_Node::Debug = 1;

$Pod::Compiler::VERSION = '0.21';
@Pod::Compiler::ISA = qw(Exporter Pod::Parser);

@Pod::Compiler::EXPORT = qw();
@Pod::Compiler::EXPORT_OK = qw(pod_compile);

##############################################################################
# subs to be imported

=head2 Package Functions

The following functions can be imported and called from a script,
e.g. like this:

  use Pod::Compiler qw(pod_compile);
  my $root = pod_compile('myfile.pod');

=over 4

=item pod_compile( { %options } , $file )

=item pod_compile( $file )

Compile the given I<$file> using some I<%options> and return the root
of the object tree representing the POD in I<$file>. The return value
is either I<undef> if some fatal error occured or an object of type
B<Pod::root>. See below for methods applicable to this class and for the
options.

The special option C<-compiler =E<gt> 'class'> lets you specify an
alternate (derived) compiler class rather than B<Pod::Compiler>.

=back

=cut

sub pod_compile($;$)
{
  my %opts;
  %opts = %{(shift)} if(ref($_[0]) && ref($_[0]) eq 'HASH');
  my ($infile) = @_;
  my $compiler_class = delete($opts{-compiler}) || 'Pod::Compiler';
  my $compiler = $compiler_class->new(%opts);
  # the compiler won't print anything, though
  $compiler->parse_from_file($infile,\*STDERR);
  # return the parseed POD root object
  $compiler->root();
}

##############################################################################
# Method definitions begin here

=head2 Compiler Object Interface

The following section describes the OO interface of B<Pod::Compiler>.

=over 4

=item $c = Pod::Compiler->new( %options )

Set up a new compiler object. Options (see below) can be passed as a
hash, e.g.

 $c = Pod::Compiler->new( -warnings => 0 ); # don't be silly

B<Pod::Compiler> inherits from B<Pod::Parser>. See L<Pod::Parser> for
additional methods.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %opts = @_;
    my $self = +{%opts};
    bless $self, $class;
    $self->initialize();
    return $self;
}

=item $c->initialize()

Initalize, set defaults. The following options are set to the given defaults
unless they have been defined at object creation:

  -errors => 1

Print POD syntax errors (using B<messagehandler>) if option value is true.

  -warnings => 1

Print POD syntax warnings (using B<messagehandler>) if option value is true.

  -idlength => 20

Pod::Compiler creates a unique node id for each C<=head>, C<=item> and 
C<XE<lt>E<gt>>, consisting only of C<\w> characters. The option value 
specifies how many characters from the original node text are used for
the node id by the built-in B<make_unique_node_id> method. See below for
more information.

  -ignore => 'BCFS'

This option specifies which interior sequences (e.g. C<BE<lt>...E<gt>>)
are ignored when nested in itself, e.g. C<BE<lt>...BE<lt>...E<gt>...E<gt>>.
The inner C<B> is simply discarded if the corresponding letter appears in
the option value string.

  -unwrap => 'I'

This option specifies which interior sequences (e.g. C<IE<lt>...E<gt>>)
are unwrapped when nested in itself, e.g. C<IE<lt>...IE<lt>...E<gt>...E<gt>>
is turned into C<IE<lt>...E<gt>...IE<lt>...E<gt>>. While some destination
formats may handle such nestings appropriately, other might have problems.
This option solves it right away. By the way, from a typographical point
of view, italics are often used for emphasis. In order to emphasize something
within an emphasis, one reverts to the non-italic font.

  name => ''

This is used to store the (logical) name of the POD, i.e. for example the
module name as it appears in C<use module;>. It is used internally only to
detect internal links pointing to the explicit page name. Example: You
compile the file F<Compiler.pm> which contains the package C<Pod::Compiler>.
You set name to C<Pod::Compiler> (there is no safe automatic way to do so).
Thus if the file includes a link like 
C<LE<lt>Pod::Compiler/messagehandlerE<gt>> it is recognized as an internal
link and it is checked whether it resolves. Of course you should have written
the link as C<LE<lt>/messagehandlerE<gt>>...

  -perlcode => 0

If set to true, the compiler will also return the Perl code blocks
as objects B<Pod::perlcode>, rather than only the POD embedded in the file.
This is used e.g. by L<podlint|podlint>.

=cut

sub initialize
{
    my $self = shift;

    ## Options
    # print errors
    $self->{-errors}   = 1       unless defined $self->{-errors};
    # print warnings
    $self->{-warnings} = 1       unless defined $self->{-warnings};
    # length of significant chars of unique id strings
    $self->{-idlength} = 20      unless defined $self->{-idlength};
    # nested sequences to ignore
    $self->{-ignore}   = 'BCFS'  unless defined $self->{-ignore};
    # nested sequences to unwrap
    $self->{-unwrap}   = 'I'     unless defined $self->{-unwrap};
    # wrap paragraphs to n char length
    $self->{-linelength} ||= 0;
    # the POD name
    $self->{name}    ||= '';
    # get perl code as well
    $self->parseopts(-want_nonPODs => 1)
                                 if($self->{-perlcode});
    ## INTERNALS
    # counters for errors/warnings of compile
    $self->{ERROR} = 0;
    $self->{WARNING} = 0;

    # error handling for Pod::Parser
    $self->errorsub('_parser_err');
}

=item $c->option( $name , $value )

Get or set the compile option (see above) given by I<$name>. If I<$value> is
defined, the option is set to this value. The resulting (or unchanged) value is
returned.

=cut

sub option
{
  my ($self,$option,$value) = @_;
  die "Fatal: No option specified for Pod::Compiler::option.\n"
    unless($option);
  if(defined $value) {
    $self->{$option} = $value;
    $self->parseopts(-want_nonPODs => $value)
      if($option eq '-perlcode');
  }
  $self->{$option};
}

=item $c->messagehandler( $severity , $message )

This method is called every time a warning or error occurs. I<$severity> is
one of 'ERROR' or 'WARNING', I<$message> is a one-line string.
The built-in method simply does

  warn "$severity: $message\n";

=cut

# internal wrapper
sub _msg
{
  my ($self,$severity,$msg) = @_;
  $self->{$severity}++;
  return 0 if(($severity eq 'WARNING' && !$self->{-warnings}) ||
              ($severity eq 'ERROR' && !$self->{-errors}));
  # calls the real method
  $self->messagehandler($severity,$msg);
}

sub messagehandler
{
  my ($self,$severity,$msg) = @_;
  warn "$severity: $msg\n";
  1;
}

=item $c->name(S< [ $name ] >)

Set/retrieve the C<name> property, i.e. the canonical Pod name
(e.g. C<Pod::HTML>). See above for more details.

=cut

sub name
{
  return (@_ > 1) ? ($_[0]->{name} = $_[1]) : $_[0]->{name};
}

=item $c->root()

Return the root element (instance of class B<Pod::root>) representing
the compiled POD document. See below for more info about its methods.

=cut

sub root
{
  return (@_ > 1) ? ($_[0]->{_root} = $_[1]) : $_[0]->{_root};
}

=item $c->make_unique_node_id($string)

Turn given text string into a document unique node id.
Can be overridden to adapt this to specific formatter needs.
Basically this method takes a string and must return something (more or
less dependent on the string) that is unique for this POD document. The
built-in method maps all consecutive non-word characters and underlines to
a single underline and truncates the result to B<-idlength> (see options
above). If the result already exists, a suffix C<_n> is appended, where
C<n> is a number starting with 1.
A different method could e.g. just return ascending numbers, but if you 
think of HTML output, a node id that resembles the text and has a fair
chance to remain constant over subsequent compiles of the same document
gives the opportunity to link to such anchors from external documents.

=back

=cut

sub make_unique_node_id
{
  my ($self, $str) = @_;
  $str =~ s/[\W_]+/_/g;
  $str = lc substr($str,0,$self->{-idlength});
  my $ext = '';
  # build cache of existing IDs
  my %ids = map { $_ => 1 } $self->{_root}->{_nodes}->ids;
  while(defined $ids{$str.$ext}) {
    if($ext) {
      $ext++;
    } else {
      $ext = 1;
      $str .= '_';
    }
  }
  $str .= $ext;
  $str;
}

# internal: create and remember id
sub _make_node
{
  my ($self,$text,$type,$line) = @_;
  $self->_canonify($text);
  return undef unless(length $text);
  my $ncoll = $self->{_root}->{_nodes};
  my $node;
  if($ncoll->get_by_text($text)) {
    $self->_msg('WARNING',
      "node '$text' ($type) at line $line already defined");
  } else {
    my $id = $self->make_unique_node_id($text);
    unless(defined $id) {
      $self->_msg('WARNING',
        "could not create a node id for '$text' ($type) at line $line");
    } else {
      # save the type of node (head, item or X<>)
      # for later reference
      $node = Pod::node->new(text => $text, id => $id, type => $type);
      $ncoll->add($node);
    }
  }
  $node;
}

# make sure to break circular references correctly
sub DESTROY {
  my $self = shift;
  delete $self->{_current};
  delete $self->{_root};
}

##############################################################################
# overrides for Pod::Parser

# things to do at start of POD
sub begin_input
{
  my $self = shift;
  $self->{_current} = $self->{_root} = Pod::root->new(
    -linelength => $self->{-linelength} );
  $self->{_current_heading} = [ '','' ];
}

# to get the Perl code paragraphs too
sub preprocess_paragraph
{
  my ($self,$text,$line) = @_;
  if($self->cutting) {
    # we have a Perl code par
    my $last = ($self->{_current}->daughters)[-1];
    if($last && $last->isa('Pod::perlcode')) {
      $last->append($text);
    } else {
      my $pcode = Pod::perlcode->new($text);
      $pcode->line($line);
      $self->{_current}->add_daughter($pcode);
    }
    return ''; # do not process this in another way
  }
  $text;
}

# things to do at end of POD
sub end_pod {
  my $self = shift;
  my $c = $self->{_current};
  if($c->isa('Pod::clist')) {
    $self->_msg('ERROR', "=over at line ".
      $c->line()." without =back at EOF");
    unless($c->daughters) {
      $self->_msg('WARNING', "discarding empty list");
      $c->detach();
    }
  }
  if($c->isa('Pod::begin')) {
    $self->_msg('ERROR', "=begin at line ".
      $c->line()." without =end at EOF");
    unless($c->contents) {
      $self->_msg('WARNING', "discarding empty begin block");
      $c->detach();
    }
  }
  # check internal links
  my $ncoll = $self->{_root}->{_nodes};
  foreach my $link ($self->{_root}->links) {
    my $type = $link->type;
    my $text = $link->node;
    my $line = $link->line;
    # internal link:
    # page name is eq current POD name or no page name
    my $page = $link->page;
    if($type =~ /^(head|item)$/ && (!$page ||
        ($self->{name} && $self->{name} eq $page))) {
      my $node;
      if($node = $ncoll->get_by_text($text)) {
        if($type eq 'item' && $node->type =~ /^head/) {
          $self->_msg('ERROR',
            "Internal link better written as L</\"$text\"> at line $line");
          $link->type('head');
        }
        elsif($type eq 'head' && $node->type !~ /^head/) {
          $self->_msg('ERROR',
            "Internal link better written as L</$text> at line $line");
          $link->type('item');
        }
        #warn "Link '$text' resolved!\n";
      } else {
        $self->_msg('ERROR',
          "Cannot resolve internal link '$text' at line $line");
      }
    }
  }
  $self->{_root}->errors($self->{ERROR});
  $self->{_root}->warnings($self->{WARNING});
  1;
}

# expand a POD command
sub command
{
  my ($self, $cmd, $paragraph, $line, $pod_para) = @_;
  my ($file) = $pod_para->file_line;

  # Check the command syntax
  $paragraph =~ s/\s+$//s;

  if($cmd eq 'over') {
    # check argument
    my $indent = 4; # default
    if($paragraph =~ /^\s*(\d+)$/s) {
      $indent = $1;
    } else {
      $self->_msg('WARNING',
        "Not a numeric argument for =over: '$paragraph'");
    }
    # start a new list
    my $list = Pod::clist->new;
    $list->indent($indent);
    $list->line($line); # remember start line of list
    $self->{_current}->add_daughter($list);
    $self->{_current} = $list; # make list current context
  }

  elsif($cmd eq 'item') {
    # are we in a list?
    my $list = $self->{_current};
    if($list->isa('Pod::begin')) {
      # TODO ??? POD commands in begin block?
      $list = $list->mother;
    }
    unless($list->isa('Pod::clist')) {
      $self->_msg('ERROR', "=item without previous =over");
      # auto-open a list
      my $autolist = Pod::clist->new;
      $autolist->line($line);
      $autolist->autoopen(1);
      $list->add_daughter($autolist);
      $list = $self->{_current} = $autolist;
    }
    # check whether the previous item had some contents
    my $last_item = ($list->daughters)[-1];
    if($last_item && $last_item->isa('Pod::item') && !($last_item->daughters)) {
      $self->_msg('WARNING',"previous =item has no contents");
    }

    # check argument
    my $type = 'definition';
    my $prefix = '';
    if($paragraph =~ s/^(\s*[*o](?:\s+|$))//s) {
      $type = 'bullet';
      $prefix = '*';
    }
    elsif($paragraph =~ s/^(\s*([1-9]\d*\.?)\s*)//s) {
      $type = "number";
      $prefix = $2;
    }
    elsif($paragraph eq '') {
      $self->_msg('WARNING',"No argument for =item");
      $type = 'bullet';
      $prefix = '*';
    }

    my $first = $list->type();
    unless($first) {
      $list->type($type);
    }
    elsif($first ne $type) {
      $self->_msg('ERROR',"=item type mismatch ('$first' vs. '$type') at line $line");
      if($type =~ /^definition/ || ($type =~ /^number/ && $first =~ /^bullet/)) {
        $list->type($first = $type);
      }
    }

    # add this item
    my $item = Pod::item->new;
    $item->prefix($prefix);
    $item->line($line);
    $item->add_daughters($self->interpolate($paragraph, $line));
    $list->add_daughter($item);
    # verify numbering
    if($first =~ /^number/) {
      my $number = 1;
      foreach($item->left_sisters) {
        $number++ if($_->isa('Pod::item'));
      }
      unless($prefix == $number) {
        $self->_msg('WARNING',"numbering mismatch in =item at line $line");
      }
    }
  }

  elsif($cmd eq 'back') {
    # check if we have an open list
    unless($self->{_current}->isa('Pod::clist')) {
      $self->_msg('ERROR', "=back without previous =over at line $line");
    }
    else {
      # check for spurious characters
      if($paragraph =~ /\S/s) {
        $self->_msg('ERROR',"Spurious character(s) after =back");
      }
      # close list
      my $list = $self->{_current};
      $self->{_current} = $list->mother;

      # check for empty lists
      unless($list->daughters) {
        $self->_msg('ERROR',"No contents in =over/=back list");
      } else {
        $self->_postprocess_list($list);
      }
    } # end in_list
  }

  elsif($cmd =~ /^head([1-9]\d*)/) {
    my $level = $1;
    # check if there is an open list
    my $current = $self->{_current};
    while($current->isa('Pod::clist')) {
      unless($current->autoopen) {
        $self->_msg('ERROR', "=over at line ". $current->line() .
          " without closing =back (at $cmd at line $line)");
      }
      $self->_postprocess_list($current);
      $current = $self->{_current} = $current->mother;
    }
    # check contents
    my $head = Pod::head->new($level);
    $head->line($line);
    $head->add_daughters($self->interpolate($paragraph,$line));
    my $text = $head->contents_as_text;
    if($text =~ /\S/) {
      # check whether the previous =head section had some contents
      my ($cline,$clevel) = @{$self->{_current_heading}};
      if($clevel && $clevel >= $level) {
        my $last_pod = ($current->daughters)[-1];
        if($last_pod && $last_pod->isa('Pod::head')) {
          $self->_msg('WARNING',"empty =head$clevel section at line $cline");
        }
      }
      $current->add_daughter($head);
      # remember current heading
      $self->{_current_heading} = [ $line, $level ];
      # create unique node id for this item
      my $node = $self->_make_node($text,$cmd,$line);
      $head->node($node) if($node)
    } else {
      $self->_msg('ERROR',"ignoring empty =$cmd at line $line");
    }
  }

  elsif($cmd eq 'begin') {
    if($self->{_current}->isa('Pod::begin')) {
      # already have a begin
      $self->_msg('ERROR',
        "Nested =begin's (first at line ".$self->{_current}->line().")");
    }
    else {
      # check for argument
      my ($type,$args);
      if($paragraph =~ /^\s*(\S+)\s*(.*)/s) {
        ($type,$args) = ($1,$2);
      } else {
        $self->_msg('ERROR',"No argument for =begin at line $line");
        $type = 'undef';
        $args = '';
      }
      # remember the =begin
      my $begin = Pod::begin->new;
      $begin->type($type);
      $begin->args($args);
      $begin->line($line);
      $self->{_current}->add_daughter($begin);
      $self->{_current} = $begin;
    }
  }

  elsif($cmd eq 'end') {
    my $current = $self->{_current};
    if($current->isa('Pod::begin')) {
      # close the existing =begin
      $self->{_current} = $current->mother;
      # check for spurious characters
      # the closing argument is optional
      if($paragraph =~ /^\s*(\S+)\s*(.*)$/s) {
        my $type = $1;
        if($2) {
          $self->_msg('ERROR',
            "Spurious character(s) after '=end $type'");
        }
        # check opening/closing types
        my $opentype = $current->type();
        if($opentype && $opentype ne $type) {
          $self->_msg('ERROR',
            "'=begin $opentype' at line ".$current->line().
            "does not match '=end $type' at line $line");
        }
      }
    }
    else {
      # don't have a matching =begin
      $self->_msg('ERROR',"=end without =begin on $line");
    }
  }

  elsif($cmd eq 'for') {
    my ($type,$args);
    if($paragraph =~ s/^\s*(\S+)[ \t]*([^\n]*)\n*//s) {
      ($type,$args) = ($1,$2);
      $args =~ s/\s+$//s;
      my $forp = Pod::for->new;
      $forp->type($type);
      $forp->args($args);
      $forp->content($paragraph);
      # TODO check if in =begin?!?
      $self->{_current}->add_daughter($forp);
    } else {
      $self->_msg('ERROR',
        "ignoring =for without formatter specification at line $line");
      $paragraph = ''; # do not expand paragraph below
    }
  }

  elsif($cmd =~ /^(pod|cut)$/) {
    # check for argument
    if($paragraph =~ /\S/) {
      $self->_msg('ERROR',"Spurious text after =$cmd");
    }
  }

  else {
    $self->_msg('ERROR',"Invalid pod command '$cmd'");
  }
}

# to be done at =back or end of POD with an open list
sub _postprocess_list
{
  my ($self,$list) = @_;
  my $is_def = $list->type =~ /^definition/;
  my $is_num = $list->type =~ /^number/;
  my $have_item;
  my $number = 1;
  foreach my $item ($list->daughters) {
    # skip paragraphs/verbatim/etc.
    next unless $item->isa('Pod::item');
    my $line = $item->line;
    $have_item++;
    my $text = $item->_nodetext();
    if($is_num) {
      $item->prefix("$number.");
      $number++;
    }
    if($text =~ /\S/s) {
      my $node = $self->_make_node($text,'item',$line);
      $item->node($node) if($node);
    }
    elsif($is_def) {
      $self->_msg('WARNING', "no text content in =item at line $line");
    }
  }
  # non-items in =over/=back
  if($have_item) {
    my $first = ($list->daughters)[0];
    if($first && !$first->isa('Pod::item')) {
      $self->_msg('WARNING',"mixed indented/itemized list starting at line ".
        $list->line);
    }
  }
}

# process a verbatim paragraph
sub verbatim {
  my ($self, $paragraph, $line, $pod_para) = @_;

  # strip trailing whitespace
  $paragraph =~ s/\s+$//s;

  unless($paragraph =~ /\S/) {
    # just an empty line
    return 1;
  }

  my $current = $self->{_current};
  # check context (list, begin)
  if($current->isa('Pod::begin')) {
    $current->addchunk($paragraph);
    return 1;
  }

  # make verbatim par
  my $verbobj;
  my $lastobj = ($self->{_current}->daughters)[-1];
  if($lastobj && $lastobj->isa('Pod::verbatim')) {
    # recycle previous verbatim paragraph
    $verbobj = $lastobj;
    $verbobj->addline('');
  } else {
    $verbobj = Pod::verbatim->new;
    $self->{_current}->add_daughter($verbobj);
  }
  foreach(split(/[\r\n]+/, $paragraph)) {
    s/\s*$//s;
    $verbobj->addline($_);
  }
  1;
}

# a regular text paragraph
sub textblock {
  my ($self, $paragraph, $line, $pod_para) = @_;

  $paragraph =~ s/\s+$//s;
  my $current = $self->{_current};
  # check context (list, begin)
  if($current->isa('Pod::begin')) {
    $current->addchunk($paragraph);
  } else {
    my $par = Pod::para->new;
    $par->line($line);
    $par->add_daughters($self->interpolate($paragraph,$line));
    # check for non-empty content
    if($par->contents_as_text =~ /\S/) {
      $current->add_daughter($par);
    } else {
      $self->_msg('WARNING',"no text contents in paragraph at line $line, ignoring it");
    }
  }
}

# expand a POD text string into object tree
# return array of objects
sub interpolate
{
  my ($self,$paragraph,$line) = @_;
  # expand the interior sequences, map strings to objects
  my @objs = @{$self->parse_text({-expand_seq => 'my_expand_seq' },$paragraph,$line)};
  for(@objs) {
    unless(ref($_)) {
      $_ = Pod::string->new($_);
      $_->line($line);
    } else {
      $line = $_->line();
    }
  }
  # postprocessing:
  # ignore or undo nesting of interior sequences
  my $troot = Pod::root->new;
  $troot->set_daughters(@objs);
  $self->_process_nesting($troot,'');
  ($troot,@objs) = $troot->replace_with_daughters; # unroot objects
  @objs;
}

# this does the ignoring/unwrapping, recursively
sub _process_nesting
{
  my ($self,$obj,$nestlist) = @_;
  my $unwraprx = $self->{-unwrap} ? '['.$self->{-unwrap}.']' : '';
  my $ignorerx = $self->{-ignore} ? '['.$self->{-ignore}.']' : '';

  my $item = ($obj->daughters)[0]; # first daughter
  while($item) {
    my $code = $item->_code;
    if($code && $code =~ /[BCFIS]/ && $nestlist =~ /$code/) {
      if($ignorerx && $code =~ /$ignorerx/) {
        # ignore nested
        $self->_msg('WARNING', "ignoring nested $code<...$code<...>...>");
        my $new = ($item->replace_with_daughters)[1];
        if($new) {
          # process the newly promoted daughters
          $item = $new;
          next;
        }
        # else we will process the next sister
      }
      elsif($unwraprx && $code =~ /$unwraprx/) {
        # toggle
        $self->_msg('WARNING', "unwrapping nested $code<...$code<...>...>");
        my @rest = $item->right_sisters;
        my @unwrap = $item->daughters;
        # find the node of same type
        # replicate the complete nesting structure
        my $cmom = $obj;
        while($cmom->_code ne $code) {
          my $i = $cmom->new; # intermediate node
          $i->set_daughters(@unwrap);
          @unwrap = ($i);
          $i = $cmom->new; # intermediate node
          $i->set_daughters(@rest);
          @rest = ($i,$cmom->right_sisters);
          $cmom = $cmom->mother;
        }
        if(@rest) {
          my $top = $cmom->new;
          $top->set_daughters(@rest);
          @rest = ($top);
        }
        $cmom->add_right_sisters(@unwrap,@rest);
        my $mom = $item->unlink_from_mother;
        # mother is empty?
        while($mom && scalar($mom->daughters) == 0) {
          $self->_msg('WARNING', "simplifying tree");
          $mom = $mom->unlink_from_mother;
        }
        last; # ... as we've eaten up everything on this level
      } # end if unwrap
    } # end if code in nestlist
    # recurse
    $self->_process_nesting($item,"$nestlist$code");
    # next, please!
    $item = $item->right_sister;
  } # end while daughters
  1;
}

sub my_expand_seq
{
  my ($self,$seq) = @_;
  my $cmd = $seq->cmd_name();
  my $contents = $seq->parse_tree();
  my ($file,$line) = $seq->file_line();
  my $obj;
  local($_);

  # an entity
  if($cmd eq 'E') {
    my $str = $seq->parse_tree->raw_text();
    my $obj = Pod::entity->decode($str);
    unless($obj) {
      $self->_msg('ERROR', "unrecognized entity '$str' at line $line, ignoring it");
      return '';
    }
    else {
      # return string if "normal" ascii character
      $obj->line($line);
      my $val = $obj->value();
      if($val > 31 && $val < 127) {
        if($val == 47 || $val == 124) { # / or |
          my $nest = '';
          while($seq = $seq->nested) {
            $nest .= $seq->cmd_name();
          }
          # ... unless / or | in L<...> context
          return $obj if($nest =~ /L/);
        }
        return chr($val);
      }
    }
    return $obj;
  }

  # a hyperlink
  elsif($cmd eq 'L') {
    # try to parse the hyperlink
    $_ = $seq->parse_tree->raw_text();

    # collapse newlines with whitespace
    if(s/\s*\n+\s*/ /g) {
      $self->_msg('WARNING', "collapsing newlines to blanks in L<> at line $line");
    }
    # strip leading/trailing whitespace
    if(s/^[\s\n]+|[\s\n]+$//) {
      $self->_msg('WARNING', "ignoring leading/trailing whitespace in L<> at line $line");
    }
    unless(length($_)) {
      $self->_msg('ERROR', "empty link at line $line, ignoring it");
      return '';
    }

    # Check for different possibilities. This is tedious and error-prone
    # we match all possibilities (alttext, page, head/item)

    # only page
    # problem: a lot of people use (), or (1) or the like to indicate
    # man page sections. But this collides with L<func()> that is supposed
    # to point to an internal funtion...
    my $page_rx = '[\w.]+(?:::[\w.]+)*(?:[(]\d\w?[)]|)';
    my $url_rx = '(?:\w{3,8}):[^:].*';

    my ($alttext,$page,$type,$node) = (undef,'','','');
    my $mansect = '';

    if(m!^($page_rx)$!o) {
      $page = $1;
      $type = 'page';
    }
    # alttext, page and "head"
    elsif(m!^(.*?)\s*[|]\s*($page_rx)\s*/\s*"(.+)"$!o) {
      ($alttext, $page, $node) = ($1, $2, $3);
      $type = 'head';
    }
    # alttext and page
    elsif(m!^(.*?)\s*[|]\s*($page_rx)$!o) {
      ($alttext, $page) = ($1, $2);
      $type = 'page';
    }
    # alttext and "head"
    elsif(m!^(.*?)\s*[|]\s*(?:/\s*|)"(.+)"$!) {
      ($alttext, $node) = ($1,$2);
      $type = 'head';
    }
    # page and "head"
    elsif(m!^($page_rx)\s*/\s*"(.+)"$!o) {
      ($page, $node) = ($1, $2);
      $type = 'head';
    }
    # page and item
    elsif(m!^($page_rx)\s*/\s*(.+)$!o) {
      ($page, $node) = ($1, $2);
      $type = 'item';
    }
    # only "head"
    elsif(m!^/?"(.+)"$!) {
      $node = $1;
      $type = 'head';
    }
    # only item
    elsif(m!^\s*/(.+)$!) {
      $node = $1;
      $type = 'item';
    }
    # non-standard: URL
    elsif(m!^($url_rx)$!io) {
      $node = $1;
      $type = 'url';
    }
    # alttext, page and item
    elsif(m!^(.*?)\s*[|]\s*($page_rx)\s*/\s*(.+)$!o) {
      ($alttext, $page, $node) = ($1, $2, $3);
      $type = 'item';
    }
    # alttext and item
    elsif(m!^(.*?)\s*[|]\s*/(.+)$!) {
      ($alttext, $node) = ($1,$2);
      $type = 'item';
    }
    # nonstandard: alttext and url
    elsif(m!^(.*?)\s*[|]\s*($url_rx)$!oi) {
      ($alttext, $node) = ($1,$2);
      $type = 'url';
    }
    # must be an item or a "malformed" head (without "")
    else {
      $self->_msg('WARNING', "link L<$_> type not clear, assuming 'item' at line $line");
      # alttext and something
      if( /([^|]*)\|(.*)/ ) {
	$alttext = $1;
        $node = $2;
      } else {
        $node = $_;
      }
      $type = 'item';
    }

    # empty alternative text expands to node name or page name
    if(defined $alttext) {
      if(!length($alttext)) {
        $alttext = $node || $page;
      }
      elsif($alttext =~ m:[|/]:) {
        $self->_msg('WARNING', "alternative text '$alttext' in L<> at line $line contains non-escaped | or /");
      }
    }

    if($page =~ s/[(](\d\w?)[)]$//) {
      $mansect = $1;
      if($page =~ /::/) {
        $self->_msg('ERROR', "(section) in L<$page($mansect)> at line $line deprecated");
        $mansect = '';
      } else {
        $type = "man";
      }
    }

    if(length $page && $page =~ /[(]\w*[)]$/) {
      $self->_msg('WARNING', "(section) in L<$page> at line $line deprecated");
    }
    if(length $node && $node =~ m:[|/]: && $type ne 'url') {
      $self->_msg('WARNING', "node '$node' in L<> at line $line contains non-escaped | or /");
    }
    my $link = Pod::link->new;
    $link->line($line);
    if(defined $alttext) {
      my @txt = $self->interpolate($alttext,$line);
      $link->alttext(@txt);
    }
    $link->page($page);
    if(length $node) {
      # collapse markup
      my $txt = join('', map { $_->as_text }
        $self->interpolate($node,$line));
      $self->_canonify($txt);
      $link->node($txt);
    }
    $link->type($type);
    $link->mansect($mansect) if(length $mansect);
    return $link;
  }

  # bold text
  elsif($cmd eq 'B') {
    $obj = Pod::bold->new;
  }

  # code text
  elsif($cmd eq 'C') {
    $obj = Pod::code->new;
  }

  # file text
  elsif($cmd eq 'F') {
    $obj = Pod::file->new;
  }

  # italic text
  elsif($cmd eq 'I') {
    $obj = Pod::italic->new;
  }

  # non-breakable space
  elsif($cmd eq 'S') {
    $obj = Pod::nonbreaking->new;
  }

  # custom index entries
  elsif($cmd eq 'X') {
    $obj = Pod::idx->new;
    my $str = join('', map { ref($_) ? $_->as_text : $_ }
      $seq->parse_tree->children);
    my $node = $self->_make_node($str,'X',$line);
    $obj->node($node) if($node);
  }

  # zero-size element
  elsif($cmd eq 'Z') {
    # check that it has no content
    if(scalar($seq->parse_tree->children)) {
      $self->_msg('ERROR', "Z<> must not have any contents at line $line");
    }
    $obj = Pod::zero->new;
    $obj->line($line);
    return $obj;
  }

  else {
    # ignore everything else
    $self->_msg('ERROR',"Invalid command '$cmd'");
    return '';
  }
  my @contents = @{$seq->parse_tree()};
  unless(@contents) {
    $self->_msg('WARNING',"Ignoring empty $cmd<>");
    return '';
  }
  $obj->line($line);
  # set strings to the right line number
  foreach(@contents) {
    unless(ref $_) {
      $_ = Pod::string->new($_);
      $_->line($line);
    } else {
      $line = $_->line();
    }
  }
  $obj->add_daughters(@contents);
  $obj;
}

##############################################################################
# strictly internal subroutines

# this sub passes errors of Pod::Parser on to the own message handler
sub _parser_err
{
  my ($self,$msg) = @_;
  my $severity = 'ERROR';
  if($msg =~ s/^[\s*]*(error|warning)[\s:]*//i) {
    $severity = uc($1);
  }
  $msg =~ s/in file\s+\S+\s*$//;
  $self->{$severity}++;
  $self->_msg($severity,$msg);
  1; # required by Pod::Parser
}

# this is used to canonify both the link anchors and references
sub _canonify
{
  # canonify text
  $_[1] =~ s/^\s+|\s+$//gs;
  $_[1] =~ s/\s+/ /gs;
}

##############################################################################

=head1 NOTES

=head2 Building POD converters

The B<Pod::Compiler> module is designed to serve as a basis for complex
POD converters, e.g. to HTML, FrameMaker or LaTeX that can handle
multiple POD documents with a table of contents, an index and most
imporant hyperlinks/crossreferences.

The following flow outlines how such a converter may work:

=over 4

=item * Getting the documents to be converted

Interpreting command line arguments and options, the converter should
gather all the POD files to be converted. Note that because of the
structure of POD hyperlinks and restrictions in the anchor format of the
individual destination formats you'll almost certainly will need a
two-pass apporach where you process all documents at once. See
L<Pod::Find> for some useful helpers in locating POD documents. The
documents are stored as B<Pod::doc> in a B<Pod::doc::collection>.

=item * Compiling all documents

The next step would be a loop over all documents, calling
B<Pod::Compiler> on each document. This checks the syntax, prints errors
and warnings and generates an object tree and information about the
document's hyperlink anchors. The latter (a B<Pod::node::collection>) is
stored in the B<Pod::doc>, the former is saved to a temporary file (see
also L<File::Temp>) with the help of B<Storable>.

=item * Converting the documents

The second loop over all documents does the actual conversion. If you do
not care very much about OO principles, you may extend the B<Pod::*>
packages by e.g. a C<as_html> method, so that you can say
C<(Pod::root)-E<gt>as_html>. Or you use the C<walk_down> method of
B<Tree::DAG_Node> to traverse the object tree and convert the individual
objects in the callback.

The existing B<Pod::doc::collection> is used to resolve the hyperlinks.
Each node already has a node id assigned.

The result is saved to the destination files and the temporary files can
be removed.

=item * Table of contents and index

During or after the final conversion one can build a TOC and an index,
derived from the C<=headX> and C<=item>/C<XE<lt>E<gt>> respectively.
Strategies for the index could be: Only the C<XE<lt>E<gt>> entries,
single worded C<=head2>/C<=item>, all hyperlink anchors that were hit
during conversion, all C<=item>s, ...

=back

=head1 SEE ALSO

L<Pod::Checker>, L<Pod::Parser>, L<Pod::Find>,
L<pod2man>, L<pod2text>, L<Pod::Man>

=head1 AUTHOR

Marek Rouchal <marekr@cpan.org>

=head1 HISTORY

A big deal of this code has been recycled from a variety of existing
Pod converters, e.g. by Tom Christiansen and Russ Allbery. A lot of
ideas came from Nick Ing-Simmons' B<PodToHtml>.

=cut

1;
