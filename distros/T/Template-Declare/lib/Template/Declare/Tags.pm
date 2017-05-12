use 5.006;
use warnings;
use strict;
#use Smart::Comments;
#use Smart::Comments '####';

package Template::Declare::Tags;

our $VERSION = '0.43';

use Template::Declare;
use base 'Exporter';
use Carp qw(carp croak);
use Symbol 'qualify_to_ref';

our $self;

our @EXPORT = qw(
    template private current_template current_base_path
    show show_page
    attr with get_current_attr 
    outs outs_raw
    xml_decl
    under setting
    smart_tag_wrapper create_wrapper
    $self
);

our @TAG_SUB_LIST;
our @TagSubs;
*TagSubs = \@TAG_SUB_LIST;  # For backward compatibility only

our %ATTRIBUTES       = ();
our %ELEMENT_ID_CACHE = ();
our $TAG_NEST_DEPTH   = 0;
our $TAG_INDENTATION  = 1;
our $EOL              = "\n";
our @TEMPLATE_STACK   = ();

our $SKIP_XML_ESCAPING = 0;

sub import {
    my $self = shift;
    my @set_modules;
    if (!@_) {
        push @_, 'HTML';
    }
    ### @_
    ### caller: caller()

    # XXX We can't reset @TAG_SUB_LIST here since
    # use statements always run at BEGIN time.
    # A better approach may be install such lists
    # directly into the caller's namespace...
    #undef @TAG_SUB_LIST;

    while (@_) {
        my $lang = shift;
        my $opts;
        if (ref $_[0] and ref $_[0] eq 'HASH') {
            $opts = shift;
            $opts->{package} ||= $opts->{namespace};
            # XXX TODO: carp if the derived package already exists?
        }
        $opts->{package} ||= scalar(caller);
        my $module = $opts->{from} ||
            "Template::Declare::TagSet::$lang";

        ### Loading tag set: $module
        if (! $module->can('get_tag_list') ) {
            eval "use $module";
            if ($@) {
                warn $@;
                croak "Failed to load tagset module $module";
            }
        }
        ### TagSet options: $opts
        my $tagset = $module->new($opts);
        my $tag_list = $tagset->get_tag_list;
        Template::Declare::Tags::install_tag($_, $tagset)
            for @$tag_list;
    }
    __PACKAGE__->export_to_level(1, $self);
}

sub _install {
    my ($override, $package, $subname, $coderef) = @_;

    my $name = $package . '::' . $subname;
    my $slot = qualify_to_ref($name);
    return if !$override and *$slot{CODE};

    no warnings 'redefine';
    *$slot = $coderef;
}

=head1 NAME

Template::Declare::Tags - Build and install XML Tag subroutines for Template::Declare

=head1 SYNOPSIS

    package MyApp::Templates;

    use base 'Template::Declare';
    use Template::Declare::Tags 'HTML';

    template main => sub {
        link {}
        table {
            row {
                cell { "Hello, world!" }
            }
        }
        img { attr { src => 'cat.gif' } }
        img { src is 'dog.gif' }
    };

Produces:

 <link />
 <table>
  <tr>
   <td>Hello, world!</td>
  </tr>
 </table>
 <img src="cat.gif" />
 <img src="dog.gif" />

Using XUL templates with a namespace:

    package MyApp::Templates;

    use base 'Template::Declare';
    use Template::Declare::Tags
        'XUL', HTML => { namespace => 'html' };

    template main => sub {
        groupbox {
            caption { attr { label => 'Colors' } }
            html::div { html::p { 'howdy!' } }
            html::br {}
        }
    };

Produces:

 <groupbox>
  <caption label="Colors" />
  <html:div>
   <html:p>howdy!</html:p>
  </html:div>
  <html:br></html:br>
 </groupbox>

=head1 DESCRIPTION

C<Template::Declare::Tags> is used to generate templates and install
subroutines for tag sets into the calling namespace.

