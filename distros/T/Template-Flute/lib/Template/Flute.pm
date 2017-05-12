package Template::Flute;

use strict;
use warnings;

use Carp;
use Module::Runtime qw/use_module/;
use Scalar::Util qw/blessed/;
use Template::Flute::Utils;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;
use Template::Flute::Iterator;
use Template::Flute::Iterator::Cache;
use Template::Flute::Increment;
use Template::Flute::Pager;
use Template::Flute::Paginator;
use Template::Flute::Types -types;

use Moo;
use namespace::clean;

=head1 NAME

Template::Flute - Modern designer-friendly HTML templating Engine

=head1 VERSION

Version 0.025

=cut

our $VERSION = '0.025';

=head1 SYNOPSIS

    use Template::Flute;

    my ($cart, $flute, %values);

    $cart = [{...},{...}];
    $values{cost} = ...

    $flute = new Template::Flute(specification_file => 'cart.xml',
                           template_file => 'cart.html',
                           iterators => {cart => $cart},
                           values => \%values,
                           autodetect => {
                                          disable => [qw/Foo::Bar/],
                                         }
                           );

    print $flute->process();

=head1 DESCRIPTION

Template::Flute enables you to completely separate web design and programming
tasks for dynamic web applications.

Templates are designed to be designer-friendly; there's no inline code or mini
templating language for your designers to learn - instead, standard HTML and CSS
classes are used, leading to HTML that can easily be understood and edited by
WYSIWYG editors and hand-coding designers alike.

An example is easier than a wordy description:

Given the following template snippet:

    <div class="customer_name">Mr A Test</div>
    <div class="customer_email">someone@example.com</div>

and the following specification:

   <specification name="example" description="Example">
        <value name="customer_name" />
        <value name="email" class="customer_email" />
    </specification>

Processing the above as follows:

    $flute = Template::Flute->new(
        template_file      => 'template.html',
        specification_file => 'spec.xml',
    );
    $flute->set_values({
        customer_name => 'Bob McTest',
        email => 'bob@example.com',
    });;
    print $flute->process;

The resulting output would be:

    <div class="customer_name">Bob McTest</div>
    <div class="email">bob@example.com</div>


In other words, rather than including a templating language within your
templates which your designers must master and which could interfere with
previews in WYSIWYG tools, CSS selectors in the template are tied to your
data structures or objects by a specification provided by the programmer.


=head2 Workflow

The easiest way to use Template::Flute is to pass all necessary parameters to
the constructor and call the process method to generate the HTML.

You can also break it down in separate steps:

=over 4

=item 1. Parse specification

Parse specification based on your specification format (e.g with
L<Template::Flute::Specification::XML> or L<Template::Flute::Specification::Scoped>.).

    $xml_spec = new Template::Flute::Specification::XML;
    $spec = $xml_spec->parse(q{<specification name="cart" description="Cart">
         <list name="cart" class="cartitem" iterator="cart">
         <param name="name" field="title"/>
         <param name="quantity"/>
         <param name="price"/>
         </list>
         <value name="cost"/>
         </specification>});

=item 2. Parse template

Parse template with L<Template::Flute::HTML> object.

    $template = new Template::Flute::HTML;
    $template->parse(q{<html>
        <head>
        <title>Cart Example</title>
        </head>
        <body>
        <table class="cart">
        <tr class="cartheader">
        <th>Name</th>
        <th>Quantity</th>
        <th>Price</th>
        </tr>
        <tr class="cartitem">
        <td class="name">Sample Book</td>
        <td><input class="quantity" name="quantity" size="3" value="10"></td>
        <td class="price">$1</td>
        </tr>
        <tr class="cartheader"><th colspan="2"></th><th>Total</th>
        </tr>
        <tr>
        <td colspan="2"></td><td class="cost">$10</td>
        </tr>
        </table>
        </body></html>},
        $spec);

=item 3. Produce HTML output

    $flute = new Template::Flute(template => $template,
                               iterators => {cart => $cart},
                               values => {cost => '84.94'});
    $flute->process();

=back

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute object with the following parameters:

=over 4

=item specification_file

Specification file name.

=item specification_parser

Select specification parser. This can be either the full class name
like C<MyApp::Specification::Parser> or the last part for classes residing
in the Template::Flute::Specification namespace.

=item specification

Specification object or specification as string.

=item template_file

HTML template file.

=item template

L<Template::Flute::HTML> object or template as string.

=item filters

Hash reference of filter functions.

=item i18n

L<Template::Flute::I18N> object.

=item translate_attributes

An arrayref of attribute names to translate. If the name has a dot, it
is interpreted as tagname + attribute, so C<placeholder>" will
unconditionally translate all the placeholders, while
C<input.placeholder> only the placeholder found on the input tag.

Additional dotted values compose conditions for attributes. E.g.
C<input.value.type.submit> means all the value attributes with
attribute C<type> set to C<submit>.

Defaults to C<['input.value.type.submit', 'placeholder']>

=item iterators

Hash references of iterators.

=item values

Hash reference of values to be used by the process method.

=item auto_iterators

Builds iterators automatically from values.

=item autodetect

A configuration option. It should be an hashref with a key C<disable>
and a value with an arrayref with a list of B<classes> for objects
which should be considered plain hashrefs instead. Example:

  my $flute = Template::Flute->new(....
                                   autodetect => { disable => [qw/My::Object/] },
                                   ....
                                  );

Doing so, if you pass a value holding a C<My::Object> object, and you have a specification with something like this:

  <specification>
   <value name="name" field="object.method"/>
  </specification>

The value will be C<$object->{method}>, not C<$object->$method>.

The object is checked with C<isa>.

Classical example: C<Dancer::Session::Abstract>.

=item uri

Base URI for your template. This adjusts the links in the HTML tags
C<a>, C<base>, C<img>, C<link> and C<script>.

=item email_cids

This is meant to be used on HTML emails. When this is set to an hash
reference (which should be empty), the hash will be populated with the
following values:

  cid1 => { filename => 'foo.png' },
  cid2 => { filename => 'foo2.gif' },

and in the body the images C<src> attribute will be replaced with
C<cid:cid1>.

The cid names are arbitrary and assigned by the template. The code
should look at the reference values which were modified.

=item cids

Optional hashref with options for the CID replacement behaviour.

By default, if the source looks like an HTTP/HTTPS URI, the image
source is not altered and no CID is assigned.

If you pass a C<base_url> value in this hashref, the URI matching it
will be converted to cids and the rest of the path will be added to
the C<email_cids> hashref.

Example:

    my $cids = {};
    $flute = Template::Flute->new(template => $template,
                                  specification => $spec,
                                  email_cids => $cids,
                                  cids => {
                                           base_url => 'http://example.com/'
                                          });

Say the template contains images with source
C<http://example.com/image.png>, the C<email_cids> hashref will
contain a cid with C<filename> "image.png".

=back

=cut

# Constructor

has autodetect => (
    is  => 'ro',
    isa => HashRef,
);

has auto_iterators => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has cids => (
    is  => 'ro',
    isa => HashRef,
);

has email_cids => (
    is  => 'ro',
    isa => HashRef,
);

has filters => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has _filter_class => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has _filter_objects => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has _filter_opts => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has _filter_subs => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

