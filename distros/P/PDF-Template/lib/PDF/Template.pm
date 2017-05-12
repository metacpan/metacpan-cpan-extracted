package PDF::Template;

use strict;

BEGIN {
    use PDF::Template::Base;
    use vars qw ($VERSION @ISA);

    $VERSION = '0.22';
    @ISA     = qw (PDF::Template::Base);
}

use pdflib_pl;

use File::Basename;
use IO::File;
use XML::Parser;

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

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{TEMPLATES} = [] unless UNIVERSAL::isa($self->{TEMPLATES}, 'ARRAY');
    $self->{PARAM_MAP} = {} unless UNIVERSAL::isa($self->{PARAM_MAP}, 'HASH');

    $self->{PDF_VERSION} = 0;
    for my $version (reverse 1 .. 6)
    {
        eval "UNIVERSAL::VERSION('pdflib_pl', $version.0)";
        unless ($@)
        {
            $self->{PDF_VERSION} = $version;
            last;
        }
    }
    die "Cannot find pdflib_pl version",$/ unless $self->{PDF_VERSION};

    $self->_validate_option($_)
        for qw(OPENACTION OPENMODE);

    $self->parse_xml($self->{FILENAME}) if defined $self->{FILENAME};

    return $self;
}

sub param
{
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

sub write_file
{
    my $self = shift;
    my ($fname) = @_;

    my $p = pdflib_pl::PDF_new();

    pdflib_pl::PDF_open_file($p, $fname) == -1
        && die "pdflib_pl::PDF_open_file could not open file '$fname'.", $/;

    $self->_prepare_output($p);

    pdflib_pl::PDF_close($p);

    return 1;
}

sub output
{
    my $self = shift;

    $self->get_buffer(@_);
}

sub get_buffer
{
    my $self = shift;

    my $p = pdflib_pl::PDF_new();

    pdflib_pl::PDF_open_file($p, '') == -1
        && die "pdflib_pl::PDF_open_file could not open buffer.", $/;

    $self->_prepare_output($p);

    pdflib_pl::PDF_close($p);

    return pdflib_pl::PDF_get_buffer($p);
}

sub parse
{
    my $self = shift;

    $self->parse_xml(@_);
}

sub parse_xml
{
    my $self = shift;
    my ($fname) = @_;

    my %Has_TextObject = map { $_ => undef } qw(
        BOOKMARK
        IMAGE
        TEXTBOX
    );

    my ($filename, $dirname) = fileparse($fname);
 
    my @stack;
    my $parser = XML::Parser->new(
        Base => $dirname,
        Handlers => {
            Start => sub {
                shift;
#                { local $"="', '"; print "Start: '@_'\n"; }
                my $name = uc shift;

                # Pass the PDF encoding in.
                if ($name eq 'PDFTEMPLATE')
                {
                    if (exists $self->{PDF_ENCODING})
                    {
                        push @_, (
                            PDF_ENCODING => $self->{PDF_ENCODING},
                        );
                    }
                }

                my $node = PDF::Template::Factory->create_node($name, @_);
                die "'$name' (@_) didn't make a node!\n" unless defined $node;

                if ($name eq 'VAR')
                {
                    return unless @stack;

                    if (exists $stack[-1]{TXTOBJ} && $stack[-1]{TXTOBJ}->isa('TEXTOBJECT'))
                    {
                        push @{$stack[-1]{TXTOBJ}{STACK}}, $node;
                    }
                }
                elsif ($name eq 'PDFTEMPLATE')
                {
                    push @{$self->{TEMPLATES}}, $node;
                }
                else
                {
                    push @{$stack[-1]{ELEMENTS}}, $node
                        if @stack;
                }

                push @stack, $node;
#                print "Pushed $node onto stack\n";
            },
            Char => sub {
                shift;
#                { local $"="', '"; print "Char:  '@_'\n"; }
                return unless @stack;

                my $parent = $stack[-1];
                if (exists $parent->{TXTOBJ} && $parent->{TXTOBJ}->isa('TEXTOBJECT'))
                {
#                    print "Added '@_' to TextObject stack for '$parent'\n";
                    push @{$parent->{TXTOBJ}{STACK}}, @_;
                }
            },
            End => sub {
                shift;
#                { local $"="', '"; print "End:   '@_'\n"; }
                return unless @stack;

                pop @stack if $stack[-1]->isa(uc $_[0]);
            },
        },
    );

    {
        my $fh = IO::File->new($fname)
            || die "Cannot open '$fname' for reading: $!\n";
 
        $parser->parse(do { local $/ = undef; <$fh> });
 
        $fh->close;
    }

    return 1;
}

my %NoSetProperty = (
    'CreationDate' => 1,
    'Producer' => 1,
    'ModDate' => 1,
    'Trapped' => 1,
);

sub _prepare_output
{
    my $self = shift;
    my ($p) = @_;

    pdflib_pl::PDF_set_parameter($p, 'openaction', $self->{OPENACTION});
    pdflib_pl::PDF_set_parameter($p, 'openmode', $self->{OPENMODE});

    if (UNIVERSAL::isa($self->{INFO}, 'HASH'))
    {
        foreach my $key ( keys %{$self->{INFO}} )
        {
            if ($NoSetProperty{$key})
            {
                warn "Document property '$key' cannot be set.", $/;
                next;
            }

            pdflib_pl::PDF_set_info($p, $key, $self->{INFO}{$key});
        }
    }
    else
    {
        pdflib_pl::PDF_set_info($p, $_, __PACKAGE__) for qw/Creator Author/;
    }

    # __PAGE__ is incremented after the page is done.
    $self->{PARAM_MAP}{__PAGE__} = 1;

    # __PAGEDEF__ is incremented when the pagedef begins.
    $self->{PARAM_MAP}{__PAGEDEF__} = 0;

    my $context = PDF::Template::Factory->create(
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
    $_->preprocess($context) for @{$self->{TEMPLATES}};

    # Do a second pass through, for actual rendering
    $_->render($context) for @{$self->{TEMPLATES}};

    $context->close_images;

    return 1;
}

sub register { shift; PDF::Template::Factory::register(@_) }

1;
__END__

=head1 NAME

PDF::Template - PDF::Template

=head1 SYNOPSIS

  use PDF::Template

  my $pdf = PDF::Template->new(
     filename => 'some_template.xml',
  );

  $pdf->param(%my_params);

  print "Content/type: application/pdf\n\n", $pdf->get_buffer;

  $pdf->write_file('some_file.pdf');

=head1 DESCRIPTION

PDF::Template is a PDF layout system that uses the same data structures as
HTML::Template.

=head1 OVERVIEW

PDF::Template is a PDF layout system that uses the same data structures as
HTML::Template. Unlike HTML::Template, this is a full layout system. This means
you will have to describe where each item will be on the page. (This is in
contrast to HTML::Template, which adds on to HTML. The layout is determined by
the HTML, not HTML::Template.)

PDF::Template uses an XML document as the template. However, the XML is not
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

=head1 USAGE

There are a few consistency rules that that every PDF::Template has to follow:

=over 4

=item 1 The root node is called PDFTEMPLATE

=item 2 There must be at least one PAGEDEF (which does not have to be a direct
child of the PDFTEMPLATE node)

=item 3 All rendering elements (include FONT tags) must be within a PAGEDEF node

=item 4 There must be a FONT tag as an ancestor of every TEXTBOX node

=item 5 Within a PAGEDEF, there can only be on HEADER node and one FOOTER node

=back 4

For more information about each node, please see the POD for that class.

=head1 WWW CAVEATS

When taking an HTML page and adding a PDF option, there are a few differences totake into account. The primary one is the idea of pagebreaks. HTML is displayed
as a single page, with scrolling. Paper doesn't scroll, so when there should be
a new page is something PDF::Template works very hard at determining. It will
take into account any header and footer information you've provided, as well as
page sizes.

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

Currently, the only PDF rendered PDF::Template supports is PDFLib (available at
www.pdflib.com). An upcoming release of PDF::Template will also support
PDF::API2. Unless you need Unicode support, PDFLib Lite is sufficient (and
free). Please see www.pdflib.com for more details.

I am aware that PDFLib will not compile under AIX or Cygwin. These are problems
that PDFLib has acknowledged to me.

=head1 AUTHOR

Originally written by Dave Ferrance (dave@ferrance.org)
Taken over after v0.05 by Rob Kinyon (rob.kinyon@gmail.com)

=head1 CONTRIBUTORS

Patches and ideas provided by:

=over 4

=item * Michael Kiwala

=item * Nathan Byrd

=back 4

Additionally, there is a mailing list at http://groups-beta.google.com/group/PDFTemplate

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut
