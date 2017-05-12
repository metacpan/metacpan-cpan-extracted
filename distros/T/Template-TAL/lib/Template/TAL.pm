=head1 NAME

Template::TAL - Process TAL templates with Perl

=head1 SYNOPSIS

  # create the TT object, telling it where the templates are
  my $tt = Template::TAL->new( include_path => "./templates" );

  # data to interpolate into the template
  my $data = {
    foo => "bar",
  };

  # process the template from disk (in ./templates/test.tal) with the data
  print $tt->process("test.tal", $data);

=head1 DESCRIPTION

L<TAL|http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL> is a templating
language used in the Zope CMS. Template::TAL is a Perl implementation of
TAL based on the published specs on the Zope wiki.

TAL templates are XML documents, and use attributes in the TAL namespace to
define how elements of the template should be treated/displayed.  For example:

  my $template = <<'ENDOFXML';
  <html xmlns:tal="http://xml.zope.org/namespaces/tal">
    <head>
      <title tal:content="title"/>
    </head>
    <body>
      <h1>This is the <span tal:replace="title"/> page</h1>
      <ul>
        <li tal:repeat="user users">
          <a href="?" tal:attributes="href user/url"><span tal:replace="user/name"/></a>
        </li>
      </ul>
    </body>
  </html>  
  ENDOFXML

This template can be processed by passing it and the parameters to the
C<process> method:

  my $tt = Template::TAL->new();
  $tt->process(\$template, {
    title => "Bert and Ernie Fansite",
    users => [
      { url => "http://www.henson.com/",         name  => "Henson",       },
      { url => "http://www.sesameworkshop.org/", name  => "Workshop",     },
      { url => "http://www.bertisevil.tv/",      name  => "Bert is Evil", },
    ],
  })

Alternativly you can store the templates on disk, and pass the filename to
C<process> directly instead of via a reference (as shown in the synopsis above.)

Template::TAL is designed to be extensible, allowing you to load templates from
different places and produce more than one type of output.  By default the XML
template will be output as cross-browser compatible HTML (meaning, for example,
that image tags won't be closed.)  Other output formats, including well-formed
XML, can easily be produced by changing the output class (detailed below.)

For more infomation on the TAL spec itself, see 
http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL%20Specification%201.4

=cut

package Template::TAL;
use warnings;
use strict;
use Carp qw( croak );
use UNIVERSAL::require;
use Scalar::Util qw( blessed );

our $VERSION = "0.91";

use Template::TAL::Template;
use Template::TAL::Provider;
use Template::TAL::Provider::Disk;
use Template::TAL::Output::XML;
use Template::TAL::Output::HTML;
use Template::TAL::ValueParser;

=head1 METHODS

=over

=item new( include_path => ['/foo/bar'], charset => 'utf-8' )

Creates and initializes a new Template::TAL object. Options valid here are:

=over

=item include_path

If this parameter is set then it is passed to the provider, telling it where
to load files from disk (if applicable for the provider.)

=item charset

If this parameter is set then it is passed to the output, telling it what
charset to use instead of its default.  The default output class will use the
'utf-8' charset unless you tell it otherwise.

=item provider

Pass a 'provider' option to specify a provider rather than using the default
provider that reads from disk.  This can either be a class name of a loaded
class, or an object instance.

=item output

Pass a 'output' option to specify a output class rather than using the default
output class that dumps the DOM tree to as a string to create HTML.  This can
either be a class name of a loaded class, or an object instance.

=back

=cut

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;

  # if we've got a provider, set it
  if (exists $args{provider}) {
    $self->provider( delete $args{provider} );
  }

  # if we've got an include path, pass it to the provider
  if (exists $args{include_path}) {
    $self->provider->include_path(delete $args{include_path});
  }

  # if we've got an output set it
  if (exists $args{output}) {
    $self->output( delete $args{output} );
  }

  # if we've got a charset, pass it to the output
  if (exists $args{charset}) {
    $self->output->charset( delete $args{charset} );
  }

  $self->add_language("Template::TAL::Language::TALES");
  $self->add_language("Template::TAL::Language::TAL");
  $self->add_language("Template::TAL::Language::METAL");

  return $self;
}