You can specify the tag sets to install by providing a list of tag modules in
the C<use> statement:

    use Template::Declare::Tags qw/ HTML XUL /;

By default, Template::Declare::Tags uses the tag set provided by
L<Template::Declare::TagSet::HTML>. So

    use Template::Declare::Tags;

is equivalent to

    use Template::Declare::Tags 'HTML';

Currently L<Template::Declare> bundles the following tag sets:
L<Template::Declare::TagSet::HTML>, L<Template::Declare::TagSet::XUL>,
L<Template::Declare::TagSet::RDF>, and L<Template::Declare::TagSet::RDF::EM>.

You can specify your own tag set classes, as long as they subclass
L<Template::Declare::TagSet> and implement the corresponding methods (e.g.
C<get_tag_list>).

If you implement a custom tag set module named
C<Template::Declare::TagSet::Foo>, you can load it into a template module like
so:

    use Template::Declare::Tags 'Foo';

If your tag set module is not under the
L<Template::Declare::TagSet|Template::Declare::TagSet> namespace, use the
C<from> option to load it. Fore example, if you created a tag set named
C<MyTag::Foo>, then you could load it like so:

    use Template::Declare::Tags Foo => { from => 'MyTag::Foo' };

XML namespaces are emulated by Perl packages. For example, to embed HTML tags
within XUL using the C<html> namespace:

    package MyApp::Templates;

    use base 'Template::Declare';
    use Template::Declare::Tags 'XUL', HTML => { namespace => 'html' };

    template main => sub {
        groupbox {
            caption { attr { label => 'Colors' } }
            html::div { html::p { 'howdy!' } }
            html::br {}
        }
    };

This will output:

 <groupbox>
  <caption label="Colors" />
  <html:div>
   <html:p>howdy!</html:p>
  </html:div>
  <html:br></html:br>
 </groupbox>

Behind the scenes, C<Template::Declare::Tags> generates a Perl package named
C<html> and installs the HTML tag subroutines into that package. On the other
hand, XUL tag subroutines are installed into the current package, namely,
C<MyApp::Templates> in the previous example.

There may be cases when you want to specify a different Perl package for a
particular XML namespace. For instance, if the C<html> Perl package has
already been used for other purposes in your application and you don't want to
install subs there and mess things up, use the C<package> option to install
them elsewhere:

    package MyApp::Templates;
    use base 'Template::Declare';
    use Template::Declare::Tags 'XUL', HTML => {
        namespace => 'htm',
        package   => 'MyHtml'
    };

    template main => sub {
        groupbox {
            caption { attr { label => 'Colors' } }
            MyHtml::div { MyHtml::p { 'howdy!' } }
            MyHtml::br {}
        }
    };

This code will generate something like the following:

 <groupbox>
  <caption label="Colors" />
  <htm:div>
   <htm:p>howdy!</htm:p>
  </htm:div>
  <htm:br></htm:br>
 </groupbox>

=head1 METHODS AND SUBROUTINES

=head2 Declaring templates

=head3 template TEMPLATENAME => sub { 'Implementation' };

    template select_list => sub {
        my $self = shift;
        select {
            option { $_ } for @_;
        }
    };

Declares a template in the current package. The first argument to the template
subroutine will always be a C<Template::Declare> object. Subsequent arguments
will be all those passed to C<show()>. For example, to use the above example
to output a select list of colors, you'd call it like so:

    Template::Declare->show('select_list', qw(red yellow green purple));

You can use any URL-legal characters in the template name;
C<Template::Declare> will encode the template as a Perl subroutine and stash
it where C<show()> can find it.

(Did you know that you can have characters like ":" and "/" in your Perl
subroutine names? The easy way to get at them is with C<can>).

=cut

