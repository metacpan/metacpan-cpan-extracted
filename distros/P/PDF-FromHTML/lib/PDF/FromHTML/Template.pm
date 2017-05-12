package PDF::FromHTML::Template;

use strict;
use warnings;

use base 'PDF::FromHTML::Template::Base';

our $VERSION = '0.30';

use PDF::Writer;

use File::Basename qw( fileparse );
use XML::Parser ();

#-----------------------------------------------
# TODO
#-----------------------------------------------
# PDF_set_info - find out more about this
# Providers - I need to create some provider classes that abstract
#    the process of PDF creation.    This will enable P::T to work with
#    different PDF providers.    A provider could be passed in to the
#    constructor.    If non is passed, P::T should try to instantiate a
#    sensible provider depending on what is installed.
#-----------------------------------------------

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{TEMPLATES} = [] unless UNIVERSAL::isa($self->{TEMPLATES}, 'ARRAY');
    $self->{PARAM_MAP} = {} unless UNIVERSAL::isa($self->{PARAM_MAP}, 'HASH');

    $self->{PDF_VERSION} = 0;

    $self->_validate_option($_)
        for qw(OPENACTION OPENMODE);

    if ( !defined $self->{FILE} && defined $self->{FILENAME} ) {
        $self->{FILE} = $self->{FILENAME};
    }

    $self->parse_xml($self->{FILE}) if defined $self->{FILE};

    return $self;
}

sub param {
    my $self = shift;

    # Allow an arbitrary number of hashrefs, so long as they're the first things
    # into param(). Put each one onto the end, de-referenced.
    push @_, %{shift @_} while UNIVERSAL::isa($_[0], 'HASH');

    (@_ % 2)
        && die __PACKAGE__, "->param() : Odd number of parameters to param()\n";

    my %params = @_;
    $params{uc $_} = delete $params{$_} for keys %params;
    @{$self->{PARAM_MAP}}{keys %params} = @params{keys %params};

    return 1;
}

sub write_file {
    my $self = shift;
    my ($fname) = @_;

    my $p = PDF::Writer->new;
    $p->open($fname) or die "Could not open file '$fname'.", $/;

    $self->_prepare_output($p);

    $p->save();

    return 1;
}

sub get_buffer {
    my $self = shift;

    my $p = PDF::Writer->new;
    $p->open() or die "Could not open buffer.", $/;

    $self->_prepare_output($p);

    return $p->stringify();
}
*output = \&get_buffer;

sub parse {
    my $self = shift;
    my ($file) = @_;

    my %Has_TextObject = map { $_ => undef } qw(
        BOOKMARK
        IMAGE
        TEXTBOX
    );

    my @stack;
    my @params = (
        Handlers => {
            Start => sub {
                shift;
                my $name = uc shift;

                # Pass the PDF encoding in.
                if ($name eq 'PDFTEMPLATE') {
                    if (exists $self->{PDF_ENCODING}) {
                        push @_, (
                            PDF_ENCODING => $self->{PDF_ENCODING},
                        );
                    }
                }

                my $node = PDF::FromHTML::Template::Factory->create_node($name, @_);
                die "'$name' (@_) didn't make a node!\n" unless defined $node;

                if ($name eq 'VAR') {
                    return unless @stack;

                    if (exists $stack[-1]{TXTOBJ} && $stack[-1]{TXTOBJ}->isa('TEXTOBJECT')) {
                        push @{$stack[-1]{TXTOBJ}{STACK}}, $node;
                    }
                }
                elsif ($name eq 'PDFTEMPLATE') {
                    push @{$self->{TEMPLATES}}, $node;
                }
                else {
                    push @{$stack[-1]{ELEMENTS}}, $node
                        if @stack;
                }

                push @stack, $node;
            },
            Char => sub {
                shift;
                return unless @stack;

                my $parent = $stack[-1];
                if (exists $parent->{TXTOBJ} && $parent->{TXTOBJ}->isa('TEXTOBJECT')) {
                    push @{$parent->{TXTOBJ}{STACK}}, @_;
                }
            },
            End => sub {
                shift;
                return unless @stack;

                pop @stack if $stack[-1]->isa(uc $_[0]);
            },
        },
    );

    if ( exists $self->{PDF_ENCODING} ) {
        push @params, ProtocolEncoding => $self->{PDF_ENCODING};
    }

    if ( ref $file ) {
        *INFILE = $file;
    }
    else {
        my ($filename, $dirname) = fileparse($file);
        push @params, Base => $dirname;

        open( INFILE, '<', $file )
            || die "Cannot open '$file' for reading: $!\n";
    }

    my $parser = XML::Parser->new( @params );
    $parser->parse(do { local $/ = undef; <INFILE> });

    close INFILE
        unless ref $file;

    return 1;
}
*parse_xml = \&parse;