# FIXME: (SysPete 28/4/16) find & fix code that passes in i18n as undef
has i18n => (
    is  => 'ro',
    isa => Maybe[InstanceOf ['Template::Flute::I18N']],
);

has iterators => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    default => sub { +{} },
);

has patterns => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { +{} },
    init_arg => undef,
);

has scopes => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _specification => (
    is       => 'ro',
    isa      => Specification | Str,
    init_arg => 'specification',
);

# FIXME: (SysPete 28/4/16) Due to GH#54 (see below) we need a writer which
# we'll make private
has specification => (
    is       => 'rwp',
    isa      => Specification,
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $ret;

        if ( ref( $self->_specification ) ) {
            $ret = $self->_specification;
        }
        else {
            my $parser_spec = use_module( $self->specification_parser )->new;

            if ( $self->_specification ) {
                $ret = $parser_spec->parse( $self->_specification );
            }
            else {
                $ret = $parser_spec->parse_file( $self->specification_file );
            }

            croak "Error parsing specification: ", $parser_spec->error
              unless $ret;
        }

        # copy iterators into specification
        while ( my ( $name, $iter ) = each %{ $self->iterators } ) {
            $ret->set_iterator( $name, $iter );
        }

        # copy patterns from specification
        if ( my %patterns = $ret->patterns ) {
            foreach my $k ( keys %patterns ) {
                $self->_set_pattern( $k, $patterns{$k} );
            }
        }

        return $ret;
    },
);

has specification_file => (
    is      => 'ro',
    isa     => ReadableFilePath,
    lazy    => 1,
    default => sub {
        my $self = shift;

        croak "No template_file supplied so cannot determine specification_file"
          unless $self->template_file;

        Template::Flute::Utils::derive_filename( $self->template_file, '.xml' );
    },
);

has specification_parser => (
    is      => 'ro',
    isa     => Str,
    default => 'Template::Flute::Specification::XML',
    coerce  => sub {
        $_[0] =~ /::/ ? $_[0] : "Template::Flute::Specification::$_[0]";
    },
);

has _template => (
    is       => 'ro',
    isa      => HtmlParser | Str,
    init_arg => 'template',
);

has template => (
    is       => 'ro',
    isa      => HtmlParser,
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;

        return $self->_template if ref( $self->_template );

        my $template_object = Template::Flute::HTML->new(uri => $self->uri);

        if ( $self->_template ) {
            $template_object->parse(
                $self->_template, $self->specification
            );
        }
        else {
            $template_object->parse_file(
                $self->template_file, $self->specification
            );
        }

        return $template_object;
    },
);

has template_file => (
    is  => 'ro',
    isa => Str,
);

has translate_attributes => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [ 'placeholder', 'input.value.type.submit' ] },
);

# FIXME: (SysPete 28/4/16) find & fix code that passes in uri as undef
# FIXME: (SysPete 28/4/16) perhaps stringify in coerce so we don't have
# to accept URI objects?
has uri => (
    is  => 'ro',
    isa => Maybe [ InstanceOf ['URI'] | Str ],
);

has values => (
    is      => 'ro',
    isa     => HashRef,
    writer  => 'set_values',
    default => sub { +{} },
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;

    croak "Either 'template' or 'template_file' must be supplied"
      unless ( exists $args{template} || exists $args{template_file} );

    # build the various _filter_* attributes
    while ( my ( $name, $value ) = each %{ $args{filters} } ) {
        if ( ref($value) eq 'CODE' ) {
            # passing subroutine
            $args{_filter_subs}->{$name} = $value;
            next;
        }
        if ( exists( $value->{class} ) ) {
            # record filter class
            $args{_filter_class}->{$name} = $value->{class};
        }
        if ( exists( $value->{options} ) ) {
            # record filter options
            $args{_filter_opts}->{$name} = $value->{options};
        }
    }

    return \%args;
}

sub BUILD {
    my $self = shift;
    # catch exception in lazy builders early by forcing template to build now
    $self->template;
}

sub _get_pattern {
    my ($self, $name) = @_;
    return $self->patterns->{$name};
}

sub _set_pattern {
    my ($self, $name, $regexp) = @_;
    croak "Missing pattern name" unless $name;
    croak "pattern $name already exists!" if $self->patterns->{$name};
    croak "Missing pattern regexp for $name" unless $regexp;
    $self->patterns->{$name} = $regexp;
}

=head1 METHODS

=head2 BUILD

Force creation of template class as soon as object is instantiated.

=head2 process [HASHREF]

Processes HTML template, manipulates the HTML tree based on the
specification, values and iterators.

Returns HTML output.

=cut

sub process {
	my ($self, $params) = @_;

	if ($self->i18n) {
		# translate static text first
		$self->template->translate($self->i18n, @{$self->translate_attributes});
	}

	my $html = $self->_sub_process(
		$self->template->{xml},
		$self->specification->{xml}->root,
		$self->values,
		$self->specification,
		$self->template,
        0,
        0,
		);

    if ($self->email_cids) {
        $self->_cidify_html($html);
    }
	my $shtml = $html->sprint;
	return $shtml;
}

sub _cidify_html {
    my ($self, $html) = @_;

    my %options;
    if ($self->cids) {
        %options = %{ $self->cids };
    }

    foreach my $img ($html->descendants('img')) {
        my $source = $img->att('src');

        if (defined $source && $source =~ /\S/ && $source !~ /^cid:/) {
            my $cid = $source;
            # to generate a cid, remove every character save for [a-zA-Z0-9]
            # and use that.
            $cid =~ s/[^0-9A-Za-z]//g;
            next unless $cid;

            # before processing, check what we have in the src
            # url:
            my $filename;
            if ($source =~ m!https?://!) {
                if (my $base = $options{base_url}) {
                    if ($source =~ m/^\s*\Q$base\E(.+?)\s*$/s) {
                        $filename = $1;
                    }
                }
            }
            else {
                $filename = $source;
            }

            # found? cidify the source
            if ($filename) {
                $img->set_att(src => "cid:$cid");
                $self->email_cids->{$cid} = { filename => $filename };
            }
        }
    }
}