sub template ($$) {
    my $template_name  = shift;
    my $coderef        = shift;
    my $template_class = ( caller(0) )[0];

    no warnings qw( uninitialized redefine );

    # template "foo" ==> CallerPkg::_jifty_template_foo;
    # template "foo/bar" ==> CallerPkg::_jifty_template_foo/bar;
    my $codesub = sub {
        local $self = shift || $self || $template_class;
        unshift @_, $self, $coderef;
        goto $self->can('_dispatch_template');
    };

    if (wantarray) {
         # We're being called by something like private that doesn't want us to register ourselves
        return ( $template_class, $template_name, $codesub );
    } else {
       # We've been called in a void context and should register this template
        Template::Declare::register_template(
            $template_class,
            $template_name,
            $codesub,
        );
    }
}

=head3 private template TEMPLATENAME => sub { 'Implementation' };

    private template select_list => sub {
        my $self = shift;
        select {
            option { $_ } for @_;
        }
    };

Declares that a template isn't available to be called directly from client
code. The resulting template can instead only be called from the package in
which it's created.

=cut

sub private (@) {
    my $class   = shift;
    my $subname = shift;
    my $code    = shift;
    Template::Declare::register_private_template( $class, $subname, $code );
}

=head2 Showing templates

=head3 show [$template_name or $template_coderef], args

    show( main => { user => 'Bob' } );

Displays templates. The first argument is the name of the template to be
displayed. Any additional arguments will be passed directly to the template.

