package MsOffice::Word::Template;
use 5.024;
use Moose;
use MooseX::StrictConstructor;
use Carp                           qw(croak);
use MsOffice::Word::Surgeon 2.0;

# syntactic sugar for attributes
sub has_inner ($@) {my $attr = shift; has($attr => @_, init_arg => undef, lazy => 1, builder => "_$attr")}

use namespace::clean -except => 'meta';

our $VERSION = '2.05';

#======================================================================
# ATTRIBUTES
#======================================================================

# constructor attributes for interacting with MsWord
# See also BUILDARGS: the constructor can also take a "docx" arg
# that will be automatically translated into a "surgeon" attribute
has 'surgeon'       => (is => 'ro', isa => 'MsOffice::Word::Surgeon', required => 1);
has 'data_color'    => (is => 'ro', isa => 'Str',                     default  => "yellow");
has 'control_color' => (is => 'ro', isa => 'Str',                     default  => "green");
has 'part_names'    => (is => 'ro', isa => 'ArrayRef[Str]',           lazy     => 1,
                        default  => sub {[keys shift->surgeon->parts->%*]});
has 'property_files'=> (is => 'ro', isa => 'ArrayRef[Str]',
                        default => sub {[qw(docProps/core.xml docProps/app.xml docProps/custom.xml)]});

# constructor attributes for building a templating engine
has 'engine_class'  => (is => 'ro', isa => 'Str',                     default  => 'TT2');
has 'engine_args'   => (is => 'ro', isa => 'ArrayRef',                default  => sub {[]});

# attributes lazily constructed by the module -- not received through the constructor
has_inner 'engine'  => (is => 'ro', isa => 'MsOffice::Word::Template::Engine');


#======================================================================
# BUILDING INSTANCES
#======================================================================

# syntactic sugar for supporting ->new($surgeon) instead of ->new(surgeon => $surgeon)
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # if there is a unique arg without any keyword ...
  if ( @_ == 1) {

    # if the unique arg is an instance of Surgeon, it's the "surgeon" parameter
    unshift @_, 'surgeon' if $_[0]->isa('MsOffice::Word::Surgeon');

    # if the unique arg is a string, it's the "docx" parameter
    unshift @_, 'docx' if $_[0] && !ref $_[0];
  }

  # translate the "docx" parameter into a "surgeon" parameter
  my %args = @_;
  if (my $docx = delete $args{docx}) {
    $args{surgeon} = MsOffice::Word::Surgeon->new(docx => $docx);
  }

  # now call the regular Moose method
  return $class->$orig(%args);
};


#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================


sub _engine {
  my ($self) = @_;

  # instantiate the templating engine
  my $engine_class = $self->engine_class;
  my $engine;
  my @load_errors;
 CLASS:
  for my $class ("MsOffice::Word::Template::Engine::$engine_class", $engine_class) {
    eval "require $class; 1"                        or  push @load_errors, $@ and next CLASS;
    $engine = $class->new(word_template => $self,
                          $self->engine_args->@*)                             and last CLASS;
  }
  $engine or die "could not load engine class '$engine_class'", @load_errors;

  return $engine;
}



#======================================================================
# PROCESSING THE TEMPLATE
#======================================================================