my %NoSetProperty = map { $_ => 1 } qw(
    CreationDate Producer ModDate Trapped
);

sub _prepare_output {
    my $self = shift;
    my ($p) = @_;

    $p->parameter('openaction' => $self->{OPENACTION});
    $p->parameter('openmode' => $self->{OPENMODE});

    if (UNIVERSAL::isa($self->{INFO}, 'HASH')) {
        foreach my $key ( keys %{$self->{INFO}} ) {
            if ($NoSetProperty{$key}) {
                warn "Document property '$key' cannot be set.", $/;
                next;
            }

            $p->info($key, $self->{INFO}{$key});
        }
    }
    else {
        $p->info($_, __PACKAGE__) for qw/Creator Author/;
    }

    # __PAGE__ is incremented after the page is done.
    $self->{PARAM_MAP}{__PAGE__} = 1;

    # __PAGEDEF__ is incremented when the pagedef begins.
    $self->{PARAM_MAP}{__PAGEDEF__} = 0;

    my $context = PDF::FromHTML::Template::Factory->create(
        'CONTEXT',
        # Un-scoped variables
        X => 0,
        Y => 0,

        # Other variables
        PDF       => $p,
        PARAM_MAP => [ $self->{PARAM_MAP} ],

        PDF_VERSION     => $self->{PDF_VERSION},
        DIE_ON_NO_PARAM => $self->{DIE_ON_NO_PARAM},
    );

    # Do a first pass through, noting important values
#    $_->preprocess($context) for @{$self->{TEMPLATES}};

    # Do a second pass through, for actual rendering
    $_->render($context) for @{$self->{TEMPLATES}};

    $context->close_images;

    return 1;
}

sub register { shift; PDF::FromHTML::Template::Factory::register(@_) }

1;
__END__

=head1 NAME

PDF::FromHTML::Template - PDF::FromHTML::Template

=head1 SYNOPSIS

  use PDF::FromHTML::Template;

  my $pdf = PDF::FromHTML::Template->new({
     file => 'some_template.xml',
  });

  $pdf->param(%my_params);

  print "Content/type: application/pdf\n\n", $pdf->get_buffer;

  $pdf->write_file('some_file.pdf');

=head1 DESCRIPTION

B<NOTE>: This is a fork of L<PDF::Template> 0.30, originally released by Rob Kinyon,
but (as of September 11, 2006) currently not available on CPAN.  Use of this module
outside L<PDF::FromHTML> is not advised.

PDF::FromHTML::Template is a PDF layout system that uses the same data structures as
L<HTML::Template>.

=head1 OVERVIEW

PDF::FromHTML::Template is a PDF layout system that uses the same data structures as
L<HTML::Template>. Unlike L<HTML::Template>, this is a full layout system. This means
you will have to describe where each item will be on the page. (This is in
contrast to L<HTML::Template>, which adds on to L<HTML::Template>ut is determined by
the HTML, not L<HTML::Template>.)