sub _sub_process {
	my ($self, $html, $spec_xml,  $values, $spec, $root_template, $count, $level) = @_;
	my ($template, %list_active);
	# Use root spec or sub-spec
    my $specification = $spec
      || use_module( $self->specification_parser )->new()
      ->parse( "<specification>" . $spec_xml->sprint . "</specification>" );

	if($root_template){
		$template = $root_template;
	}
	else {
		$template = Template::Flute::HTML->new();;
		$template->parse("<flutexml>".$html->sprint."</flutexml>", $specification, 1);
	}

	my $classes = $specification->{classes};
	my ($dbobj, $iter, $sth, $row, $lel, $query, %skip, %iter_names);

	# Read one layer of spec
	my $spec_elements = {};
	for my $elt ( $spec_xml->descendants() ){
		my $type = $elt->tag;
		$spec_elements->{$type} ||= [];

        # check whether to skip sublists on this level
        if ($type eq 'list') {
            if ($elt->parent->tag eq 'list'
                    && $elt->parent ne $spec_xml) {
                $skip{$elt} = 1;
            }
            else {
                push @{$iter_names{$elt->att('iterator')}}, $elt;
            }
        }
		push @{$spec_elements->{$type}}, $elt;

	}

    while (my ($name, $value) = each %iter_names) {
        next if $name =~ /\./;

        if (@$value > 1) {
            my $iter_cached = Template::Flute::Iterator::Cache->new(
                iterator => $specification->iterator($name),
            );
            $specification->set_iterator($name, $iter_cached);
        };
    }

    my $cut_container = 0;

    # cut the elts in the template, *before* processing the lists
    if ($level == 0) {
        for my $container ($template->containers()) {
            next if $container->list;

            $container->set_values($values) if $values;
            unless ($container->visible()) {
                for my $elt (@{$container->elts()}) {
                    $elt->cut();
                }
            }
        }
    }
    elsif ($spec_xml->gi eq 'list') {
        # we check whether the container is a child of this list
        for my $container ($template->containers()) {
            next if $container->list ne $spec_xml->att('name');

            $container->set_values($values) if $values;
            unless ($container->visible()) {
                $cut_container = 1;
                for my $elt (@{$container->elts()}) {
                    $elt->cut();
                }
            }
        }
    }

	# List
	for my $elt ( @{$spec_elements->{list}} ) {
        next if exists $skip{$elt};

		my $spec_name = $elt->{'att'}->{'name'};
		my $spec_class = $elt->{'att'}->{'class'} ? $elt->{'att'}->{'class'} : $spec_name;
		my $sep_copy;
		my $iterator = $elt->{'att'}->{'iterator'} || '';
		my $sub_spec = $elt->copy();
		my $element_template = $classes->{$spec_class}->[0]->{elts}->[0];

		unless($element_template){
			next;
		}

        # collect the list of classes to see if the separator is
        # inside or outside the list element
        my %children_classes;
        foreach my $child_element ($element_template->children) {
            if (my $c = $child_element->att('class')) {
                $children_classes{$c} = 1;
            }
        }

        # determine where to paste
		my ($list_paste_to, $paste_operation);
        # if last child, append
		if ($element_template->is_last_child) {
            $list_paste_to = $element_template->parent;
            $paste_operation = 'last_child';
        }
        # if there is material, before the template element (we will cut that later)
        elsif ($element_template->next_sibling) {
            $list_paste_to = $element_template;
            $paste_operation = 'before';
        }
        else {
            # list is root element in the template
            $list_paste_to = $html;
            $paste_operation = 'last_child';
        }

        my @iter_steps = split(/\./, $iterator);
        my $iter_ref = $values;
        my $records;
        my $spec_iter = $specification->iterator($iterator);

        if ($spec_iter) {
            $iter_ref->{$iterator} = $spec_iter;
        }

        for my $step (@iter_steps) {
            if (defined blessed $iter_ref) {
                $records = $iter_ref->$step;
                $iter_ref = {};
            }
            elsif (ref($iter_ref->{$step})) {
                $records = $iter_ref->{$step};
                $iter_ref = $iter_ref->{$step};
            }
            else {
                $records = $iter_ref->{$step};
                $iter_ref = {};
            }
        }

		my $list = $template->{lists}->{$spec_name};
		my $count = 1;
        my $iter_records;

        if (defined blessed $records) {
            # check whether this object can serve as iterator
            if ($records->can('next') && $records->can('count')) {
                $iter_records = $records;
            }
            else {
                croak "Object cannot be used as iterator for list $spec_name: ", ref($records);
            }
        }
        else {
            $iter_records = Template::Flute::Iterator->new(@$records);
        }

        if ($list->{paging}) {
            $iter_records->reset;
            # replace the iterator with the paginator
            $iter_records = $self->_paging($list, $iter_records);
        }



        if ($iter_records->count) {
            $list_active{$spec_name} = 1;
        }
        else {
            $list_active{$spec_name} = 0;
        }

        my $count_iterations = 0;
		while (my $record_values = $iter_records->next) {

            $count_iterations++;
            last
                if defined $list->{limit}
                && $count_iterations > $list->{limit};

            # cut the separators away before copying
            for my $sep (@{$list->{separators}}) {
                for my $elt (@{$sep->{elts}}) {
                    $elt->cut();
                }
            }

			my $element = $element_template->copy();

            # make sure that we save and restore specification object
            # otherwise it would be overwritten and can cause weird
            # errors (GH #54)

            my $old_spec = $self->specification;
			$element = $self->_sub_process($element, $sub_spec, $record_values, undef, undef, $count, $level + 1);
            $self->_set_specification($old_spec);

			# Get rid of flutexml container and put it into position
			my $current;
			for my $e (reverse($element->cut_children())) {
				$e->paste($paste_operation, $list_paste_to);
				$current = $e;
       		}

			# Add separator
			if ($current && $list->{separators}) {
			    for my $sep (@{$list->{separators}}) {

                    if (my $every_x = $sep->{every}) {
                        unless ($count_iterations % $every_x == 0) {
                            # prevent the last separator to be removed
                            # if not last element.
                            $sep_copy = undef;
                            next;
                        }
                    }
					for my $elt (@{$sep->{elts}}) {
					    $sep_copy = $elt->copy();
                        my $operation = 'after';
                        if ($children_classes{$sep_copy->att('class')}) {
                            $operation = 'last_child';
                        }
					    $sep_copy->paste($operation, $current);
					    last;
					}
			    }
			}
			$count++;
		}

        if (blessed $spec_iter && $spec_iter->isa('Template::Flute::Iterator::Cache')) {
            $spec_iter->reset;
        }

		$element_template->cut(); # Remove template element

        if ($sep_copy) {
            # Remove last separator and original one(s) in the template
            $sep_copy->cut();

        }
    }

	# Values
	for my $elt ( @{$spec_elements->{value}}, @{$spec_elements->{param}}, @{$spec_elements->{field}} ){
        if ($elt->tag eq 'param') {
            my $name = $spec_xml->att('name');

            # skip params on top level
            next unless defined $name;

            my $parent_name;
            if ($elt->parent->gi eq 'container') {
                next if $cut_container;
                $parent_name = $name;
            }
            else {
                $parent_name = $elt->parent->att('name');
            }

            if ($name ne $parent_name) {
                # don't process params of sublists again
                next;
            }

            if (exists $list_active{$parent_name} && ! $list_active{$parent_name}) {
                # don't process params for empty lists
                 next;
            }
        }
		my $spec_id = $elt->{'att'}->{'id'};
		my $spec_name = $elt->{'att'}->{'name'};
		my $spec_class = $elt->{'att'}->{'class'} ? $elt->{'att'}->{'class'} : $spec_name;

		# Use CLASS or ID if set
		my $spec_clases = [];
		if ($spec_id){
			$spec_clases = $specification->{ids}->{$spec_id};
		}
		else {
			$spec_clases = $classes->{$spec_class};
		}

		for my $spec_class (@$spec_clases){
            # check if it's a form and it's already filled
            if (exists $spec_class->{form} && $spec_class->{form}) {
                my $form = $self->template->form($spec_class->{form});
                next if $form && $form->is_filled;
            }
            # check if we need an iterator for this element
            if ($self->auto_iterators && $spec_class->{iterator}) {
                my ($iter_name, $iter);

                $iter_name = $spec_class->{iterator};

                unless ($specification->iterator($iter_name)) {
		    my $maybe_iter = $self->values->{$iter_name};

		    if (defined blessed $maybe_iter) {
			if ($maybe_iter->can('next') &&
			    $maybe_iter->can('count')) {
			    $iter = $maybe_iter;
			}
			else {
			    croak "Object cannot be used as iterator for value $spec_name: ", ref($maybe_iter);
			}
		    }
                    elsif (ref($self->values->{$iter_name}) eq 'ARRAY') {
                        $iter = Template::Flute::Iterator->new($self->values->{$iter_name});
                    }
                    else {
                        $iter = Template::Flute::Iterator->new([]);
                    }

                    $specification->set_iterator($iter_name, $iter);
                }
            }

			# Increment count
			$spec_class->{increment} = Template::Flute::Increment->new(
				increment => $spec_class->{increment}->{increment},
				start => $count
			) if $spec_class->{increment};

            my $field = $spec_class->{'field'};

            if (defined $field && ! ref($field) && $field =~ /\./) {
                $spec_class->{'field'} = [split /\./, $field];
            }

			$self->_replace_record($spec_name, $values, $spec_class, $spec_class->{elts});
		}
	}

    # cut again the invisible containers, after the values are interpolated
    if ($level == 0) {
        for my $container ($template->containers()) {
            unless ($container->visible()) {
                for my $elt (@{$container->elts()}) {
                    $elt->cut();
                }
            }
        }
    }

	return $count ? $template->{xml}->root() : $template->{xml};
}

