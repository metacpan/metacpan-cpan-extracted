
package RDF::Simple::Parser::Handler;

use strict;
use warnings;

use Carp;
use Data::Dumper;  # for debugging only
use RDF::Simple::NS;
use RDF::Simple::Parser::Attribs;
use RDF::Simple::Parser::Element;

use constant DEBUG => 0;

use Class::MethodMaker [
                        scalar => [ qw/ stack base genID disallowed qnames result bnode_absolute_prefix / ],
                       ];

my
$VERSION = 1.17;

sub new
  {
  DEBUG && print STDERR " FFF Handler::new(@_)\n";
  my ($class, $sink, %p) = @_;
  my $self = bless {}, ref $class || $class;
  $self->base($p{'base'});
  $self->qnames($p{qnames});
  $self->genID(1);
  $self->stack([]);
  my @dis;
  foreach my $s (qw( RDF ID about bagID parseType resource nodeID datatype li aboutEach aboutEachPrefix ))
    {
    push @dis, $self->ns->uri('rdf').$s;
    } # foreach
  $self->disallowed(\@dis);
  return $self;
  } # new

=head1 METHODS

=over

=cut

sub addns
  {
  my ($self, $prefix, $uri) = @_;
  DEBUG && print STDERR " DDD Handler::addns($prefix => $uri)\n";
  $self->ns->lookup($prefix,$uri);
  } # addns

sub ns
  {
  my $self = shift;
  return $self->{_ns} if $self->{_ns};
  $self->{_ns} = RDF::Simple::NS->new;
  } # ns


sub _triple
  {
  my $self = shift;
  my ($s, $p, $o) = @_;
  if (DEBUG)
    {
    print STDERR " FFF $self ->_triple($s,$p,$o)\n";
    # print STDERR Dumper(\@_);
    my ($package, $file, $line, $sub) = caller(1);
    print STDERR " DDD   called from $sub line $line\n";
    } # if
  my $r = $self->result;
  push @$r, [$s,$p,$o];
  $self->result($r);
  } # _triple

sub start_element
  {
  my ($self, $sax) = @_;
  DEBUG && print STDERR " FFF start_element($sax->{LocalName})\n";
  DEBUG && print STDERR Dumper($sax->{Attributes});
  if ($sax->{LocalName} eq 'RDF')
    {
    # This is the toplevel element of the RDF document.  See if there
    # is an xml:base URL specified:
    foreach my $rh (values %{$sax->{Attributes}})
      {
      if (($rh->{Prefix} eq 'xml') && ($rh->{LocalName} eq 'base'))
        {
        # Found the xml:base!
        $self->addns(q{_perl_module_rdf_simple_base_} => $rh->{Value});
        } # if
      } # foreach
    } # if
  my $e;
  my $stack = $self->stack;
  my $parent;
  if (scalar(@$stack) > 0)
    {
    $parent = $stack->[-1];
    }
  my $attrs = RDF::Simple::Parser::Attribs->new($sax->{Attributes},
                                                $self->qnames);
  # Add namespace to our lookup table:
  $self->addns($sax->{Prefix} => $sax->{NamespaceURI});
  $e = RDF::Simple::Parser::Element->new(
                                         $sax->{NamespaceURI},
                                         $sax->{Prefix},
                                         $sax->{LocalName},
                                         $parent,
                                         $attrs,
                                         qnames => $self->qnames,
                                         base => $self->base,
                                        );
  push @{$e->xtext}, $e->qname.$e->attrs;
  push @{$stack}, $e;
  $self->stack($stack);
  } # start_element

sub characters
  {
  my ($self, $chars) = @_;
  my $stack = $self->{stack} || [];
  $stack->[-1]->{text} .= $chars->{Data};
  $stack->[-1]->{xtext}->[-1] .= $chars->{Data};
  $self->stack($stack);
  } # characters

sub end_element
  {
  my ($self, $sax) = @_;
  my $name = $sax->{LocalName};
  my $qname = $sax->{Name};
  DEBUG && print STDERR " FFF end_element($name,$qname)\n";
  my $stack = $self->stack;
  my $element = pop @{$stack};
  # DEBUG && print STDERR " DDD   element is ", Dumper($element);
  $element->{xtext}->[2] .= '</'.$element->{qname}.'>';
  if (scalar(@$stack) > 0)
    {
    my $kids = $stack->[-1]->children || [];
    push @$kids, $element;
    $stack->[-1]->children($kids);
    @{ $element->{xtext} } = grep { defined($_) } @{ $element->{xtext} };
    $stack->[-1]->{xtext}->[1] = join('', @{$element->{xtext}});
    $self->stack($stack);
    }
  else
    {
    $self->document($element);
    }
  } # end_element