sub provider {
  my $self = shift;
  return $self->{provider} ||= Template::TAL::Provider::Disk->new() unless @_;
  $self->{provider} = blessed($_[0]) ? $_[0] : $_[0]->new();
  return $self;
}

sub output {
  my $self = shift;
  return $self->{output} ||= Template::TAL::Output::HTML->new() unless @_;
  $self->{output} = blessed($_[0]) ? $_[0] : $_[0]->new();
  return $self;
}

=item languages

a listref of language plugins we will use when parsing. All
templates get at least the L<Template::TAL::Language:TAL> language module.

=cut

sub languages {
  my $self = shift;
  return $self->{languages} ||= [] unless @_;
  $self->{languages} = ref($_[0]) ? shift : [ @_ ];
  return $self;
}

=item add_language( language module, module, module... )

adds a language to the list of those used by the template renderer. 'module'
here can be a classname or an instance.

=cut

sub add_language {
  my $self = shift;
  for (@_) {
    my $language = $_; # take a modifiable copy.
    unless (ref($language)) {
      $language->require or die "Can't load language '$language': $@";
      $language = $language->new;
    }
    push @{ $self->{languages} }, $language;
  }
  return $self;
}

=item process( $template, $data_hashref )

Process the template with the passed data and return the resulting rendered
byte sequence.

C<$template> can either be a string containing where the provider should get
the template from (i.e. the filename of the template in the include path), a
reference to a string containing the literal text of the template, or a
Template::TAL::Template object.

C<$data_hashref> should be a reference to a hash containing the values that
are to be substituted into the template.

=cut

sub process {
  my ($self, $template, $data) = @_;

  if (!ref $template) {
    $template = $self->provider->get_template( $template )
  } elsif (ref($template) eq 'SCALAR') {
    # scalar reference - a reference to source of a template
    $template = Template::TAL::Template->new->source($$template);
  } elsif (!UNIVERSAL::isa($template, 'Template::TAL::Template')) {
    croak("Can't understand object of type ".ref($template)." as a template");
  }

  # walk the template, converting the DOM tree as we go. Local context
  # starts as empty, global context is the template data.
  my $dom = $template->document->cloneNode(1); # deep clone
  $self->_process_node( $dom->documentElement, {}, $data );

  return $self->output->render( $dom );
}