sub _replace_within_elts {
	my ($param, $rep_str, $elt_handler, $elts) = @_;
	my ($name, $zref);
	for my $elt (@$elts) {
	    if ($elt_handler) {
		$elt_handler->($elt, $rep_str);
		next;
	    }

		$name = $param->{name};
		$zref = $elt->{"flute_$name"};

        if (! $elt->parent && $elt->former_parent) {
            # paste back a formerly cut element
            my $pos;

            if (($pos = $elt->former_prev_sibling) && $pos->parent) {
                $elt->paste(after => $pos);
            }
            else {
                $elt->paste(first_child => $elt->former_parent);
            }
        }

		if ($zref->{rep_sub}) {
			# call subroutine to handle this element
			$zref->{rep_sub}->($elt, $rep_str);
		} elsif ($zref->{rep_att}) {
			# replace attribute instead of embedded text (e.g. for <input>)
            foreach my $replace_attr (_expand_elt_attributes($elt, $zref->{rep_att})) {
                if (exists $param->{op}) {
                    if ($param->{op} eq 'toggle') {
                        if ($rep_str) {
                            $elt->set_att($replace_attr);
                        }
                        else {
                            $elt->del_att($replace_attr);
                        }
                        next;
                    }

                    my $original_attribute = '';

                    if (exists $zref->{rep_att_orig}->{$replace_attr}) {
                        $original_attribute = $zref->{rep_att_orig}->{$replace_attr};
                    }

                    if (exists $param->{joiner}) {
                        if ($rep_str) {
                            if ($param->{op} eq 'append') {
                                $elt->set_att($replace_attr, $original_attribute . $param->{joiner} . $rep_str);
                            }
                            elsif ($param->{op} eq 'prepend') {
                                $elt->set_att($replace_attr, $rep_str . $param->{joiner} . $original_attribute);
                            }
                        }
                    }
                    else {
                        my $rep_str_new;

                        if ($param->{op} eq 'append') {
                            $rep_str_new = $rep_str ? ($original_attribute . $rep_str) : $original_attribute;
                        }
                        elsif ($param->{op} eq 'prepend') {
                            $rep_str_new = $rep_str ? ($rep_str . $original_attribute) : $original_attribute;
                        }

                        $elt->set_att($replace_attr, $rep_str_new);
                    }
                    next;
                }

                if (defined $rep_str) {
                    $elt->set_att($replace_attr, $rep_str);
                }
                else {
                    $elt->del_att($replace_attr);
                }
             }
		} elsif ($zref->{rep_elt}) {
			# use provided text element for replacement
			$zref->{rep_elt}->set_text($rep_str);
		} else {
        	$elt->set_text($rep_str) if defined $rep_str;
		}
	}
}

=head2 process_template

Processes HTML template and returns L<Template::Flute::HTML> object.

=cut

sub process_template {
	my ($self) = @_;

#	unless ($self->{template}) {
#		$self->_bootstrap();
#	}

	return $self->template;
}


sub _replace_record {
	my ($self, $name, $values, $value, $elts) = @_;
	my ($key, $filter, $att_name, $att_spec,
		$att_tag_name, $att_tag_spec, %att_tags,  $elt_handler, $raw, $rep_str,);

		# determine value used for replacements
		$rep_str = $self->value($value, $values);
		#return undef if ((not defined $rep_str) and (defined $value->{target}));
		$raw = $rep_str;
    if ($self->_value_should_be_skipped($value, $rep_str)) {
        # do nothing
        return;
    }

		if (exists $value->{op}) {
            if ($value->{op} eq 'toggle' && ! $value->{target}) {
                if (exists $value->{args} && $value->{args} eq 'static') {
                    if ($rep_str) {
                        # preserve static text, like a container
                        return;
                    }
                }

                unless ($raw) {
                    # remove corresponding HTML elements from tree
                    for my $elt (@$elts) {
                        $elt->cut();
                    }
                    return;
                }
                $rep_str = '' unless defined $rep_str;
		    }
		    elsif ($value->{op} eq 'hook') {
                for my $elt (@$elts) {
                    Template::Flute::HTML::hook_html($elt, $rep_str);
                }
		    }
		    elsif (ref($value->{op}) eq 'CODE') {
                $elt_handler = $value->{op};
		    }
		}
		#debug "$name has value ";
		#debug "'$rep_str'";

		# Template specified value if value defined
		if ($value->{value}) {
            if ($rep_str) {
            	$rep_str = $value->{value};
            }
            else {
            	$rep_str = '';
            }
        }

    if (my $pattern = $value->{pattern}) {
        if (my $regexp = $self->_get_pattern($pattern)) {
            # if the value has a target operate on that attribute, otherwise
            # operate on the text, as expected
            if (my $attribute = $value->{target}) {
                $elt_handler = sub {
                    my ($elt, $string) = @_;
                    if (!defined($string)) {
                        $string = '';
                    }
                    foreach my $att (_expand_elt_attributes($elt, $attribute)) {
                        my $newtext = $elt->att($att);
                        if (!defined($newtext)) {
                            $newtext = '';
                        }
                        $newtext =~ s/$regexp/$string/g;
                        $elt->set_att($att, $newtext)
                    };
                };
            }
            else {
                $elt_handler = sub {
                    my ($elt, $string) = @_;
                    if (!defined($string)) {
                        $string = '';
                    }
                    my $newtext = $elt->text;
                    if (!defined($newtext)) {
                        $newtext = '';
                    }
                    $newtext =~ s/$regexp/$string/g;
                    $elt->set_text($newtext);
                };
            }
        }
        else {
            croak "No pattern named $pattern!";
        }

    }


		if ($value->{increment}) {
			$rep_str = $value->{increment}->value();
			$value->{increment}->increment();
		}
		#return undef unless defined $rep_str;

		if (ref($value->{op}) eq 'CODE') {
		    _replace_within_elts($value, $rep_str, $value->{op}, $elts);
		}
		else {
		    _replace_within_elts($value, $rep_str, $elt_handler, $elts);
		}
}