sub process {
  my ($self, $vars) = @_;

  # create a clone of the original 
  my $new_doc = $self->surgeon->clone;

  # process each package part
  foreach my $part_name ($self->part_names->@*) {
    my $new_doc_part = $new_doc->part($part_name);
    my $new_contents = $self->engine->process_part($part_name, $new_doc_part, $vars);
    $new_doc_part->contents($new_contents);
  }

  # process the property files (core.xml, app.xml. custom.xml -- if present in the original word template)
  foreach my $property_file ($self->property_files->@*) {
    if ($self->surgeon->zip->memberNamed($property_file)) {
      my $new_contents = $self->engine->process($property_file, $vars);
      $new_doc->xml_member($property_file, $new_contents);
    }
  }

  return $new_doc;
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Template - generate Microsoft Word documents from Word templates

=head1 SYNOPSIS

  my $template = MsOffice::Word::Template->new($filename);
  my $new_doc  = $template->process(\%data);
  $new_doc->save_as($path_for_new_doc);

=head1 DESCRIPTION

=head2 Purpose

This module treats a Microsoft Word document as a template for generating other documents. The idea is
similar to the "mail merge" functionality in Word, but with much richer possibilities. The
whole power of a Perl templating engine can be exploited, for example for

=over

=item *

dealing with complex, nested datastructures

=item *

using control directives for loops, conditionals, subroutines, etc.

=item *

defining custom data processing functions or macros

=back


Template authors just use basic highlighing in MsWord to
mark the templating directives :

=over

=item *

fragments highlighted in B<yelllow> are interpreted as I<data>
directives, i.e. the template result will be inserted at that point in
the document, keeping the current formatting properties (bold, italic,
font, etc.).

=item *

fragments highlighted in B<green> are interpreted as I<control>
directives that do not directly generate content, like loops, conditionals,
etc. Paragraphs or table rows around such directives are dismissed,
in order to avoid empty paragraphs or empty rows in the resulting document.

=back

The syntax of data and control directives depends on the backend
templating engine.  The default engine is the L<Perl Template Toolkit|Template>;
other engines can be specified as subclasses -- see the L</TEMPLATE ENGINE> section below.


=head2 Status

This distribution is a major refactoring
of the first version, together with a refactoring of
L<MsOffice::Word::Surgeon>. New features include support for headers
and footers, for metadata and for image insertion. The internal
object-oriented structure has been redesigned.

This module has been used successfully for a pilot project in my
organization, generating quite complex documents from deeply nested
datastructures.  However it has not been used yet at large scale in
production, so it is quite likely that some youth defects may still be
discovered.  If you use this module, please keep me informed of your
difficulties, tricks, suggestions, etc.


=head1 METHODS

=head2 new

  my $template = MsOffice::Word::Template->new($docx);
  # or : my $template = MsOffice::Word::Template->new($surgeon);   # an instance of MsOffice::Word::Surgeon
  # or : my $template = MsOffice::Word::Template->new(docx => $docx, %options);

In its simplest form, the constructor takes a single argument which
is either a string (path to a F<docx> document), or an instance of
L<MsOffice::Word::Surgeon>. Otherwise the constructor takes a list of named parameters,
which can be


=over

=item docx

path to a MsWord document in F<docx> format. This will automatically create
an instance of L<MsOffice::Word::Surgeon> and pass it to the constructor
through the C<surgeon> keyword.

=item surgeon

an instance of L<MsOffice::Word::Surgeon>. This is a mandatory parameter, either
directly through the C<surgeon> keyword, or indirectly through the C<docx> keyword.

=item data_color

the Word highlight color for marking data directives (default : yellow)

=item control_color

the Word highlight color for marking control directives (default : green).
Such directives should produce no content. They are treated outside of the regular text flow.

=item part_names

an arrayref to the list of package parts to be processed as templates within the C<.docx>
ZIP archive. The default list is the main document (C<document.xml>), together with all
headers and footers found in the ZIP archive.

=item property_files

an arrayref to the list of property files (i.e. metadata) to be processed as templates within the C<.docx>
ZIP archive. For historical reasons, MsWord has three different XML files for storing document
properties : C<core.xml>, C<app.xml> and C<custom.xml> : the default list contains those
three files. Supply an empty list if you don't want any document property to be processed.


=back

In addition to the attributes above, other attributes can be passed to the
constructor for specifying a templating engine different from the 
default L<Perl Template Toolkit|Template>.
These are described in section L</TEMPLATE ENGINE> below.


=head2 process

  my $new_doc = $template->process(\%data);
  $new_doc->save_as($path_for_new_doc);

Processes the template on a given data tree, and returns a new document
(actually, a new instance of L<MsOffice::Word::Surgeon>).
That document can then be saved  using L<MsOffice::Word::Surgeon/save_as>.


=head1 AUTHORING TEMPLATES

=head2 Textual content

A template is just a regular Word document, in which the highlighted
fragments represent templating directives.

The data directives, i.e. the "holes" to be filled must be highlighted
in B<yellow>. Such zones must contain the names of variables to fill the
holes. If the template engine supports it, names of variables can be paths
into a complex datastructure, with dots separating the levels, like
C<foo.3.bar.-1> -- see L<Template::Manual::Directive/GET> and
L<Template::Manual::Variables> if you are using the Template Toolkit.

Control directives like C<IF>, C<FOREACH>, etc. must be highlighted in
B<green>. When seeing a green zone, the system will remove XML markup for
the surrounding text and run nodes. If the directive is the only content
of the paragraph, then the paragraph node is also removed. If this
occurs within the first cell of a table row, the markup for that row is also
removed. This mechanism ensures that the final result will not contain
empty paragraphs or empty rows at places corresponding to control directives.

In consequence of this distinction between yellow and green
highlights, templating zones cannot mix data directives with control
directives : a data directive within a green zone would generate output
outside of the regular XML flow (paragraph nodes, run nodes and text
nodes), and therefore MsWord would generate an error when trying to
open such content. There is a workaround, however : data directives
within a green zone will work if they I<also generate the appropriate markup>
for paragraph nodes, run nodes and text nodes.

To highlight using LibreOffice, set the Character Highlighting to Export As
"Highlighting" instead of the default "Shading". See
L<https://help.libreoffice.org/7.5/en-US/text/shared/optionen/01130200.html|LibreOffice help for MS Office>.


See also L<MsOffice::Word::Template::Engine::TT2> for
additional advice on authoring templates based on the
L<Template Toolkit|Template>.


=head2 Images

Insertion of generated images such as barcodes is done in two steps:

=over

=item *

the template must contain a I<placeholder image> : this is an arbitrary image,
positioned within the document through usual MsWord commands, including alignment
instructions, border, etc. That image must be given an I<alternative text> -- see
L<https://support.microsoft.com/en-us/office/add-alternative-text-to-a-shape-picture-chart-smartart-graphic-or-other-object-44989b2a-903c-4d9a-b742-6a75b451c669|MsOffice documentation>). That text 
will be used as a unique identifier for the image.

=item *

somewhere in the document (it doesn't matter where), a directive
must replace the placeholder image by a generated image.
For example for a barcode, the TT2 directive looks like :

  [[ PROCESS barcode type="QRCode" img="my_image_name" content="some value for the QR code" ]]

See L<MsOffice::Word::Template::Engine::TT2/barcodes> for details. The source
code can be used as an example of how to implement other image generating blocks.

=back

=head2 Metadata (also known as "document properties" in MsWord parlance)

MsWord documents store metadata, also called "document properties". Each property
has a name and a value. A number of property names are builtin, like 'author' or 'description';
other custom properties can be defined. Properties are edited from the MsWord 
"Backstage view" (the screen displayed after a click on the File tab).

For feeding values into document properties, just use the regular syntax of
the templating engine. For example with the default Template Toolkit engine,
directives are enclosed in C<'[% '> and C<' %]'>; so you can write

  [% path.to.subject.data %]

within the 'subject' property of the MsWord template, and the resulting document
will have its subject filled with the given data path.

Obviously, the reason for this different mechanism is that MsWord has no support
for highlighting contents in property values.

Unfortunately, this mechanism only works for document properties of type 'string'.
MsWord would not allow specific templating syntax within fields of type
boolean, number or date.



=head1 TEMPLATE ENGINE

This module invokes a backend I<templating engine> for interpreting the
template directives. The default engine is
L<MsOffice::Word::Template::Engine::TT2>, built on top of
L<Template Toolkit|Template>. Another engine supplied in this distribution is
L<MsOffice::Word::Template::Engine::Mustache>, mostly as an example.
To implement another engine, just subclass
L<MsOffice::Word::Template::Engine>.

To use an engine different from the default, the following arguments
must be supplied to the L</new> method :

=over

=item engine_class

The name of the engine class. If the class sits within the L<MsOffice::Word::Template::Engine>
namespace, just the suffix is sufficient; otherwise, specify the fully qualified class name.

=item engine_args

An optional list of parameters that may be used for initializing the engine

=back

After initialization the engine will receive a C<compile_template> method call for each part in the
C<.docx> package. The default parts to be handled are the main document body (C<document.xml>), and
all headers and footers. A different list of package parts can be supplied through the
C<part_names> argument to the constructor.

In addition to the package parts, templates are also compiled for the I<property> files that contain
metadata such as author name, subject, description, etc. The list of files can be controlled through
the C<property_files> argument to the constructor.

When processing templates, the engine must make sure that ampersand
characters and angle brackets are automatically replaced by the
corresponding HTML entities (otherwise the resulting XML would be
incorrect and could not be opened by Microsoft Word).
The L<Mustache engine|MsOffice::Word::Template::Engine::Mustache> does this
automatically.
The L<Template Toolkit engine|MsOffice::Word::Template::Engine::TT2>
would normally require to
explicitly add an C<html> filter at each directive :

  [% foo.bar | html %]

but thanks to the L<Template::AutoFilter>
module, this is performed automatically.

=head1 TROUBLESHOOTING

If a document generated by this module cannot open in Word, it is probably because the XML
generated by your template is not equilibrated and therefore not valid.
For example a template like this :

  This paragraph [[ IF condition ]]
     may have problems
  [[END]]

is likely to generate incorrect XML, because the IF statement starts in the middle
of a paragraph and closes at a different paragraph -- therefore when the I<condition>
evaluates to false, the XML tag for closing the initial paragraph will be missing.

Compound directives like IF .. END, FOREACH .. END,  TRY .. CATCH .. END should therefore
be equilibrated, either all within the same paragraph, or each directive on a separate
paragraph. Examples like this should be successful :

  This paragraph [[ IF condition ]]has an optional part[[ ELSE ]]or an alternative[[ END ]].
  
  [[ SWITCH result ]]
  [[ CASE 123 ]]
     Not a big deal.
  [[ CASE 789 ]]
     You won the lottery.
  [[ END ]]



=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020-2024 by Laurent Dami.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.



