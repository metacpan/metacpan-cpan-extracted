package Role::LibXSLT::Extender;
{
  $Role::LibXSLT::Extender::VERSION = '1.140260';
}
use Moose::Role;
use XML::LibXSLT;
use namespace::autoclean;



=head1 NAME

Role::LibXSLT::Extender

=head1 VERSION

version 1.140260

=head1 SYNOPSIS

    # your extension class
    package My::Special::XSLTProcessor
    use Moose;
    with 'MooseX::LibXSLT::Extender';

    sub set_extension_namespace {
        return 'http:/fake.tld/my/app/namespace/v1'
    }

    sub special_text_munger {
        my $self = shift;
        my $text = shift;

        # magic happens here

        return $text;
    }

    -------------------
    # in your XSLT stylesheet

    <?xml version="1.0"?>
    <xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:myapp="http:/fake.tld/my/app/namespace/v1">

    <xsl:template match="/some/xpath">
        <!-- pass the current text node to special_text_munger()
             in your extension class. -->
        <foo><xsl:value-of select="myapp:special_text_munger(.)"/></foo>
    </xsl:template>

    -------------------
    # in your application or script

    my $extended = My::Special::XSLTProcessor->new();

    # load the XML and XSLT files
    my $style_dom = XML::LibXML->load_xml( location=> $xsl_file );
    my $input_dom = XML::LibXML->load_xml( location=> $xml_file );
    my $stylesheet = $extended->parse_stylesheet($style_dom);

    # your custom extensions are called here
    my $transformed_dom = $stylesheet->transform( $input_dom );

    # dump the result to STDOUT
    print $stylesheet->output_as_bytes($transformed_dom);


=head1 DESCRIPTION

Simple Moose Role that instantiates an XML::LibXSLT processor and registers a series of site-specific Perl extension functions that can be called from within your XSLT stylesheets.

=head1 WHY WOULD I WANT THIS?

XSLT is great for recursively transforming nested XML documents but operating on the text in those documents can be time consuming and error-prone. Perl is great for all sort of things, but transforming nested XML documents programmatically is the source of much unnecessary pain and consternation. This module seeks to bridge the gap by letting you use XSLT for what it is best at while using the power of Perl for everything else.

=head1 METHODS

=over

=item set_extension_namespace

In addition to the various custom functions in your extention class, you are required to implement the set_extension_namespace() method. This namespace URI will be used to register your functions with the LibXSLT processor and is the mechanism by which your custom functions will be available from within your XSLT stylesheets.

For example, if your extention class has the following:

    sub set_extension_namespace { return 'http:/fake.tld/my/app/namespace/v1'; }

You can access functions in this namespace by declaring that namespace in your XSLT stylesheet:

  <?xml version="1.0"?>
  <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:myapp="http:/fake.tld/my/app/namespace/v1"
  >

And then using the bound prefix to call the functions in that namespace:

  <xsl:value-of select="myapp:some_function_name( arguments )" />

=item xslt_processor

This method returns the instance of the L<XML::LibXSLT> processor with your extension functions registered and ready to go.

=back

=head1 FUNCTIONS ARE METHODS, NOT SIMPLE SUBROUTINES

Note that this Role gives your extension functions extra magical powers beyond the mechanism provided by L<XML::LibXSLT> by making your functions into methods rather than simple subroutines. From the example above:

    sub special_text_munger {
        my $self = shift;
        my $text = shift;

        # magic happens here

        return $text;
    }

Note that the first argument passed to this function is the instance of this class, and the text node (or nodelist) sent over from the XML document is the second argument. This gives your functions access to all other attributes, methods, etc. contained in this class without having to resort to global variables and so forth. This gives your functions (and the stylesheets that use them) the power to easily alter the document by adding nodes based on database queries, perform complex operations on data using other objects, and a myriad of other options.

=head1 KEEPING PRIVATE THINGS PRIVATE

This Role uses Moose's handy introspection facilities to avoid registering methods that you probably don't want to make available to your stylesheets (attribute accessors, builders, etc.) but it has no way of differentiating between methods that you want to register and those that you will use for other purposes. To that end, if you want to implement methods that B<will not> be registered, simply use the "make this private" convention and prepend the method's name with an underscore:

sub my_function {
    # i'll be registered and available in the stylesheets.
}

sub _my_function {
    # But I won't be.
}

=cut

has _extension_namespace => (
    is          =>  'ro',
    isa         =>  'Str|Undef',
    lazy        =>  1,
    builder     =>  'set_extension_namespace',
);

sub set_extension_namespace { return undef; }

has xslt_processor => (
    is          =>  'ro',
    isa         =>  'XML::LibXSLT',
    lazy_build  =>  1,
    handles     =>  [qw(parse_stylesheet parse_stylesheet_file)],
);

sub _build_xslt_processor {
    my $self = shift;
    my $class_meta = __PACKAGE__->meta;
    my $meta = $self->meta;

    my @class_methods = ($class_meta->get_method_list, 'set_namespace');

    my $ns = $self->_extension_namespace || die "No extention namespace declared. Use set_namespace() to bind your functions.";

    foreach my $method_name ( $meta->get_method_list ) {
        next if grep {$_ eq $method_name} @class_methods;
        if ( my $method = $meta->get_method( $method_name ) ) {
            # attribute accessors, etc. have
            # specialized 'Moose::Meta::Method::* subclasses,
            # plain old methods don't.

            next unless blessed( $method ) eq 'Moose::Meta::Method';

            # keep private methods private

            next if $method_name =~ /^_/;
            #warn "registering $method_name to namespace $ns \n";
            XML::LibXSLT->register_function($ns, $method_name, sub { $self->$method_name( @_ ) });
        }
    }

    return XML::LibXSLT->new();
}

1;