sub _expand_elt_attributes {
    my ($elt, $attribute) = @_;
    if ($attribute eq '*') {
        my @attributes = keys %{ $elt->atts };
        return grep { $_ ne 'class' and $_ ne 'id' and $_ ne 'name' } @attributes;
    }
    elsif ($attribute =~ m/,/) {
        return split(/\s*,\s*/, $attribute);
    }
    else {
        return $attribute;
    }
}


=head2 filter ELEMENT VALUE

Runs the filter used by ELEMENT on VALUE and returns the result.

=cut

sub filter {
	my ($self, $element, $value) = @_;
	my ($name, @filters);

	$name = $element->{filter};

    @filters = grep {/\S/} split(/\s+/, $name);

    if (@filters > 1) {
        # chain filters
        for my $f_name (@filters) {
            $value = $self->_filter($f_name, $element, $value);
        }

        return $value;
    }
    else {
        return $self->_filter($name, $element, $value);
    }
}

sub _filter {
    my ($self, $name, $element, $value) = @_;
	my ($filter, $mod_name, $class, $filter_obj, $filter_sub);

    if (exists $self->_filter_subs->{$name}) {
        $filter = $self->_filter_subs->{$name};
        return $filter->($value);
    }

    unless (exists $self->_filter_objects->{$name}) {
        # try to bootstrap filter
	    unless ($class = $self->_filter_class->{$name}) {
            $mod_name = join('', map {ucfirst($_)} split(/_/, $name));
            $class = "Template::Flute::Filter::$mod_name";
	    }

        $self->_filter_objects->{$name} =
          use_module($class)->new( options => $self->_filter_opts->{$name} );
    }

    $filter_obj = $self->_filter_objects->{$name};

    if ($filter_obj->can('twig')) {
		$element->{op} = sub {$filter_obj->twig(@_)};
    }

    return $filter_obj->filter($value);
}

sub _paging {
    my ($self, $list, $iterator) = @_;

    # turn iterator into paginator
    my $page_size = $list->{paging}->{page_size} || 20;

    my ($iter, $pager);

    if (defined blessed($iterator)) {
        # DBIx::Class::ResultSet objects have a pager method, but
        # it throws an error without a limit through the rows attribute
        if ($iterator->can('pager')) {
            if ($iterator->can('is_paged')) {
                if ($iterator->is_paged) {
                    $pager = $iterator->pager;
                }
            }
            else {
                $pager = $iterator->pager;
            }
        }
    }

    if ($pager) {
        $iter = Template::Flute::Pager->new(iterator => $pager,
                                            page_size => $page_size);
    }
    else {
        $iter = Template::Flute::Paginator->new(iterator => $iterator,
                                                page_size => $page_size);
    }

    if ($iter->pages > 1) {
        my ($element_orig, $element_copy, %element_pos, $element_link,
            $paging_page, $paging_link, $slide_length, $element, $element_active, $paging_min, $paging_max);

        $slide_length = $list->{paging}->{slide_length} || 0;

        if (exists $list->{paging}->{page_value} and
            exists $self->values->{$list->{paging}->{page_value}}) {
            $paging_page = $self->values->{$list->{paging}->{page_value}};
        }
        if (exists $list->{paging}->{link_value} and
            exists $self->values->{$list->{paging}->{link_value}}) {
            $paging_link = $self->values->{$list->{paging}->{link_value}};
        }
        $paging_page ||= 1;

        $iter->select_page($paging_page);
        # print "Page size is: " . $iter->page_size;

        $paging_min = 1;
        $paging_max = $iter->pages;

        if ($slide_length > 0) {
            # determine the page numbers to show up
            if ($iter->pages > $slide_length) {
                $paging_min = int($paging_page - $slide_length / 2);

                if ($paging_min < 1) {
                    $paging_min = 1;
                }

                $paging_max = $paging_min + $slide_length - 1;
            }
        }

        for my $type (qw/first previous next last active standard/) {
            if ($element = $list->{paging}->{elements}->{$type}) {
                $element_orig = shift @{$element->{elts}};
                next unless $element_orig;

                # cut any other elements
                for my $sf (@{$element->{elts}}) {
                    $sf->cut;
                }
            }
	    else {
		# skip processing of paging elements which aren't specified
		next;
            }

            if ($element_orig->is_last_child()) {
                %element_pos = (last_child => $element_orig->parent());
            } elsif ($element_orig->next_sibling()) {
                %element_pos = (before => $element_orig->next_sibling());
            } else {
                croak "Neither last child nor next sibling.";
            }

            if ($element->{type} eq 'active') {
                $element_active = $element_orig;
            } elsif ($element->{type} eq 'standard') {
                for (1 .. $iter->pages) {
                    next if $_ < $paging_min || $_ > $paging_max;

                    if ($_ == $paging_page) {
                                # Move active element here
                        if ($element_active->{"flute_active"}->{rep_elt}) {
                            $element_active->{"flute_active"}->{rep_elt}->set_text($_);
                        } else {
                            $element_active->set_text($_);
                        }

                        $element_copy = $element_active->cut;
                        $element_copy->paste(%element_pos);
                        next;
                    }

                    # Adjust text
                    if ($element_orig->{"flute_$element->{name}"}->{rep_elt}) {
                        $element_orig->{"flute_$element->{name}"}->{rep_elt}->set_text($_);
                    } else {
                        $element_orig->set_text($_);
                    }

                    # Adjust link
                    if ($element_link = $element_orig->first_descendant('a')) {
                        $self->_paging_link($element_link, $paging_link, $_);
                    }

                    # Copy HTML element
                    $element_copy = $element_orig->copy;
                    $element_copy->paste(%element_pos);
                }

                $element_orig->cut;
            } elsif ($element->{type} eq 'first') {
                if ($paging_page > 1) {
                    # Adjust link
                    if ($element_link = $element_orig->first_descendant('a')) {
                        $self->_paging_link($element_link, $paging_link, 1);
                    }
                } else {
                    $element_orig->cut;
                }
            } elsif ($element->{type} eq 'last') {
                if ($paging_page < $iter->pages) {
                    # Adjust link
                    if ($element_link = $element_orig->first_descendant('a')) {
                        $self->_paging_link($element_link, $paging_link, $iter->pages);
                    }
                } else {
                    $element_orig->cut;
                }
            } elsif ($element->{type} eq 'next') {
                if ($paging_page < $iter->pages) {
                    # Adjust link
                    if ($element_link = $element_orig->first_descendant('a')) {
                        $self->_paging_link($element_link, $paging_link, $paging_page + 1);
                    }
                } else {
                    $element_orig->cut;
                }
            } elsif ($element->{type} eq 'previous') {
                if ($paging_page > 1) {
                    # Adjust link
                    if ($element_link = $element_orig->first_descendant('a')) {
                        $self->_paging_link($element_link, $paging_link, $paging_page - 1);
                    }
                } else {
                    $element_orig->cut;
                }
            }
        }
    } else {
        # remove paging area
        for my $paging_elt (@{$list->{paging}->{elts}}) {
            $paging_elt->cut;
        }
    }
    return $iter;
}