PDF::FromHTML::Template uses an XML document as the template. However, the XML is not
completely compliant. The only difference (that I'm aware of) is that any node
can have any parameter. (This prevents the creation of a DTD.) The reason for
this is to allow scoping by parents for parameters used by children. (More on
this later.)

Each node in the document corresponds to an object, with each parameter
mapping (mostly) 1 to 1 to an object attribute. Parent-child relationships are
strictly preserved. Each parent provides a scope (similar to variable scope) to
its children. (This is why any node can have any parameter.) If a child needs
the value of a parameter and it doesn't have that value as an attribute, it will
ask its parent for the value. If the parent doesn't have it, it will ask its
parent, and so on.

=head1 METHODS

=over 4

=item * C<new( [$opts] )>

This will create a new instance of PDF::FromHTML::Template. $opts is an optional hashref
that can contain the following parameters:

=over 4

=item * file

This is either the name of the file or the filehandle of the open file. If it
is present, C<parse()> will be called upon that filename/filehandle. Otherwise,
after new() is called, you will have to call C<parse()> yourself.

filename is a synonym for file.

=item * openaction

This is the action that the PDF reader will take when it opens this file. The
valid values are:

=over 4

=item * fitbox

=item * fitheight

=item * fitpage (default)

=item * fitwidth

=item * retain

=back

=item * openmode

This is the mode that the PDF reader will use when it opens this file. The
valid values are:

=over 4

=item * bookmarks

=item * fullscreen

=item * none (default)

=item * thumbnails

=back

=item * info

This is a hashref of information that you wish to have the PDF retain as
metadata. If this is not present, both Author and Creator will be set to
PDF::FromHTML::Template.

The following keys are not supported:

=over 4

=item * CreationDate

=item * Producer

=item * ModDate

=item * Trapped

=back

=item * pdf_encoding

This is the encoding that the template is in. It defaults to the host
encoding. This is different from the encoding parameter for the pdftemplate
tag.

=back

=item * C<parse( $file )>

This will parse the XML template into the appropriate datastructure(s) needed
for PDF::FromHTML::Template to function.

=item * C<parse_xml( $file )>

This is a deprecated synonym for C<parse()>.

=item * C<param( key => value, [ key => value, ... ] )>

This will set the parameters that PDF::FromHTML::Template will use to merge the template
with. This method is identical to the HTML::Template or Template Toolkit
method of the same name.

=item * C<write_file( $filename )>

This will write the rendered PDF to the file specified in $filename.

=item * C<get_buffer()>

This will return the rendered PDF stringified in a form appropriate for
returning over an HTTP connection.

=item * C<output()>

This is a synonym for C<get_buffer()> provided for HTML::Template
compatibility.

=item * C<register( ... )>

XXX

=back

=head1 USAGE

There are a few consistency rules that that every PDF::FromHTML::Template has to follow:

=over 4

=item 1 The root node is called PDFTEMPLATE

=item 2 There must be at least one PAGEDEF (which does not have to be a direct
child of the PDFTEMPLATE node)

=item 3 All rendering elements (include FONT tags) must be within a PAGEDEF node

=item 4 There must be a FONT tag as an ancestor of every TEXTBOX node

=item 5 Within a PAGEDEF, there can only be one HEADER node and one FOOTER node

=back

For more information about each node, please see the POD for that class.

=head1 WWW CAVEATS

When taking an HTML page and adding a PDF option, there are a few differences
to take into account. The primary one is the idea of pagebreaks. HTML is
displayed as a single page, with scrolling. Paper doesn't scroll, so when
there should be a new page is something PDF::FromHTML::Template works very hard at
determining. It will take into account any header and footer information
you've provided, as well as page sizes.

The second is that you have to determine how wide you want your text to be. One
of the most common activities is to take a tabular report and covert it to a
PDF. In HTML, the browser handles text width for you. Right now, there isn't a
TABLE tag (though work is being done on it). So, you have to layout out your
TEXTBOX nodes by hand. (See the EXAMPLES for some ideas on this.) That said, it
really isn't that hard. TR/TH tags convert to ROW tags easily, and TD tags are
basically TEXTBOX tags. Add a few width="20%" (or whatever) and you're fine.

=head1 BUGS

None, that I'm aware of.

=head1 LIMITATIONS

Currently, the only PDF renderer PDF::FromHTML::Template supports is PDFlib (available at
www.pdflib.com). The next release of PDF::FromHTML::Template will also support PDF::API2.
Unless you need Unicode support, PDFlib Lite is sufficient (and free). Please
see L<http://www.pdflib.com> for more details.

I am aware that PDFlib will not compile under AIX or Cygwin. These are
problems that PDFlib has acknowledged to me.

=head1 AUTHOR/MAINTAINER

Originally written by Dave Ferrance (dave@ferrance.org)

Taken over after v0.05 by Rob Kinyon (rob.kinyon@iinteractive.com)

=head1 CONTRIBUTORS

Patches and ideas provided by:

=over 4

=item * Audrey Tang

Provided the impetus to move to L<PDF::Writer> (which she also wrote).

=item * Michael Kiwala

Aided in the design and testing of the transition from Dave Ferrance's
version.

=item * Nathan Byrd

Provided nearly all the initial doublebyte expertise.

=back

Additionally, there is a mailing list at
L<http://groups.google.com/group/PDFTemplate>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