# this processes a given DOM node with the passed contexts, using the
# language plugins, and manipulates the DOM node
# according to the instructions of the plugins. Returns nothing
# interesting - it is expected to change the DOM tree in place.
#
# this method is private because it shouldn't be exposed to the user,
# but the TAL language module calls it, so it's not 'properly' private.
sub _process_node {
  my ($self, $node, $local_context, $global_context) = @_;

  # we only care about handling elements - text nodes, etc, don't have
  # attributes and therefore can't be munged.
  return unless $node->nodeType == 1;

  # a mapping of namespaces->plugin class for fast lookup later.
  my %namespaces = map { $_->namespace => $_ } grep { $_->namespace } @{ $self->languages };
  
  # we have to make a distinction between local and global context,
  # because the define tag can set into the global context. Curses.
  $global_context ||= {};
  $local_context ||= {};

  # make a shallow copy. Shallow is enough, because we can't set deep paths.
  $local_context = { %$local_context };

  # record attributes of the node we're processing, but leave them
  # in place, so recursive processing gets a chance to look at them
  # again later
  my %attrs; # will be $attrs{ language module namespace uri }{ tag name }
  for my $attribute ($node->attributes) {
    my $uri = $attribute->getNamespaceURI;
    next unless $uri and $attribute->nodeType == 2; # attributes with namespaces only
    if ( $namespaces{ $uri } ) {
      # we have a handler for this namespace
      $attrs{ $uri }{ $attribute->name } = $attribute->value;
    }
  }

  # If at any point something replaces the whole node, we can stop thinking,
  # and return, as the new node is supposed to have already been processed.
  # Record this state here.
  my $replaced = 0; 

  # for all our language classes (in order)
  LANGUAGE: for my $language ( @{ $self->languages } ) {
    # only process if the language is referenced.
    next unless $language->namespace and exists $attrs{ $language->namespace };

    # the languages have an ordered list of tag types they want to deal with.
    OPS: for my $type ($language->tags) {
      next unless exists $attrs{ $language->namespace }{ $type };

      # remove this attribute from the node first, recursive processing
      # wants to see all _other_ attributes, but not the one that caused
      # the recursion in the first place.
      $node->removeAttributeNS( $language->namespace, $type );
      
      # handle this attribute
      my $sub = "process_tag_$type"; $sub =~ s/\-/_/;
      Carp::croak("language module $language can't handle nodes of type '$type', as claimed")
        unless $language->can($sub);
      my @replace = $language->$sub($self, $node, $attrs{ $language->namespace }{ $type }, $local_context, $global_context);
  
      # remove from the todo list, so we can track unhandled attributes later.
      delete $attrs{ $language->namespace }{ $type };
  
      # if we're replacing the node with something else as a result of the
      # attribute, do so. Once we've done that, we're finished, so leave.
      if (!@replace) {
        # remove the node
        $node->parentNode->removeChild( $node );
        $replaced = 1;
  
      } elsif (@replace and $replace[0] != $node) {
        # replacing with something else. There's no nice 'replace this
        # single node with this list of nodes' operator, so we need this
        # fairly nasty cludge.
        my $this = shift @replace;
        $node->replaceNode($this);
        for (@replace) {
          $this->parentNode->insertAfter($_, $this);
          $this = $_;
        }
        $replaced = 1;
      }
  
      if ($replaced) {
        delete $attrs{ $language->namespace }; # because the handler will have dealt with them
        last LANGUAGE; # there's no point.
      }

    } # ops loop

    # complain about any other attributes on the node
    warn sprintf("unhandled TAL attributes '%s' in namespace '%s' on element '%s' at line %d\n",
                 join(',', keys %{ $attrs{ $language->namespace } }),
                 $language->namespace, $node->nodeName, $node->line_number)
      if %{ $attrs{ $language->namespace } };

  } # languages loop
  

  # now recurse into child nodes, unless we replaced the current node, in
  # which case we assume that it's been dealt with.
  unless ($replaced) {
    for my $child ( $node->childNodes() ) {
      $self->_process_node( $child, $local_context, $global_context );
    }
  }
}

=item parse_tales( value, context, context,... )

Parses a TALES string (see http://www.zope.org/Wikis/DevSite/Projects/ZPT/TALES),
looking in each of the passed contexts in order for variable values, and returns
the value.

=cut

sub parse_tales {
  my ($self, $value, @contexts) = @_;
  return Template::TAL::ValueParser->value($value, \@contexts, $self->languages);
}

=back

=head1 ATTRIBUTES

These are get/set chained accessor methods that can be used to alter the object
after initilisation (meaning they return their value when called without
arguments, and set the value and return $self when called with.)

In both cases you can set these to either class names or actual instances
and they with do the right thing.

=over

=item provider

The instance of the L<Template::TAL::Provider> subclass that will be providing
templates to this engine.

=item output

The instance of the L<Template::TAL::Output> subclass that will be used to
render the produced template output.

=back

=head1 RATIONALE

L<Petal> is another Perl module that can process a templating language
suspiciously similar to TAL.  So why did we implement Yet Another
Templating Engine?  Well, we liked Petal a lot. However, at the time of
writing our concerns with Petal were:

=over

=item

Petal isn't strictly TAL. We consider this a flaw.

=item

Petal assumes rather strongly that templates are stored on disk.  We wanted
a system with a pluggable template source so that we could store templates
in other places (such as a database.)

=item

Petal does lots of caching.  This is a good thing if you've got a small
number of templates compared to the number of pages you serve. However, if 
you've got a vast number of templates - more than you can hold in memory -
then this quickly becomes self defeating.  We wanted code that doesn't have 
any caching in it at all.

=back

In conclusion:  You may be better off using Petal.  Certainly the caching
layer could be very useful to you.

There's more than one way to do it.

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 BUGS

Template::TAL creates superfluous XML namespace attributes in the
output.

Please report any bugs you find via the CPAN RT system.
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template::TAL

=head1 SEE ALSO

The TAL specification: http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL%20Specification%201.4

L<Petal>, another Perl implementation of TAL on CPAN.

=cut

1;