sub _paging_link {
    my ($self, $elt, $paging_link, $paging_page) = @_;
    my ($path, $uri);

    if (ref($paging_link) =~ /^URI::/) {
        # add to path
        $uri = $paging_link->clone;
        if ($paging_page == 1) {
            $uri->path(join('/', $paging_link->path));
        }
        else {
            $uri->path(join('/', $paging_link->path, $paging_page));
        }
        $path = $uri->as_string;
    }
    elsif ($paging_link) {
        if ($paging_page == 1) {
            $path = "/$paging_link";
        }
        else {
            $path = "/$paging_link/$paging_page";
        }
    }
    else {
        $path = $paging_page;
    }

    $elt->set_att(href => $path);
}

=head2 value NAME

Returns the value for NAME.

=cut

sub value {
	my ($self, $value, $values) = @_;
	my ($raw_value, $ref_value, $rep_str, $record_is_object, $key);
	$ref_value = $values;
	$record_is_object = $self->_is_record_object($ref_value);

	if ($self->scopes) {
		if (exists $value->{scope}) {
			$ref_value = $self->values->{$value->{scope}};
		}
	}

	if (exists $value->{include}) {
		my (%args, $include_file);

		if ($self->template_file) {
			$include_file = Template::Flute::Utils::derive_filename
				($self->template_file, $value->{include}, 1,
				 pass_absolute => 1);
		}
		else {
			$include_file = $value->{include};
		}

		# process template and include it
        %args = (
            template_file  => $include_file,
            auto_iterators => $self->auto_iterators,
            i18n           => $self->i18n,
            filters        => $self->filters,
            values         => $value->{field}
                              ? $self->values->{ $value->{field} }
                              : $self->{values},
            uri => $self->uri,
        );

		$raw_value = Template::Flute->new(%args)->process();
	}
	elsif (exists $value->{field}) {
        if (ref($value->{field}) eq 'ARRAY') {
            $raw_value = $ref_value;

            for my $lookup (@{$value->{field}}) {
                if (ref($raw_value)) {
                    if ($self->_is_record_object($raw_value)) {
                        $raw_value = $raw_value->$lookup;
                    }
                    elsif (exists $raw_value->{$lookup}) {
                        $raw_value = $raw_value->{$lookup};
                    }
                }
                else {
                    $raw_value = '';
                    last;
                }
            }

            if (ref $raw_value && ! $self->_is_record_object($raw_value)) {
                # second case: don't pass back stringified reference
                $raw_value = '';
            }
        }
        else {
        	$key = $value->{field};
            $raw_value = $record_is_object ? $ref_value->$key : $ref_value->{$key};
        }
	}
	else {
       	$key = $value->{name};
        $raw_value = $record_is_object ? $ref_value->$key : $ref_value->{$key};

        # if the value is undef, but the type is 'value', set it to
        # the empty string. this way we prevent template values to pop
        # up because no action is done somewhere else.
        if (!defined($raw_value) and $value->{type} eq 'value') {
            $raw_value = '';
        }
	}

	if ($value->{filter}
        and !$self->_value_should_be_skipped($value, $raw_value)) {
		$rep_str = $self->filter($value, $raw_value);
	}
	else {
		$rep_str = $raw_value;
	}

	if (wantarray) {
		return ($raw_value, $rep_str);
	}

	return $rep_str;
}

# internal helpers

sub _is_record_object {
    my ($self, $record) = @_;
    my $class = blessed($record);
    return unless defined $class;

    # it's an object. Check if we have it in the blacklist
    my @ignores = $self->_autodetect_ignores;
    my $is_good_object = 1;
    foreach my $i (@ignores) {
        if ($record->isa($i)) {
            $is_good_object = 0;
            last;
        }
    }
    return $is_good_object;
}

sub _autodetect_ignores {
    my $self = shift;
    my @ignores;
    if ($self->autodetect and exists $self->autodetect->{disable}) {
        @ignores = @{ $self->autodetect->{disable} };
    }
    foreach my $f (@ignores) {
        croak "empty string in the disabled autodetections" unless length($f);
    }
    return @ignores;
}

sub _value_should_be_skipped {
    my ($self, $value, $replacement) = @_;
    if (my $skiptype = $value->{skip}) {
        if ($skiptype eq 'empty') {
            if (!defined($replacement) or
                $replacement =~ m/^\s*$/s) {
                return 1;
            }
        }
        else {
            croak "Unrecognized skip type $skiptype";
        }
    }
    return;
}


=head2 set_values HASHREF

Sets hash reference of values to be used by the process method.
Same as passing the hash reference as values argument to the
constructor.

=head2 template

Returns HTML template object, see L<Template::Flute::HTML> for
details.

=head2 specification

Returns specification object, see L<Template::Flute::Specification> for
details.

=head2 patterns

Returns all patterns found in the specification.

=cut

# FIXME: (SysPete 28/4/16) (SysPete) What is scopes used for? I don't see
# anything in the pod.

=head2 scopes

=head1 SPECIFICATION

The specification ties the elements in the HTML template to the data
(variables, lists, forms) which is added to the template.

The default format for the specification is XML implemented by the
L<Template::Flute::Specification::XML> module. You can use the Config::Scoped
format implemented by L<Template::Flute::Specification::Scoped> module or
write your own specification parser class.

=head2 COMMON ATTRIBUTES

Common attributes for specification elements are:

=over 4

=item name

Name of element.

    <value name="dancefloor"/>

=item class

Class of corresponding elements in the HTML template.

    <value name="dancefloor" class="dancefloor-link"/>

If this attribute is omitted, the value of the name attribute
is used to relate to the class in the HTML template.

=item id

Id of corresponding element in the HTML template. Overrides
the class attribute for the specification element.

   <value name="dancefloor" id="dancefloor-link"/>

=item target

HTML attribute to fill the value instead of replacing the body of
the HTML element.

   <value name="dancefloor" class="dancefloor-link" target="href"/>

=item joiner

String placed between the text and the appended value. The joiner
isn't added if the value is empty.

=back

=head2 ELEMENTS

Possible elements in the specification are:

=over 4

=item container

The first container is only shown in the output if the value C<billing_address> is set:

  <container name="billing" value="billing_address" class="billingWrapper">
  </container>

The second container is shown if the value C<warnings> or the value C<errors> is set:

  <container name="account_errors" value="warnings|errors" class="infobox">
  <value name="warnings"/>
  <value name="errors"/>
  </container>

=item list

=item separator

Separator elements for list are added after any list item in the output with
the exception of the last one.

Example specification, HTML template and output:

  <specification>
  <list name="list" iterator="tokens">
  <param name="key"/>
  <separator name="sep"/>
  </list>
  </specification>

  <div class="list"><span class="key">KEY</span></div><span class="sep"> | </span>

  <div class="list"><span class="key">FOO</span></div><span class="sep"> | </span>
  <div class="list"><span class="key">BAR</span></div>

=item param

Param elements are replaced with the corresponding value from the list iterator.

The following operations are supported for param elements:

=over 4

=item append

Appends the param value to the text found in the HTML template.

=item prepend

Prepends the param value to the text found in the HTML template.

=item target

The attribute to operate on. See below C<target> for C<value> for details.

=item toggle