=item uri

Takes a URI (possibly relative to the current RDF document)
and returns an absolute URI.

=cut

sub uri
  {
  my ($self, $uri) = @_;
  my $sBase = $self->ns->uri('_perl_module_rdf_simple_base_') || q{};
  if ($uri =~ m/\A:/)
    {
    # URI has empty base.
    $uri = qq{$sBase$uri};
    } # if
  elsif (($uri =~ m/\A#/) && defined $sBase)
    {
    # URI has empty base.
    $uri = qq{$sBase$uri};
    } # if
  return $uri;
  } # uri

sub bNode
  {
  my ($self, $id, %p) = @_;
  my $n_id = sprintf("_:id%08x%04x", time, int rand 0xFFFF);
  $n_id = $self->bnode_absolute_prefix.$n_id if $self->bnode_absolute_prefix;
  return $n_id;
  } # bNode

sub literal
  {
  my ($self, $string, $attrs) = @_;
  DEBUG && print STDERR " FFF literal()\n";
  if ($attrs->{lang} and $attrs->{dtype})
    {
    die "can't have both lang and dtype";
    } # if
  return $string;
  #r_quot = re.compile(r'([^\\])"')
  #      return ''.join(('"%s"' %
  # r_quot.sub('\g<1>\\"',
  #`unicode(s)`[2:-1]),
  #          lang and ("@" + lang) or '',
  # dtype and ("^^<%s>" % dtype) or ''))
  } # literal

sub document
  {
  my ($self, $doc) = @_;
  warn("couldn't find rdf:RDF element") unless $doc->URI eq $self->ns->uri('rdf').'RDF';
  my @children = @{$doc->children} if $doc->children;
  unless (scalar(@children) > 0)
    {
    warn("no rdf triples found in document!");
    return;
    }
  foreach my $e (@children)
    {
    # DEBUG && print STDERR Dumper($e);
    $self->nodeElement($e);
    } # foreach
  } # document


sub nodeElement
  {
  my ($self, $e) = @_;
  my $dissed =  $self->disallowed;
  my $dis = grep {$_ eq $e->URI} @$dissed;
  warn("disallowed element used as node") if $dis;
  my $rdf = $self->ns->uri('rdf');
  my $base = $e->base || $self->base || q{};
  if ($e->attrs->{$rdf.'ID'})
    {
    $e->subject( $self->uri($base .'#'. $e->attrs->{$rdf.'ID'}));
    }
  elsif ($e->attrs->{$rdf.'about'})
    {
    $e->subject( $self->uri( $e->attrs->{$rdf.'about'} ));
    }
  elsif ($e->attrs->{$rdf.'nodeID'})
    {
    $e->subject( $self->bNode($e->attrs->{$rdf.'nodeID'}) );
    }
  elsif (not $e->subject)
    {
    $e->subject($self->bNode);
    }
  if ($e->URI ne $rdf.'Description')
    {
    $self->_triple($e->subject, $rdf.'type', $self->uri($e->URI));
    }
  if ($e->attrs->{$rdf.'type'})
    {
    $self->_triple($e->subject, $rdf.'type', $self->ns->uri($e->{$rdf.'type'}));
    }
  foreach my $k (keys %{$e->attrs})
    {
    my $dis = $self->disallowed;
    push @$dis, $rdf.'type';
    my ($in) = grep {/$k/} @$dis;
    if (not $in)
      {
      my $objt = $self->literal($e->attrs->{$k}, $e->language);
      DEBUG && print STDERR " DDD nodeElement _triple(,,$objt)\n";
      $self->_triple($e->subject, $self->uri($k), $objt);
      } # if
    } # foreach
  my $children = $e->children;
  foreach my $child (@$children)
    {
    $self->propertyElt($child);
    } # foreach
  } # nodeElement


sub propertyElt
  {
  my $self = shift;
  my $e = shift;
  DEBUG && print STDERR " FFF propertyElt($e)\n";
  # DEBUG && print STDERR Dumper($e);
  my $rdf = $self->ns->uri('rdf');
  if ($e->URI eq $rdf.'li')
    {
    $e->parent->{liCounter} ||= 1;
    $e->URI($rdf.$e->parent->{liCounter});
    $e->parent->{liCounter}++;
    }
  my $children = $e->children || [];
  if ($e->attrs->{$rdf.'resource'})
    {
    # This is an Object Property Declaration Axiom.
    $self->_triple($e->parent->subject, $self->uri($e->URI), $e->attrs->{$rdf.'resource'});
    return;
    }
  if (
      (scalar(@$children) == 1)
      &&
      (! $e->attrs->{$rdf.'parseType'})
     )
    {
    $self->resourcePropertyElt($e);
    return;
    }
  if ((scalar(@$children) eq 0) && (defined $e->text) && ($e->text ne q{}))
    {
    $self->literalPropertyElt($e);
    return;
    }
  my $ptype = $e->attrs->{$rdf.'parseType'};
  if ($ptype)
    {
    if ($ptype eq 'Resource')
      {
      $self->parseTypeResourcePropertyElt($e);
      return;
      }
    if ($ptype eq 'Collection')
      {
      $self->parseTypeCollectionPropertyElt($e);
      return;
      }
    $self->parseTypeLiteralOrOtherPropertyElt($e);
    return;
    } # if has a parseType
  if ((! defined $e->text) || ($e->text eq q{}))
    {
    # DEBUG && print STDERR Dumper($e);
    $self->emptyPropertyElt($e);
    return;
    } # if
  delete $e->{parent};
  warn " WWW failed to parse element: ", Dumper($e);
  } # propertyElt

sub resourcePropertyElt
  {
  my ($self, $e) = @_;
  DEBUG && print STDERR " FFF resourcePropertyElt($e)\n";
  # DEBUG && print STDERR Dumper($e);
  my $rdf = $self->ns->uri('rdf');
  my $n = $e->children->[0];
  $self->nodeElement($n);
  if ($e->parent)
    {
    $self->_triple($e->parent->subject, $self->uri($e->URI), $n->subject);
    }
  if ($e->attrs->{$rdf.'ID'})
    {
    my $base = $e->base || $self->base;
    my $i = $self->uri($base .'#'. $e->attrs->{$rdf.'ID'});
    $self->reify($i, $e->parent->subject, $self->uri($e->URI), $n->subject);
    } # if
  } # resourcePropertyElt


sub reify
  {
  my ($self,$r,$s,$p,$o) = @_;
  my $rdf = $self->ns->uri('rdf');
a  $self->_triple($r, $self->uri($rdf.'subject'), $s);
  $self->_triple($r, $self->uri($rdf.'predicate'), $p);
  $self->_triple($r, $self->uri($rdf.'object'), $o);
  $self->_triple($r, $self->uri($rdf.'type'), $self->uri($rdf.'Statement'));
  } # reify


sub literalPropertyElt
  {
  my ($self, $e) = @_;
  DEBUG && print STDERR " FFF literalPropertyElt($e)\n";
  my $base = $e->base || $self->base;
  my $rdf = $self->ns->uri('rdf');
  my $o = $self->literal($e->text, $e->language, $e->attrs->{$rdf.'datatype'});
  DEBUG && print STDERR " DDD literalPropertyElt _triple(,,$o)\n";
  $self->_triple($e->parent->subject, $self->uri($e->URI), $o);
  if ($e->attrs->{$rdf.'ID'})
    {
    my $i = $self->uri($base .'#'. $e->attrs->{$rdf.'ID'});
    $self->reify($i, $e->parent->subject, $self->uri($e->URI), $o);
    } # if
  } # literalPropertyElt

sub parseTypeLiteralOrOtherPropertyElt {
    my ($self,$e) = @_;
    DEBUG && print STDERR " FFF parseTypeLiteralOrOtherPropertyElt($e)\n";
    my $base = $e->base || $self->base;
    my $rdf = $self->ns->uri('rdf');
    my $o = $self->literal($e->xtext->[1],$e->language,$rdf.'XMLLiteral');
    DEBUG && print STDERR " DDD parseTypeLiteralOrOtherPropertyElt _triple(,,$o)\n";
    $self->_triple($e->parent->subject,$self->uri($e->URI),$o);
    if ($e->attrs->{$rdf.'ID'}) {
        my $i = $self->uri($base .'#'. $e->attrs->{$rdf.'ID'});
        $e->subject($i);
        $self->reify($i,$e->parent->subject,$self->URI($e->URI),$o);
    }
}

sub parseTypeResourcePropertyElt
  {
  my ($self,$e) = @_;
  DEBUG && print STDERR " FFF parseTypeResourcePropertyElt($e)\n";
  my $n = $self->bNode;
  DEBUG && print STDERR " DDD parseTypeResourcePropertyElt _triple(,,$n)\n";
  $self->_triple($e->parent->subject, $self->uri($e->URI), $n);
  my $c = RDF::Simple::Parser::Element->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                                            'rdf',
                                            'Description',
                                            $e->parent,
                                            $e->attrs,
                                            qnames => $self->qnames,
                                            base => $e->base,
                                           );
  $c->subject($n);
  my @c_children;
  my $children = $e->children;
  foreach (@$children)
    {
    $_->parent($c);
    push @c_children, $_;
    }
  $c->children(\@c_children);
  $self->nodeElement($c);
  } # parseTypeResourcePropertyElt

sub parseTypeCollectionPropertyElt
  {
  my ($self,$e) = @_;
  DEBUG && print STDERR " FFF parseTypeCollectionPropertyElt($e)\n";
  my $rdf = $self->ns->uri('rdf');
  my $children = $e->children;
  my @s;
  foreach (@$children)
    {
    $self->nodeElement($_);
    push @s, $self->bNode;
    }
  if (scalar(@s) eq 0)
    {
    $self->_triple($e->parent->subject,$self->uri($e->URI),$self->uri($rdf.'nil'));
    }
  else
    {
    $self->_triple($e->parent->subject,$self->uri($e->URI),$s[0]);
    foreach my $n (@s)
      {
      $self->_triple($n,$self->uri($rdf.'type'),$self->uri($rdf.'List'));
      }
    for (0 .. $#s)
      {
      $self->_triple($s[$_],$self->uri($rdf.'first'),$e->children->[$_]->subject);
      }
    for (0 .. ($#s-1))
      {
      $self->_triple($s[$_],$self->uri($rdf.'rest'),$s[$_+1]);
      }
    $self->_triple($s[-1],$self->uri($rdf.'rest'),$self->uri($rdf.'nil'));
    }
  } # parseTypeCollectionPropertyElt


sub emptyPropertyElt
  {
  my $self = shift;
  my $e = shift;
  DEBUG && print STDERR " FFF emptyPropertyElt($e)\n";
  # DEBUG && print STDERR Dumper($e);
  my $rdf = $self->ns->uri('rdf');
  my $base = $e->base or $self->base;
  $base ||= '';
  my @keys = keys %{$e->attrs};
  my $ids = $rdf.'ID';
  my ($id) = grep {/$ids/} @keys;
  my $r;
  if ($id)
    {
    $r = $self->literal($e->text, $e->language); # was o
    DEBUG && print STDERR " DDD emptyPropertyElt _triple(,,$r)\n";
    $self->_triple($e->parent->subject, $self->uri($e->URI), $r);
    }
  else
    {
    if ($e->attrs->{$rdf.'resource'})
      {
      my $res = $e->attrs->{$rdf.'resource'};
      $res ||= '';
      $res = $base.$res if $res !~ m/\:\/\//;
      $r = $self->uri($res);
      }
    elsif ($e->attrs->{$rdf.'nodeID'})
      {
      $r = $self->bNode($e->attrs->{$rdf.'nodeID'});
      }
    else
      {
      DEBUG && print STDERR " DDD   element has no 'resource' attr and no 'nodeID' attr.\n";
      # Generate a new node ID, in case this empty element has attributes:
      $r = $self->bNode;
      }
    my $dis = $self->disallowed;
    my @a = map { grep {!/$_/} @$dis } keys %{$e->attrs};
    if (scalar(@a) < 1)
      {
      # This empty element has no attributes, nothing to declare.
      # Just add empty string to the triple:
      $r = q{};
      } # if
    foreach my $a (@a)
      {
      if ($a ne $rdf.'type')
        {
        my $o = $self->literal($e->attrs->{$a}, $e->language);
        DEBUG && print STDERR " DDD emptyPropertyElt _triple(,,$o)\n";
        $self->_triple($r, $self->uri($a), $o);
        } # if
      else
        {
        $self->_triple($r, $self->uri($rdf.'type'), $self->uri($e->attrs->{$a}));
        }
      } # foreach
    $self->_triple($e->parent->subject, $self->uri($e->URI), $r);
    } # else ! $id
  if ($e->attrs->{$rdf.'ID'})
    {
    my $i = $self->uri($base .'#'. $e->attrs->{$rdf.'ID'});
    $self->reify($i, $e->parent->subject, $self->uri($e->URI,$r));
    }
  } # emptyPropertyElt


=back

=head1 NOTES

This parser is a transliteration of
Sean B Palmer's python RDF/XML parser:

http://www.infomesh.net/2003/rdfparser/

Thus the idioms inside are a bit pythonic.
Most credit for the effort is due to sbp.

=cut

1;

__END__