C<show> can either be called with a template name or a package/object and a
template. (It's both functional and OO.)

If called from within a Template::Declare subclass, then private templates are
accessible and visible. If called from something that isn't a
Template::Declare, only public templates will be visible.

From the outside world, users can either call C<< Template::Declare->show() >>,
C<< show() >> exported from Template::Declare::Tags or
C<Template::Declare::Tags::show()> directly to render a publicly visible template.

Private templates may only be called from within the C<Template::Declare>
package.

=cut

sub show {
    my $template = shift;

    # if we're inside a template, we should show private templates
    if ( caller->isa('Template::Declare') ) {
        _show_template( $template, 1, \@_ );
        return Template::Declare->buffer->data;
    } else {
        show_page( $template, @_);
    }

}

=head3 show_page

    show_page( main => { user => 'Bob' } );

Like C<show()>, but does not dispatch to private templates. It's used
internally by C<show()> when when that method is called from outside a
template class.

=cut

sub show_page {
    my $template = shift;
    my $args = \@_;

    Template::Declare->buffer->push(
        private => defined wantarray,
        from => "T::D path $template",
    );
    _show_template( $template, 0, $args );
    %ELEMENT_ID_CACHE = ();
    return Template::Declare->buffer->pop;
}

=head2 Attributes

=head3 attr HASH

    attr { src => 'logo.png' };

Specifies attributes for the element tag in which it appears. For example, to
add a class and ID to an HTML paragraph:

    p {
       attr {
           class => 'greeting text',
           id    => 'welcome',
       };
       'This is a welcoming paragraph';
    }

=cut

sub attr (&;@) {
    my $code = shift;
    my @rv   = $code->();
    while ( my ( $field, $val ) = splice( @rv, 0, 2 ) ) {

        # only defined whle in a tag context
        append_attr( $field, $val );
    }
    return @_;
}

=head3 ATTR is VALUE

Attributes can also be specified by using C<is>, as in

    p {
       class is 'greeting text';
       id    is 'welcome';
       'This is a welcoming paragraph';
    }

A few tricks work for 'is':

    http_equiv is 'foo'; # => http-equiv="foo"
    xml__lang is 'foo';  # => xml:lang="foo"

So double underscore replaced with colon and single underscore with dash.

=cut

# 'is' is declared later, when needed, using 'local *is::AUTOLOAD = sub {};'

=head3 with

    with ( id => 'greeting', class => 'foo' ),
        p { 'Hello, World wide web' };

An alternative way to specify attributes for a tag, just for variation. The
standard way to do the same as this example using C<attr> is:

    p { attr { id => 'greeting', class => 'foo' }
        'Hello, World wide web' };

=cut

sub with (@) {
    %ATTRIBUTES = ();
    while ( my ( $key, $val ) = splice( @_, 0, 2 ) ) {
        no warnings 'uninitialized';
        $ATTRIBUTES{$key} = $val;

        if ( lc($key) eq 'id' ) {
            if ( $ELEMENT_ID_CACHE{$val}++ ) {
                my $msg = "HTML appears to contain illegal duplicate element id: $val";
                die $msg if Template::Declare->strict;
                warn $msg;
            }
        }

    }
    wantarray ? () : '';
}

=head2 Displaying text and raw data

=head3 outs STUFF

    p { outs 'Grettings & welcome pyoonie hyoomon.' }

HTML-encodes its arguments and appends them to C<Template::Declare>'s output
buffer. This is similar to simply returning a string from a tag function call,
but is occasionally useful when you need to output a mix of things, as in:

    p { outs 'hello'; em { 'world' } }

=head3 outs_raw STUFF

   p { outs_raw "That's what <em>I'm</em> talking about!' }

Appends its arguments to C<Template::Declare>'s output buffer without HTML
escaping.

=cut

sub outs     { _outs( 0, @_ ); }
sub outs_raw { _outs( 1, @_ ); }

=head2 Installing tags and wrapping stuff

=head3 install_tag TAGNAME, TAGSET

    install_tag video => 'Template::Declare::TagSet::HTML';

Sets up TAGNAME as a tag that can be used in user templates. TAGSET is an
instance of a subclass for L<Template::Declare::TagSet>.

=cut

sub install_tag {
    my $tag  = $_[0]; # we should not do lc($tag) here :)
    my $name = $tag;
    my $tagset = $_[1];

    my $alternative = $tagset->get_alternate_spelling($tag);
    if ( defined $alternative ) {
        _install(
            0, # do not override
            scalar(caller), $tag,
            sub (&) {
                die "$tag {...} is invalid; use $alternative {...} instead.\n";
            }
        );
        ### Exporting place-holder sub: $name
        # XXX TODO: more checking here
        if ($name !~ /^(?:base|tr|time)$/) {
            push @EXPORT, $name;
            push @TAG_SUB_LIST, $name;
        }
        $name = $alternative or return;
    }

    # We don't need this since we directly install
    # subs into the target package.
    #push @EXPORT, $name;
    push @TAG_SUB_LIST, $name;

    no strict 'refs';
    no warnings 'redefine';
    #### Installing tag: $name
    # XXX TODO: use sub _install to insert subs into the caller's package so as to support XML packages
    my $code  = sub (&;$) {
        local *__ANON__ = $tag;
        if ( defined wantarray and not wantarray ) {

            # Scalar context - return a coderef that represents ourselves.
            my @__    = @_;
            my $_self = $self;
            my $sub   = sub {
                local $self     = $_self;
                local *__ANON__ = $tag;
                _tag($tagset, $tag, @__);
            };
            bless $sub, 'Template::Declare::Tag';
            return $sub;
        } else {
            _tag($tagset, $tag, @_);
        }
    };
    _install(
        1, # do override the existing sub with the same name
        $tagset->package => $name => $code
    );
}

=head3 smart_tag_wrapper

    # create a tag that has access to the arguments set with L</with>.
    sub sample_smart_tag (&) {
        my $code = shift;

        smart_tag_wrapper {
            my %args = @_; # set using 'with'
            outs( 'keys: ' . join( ', ', sort keys %args) . "\n" );
            $code->();
        };
    }

    # use it
    with ( foo => 'bar', baz => 'bundy' ), sample_smart_tag {
        outs( "Hello, World!\n" );
    };

The output would be

    keys: baz, foo
    Hello, World!

The smart tag wrapper allows you to create code that has access to the
attribute arguments specified via C<with>. It passes those arguments in to the
wrapped code in C<@_>. It also takes care of putting the output in the right
place and tidying up after itself. This might be useful to change the behavior
of a template based on attributes passed to C<with>.

=cut

sub smart_tag_wrapper (&) {
    my $coderef = shift;

    Template::Declare->buffer->append($EOL);
    Template::Declare->buffer->push( from => "T::D tag wrapper", private => 1 );

    my %attr = %ATTRIBUTES;
    %ATTRIBUTES = ();                              # prevent leakage

    my $last = join '',
        map { ref($_) ? $_ : _postprocess($_) }
        $coderef->(%attr);

    my $content = Template::Declare->buffer->pop;
    $content .= "$last" if not length $content and length $last;
    Template::Declare->buffer->append( $content );

    return '';
}

=head3 create_wrapper WRAPPERNAME => sub { 'Implementation' };

    create_wrapper basics => sub {
        my $code = shift;
        html {
            head { title { 'Welcome' } };
            body { $code->() }
        }
    };

C<create_wrapper> declares a wrapper subroutine that can be called like a tag
sub, but can optionally take arguments to be passed to the wrapper sub. For
example, if you wanted to wrap all of the output of a template in the usual
HTML headers and footers, you can do something like this:

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    BEGIN {
        create_wrapper wrap => sub {
            my $code = shift;
            my %params = @_;
            html {
                head { title { outs "Hello, $params{user}!"} };
                body {
                    $code->();
                    div { outs 'This is the end, my friend' };
                };
            }
        };
    }

    template inner => sub {
        wrap {
            h1 { outs "Hello, Jesse, s'up?" };
        } user => 'Jesse';
    };

Note how the C<wrap> wrapper function is available for calling after it has
been declared in a C<BEGIN> block. Also note how you can pass arguments to the
function after the closing brace (you don't need a comma there!).

The output from the "inner" template will look something like this:

 <html>
  <head>
   <title>Hello, Jesse!</title>
  </head>
  <body>
   <h1>Hello, Jesse, s&#39;up?</h1>
   <div>This is the end, my friend</div>
  </body>
 </html>

=cut

sub create_wrapper ($$) {
    my $wrapper_name   = shift;
    my $coderef        = shift;
    my $template_class = caller;

    # Shove the code ref into the calling class.
    no strict 'refs';
    *{"$template_class\::$wrapper_name"} = sub (&;@) { goto $coderef };
}

=head2 Helpers

=head3 xml_decl HASH

    xml_decl { 'xml', version => '1.0' };

Emits an XML declaration. For example:

    xml_decl { 'xml', version => '1.0' };
    xml_decl { 'xml-stylesheet',  href => "chrome://global/skin/", type => "text/css" };

Produces:

 <?xml version="1.0"?>
 <?xml-stylesheet href="chrome://global/skin/" type="text/css"?>

=cut

sub xml_decl (&;$) {
    my $code = shift;
    my @rv   = $code->();
    my $name = shift @rv;
    outs_raw("<?$name");
    while ( my ( $field, $val ) = splice( @rv, 0, 2 ) ) {
        outs_raw(qq/ $field="$val"/);
    }
    outs_raw("?>$EOL");
    return @_;
}

=head3 current_template

    my $path = current_template();

Returns the absolute path of the current template

=cut

sub current_template {
    return $TEMPLATE_STACK[-1] || '';
}

=head3 current_base_path

    my $path = current_base_path();

Returns the absolute base path of the current template

=cut

sub current_base_path {
    # Rip it apart
    my @parts = split('/', current_template());

    # Remove the last element
    pop @parts;

    # Put it back together again
    my $path = join('/', @parts);

    # And serve
    return $path;
}

=head3 under

C<under> is a helper function providing semantic sugar for the C<mix> method
of L<Template::Declare|Template::Declare/"mix">.

=cut

sub under ($) { return shift }

=head3 setting

C<setting> is a helper function providing semantic sugar for the C<mix> method
of L<Template::Declare|Template::Declare/"mix">.

=cut

sub setting ($) { return shift }

=begin comment

=head2 get_current_attr

Deprecated.

=end comment

=cut

sub get_current_attr ($) {
    $ATTRIBUTES{ $_[0] };
}

sub _tag {
    my $tagset    = shift;
    my $tag       = shift;
    my $code      = shift;
    my $more_code = shift;
    $tag = $tagset->namespace . ":$tag" if defined $tagset->namespace;

    Template::Declare->buffer->append(
              $EOL
            . ( " " x $TAG_NEST_DEPTH )
            . "<$tag"
            . join( '',
            map { qq{ $_="} . ( $ATTRIBUTES{$_} || '' ) . qq{"} }
                sort keys %ATTRIBUTES )
    );

    my $attrs = "";
    my $last;
    {
        no warnings qw( uninitialized redefine once );

        local *is::AUTOLOAD = sub {
            shift;

            my $field = our $AUTOLOAD;
            $field =~ s/.*:://;

            $field =~ s/__/:/g;   # xml__lang  is 'foo' ====> xml:lang="foo"
            $field =~ s/_/-/g;    # http_equiv is 'bar' ====> http-equiv="bar"

            # Squash empty values, but not '0' values
            my $val = join ' ', grep { defined $_ && $_ ne '' } @_;

            append_attr( $field, $val );
        };

        local *append_attr = sub {
            my $field = shift;
            my $val   = shift;

            $attrs .= ' ' . $field . q{="} . _postprocess($val, 1) . q{"};
            wantarray ? () : '';
        };

        local $TAG_NEST_DEPTH = $TAG_NEST_DEPTH + $TAG_INDENTATION;
        %ATTRIBUTES = ();
        Template::Declare->buffer->push( private => 1, from => "T::D tag $tag" );
        $last = join '', map { ref($_) && $_->isa('Template::Declare::Tag') ? $_ : _postprocess($_) } $code->();
    }
    my $content = Template::Declare->buffer->pop;
    $content .= "$last" if not length $content and length $last;
    Template::Declare->buffer->append($attrs) if length $attrs;

    if (length $content) {
        Template::Declare->buffer->append(">$content");
        Template::Declare->buffer->append( $EOL . ( " " x $TAG_NEST_DEPTH )) if $content =~ /\</;
        Template::Declare->buffer->append("</$tag>");
    } elsif ( $tagset->can_combine_empty_tags($tag) ) {
        Template::Declare->buffer->append(" />");
    } else {
        # Otherwise we supply a closing tag.
        Template::Declare->buffer->append("></$tag>");
    }

    return ( ref($more_code) && $more_code->isa('CODE') )
        ? $more_code->()
        : '';
}

sub _resolve_template_path {
    my $template = shift;

    my @parts;
    if ( substr($template, 0, 1) ne '/' ) {
        # relative
        @parts = split '/', current_template();
        # Get rid of the parent's template name
        pop @parts;
    }

    foreach ( split '/', $template ) {
        if ( $_ eq '..' ) {
            pop @parts;
        }
        # Get rid of "." and empty entries by the way
        elsif ( $_ ne '.' && $_ ne '' ) {
            push @parts, $_;
        }
    }

    return join '/', @parts;
}

sub _show_template {
    my $template        = shift;
    my $inside_template = shift;
    my $args = shift;
    $template = _resolve_template_path($template);
    local @TEMPLATE_STACK  = (@TEMPLATE_STACK, $template);

    my $callable =
        ( ref($template) && $template->isa('Template::Declare::Tag') )
        ? $template
        : Template::Declare->resolve_template( $template, $inside_template );

    # If the template was not found let the user know.
    unless ($callable) {
        my $msg = "The template '$template' could not be found";
        $msg .= " (it might be private)" if !$inside_template;
        croak $msg if Template::Declare->strict;
        carp $msg;
        return '';
    }

    if (my $instrumentation = Template::Declare->around_template) {
        $instrumentation->(
            sub { &$callable($self, @$args) },
            $template,
            $args,
            $callable,
        );
    }
    else {
        &$callable($self, @$args);
    }

    return;
}

sub _outs {
    my $raw     = shift;
    my @phrases = (@_);

    Template::Declare->buffer->push(
        private => (defined wantarray and not wantarray), from => "T::D outs"
    );

    foreach my $item ( grep {defined} @phrases ) {
        my $returned = ref($item) eq 'CODE'
            ? $item->()
            : $raw
                ? $item
                : _postprocess($item);
        Template::Declare->buffer->append( $returned );
    }
    return Template::Declare->buffer->pop;
}

sub _postprocess {
    my $val = shift;
    my $skip_postprocess = shift;

    return $val unless defined $val;

    # stringify in case $val is object with overloaded ""
    $val = "$val";
    if ( ! $SKIP_XML_ESCAPING ) {
        no warnings 'uninitialized';
        $val =~ s/&/&#38;/g;
        $val =~ s/</&lt;/g;
        $val =~ s/>/&gt;/g;
        $val =~ s/\(/&#40;/g;
        $val =~ s/\)/&#41;/g;
        $val =~ s/"/&#34;/g;
        $val =~ s/'/&#39;/g;
    }
    $val = Template::Declare->postprocessor->($val)
        unless $skip_postprocess;

    return $val;
}

=begin comment

=head2 append_attr

C<append_attr> is a helper function providing an interface for setting
attributes from within tags. But it's better to use C<attr> or C<is> to set
your attributes. Nohting to see here, really. Move along.

=end comment

=cut

sub append_attr {
    die "Subroutine attr failed: $_[0] => '$_[1]'\n\t".
        "(Perhaps you're using an unknown tag in the outer container?)";
}

=head1 VARIABLES

=over 4

=item C<@Template::Declare::Tags::EXPORT>

Holds the names of the static subroutines exported by this class. Tag
subroutines generated by tag sets, however, are not included here.

=item C<@Template::Declare::Tags::TAG_SUB_LIST>

Contains the names of the tag subroutines generated from a tag set.

Note that this array won't get cleared automatically before another
C<< use Template::Decalre::Tags >> statement.

C<@Template::Declare::Tags::TagSubs> is aliased to this variable for
backward-compatibility.

=item C<$Template::Declare::Tags::TAG_NEST_DEPTH>

Controls the indentation of the XML tags in the final outputs. For example,
you can temporarily disable a tag's indentation by the following lines of
code:

    body {
        pre {
          local $Template::Declare::Tags::TAG_NEST_DEPTH = 0;
          script { attr { src => 'foo.js' } }
        }
    }

It generates

 <body>
  <pre>
 <script src="foo.js"></script>
  </pre>
 </body>

Note that now the C<script> tag has I<no> indentation and we've got what we
want. ;)

=item C<$Template::Declare::Tags::SKIP_XML_ESCAPING>

Disables XML escape postprocessing entirely. Use at your own risk.

=back

=head1 SEE ALSO

L<Template::Declare::TagSet::HTML>,
L<Template::Declare::TagSet::XUL>, L<Template::Declare>.

=head1 AUTHORS

Jesse Vincent <jesse@bestpractical.com>

Agent Zhang <agentzh@yahoo.cn>

=head1 COPYRIGHT

Copyright 2006-2009 Best Practical Solutions, LLC.

=cut

package Template::Declare::Tag;

use overload '""' => \&stringify;

sub stringify {
    my $self = shift;

    if ( defined wantarray ) {
        Template::Declare->buffer->push( private => 1, from => "T::D stringify" );
        my $returned = $self->();
        return Template::Declare->buffer->pop . $returned;
    } else {
        return $self->();
    }
}

1;