When the C<args> attribute is set to C<tree>, it doesn't interpolate
anything and just shows corresponding HTML element if param value is
set.

With C<target> attribute, it simply toggles the target attribute.

Otherwise, if value is true, shows the HTML element and set its
content to the value. If value is false, removes the HTML element.

So, if your element has children elements, you probably want to use
the C<args="tree"> attribute (see below for an example).

=back

Other attributes for param elements are:

=over 4

=item filter

Applies filter to param value.

=item increment

Uses value from increment instead of a value from the iterator.

    <param name="pos" increment="1">

=back

=item value

Value elements are replaced with a single value present in the values hash
passed to the constructor of this class or later set with the
L<set_values|/set_values HASHREF> method.

The following operations are supported for value elements:

=over 4

=item append

Appends the value to the text found in the HTML template.

=item prepend

Prepends the value to the text found in the HTML template.

=item hook

Insert HTML residing in value as subtree of the corresponding HTML element.
HTML will be parsed with L<XML::Twig>. See L</INSERT HTML> for an example.

=item keep

Preserves the text inside of the HTML element if value is false
in the Perl sense.

=item toggle

Only shows corresponding HTML element if value is set.

=back

Other attributes for value elements are:

=over 4

=item target

Specify the attribute to operate on instead of the tag content. It can
be a named attribute (e.g., C<href>), the wildcard character(C<*>,
meaning all the attributes found in the HTML template), or a comma
separated list (e.g., C<alt,title>).

=item filter

Applies filter to value.

=item include

Processes the template file named in this attribute. This implies
the hook operation. See L</INCLUDE FILES> for more information.

=back

=item form

Form elements are tied through specification to HTML forms.
Attributes for form elements in addition to C<class> and C<id> are:

=over 4

=item link

The link attribute can only have the value C<name> and allows to
base the relationship between form specification elements and HTML
form tags on the name HTML attribute instead of C<class>, which
is usually more convenient.

=back

=item input

=item filter

=item sort

=item i18n

=item skip

This attribute (which can be provided to C<param> or C<value>
specification elements) supports the following values:

=over 4

=item empty

Do not replace the template string if the value or parameter is
undefined, empty or just whitespace.

E.g.

 <value name="cartline" skip="empty"/>
 <list name="items" iterator="items">
   <param name="category" skip="empty"/>
 </list>

=back

=item pattern

You can define patterns in your specification to I<interpolate> the
strings instead of replacing them.

A pattern is defined by the attributes C<name> and C<type> and its
content. C<type> can be only C<string> or C<regexp>.

The interpolation happens if the C<value> and C<param> elements of the
specification have an attribute C<pattern> set with the pattern's name.

Given this HTML:

 <p class="cartline">There are 123 items in your shopping cart.</p>
 <ul>
   <li class="items">
     <span class="number">1</span>
     <span class="category">in category 123</span>
   </li>
 </ul>

And this specification:

 <specification>
 <pattern name="pxt" type="string">123</pattern>
 <list name="items" iterator="items">
   <param name="number"/>
   <param name="category" pattern="pxt"/>
 </list>
 <value name="cartline" pattern="pxt"/>
 </specification>

In this example, in the cartline and category classes' text, only the
template text "123" will be replaced by the value, not the whole
element content, yielding such output:

 <p class="cartline">There are 42 items in your shopping cart.</p>
 <ul>
  <li class="items">
   <span class="number">1</span>
   <span class="category">in category tofu</span>
  </li>
  <li class="items">
   <span class="number">2</span>
   <span class="category">in category pizza</span>
  </li>
 </ul>

Note: All matches of the pattern are subject to replacement, starting
with version 0.025.

=back

=head1 SIMPLE OPERATORS

=head2 append

Appends the value to the text inside a HTML element or to an attribute
if C<target> has been specified. This can be used in C<value> and C<param>
specification elements.

The example shows how to add a HTML class to elements in a list:

HTML:

    <ul class="nav-sub">
        <li class="category"><a href="" class="catname">Medicine</a></li>
    </ul>

XML:

    <specification>
        <list name="category" iterator="categories">
            <param name="name" class="catname"/>
            <param name="catname" field="uri" target="href"/>
            <param name="css" class="catname" target="class" op="append" joiner=" "/>
        </list>
    </specification>

=head1 CONTAINERS

Conditional processing like C<IF> or C<ELSE> is done with the help of containers.

=head2 Display image only if present

In this example we want to show an image only on
a certain condition:

HTML:

    <span class="banner-box">
        <img class="banner" src=""/>
    </span>

XML:

    <container name="banner-box" value="banner">
        <value name="banner" target="src"/>
    </container>

Source code:

    if ($organization eq 'Big One') {
        $values{banner} = 'banners/big_one.png';
    }

=head2 Display link in a list only if present

In this example we want so show a link only if
an URL is available:

HTML:

    <div class="linklist">
        <span class="name">Name</span>
        <div class="link">
            <a href="#" class="url">Goto ...</a>
        </div>
    </div>

XML:

    <specification name="link">
        <list name="links" class="linklist" iterator="links">
            <param name="name"/>
            <param name="url" target="href"/>
            <container name="link" class="link" value="url"/>
        </list>
    </specification>

Source code:

   @records = ({name => 'Link', url => 'http://localhost/'},
               {name => 'No Link'},
               {name => 'Another Link', url => 'http://localhost/'},
              );

   $flute = Template::Flute->new(specification => $spec_xml,
                                 template => $template,
                                 iterators => {links => \@records});

   $output = $flute->process();

=head1 ITERATORS

Template::Flute uses iterators to retrieve list elements and insert them into
the document tree. This abstraction relieves us from worrying about where
the data actually comes from. We basically just need an array of hash
references and an iterator class with a next and a count method. For your
convenience you can create an iterator from L<Template::Flute::Iterator>
class very easily.

=head2 DROPDOWNS

Iterators can be used for dropdowns (HTML <select> elements) as well.

Template:

    <select class="color"></select>

Specification:

    <value name="color" iterator="colors"/>

Code:

    @colors = ({value => 'red', label => 'Red'},
               {value => 'black', label => 'Black'});

    $flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                              values => {color => 'black'},
                             );

HTML output:

      <select class="color">
      <option value="red">Red</option>
      <option value="black" selected="selected">Black</option>
      </select>

=head3 Default value for dropdowns

You can specify the dropdown item which is selected by
default with the C<iterator_default>) attribute.

Template:

    <select class="color"></select>

Specification:

    <value name="color" iterator="colors" iterator_default="black"/>

Code:

    @colors = ({value => 'red', label => 'Red'},
               {value => 'black', label => 'Black'});

    $flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              iterators => {colors => \@colors},
                             );

HTML output:

      <select class="color">
      <option value="red">Red</option>
      <option value="black" selected="selected">Black</option>
      </select>

=head3 Custom iterators for dropdowns

By default, the iterator for a dropdown is an arrayref of hashrefs
with two hardcoded keys: C<value> and (optionally) C<label>. You can
override this behaviour in the specification with
C<iterator_value_key> and C<iterator_name_key> to use your own
hashref's keys from the iterator, instead of C<value> and C<label>.

Specification:

  <specification>
    <value name="color" iterator="colors"
           iterator_value_key="code" iterator_name_key="name"/>
  </specification>

Template:

  <html>
   <select class="color">
   <option value="example">Example</option>
   </select>
  </html>

Code:

  @colors = ({code => 'red', name => 'Red'},
             {code => 'black', name => 'Black'},
            );

  $flute = Template::Flute->new(template => $html,
                                specification => $spec,
                                iterators => {colors => \@colors},
                                values => { color => 'black' },
                               );

  $out = $flute->process();

Output:

  <html>
   <head></head>
   <body>
    <select class="color">
     <option value="red">Red</option>
     <option selected="selected" value="black">Black</option>
    </select>
   </body>
  </html>


=head3 Limit lists

Sometimes you may wish to limit the number or iterations through you list.

Specification:

    <specification>
        <list name="images" iterator="images" limit="1">
            <param name="image" target="src" field="image_url" />
        </list>
    </specification>

Template:

    <div class="images">
        <img class="image" src="/images/bottle.jpg" />
    </div>

Code:

    $images = [
        { image_url => '/images/bottle1.jpg' },
        { image_url => '/images/bottle2.jpg' },
        { image_url => '/images/bottle3.jpg' },
    ];

    $flute = Template::Flute->new(
        template      => $html,
        specification => $spec,
        values        => { images => $images },
    );

    $out = $flute->process;

Output:

    <html><head></head><body>
        <div class="images">
            <img class="image" src="/images/bottle1.jpg" />
        </div>
    </body></html>

=head1 LISTS

Lists can be accessed after parsing the specification and the HTML template
through the HTML template object:

    $flute->template->lists();

    $flute->template->list('cart');

Only lists present in the specification and the HTML template can be
addressed in this way.

See L<Template::Flute::List> for details about lists.

=head1 OBJECTS AND STRUCTURES

You can pass objects and hashrefs as values. To access a key or an
accessor, you have to use a dotted notation with C<field>. An example
for both hashrefs and objects follows.

Specification:

  <specification>
   <value name="object" field="myobject.method" />
   <value name="struct" field="mystruct.key" />
  </specification>


HTML:

  <html>
    <body>
      <span class="object">Welcome back!</span>
      <span class="struct">Another one</span>
    </body>
  </html>


Code:

  package My::Object;
  sub new {
      my $class = shift;
      bless {}, $class;
  }
  sub method {
      return "Hello from the method";
  }
  package main;
  my $flute = Template::Flute->new(
      specification => $spec,
      template => $html,
      values => {
          myobject => My::Object->new,
          mystruct => { key => "Hello from hash" },
         }
     );

C<process> will return:

  <html>
    <head></head>
    <body>
      <span class="object">Hello from the method</span>
      <span class="struct">Hello from hash</span>
    </body>
  </html>

Sometimes you need to treat an object like an hashref. How to do that
is explained under the C<autodetect> option for the constructor.

=head1 FORMS

Forms can be accessed after parsing the specification and the HTML template
through the HTML template object:

    $flute->template->forms();

    $flute->template->form('edit_content');

Only forms present in the specification and the HTML template can be
addressed in this way.

See L<Template::Flute::Form> for details about forms.

=head1 FILTERS

Filters are used to change the display of value and param elements in
the resulting HTML output:

    <value name="billing_address" filter="eol"/>

    <param name="price" filter="currency"/>

The following filters are included:

=over 4

=item upper

Uppercase filter, see L<Template::Flute::Filter::Upper>.

=item strip

Strips whitespace at the beginning at the end,
see L<Template::Flute::Filter::Strip>.

=item eol

Filter preserving line breaks, see L<Template::Flute::Filter::Eol>.

=item nobreak_single

Filter replacing missing text with no-break space,
see L<Template::Flute::Filter::NobreakSingle>.

=item currency

Currency filter, see L<Template::Flute::Filter::Currency>.
Requires L<Number::Format> module.

=item date

Date filter, see L<Template::Flute::Filter::Date>.
Requires L<DateTime> and L<DateTime::Format::ISO8601> modules.

=item country_name

Country name filter, see L<Template::Flute::Filter::CountryName>.
Requires L<Locales> module.

=item language_name

Language name filter, see L<Template::Flute::Filter::LanguageName>.
Requires L<Locales> module.

=item json_var

JSON to Javascript variable filter, see L<Template::Flute::Filter::JsonVar>.
Requires L<JSON> module.

=item lower_dash

Replaces spaces with dashes (-) and makes lowercase.
see L<Template::Flute::Filter::LowerDash>.

=item markdown

Turns text in Markdown format into HTML.
see L<Template::Flute::Filter::Markdown>.

=back

Filter classes are loaded at runtime for efficiency and to keep the
number of dependencies for Template::Flute as small as possible.

See above for prerequisites needed by the included filter classes.

=head2 Chained Filters

Filters can also be chained:

    <value name="note" filter="upper eol"/>

Example template:

    <div class="note">
        This is a note.
    </div>

With the following value:

    Update now!
    Avoid security hazards!

The HTML output would look like:

    <div class="note">
    UPDATE NOW!<br />
    AVOID SECURITY HAZARDS!
    </div>

=head1 INSERT HTML AND INCLUDE FILES

=head2 INSERT HTML

HTML can be generated in the code or retrieved from a database
and inserted into the template through the C<hook> operation:

    <value name="description" op="hook"/>

The result replaces the inner HTML of the following C<div> tag:

    <div class="description">
        Sample content
    </div>

=head2 INCLUDE FILES

Files, especially components for web pages can be processed and included
through value elements with the include attribute:

    <value name="sidebar" include="component.html"/>

The result replaces the inner HTML of the following C<div> tag:

    <div class="sidebar">
        Sample content
    </div>

=head1 INSTALLATION

C<Template::Flute> can be installed from the latest release on CPAN, or if
you wish for the very latest version, you can also install from the sources
on GitHub.

=head2 FROM CPAN

To install from CPAN, simply use the C<cpanm> utility:

    $ cpanm Template::Flute

=head2 FROM SOURCE

To install from source, first clone the repository, install the required
dependencies, and build:

    $ git clone https://github.com/racke/Template-Flute
    $ cd Template-Flute
    $ cpanm --installdeps .
    $ perl Makefile.PL
    $ make
    $ make test     # optional, but still a good idea
    $ make install

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/racke/Template-Flute/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Flute

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Flute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Flute>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Flute/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Nitish Bezzala (GH #157).

Thanks to Mohammad S Anwar (GH #156).

Thanks to Paul Cochrane for his tremendous amount of pull requests
issued during the GitHub challenge.

Thanks to Peter Mottram (GH #81, #87).

Thanks to William Carr (GH #86, #91).

Thanks to David Precious (bigpresh) for writing a much clearer introduction for
Template::Flute.

Thanks to Grega Pompe for proper implementation of nested lists and
a documentation fix.

Thanks to Jeff Boes for spotting a typo in the documentation of the
Template::Flute::Filter::JsonVar class.

Thanks to Ton Verhagen for being a big supporter of my projects in all aspects.

Thanks to Sam Batschelet (GH #14, #93).

Thanks to Terrence Brannon for spotting a documentation mix-up.

=head1 HISTORY

Template::Flute was initially named Template::Zoom. I renamed the module because of
a request from Matt S. Trout, author of the L<HTML::Zoom> module.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
