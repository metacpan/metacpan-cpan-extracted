#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2014 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_001;
use     strict;
use     experimental    'smartmatch';
#=============================================================================
#       Base ODF element class and some derivatives
#=============================================================================
package ODF::lpOD::Element;
our     $VERSION        = '1.015';
use constant PACKAGE_DATE => '2014-04-30T08:27:41';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------
use XML::Twig           3.34;
use base 'XML::Twig::Elt';
#=== element classes =========================================================

our %CLASS    =
        (
        '#PCDATA'                       => odf_text_node,
        'text:p'                        => odf_paragraph,
        'text:h'                        => odf_heading,
        'text:span'                     => odf_text_element,
        'text:a'                        => odf_text_hyperlink,
        'text:bibliography-mark'        => odf_bibliography_mark,
        'text:note'                     => odf_note,
        'office:annotation'             => odf_annotation,
        'text:changed-region'           => odf_changed_region,
        'text:section'                  => odf_section,
        'text:list'                     => odf_list,
        'table:table'                   => odf_table,
        'table:table-column-group'      => odf_column_group,
        'table:table-header-columns'    => odf_column_group,
        'table:table-row-group'         => odf_row_group,
        'table:table-header-rows'       => odf_row_group,
        'table:table-column'            => odf_column,
        'table:table-row'               => odf_row,
        'table:table-cell'              => odf_cell,
        'table:covered-table-cell'      => odf_cell,
        'text:variable-decl'            => odf_simple_variable,
        'text:user-field-decl'          => odf_user_variable,
        'draw:page'                     => odf_draw_page,
        'draw:rect'                     => odf_rectangle,
        'draw:ellipse'                  => odf_ellipse,
        'draw:line'                     => odf_line,
        'draw:connector'                => odf_connector,
        'draw:frame'                    => odf_frame,
        'draw:image'                    => odf_image,
        'manifest:file-entry'           => odf_file_entry,
        'style:font-face'               => odf_font_declaration,
        'style:style'                   => odf_style,
        'style:default-style'           => odf_style,
        'text:list-style'               => odf_list_style,
        'text:list-level-style-number'  => odf_list_level_style,
        'text:list-level-style-bullet'  => odf_list_level_style,
        'text:list-level-style-image'   => odf_list_level_style,
        'text:outline-level-style'      => odf_list_level_style,
        'text:outline-style'            => odf_outline_style,
        'style:master-page'             => odf_master_page,
        'style:page-layout'             => odf_page_layout,
        'draw:gradient'                 => odf_gradient,
        'style:presentation-page-layout'
                                        => odf_presentation_page_layout,
        'style:header-style'            => odf_page_end_style,
        'style:footer-style'            => odf_page_end_style,
        'text:table-of-content'         => odf_toc,
        'table:named-range'             => odf_named_range
        );

sub     get_class_map   { %CLASS }
sub     associate_tag
        {
        my $caller = shift;
        my $class = ref($caller) || $caller;
        $CLASS{$_} = $class for @_;
        }

#=== aliases and initialization ==============================================

BEGIN
        {
        *create                         = *new;
        *xe_new                         = *XML::Twig::Elt::new;
        *get_tag                        = *XML::Twig::Elt::tag;
        *get_tagname                    = *XML::Twig::Elt::tag;
        *del_attributes                 = *XML::Twig::Elt::del_atts;
        *get_children                   = *XML::Twig::Elt::children;
        *get_descendants                = *XML::Twig::Elt::descendants;
        *get_parent                     = *XML::Twig::Elt::parent;
        *get_ancestor                   = *XML::Twig::Elt::parent;
        *previous_sibling               = *XML::Twig::Elt::prev_sibling;
        *ungroup                        = *XML::Twig::Elt::erase;
        *get_root                       = *XML::Twig::Elt::root;
        *is_element                     = *XML::Twig::Elt::is_elt;
        *is_text_segment                = *XML::Twig::Elt::is_text;
        *_set_text                      = *XML::Twig::Elt::set_text;
        *_get_text                      = *XML::Twig::Elt::text;
        *_set_tag                       = *XML::Twig::Elt::set_tag;
        *_set_first_child				= *XML::Twig::Elt::set_first_child;
        *_set_last_child				= *XML::Twig::Elt::set_last_child;
        *replace_element                = *XML::Twig::Elt::replace;
        *set_child                      = *set_first_child;
        *get_element_list               = *get_elements;
        *get_bookmark_list              = *get_bookmarks;
        *get_index_mark_list            = *get_index_marks;
        *get_bibliography_mark_list     = *get_bibliography_marks;
        *get_table_list                 = *get_tables;
        *get_draw_page_list             = *get_draw_pages;
        *get_part                       = *lpod_part;
        *document_part                  = *lpod_part;
        *get_document_part              = *lpod_part;
        *get_document                   = *document;
        *get_document_type              = *document_type;
        *export                         = *serialize;
        }

#=== exported constructor ====================================================

sub     _create  { ODF::lpOD::Element->new(@_) }

#-----------------------------------------------------------------------------

our $INIT_CALLBACK   = undef;

sub     new
        {
	my $caller	= shift;
	my $class	= ref($caller) || $caller;
        my $data        = shift         or return undef;
        my $element;
        if (ref $data || $data =~ /\.xml$/i)    # load from file
                {
                $data = load_file($data);
                }
        $data	=~ s/^\s+//;
        $data	=~ s/\s+$//;
        if ($data =~ /^</)	                # create from XML string
                {
                return ODF::lpOD::Element->parse_xml($data, @_);
                }
                # odf_element creation
        return undef unless $data;
        $element     = $class->SUPER::new($data, @_);
                # possible subclassing according to the tag
        my $tag = $element->tag;
        if ($CLASS{$tag})
                {
                bless $element, $CLASS{$tag};
                }
        elsif ($tag =~ /^number:.*-style$/)
                {
                bless $element, 'ODF::lpOD::DataStyle';
                }
                # optional user-defined post-constructor function
        if ($INIT_CALLBACK && (caller() eq 'XML::Twig'))
                {
                &$INIT_CALLBACK($element);
                }
        return $element;
        }

#-----------------------------------------------------------------------------

sub	parse_xml
	{
        state $twig;
        unless ($twig)
                {
                $twig = XML::Twig->new
                                (
                                elt_class       => 'ODF::lpOD::Element',
                                output_encoding => TRUE,
                                id              => $ODF::lpOD::Common::LPOD_ID
                                );
                $twig->set_output_encoding('UTF-8');
                }
	my $class	= shift;
	$twig->safe_parse(@_) or return undef;
        my $element = $twig->root;
        $element->set_classes;
        return $element;
	}

sub     clone
        {
        my $self	= shift;
        my $class       = ref $self;
        my $elt         = $self->copy;
        return bless $elt, $class;
        }

#-----------------------------------------------------------------------------

sub     convert         { FALSE }
sub     context_path    {}

sub     set_tag
        {
        my $self        = shift;
        my $tag         = shift;
        $self->_set_tag($tag);
        bless $self, $CLASS{$tag} || 'ODF::lpOD::Element';
        $self->set_class;
        return $tag;
        }

sub     set_class
        {
        my $self        = shift;
        my $prefix = $self->ns_prefix or return $self;
        if ($prefix eq 'text')
                {
                ODF::lpOD::TextField::classify($self);
                }
        return $self;
        }

sub     set_classes
        {
        my $self        = shift;
        foreach my $e ($self->descendants_or_self)
                {
                my $class;
                next if $e->isa('ODF::lpOD::TextNode');
                my $tag = $e->tag;
                if ($tag =~ /^number:.*style$/)
                        {
                        $class = 'ODF::lpOD::Style';
                        }
                $class ||= $CLASS{$tag};
                $class ||= 'ODF::lpOD::Element';
                bless $e, $class;
                $e->set_class;
                }
        return $self;
        }

sub     check_tag
        {
        my $self        = shift;
        my $new_tag     = shift;
        my $old_tag     = $self->tag;
        return $old_tag unless $new_tag;
        unless ($new_tag eq $old_tag)
                {
                $self->set_tag($new_tag);
                }
        return $self->tag;
        }

sub     is
        {
        my $self        = shift;
        my $classname   = shift;
        unless (ref($classname))
                {
                return  (
                        $self->isa($classname) || $classname eq $self->tag
                        ) ? TRUE : FALSE;
                }
        if (ref($classname) eq 'Regexp')
                {
                my $tag = $self->tag;
                return ($tag =~ $classname) ? TRUE : FALSE;
                }
        else
                {
                alert("Wrong reference");
                return undef;
                }
        }

sub     set_id
        {
        my $self        = shift;
        return $self->set_attribute('id' => shift);
        }

sub     get_id
        {
        my $self        = shift;
        return $self->get_attribute('id');
        }

sub     is_child
        {
        my $self        = shift;
        my $ref_elt     = shift;
        my $parent = $self->parent;
        return ($parent && $parent == $ref_elt) ? TRUE : FALSE;
        }

sub     get_child
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift) or return undef;
        return $self->first_child($tag);
        }

sub     set_first_child
        {
        my $self        = shift;
        return $self->_set_first_child(@_) if caller() eq 'XML::Twig::Elt';
        my $tag         = $self->normalize_name(shift);
        my $child =     $self->first_child($tag)
                                //
                        $self->insert_element($tag);
        $child->set_text(shift);
        $child->set_attributes(@_);
        return $child;
        }

sub		set_last_child
		{
		my $self	= shift;
		return $self->_set_last_child(@_) if caller() eq 'XML::Twig::Elt';
		my $tag         = $self->normalize_name(shift);
	        my $child =     $self->first_child($tag)
	                                //
	                        $self->append_element($tag);
	        $child->set_text(shift);
	        $child->set_attributes(@_);
	        return $child;
		}

sub     set_parent
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift);
        my $parent      = $self->parent;

        if ($parent)
                {
                unless ($parent->is($tag))
                        {
                        $parent = ODF::lpOD::Element->create($tag);
                        $parent->paste(before => $self);
                        $self->move(first_child => $parent);
                        }
                }
        else
                {
                $parent = ODF::lpOD::Element->create($tag);
                $self->move(first_child => $parent);
                }

        $parent->set_text(shift);
        $parent->set_attributes(@_);
        return $parent;
        }

sub	delete_child
	{
	my $self	= shift;
	my $child       = $self->get_child(shift) or return FALSE;
        $child->delete;
        return TRUE;
	}

sub	delete_children
	{
	my $self	= shift;
	my @children= $self->children(shift);
        my $count = 0;
        foreach my $e (@children)
                {
                $e->delete; $count++;
                }
        return $count;
	}

sub     import_children
        {
        my $self        = shift;
        my $source      = shift         or return FALSE;
        my $count = 0;
        foreach my $e ($source->children(shift))
                {
                $e->clone->paste_last_child($self); $count++
                }
        return $count;
        }

sub	substitute_children
	{
	my $self	= shift;
	my $source      = shift         or return FALSE;
        $self->delete_children(@_);
        return $self->import_children($source, @_);
	}

sub     replace_child
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift) or return undef;
        $self->delete_child($tag);
        my $child = $self->insert_element($tag);
        $child->set_text(shift);
        $child->set_attributes(@_);
        return $child;
        }

sub     next
        {
        my $self        = shift;
        my $context     = shift;
        my $tag         = $self->get_tag;
        unless ($context)
                {
                return $self->next_sibling($tag);
                }
        return $self->next_elt($context, $tag);
        }

sub     previous
        {
        my $self        = shift;
        my $context     = shift;
        my $tag         = $self->get_tag;
        unless ($context)
                {
                return $self->previous_sibling($tag);
                }
        return $self->prev_elt($self, $tag);
        }

sub     get_class
        {
        my $self        = shift;
        return Scalar::Util::blessed($self);
        }

sub     get_children_elements
        {
        my $self        = shift;
        return $self->children(qr'^[^#]');
        }

sub     get_descendant_elements
        {
        my $self        = shift;
        return $self->descendants(qr'^[^#]');
        }

sub     group
        {
        my $self        = shift;
        my @elts        = @_;
        $_->move(last_child => $self) for @elts;
        }

sub     node_info
        {
        my $self        = shift;
        my %i           = ();
        $i{text}        = $self->_get_text;
        $i{size}        = length($i{text});
        $i{tag}         = $self->tag;
        $i{class}       = $self->get_class;
        $i{attributes}  = $self->get_attributes;
        return %i;
        }

sub     has_text
        {
        my $self        = shift;
        return $self->has_child(TEXT_SEGMENT) ? TRUE : FALSE;
        }

sub     is_text_container
        {
        my $self        = shift;
        my $name = $self->tag;
        return $name =~ /^text:(p|h|span)$/ ? TRUE : FALSE;
        }

sub     normalize_name
        {
        my $self        = shift;
        my $name        = shift // return undef;
        $name =~ s/^\s+//;
        $name =~ s/\s+$//;
        return $name if $name =~ /^</;
        $name .= ' name' if $name eq 'style';
        if ($name && ! ref $name)
                {
                unless ($name =~ /[:#]/)
                        {
                        my $prefix = $self->ns_prefix;
                        $name = $prefix . ':' . $name   if $prefix;
                        }
                $name =~ s/[ _]/-/g;
                }
        return $name;
        }

sub     repeat
        {
        my $self        = shift;
        unless ($self->parent)
                {
                alert "Repeat not allowed for root elements";
                return FALSE;
                }
        my $r           = shift;
        return undef unless defined $r;

        my $count = 0;
        while ($r > 1)
                {
                my $elt = $self->clone;
                $elt->paste_after($self);
                $count++; $r--;
                }
        return $count;
        }

sub     set_lpod_mark
        {
        state $count    = 0;
        my $self        = shift;
        my %opt         = @_;

        my $id;
        if (defined $opt{id})
                {
                $id = $opt{id}; delete $opt{id};
                }
        else
                {
                $id = lpod_common->new_id;
                }

        my $e = $self->insert_element($ODF::lpOD::Common::LPOD_MARK, %opt);
        $e->set_attribute($ODF::lpOD::Common::LPOD_ID, $id);
        return $id;
        }

sub     ro
        {
        my $self        = shift;
        my $ro          = shift;
        unless (defined $ro)
                {
                return $self->att('#lpod:ro') // FALSE;
                }
        elsif (is_true($ro))
                {
                $self->set_att('#lpod:ro', TRUE);
                }
        else
                {
                $self->del_att('#lpod:ro') if $self->att('#lpod:ro');
                return undef;
                }
        }

sub     rw
        {
        my $self        = shift;
        my $rw          = shift;
        unless (defined $rw)
                {
                return is_false($self->att('#lpod:ro'));
                }
        elsif (is_true($rw))
                {
                $self->del_att('#lpod:ro') if $self->att('#lpod:ro');
                return TRUE;
                }
        elsif (is_false($rw))
                {
                $self->set_att('#lpod:ro', TRUE);
                return FALSE;
                }
        }

sub     get_lpod_mark
        {
        my $self        = shift;
        my $id          = shift;
        return $self->get_element
                (
                $ODF::lpOD::Common::LPOD_MARK,
                attribute       => $ODF::lpOD::Common::LPOD_ID,
                value           => $id
                );
        }

sub     remove_lpod_mark
        {
        my $self        = shift;
        my $mark        = $self->get_lpod_mark(shift);
        if ($mark)
                {
                $mark->delete; return TRUE;
                }
        return FALSE;
        }

sub     remove_lpod_marks
        {
        my $self        = shift;
        $_->delete()
                for $self->get_elements($ODF::lpOD::Common::LPOD_MARK);
        }

sub     set_lpod_id
        {
        my $self        = shift;
        return $self->set_att($ODF::lpOD::Common::LPOD_ID, shift);
        }

sub     remove_lpod_id
        {
        my $self        = shift;
        return $self->del_att($ODF::lpOD::Common::LPOD_ID);
        }

sub     strip_lpod_id
        {
        my $self        = shift;
        return $self->strip_att($ODF::lpOD::Common::LPOD_ID);
        }

sub     lpod_part
        {
        my $self        = shift;
        my $part        = shift;
        if ($part)
                {
                return $self->set_att($ODF::lpOD::Common::LPOD_PART, $part);
                }
        else
                {
                return
                        $self->att($ODF::lpOD::Common::LPOD_PART)       ||
                        $self->root->att($ODF::lpOD::Common::LPOD_PART);
                }
        }

sub     document
        {
        my $self        = shift;
        my $part        = $self->lpod_part      or return undef;
        return $part->document;
        }

sub     document_type
        {
        my $self        = shift;
        my $doc = $self->document  or return undef;
        return $doc->get_type;
        }

#-----------------------------------------------------------------------------

sub     text_segments
        {
        my $self        = shift;
        my %opt         =
                (
                deep    => FALSE,
                @_
                );
        return (is_true($opt{deep})) ?
                $self->descendants(TEXT_SEGMENT)   :
                $self->children(TEXT_SEGMENT);
        }

sub     search_in_text_segment
        {
        my $self        = shift;
        unless ($self->is_text)
                {
                alert("Not in text segment");
                return undef;
                }
        return search_string($self->get_text, @_);
        }

sub     replace_in_text_segment
        {
        my $self        = shift;
        my $expr        = shift;
        my $repl        = shift;

        my ($content, $change_count) = search_string
                        ($self->get_text, $expr, replace => $repl, @_);
        $self->set_text($content) if $change_count;
        return $change_count;
        }

#--- generic element retrieval method ----------------------------------------

sub     _get_elements
        {
        my $self        = shift;
        my $tag         = shift;
        if (ref $tag)
                {
                return $self->descendants($tag);
                }
        my %opt         =
                (
                content         => undef,
                attribute       => undef,
                position        => undef,
                @_
                );
        $tag = $self->normalize_name($tag);
        my $xpath = './/' . ($tag // "");

        if (defined $opt{attribute})
                {
                my $a = $opt{attribute};
                my $v = input_conversion($opt{value});
                $a =~ s/[ _]/-/g;
                unless ($a =~ /:/)
                        {
                        $tag =~ /^(.*):/; $a = $1 . ':' . $a;
                        }
                $xpath .= '[@' . $a . '="' . $v . '"]';
                }

        my $pos = $opt{position};
        my $expr = $opt{content};
        unless (defined $opt{content})
                {
                return defined $pos ?
                        $self->get_xpath($xpath, $pos) :
                        $self->get_xpath($xpath);
                }
        else
                {
                my $elt;
                my @elts = ();
                my $count = 0;
                unless (defined $pos)
                        {
                        foreach $elt ($self->get_xpath($xpath))
                                {
                                push @elts, $elt if $elt->count_matches($expr);
                                }
                        return @elts;
                        }
                elsif ($pos >= 0)
                        {
                        foreach $elt ($self->get_xpath($xpath))
                                {
                                if ($elt->count_matches($expr))
                                        {
                                        $count++;
                                        return $elt if $count > $pos;
                                        }
                                }
                        return undef;
                        }
                else
                        {
                        foreach $elt ($self->get_xpath($xpath))
                                {
                                push @elts, $elt if $elt->count_matches($expr);
                                }
                        my $size = scalar @elts;
                        return ($size >= abs($pos)) ? $elts[$pos] : undef;
                        }
                }
        }

sub     get_element
        {
        my $self        = shift;
        my $tag         = shift;
        my %opt         = @_;
        $opt{position} //= 0;
        if ($opt{bookmark})
                {
                return $self->get_element_by_bookmark
                                ($opt{bookmark}, tag => $tag);
                }
        return $self->_get_elements($tag, %opt);
        }

sub     get_element_by_id
        {
        my $self        = shift;
        my $tag         = shift;
        return $self->get_element($tag, attribute => 'id', value => shift);
        }

sub     get_element_by_name
        {
        my $self        = shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing object name"; return undef;
                }
        return $self->get_element($name, attribute => 'name', value => shift);
        }

sub     get_elements
        {
        my $self        = shift;
        my $tag         = shift;
        my %opt         = @_;
        delete $opt{position};
        return $self->_get_elements($tag, %opt);
        }

#--- specific unnamed element retrieval methods ------------------------------

sub     get_text_element
        {
        my $self        = shift;
        my %opt         = @_;
        my $type = $opt{type} // 'p';
        delete $opt{type};
        $type = 'text:' . $type unless $type =~ /:/;

        if ($opt{bookmark})
                {
                return $self->get_element_by_bookmark
                                ($opt{bookmark}, tag => $type);
                }
        unless (defined $opt{style})
                {
                return $self->get_element($type, %opt);
                }
        else
                {
                return $self->get_element
                        (
                        $type,
                        attribute       => 'style name',
                        value           => $opt{style},
                        position        => $opt{position},
                        content         => $opt{content}
                        );
                }
        }

sub	get_paragraph
        {
        my $self	= shift;
        return $self->get_text_element(type => 'p', @_);
        }

sub	get_text_span
        {
        my $self	= shift;
        return $self->get_text_element(type => 'span', @_);
        }

sub     get_parent_paragraph
        {
        my $self	= shift;
        return $self->parent(qr'text:(p|h)');
        }

sub     get_text_elements
        {
        my $self        = shift;
        my %opt         = @_;
        my $type = $opt{type} // 'p';
        delete $opt{type};
        $type = 'text:' . $type unless $type =~ /:/;

        if ($opt{style})
                {
                $opt{attribute} = 'style name';
                $opt{value} = $opt{style};
                delete $opt{style};
                }
        return $self->get_elements($type, %opt);
        }

sub	get_paragraphs
        {
        my $self	= shift;
        return $self->get_text_elements(type => 'p', @_);
        }

sub	get_text_spans
        {
        my $self	= shift;
        return $self->get_text_elements(type => 'span', @_);
        }

sub     get_heading
        {
        my $self        = shift;
        my %opt         = @_;
        if ($opt{bookmark})
                {
                return $self->get_element_by_bookmark
                        ($opt{bookmark}, tag => 'text:h');
                }
        if (defined $opt{level})
                {
                $opt{attribute} = 'outline level';
                $opt{value} = $opt{level};
                delete $opt{level};
                }
        return $self->get_element('text:h', %opt);
        }

sub     get_headings
        {
        my $self        = shift;
        my %opt         = @_;
        unless (is_true($opt{all}))
                {
                if (defined $opt{level})
                        {
                        $opt{attribute} = 'outline level';
                        $opt{value} = $opt{level};
                        delete $opt{level};
                        }
                return $self->get_elements('text:h', %opt);
                }
        else
                {
                unless (defined $opt{level})
                        {
                        return $self->get_elements('text:h');
                        }
                my @headings = ();
                my $h = $self->first_child('text:h');
                while ($h)
                        {
                        my $l = $h->get_level;
                        push @headings, $h if $l > 0 and $l <= $opt{level};
                        $h = $h->next_sibling('text:h');
                        }
                return @headings;
                }
        }

sub	get_hyperlinks
	{
	my $self	= shift;
	my %opt         = @_;
        my $type = $opt{type};
        delete $opt{type};
        unless ($type)
                {
                return  (
                        $self->get_hyperlinks(type => 'text', %opt),
                        $self->get_hyperlinks(type => 'draw', %opt)
                        );
                }
        if (defined $opt{url})
                {
                $opt{attribute} = 'xlink:href';
                $opt{value} = $opt{url};
                delete $opt{url};
                }
        return $self->get_elements("$type:a", %opt);
	}

sub     get_list
        {
        my $self        = shift;
        return $self->get_element('text:list', @_);
        }

sub     get_list_by_id
        {
        my $self        = shift;
        return $self->get_list(attribute => 'xml:id', value => shift);
        }

sub     get_lists
        {
        my $self        = shift;
        return $self->get_elements('text:list', @_);
        }

sub	get_fields
	{
	my $self	= shift;
	my $type        = shift;
        unless ($type)
                {
                my @elts;
                for (ODF::lpOD::TextField->types)
                        {
                        push @elts, $self->get_fields($_);
                        }
                return @elts;
                }
        return $self->get_elements('text:' . $type);
	}

#--- table retrieval ---------------------------------------------------------

sub	get_table
	{
	my $self	= shift;
	my $arg         = shift // 0;
        return is_numeric($arg) ?
                $self->get_table_by_position($arg, @_)  :
                $self->get_table_by_name($arg, @_);
	}

sub	get_parent_table
	{
	my $self	= shift;
	return $self->parent('table:table');
	}

sub     get_parent_cell
        {
	my $self	= shift;
	return $self->parent('table:table-cell');
        }

sub     get_tables
        {
        my $self        = shift;
        return $self->get_elements('table:table', @_);
        }

sub     get_table_by_name
        {
        my $self        = shift;
        my $name        = shift;
        return $self->get_element_by_name('table:table', $name);
        }

sub     get_table_by_position
        {
        my $self        = shift;
        my $position    = shift || 0;
        return $self->get_element('table:table', position => $position);
        }

sub     get_table_by_content
        {
        my $self        = shift;
        my $expr        = shift;
        unless (defined $expr)
                {
                alert "Missing search expression";
                return FALSE;
                }
        foreach my $t ($self->get_tables(@_))
                {
                foreach my $n ($t->descendants(TEXT_SEGMENT))
                        {
                        my $text = $n->get_text()       or next;
                        return $t;
                        }
                }
        return FALSE;
        }

#--- check & retrieval tools for bookmarks, index marks ----------------------

sub     get_position_mark
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift);
        my $name        = shift;
        my $role        = shift;
        unless ($name)
                {
                alert ("Name is mandatory for position mark retrieval");
                return FALSE;
                }
        my $attr = $tag =~ /bookmark|reference-mark/ ?
                'text:name' : 'text:id';
        my %opt = (attribute => $attr, value => $name);
        given ($role)
                {
                when (undef)
                        {
                        my $single = $self->get_element($tag, %opt);
                        unless ($single)
                                {
                                my $start = $self->get_element
                                        ($tag . '-start', %opt);
                                my $end   = $self->get_element
                                        ($tag . '-end', %opt);
                                return wantarray ? ($start, $end) : $start;
                                }
                        return $single;
                        }
                when (/^(start|end)$/)
                        {
                        return $self->get_element($tag . '-' . $_, %opt);
                        }
                default
                        {
                        alert "Wrong role $role";
                        return FALSE;
                        }
                }
        }

sub     check_position_mark
        {
        my $self        = shift;
        my $tag         = shift;
        my $name        = shift;

        my %opt = (attribute => 'text:name', value => $name);

        return TRUE if $self->get_element($tag, %opt);

        my $start = $self->get_position_mark($tag, $name, 'start')
                or return FALSE;
        my $end   = $self->get_position_mark($tag, $name, 'end')
                or return FALSE;
        return $start->before($end) ? TRUE : FALSE;
        }

sub     remove_position_mark
        {
        my $self        = shift;
        my $tag         = shift;
        my $name        = shift;

        my %opt = (attribute => 'text:name', value => $name);

        my $single      = $self->get_element($tag, %opt);
        if ($single)
                {
                $single->delete;
                return TRUE;
                }

        my $start = $self->get_position_mark($tag, $name, 'start')
                or return FALSE;
        my $end   = $self->get_position_mark($tag, $name, 'end')
                or return FALSE;
        $start->delete;
        $end->delete;
        return TRUE;
        }

#--- text mark retrieval stuff -----------------------------------------------

sub     get_bookmark
        {
        my $self        = shift;
        return $self->get_position_mark('text:bookmark', shift);
        }

sub     get_bookmarks
        {
        my $self        = shift;
        return $self->get_elements(qr'bookmark$|bookmark-start$');
        }

sub     get_reference_mark
        {
        my $self        = shift;
        return $self->get_position_mark('text:reference-mark', shift);
        }

sub     get_reference_marks
        {
        my $self        = shift;
        return $self->get_elements(qr'reference-mark$|reference-mark-start$');
        }

sub     get_index_marks
        {
        my $self        = shift;
        my $type        = shift;

        my $filter;
        given ($type)
                {
                when (undef)
                        {
                        alert "Missing index mark type";
                        }
                when (["lexical", "alphabetical"])
                        {
                        $filter = 'alphabetical-index-mark';
                        }
                when ("toc")
                        {
                        $filter = 'toc-mark';
                        }
                when ("user")
                        {
                        $filter = 'user-index-mark';
                        }
                default
                        {
                        alert "Wrong index mark type";
                        }
                }
        return FALSE unless $filter;
        $filter = $filter . '$|' . $filter . '-start$';
        return $self->get_elements(qr($filter));
        }

sub     clean_marks
        {
        my $self        = shift;
        my $count = 0;
        my ($tag, $start, $end, $att, $id);
        foreach $start ($self->get_elements(qr'mark-start$'))
                {
                $tag = $start->get_tag;
                $att = $tag =~ /bookmark/ ? 'text:name' : 'text:id';
                $id = $start->get_attribute($att);
                unless ($id)
                        {
                        $start->delete; $count++;
                        next;
                        }
                $tag =~ s/start$/end/;
                $end = $self->get_element
                        ($tag, attribute => $att, value => $id);
                unless ($end)
                        {
                        $start->delete; $count++;
                        next;
                        }
                unless ($start->before($end))
                        {
                        $start->delete; $end->delete; $count += 2;
                        }
                }
        foreach $end ($self->get_elements(qr'mark-end$'))
                {
                $tag = $end->get_tag;
                $att = $tag =~ /bookmark/ ? 'text:name' : 'text:id';
                $id = $end->get_attribute($att);
                unless ($id)
                        {
                        $end->delete; $count++;
                        next;
                        }
                $tag =~ s/end$/start/;
                $start = $self->get_element
                        ($tag, attribute => $att, value => $id);
                unless ($start)
                        {
                        $end->delete; $count++;
                        next;
                        }
                unless ($end->after($start))
                        {
                        $start->delete; $end->delete; $count += 2;
                        }
                }
        return $count;
        }

sub     remove_bookmark
        {
        my $self        = shift;
        return $self->remove_position_mark('text:bookmark', shift);
        }

sub     check_bookmark
        {
        my $self        = shift;
        return $self->check_position_mark('text:bookmark', shift);
        }

sub     get_element_by_bookmark
        {
        my $self        = shift;
        my $name        = shift;
        my %opt         = @_;

        my $bookmark = $self->get_position_mark
                ('text:bookmark', $name, $opt{role});
        unless ($bookmark)
                {
                alert("Bookmark not found"); return FALSE;
                }
        if ($opt{tag})
                {
                return $bookmark->get_ancestor($opt{tag});
                }
        return $bookmark->parent;
        }

sub     get_paragraph_by_bookmark
        {
        my $self        = shift;
        my $name        = shift;
        my %opt         = @_;
        $opt{tag} = qr'text:(p|h)';
        return $self->get_element_by_bookmark($name, %opt);
        }

sub     get_bookmark_text
        {
        my $self        = shift;
        my ($start, $end) = $self->get_bookmark(shift);
        unless ($start && $end && $start->before($end))
                {
                alert "The required bookmark in not defined in the context";
                return undef;
                }
        my $text = "";
        my $n = $start->next_elt($self, TEXT_SEGMENT);
        while ($n && $n->before($end))
                {
                $text .= $n->get_text;
                $n = $n->next_elt($self, TEXT_SEGMENT);
                }
        return $text;
        }

sub     remove_reference_mark
        {
        my $self        = shift;
        return $self->remove_position_mark('text:reference-mark', shift);
        }

sub     check_reference_mark
        {
        my $self        = shift;
        return $self->check_position_mark('text:reference-mark', shift);
        }

sub     get_bibliography_marks
        {
        my $self        = shift;
        my $text        = shift;
        return defined $text ?
                $self->get_elements
                        (
                        'text:bibliography-mark',
                        attribute       => 'identifier',
                        value           => $text
                        )
                        :
                $self->get_elements('text:bibliography-mark');
        }

#--- note retrieval ----------------------------------------------------------

sub     get_note
        {
        my $self        = shift;
        my $id          = shift;
        unless ($id)
                {
                alert "Missing note identifier"; return FALSE;
                }
        return $self->get_element(
                'text:note',
                attribute       => 'id',
                value           => $id
                );
        }

sub     get_notes
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $class       = $opt{class} || $opt{note_class};
        my $label       = $opt{label};
        my $citation    = $opt{citation};

        my $xp =        './/text:note';
        $xp .= '[@text:note-class="' . $class . '"]'    if defined $class;
        if (defined $label || defined $citation)
                {
                $xp .= '/text:note-citation';
                $xp .= '[@text:label="' . $label . '"]'
                                                        if defined $label;
                $xp .= '[string()="' . $citation . '"]'
                                                        if defined $citation;
                my @result = ();
                foreach my $n ($self->get_xpath($xp))
                        {
                        push @result, $n->parent;
                        }
                return @result;
                }
        return $self->get_xpath($xp);
        }

sub     get_annotations
        {
        my $self        = shift;
        my %opt         = @_;
        my $date        = $opt{date};
        my $author      = $opt{author};

        my $xp = './/office:annotation';
        $xp .= '[@dc:date="' . $date . '"]'             if $date;
        $xp .= '[@dc:creator="' . $author . '"]'        if $author;

        return $self->get_xpath($xp);
        }

#--- tracked change retrieval ------------------------------------------------

sub     get_changes
        {
        my $self        = shift;
        my %opt         = @_;
        my $context     = $self;

        unless ($opt{date} || $opt{author})
                {
                return $context->get_elements('text:changed-region');
                }

        my @r = ();
        foreach my $ci ($context->descendants('text:changed-region'))
                {
                my ($elt, $text);
                if ($opt{date})
                        {
                        $elt = $ci->first_descendant('dc:date') or next;
                        $text = $elt->get_text or next;
                        if (ref $opt{date})
                                {
                                my $start       = ${opt{date}}[0];
                                my $end         = ${opt{date}}[1];
                                next if $start  && ($text lt $start);
                                next if $end    && ($text gt $end);
                                }
                        else
                                {
                                next unless $text eq $opt{date};
                                }
                        }
                if ($opt{author})
                        {
                        $elt = $ci->first_descendant('dc:creator') or next;
                        $text = $elt->get_text;
                        next unless $text eq $opt{author};
                        }
                push @r, $ci;
                }
        return @r;
        }

sub     get_change
        {
        my $self        = shift;
        return $self->get_element(
                'text:changed-region',
                attribute       => 'id',
                value           => shift
                );
        }

#--- section retrieval -------------------------------------------------------

sub     get_section
        {
        my $self        = shift;
        return $self->get_element
                ('text:section', attribute => 'text:name', value => shift);
        }

sub     get_sections
        {
        my $self        = shift;
        return $self->get_elements('text:section', @_);
        }

sub	get_parent_section
	{
	my $self	= shift;
	return $self->parent('text:section');
	}

#--- frame & draw page retrieval ---------------------------------------------

sub     get_shape
        {
        my $self        = shift;
        my $type        = shift;
        $type = 'draw:' . $type         unless $type =~ /:/;
        return $self->get_element(
                $type, attribute => 'draw:name', value => shift
                );
        }

sub     get_rectangle
        {
        my $self = shift; return $self->get_shape('rect', @_);
        }

sub     get_rectangles
        {
        my $self = shift; return $self->get_elements('draw:rect', @_);
        }

sub     get_ellipse
        {
        my $self = shift; return $self->get_shape('ellipse', @_);
        }

sub     get_ellipses
        {
        my $self = shift; return $self->get_elements('draw:ellipse', @_);
        }

sub     get_line
        {
        my $self = shift; return $self->get_shape('line', @_);
        }

sub     get_lines
        {
        my $self = shift; return $self->get_elements('draw:line', @_);
        }

sub     get_connector
        {
        my $self = shift; return $self->get_shape('connector', @_);
        }

sub     get_connectors
        {
        my $self = shift; return $self->get_elements('draw:connector', @_);
        }

sub     get_frame
        {
        my $self = shift; return $self->get_shape('frame', @_);
        }

sub	get_parent_frame
	{
	my $self	= shift;
	return $self->parent('draw:frame');
	}

sub     get_frames
        {
        my $self = shift; return $self->get_elements('draw:frame', @_);
        }

sub     get_draw_page_by_position
        {
        my $self        = shift;
        return $self->get_element('draw:page', position => shift);
        }

sub     get_draw_page_by_name
        {
        my $self        = shift;
        return $self->get_element(
                'draw:page', attribute => 'name', value => shift
                );
        }

sub     get_draw_page
        {
        my $self        = shift;
        my $arg         = shift;
        return $self->get_element(
                'draw:page', attribute => 'id', value => $arg
                )               ||
                $self->get_draw_page_by_name($arg);
        }

sub     get_draw_pages
        {
        my $self = shift; return $self->get_elements('draw:page', @_);
        }

#-----------------------------------------------------------------------------

sub     get_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift) or return undef;
        my $value       = $self->att($name);
        return output_conversion($value);
        }

sub     get_attributes
        {
        my $self        = shift;
        return undef unless $self->is_element;
        my $atts = $self->atts          or return undef;
        my %attr = %{$atts};
        my %result = ();
        $result{$_} = output_conversion($attr{$_}) for keys %attr;

        return wantarray ? %result : { %result };
        }

sub     set_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift) or return undef;
        my $value       = input_conversion(shift);
        if ($name =~ /color$/)
                {
                $value = color_code($value);
                }
	return defined $value ?
                $self->set_att($name, $value) : $self->del_attribute($name);
        }

sub     set_boolean_attribute
        {
        my $self        = shift;
        my ($name, $value) = @_;
        $value = odf_boolean($value);
        return $self->set_attribute($name, $value);
        }

sub     get_boolean_attribute
        {
        my $self        = shift;
        my $value       = $self->get_attribute(shift);
        given ($value)
                {
                when (undef)
                        {
                        return undef;
                        }
                when ('true')
                        {
                        return TRUE;
                        }
                when ('false')
                        {
                        return FALSE;
                        }
                default
                        {
                        alert("Improper ODF boolean");
                        return undef;
                        }
                }
        }

sub     input_convert_attributes
        {
        my $self        = shift;
        my $in          = shift;
        my %out         = ();
        my $prefix      = $self->ns_prefix;
        foreach my $kin (keys %{$in})
                {
                my $kout = $kin;
                unless ($kout =~ /:/)
                        {
                        $kout = $prefix . ':' . $kout;
                        }
                $kout =~ s/ /-/g;
                $out{$kout} = input_conversion($in->{$kin});
                }
        return wantarray ? %out : { %out };
        }

sub     set_attributes
        {
        my $self        = shift;
        my $attr        = shift         or return undef;
        my %attr        = ref $attr ? %{$attr} : ($attr, @_);

        foreach my $k (keys %attr)
                {
                $self->set_attribute($k, $attr{$k});
                }
        return $self->get_attributes;
        }

sub     del_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift);
        return $self->att($name) ? $self->del_att($name) : FALSE;
        }

sub     clear
        {
        my $self        = shift;
        return $self->_set_text('');
        }

sub     get_text
        {
        my $self        = shift;
        my %opt         = (recursive => FALSE, @_);
        my $text        = undef;
        unless ($self->is_element)
                {
                $text = $self->text;
                }
        elsif (is_true($opt{recursive}))
                {
                foreach my $t ($self->descendants(TEXT_SEGMENT))
                        {
                        $text .= $t->text;
                        }
                }
        else
                {
                $text = $self->text_only;
                }
        return output_conversion($text);
        }

sub     set_text
        {
        my $self        = shift;
        my $input       = shift;
        return undef unless defined $input;

        my $text = caller() ne 'XML::Twig::Elt' ?
                input_conversion($input) : $input;
        my $r = $self->_set_text($text);
        bless $_, 'ODF::lpOD::TextNode' for $self->children(TEXT_SEGMENT);
        return $r;
        }

sub     get_text_content
        {
        my $self        = shift;
        my $t           = "";
        foreach my $p ($self->descendants('text:p'))
                {
                $t .= ($p->get_text(@_) // "");
                }
        return $t;
        }

sub     set_text_content
        {
        my $self        = shift;
        my $text        = shift;
        my %opt         = @_;

        my @paragraphs = $self->descendants('text:p');
        my $p = shift @paragraphs;
        unless (defined $p)
                {
                $p = ODF::lpOD::Element->create('text:p');
                $p->paste_first_child($self);
                }
        else
                {
                $_->delete() for @paragraphs;
                }
        $p->set_style($opt{style}) if $opt{style};
        return $p->set_text($text);
        }

sub     get_family              {}

sub     get_name
        {
        my $self        = shift;
        return $self->get_attribute('name');
        }

sub     set_name
        {
        my $self        = shift;
        my $name        = shift;
        return undef unless defined $name;
        return caller() eq 'XML::Twig::Elt' ?
                $self->set_tag($name)           :
                $self->set_attribute('name' => $name);
        }

sub     get_size
        {
        my $self        = shift;
        my $sep         = shift // ', ';
        my $w = $self->get_attribute('svg:width');
        my $h = $self->get_attribute('svg:height');
        return undef unless (defined $w && defined $h);
        return wantarray ? ($w, $h) : join $sep, $w, $h;
        }

sub     set_size
        {
        my $self        = shift;
        my ($w, $h)     = input_2d_value(@_);
        $self->set_attribute('svg:width' => $w);
        $self->set_attribute('svg:height' => $h);
        return $self->get_size;
        }

sub     get_display
        {
        my $self        = shift;
        return is_true($self->get_attribute('display'));
        }

sub     set_display
        {
        my $self        = shift;
        return $self->set_attribute('display' => odf_boolean(shift));
        }

sub     get_position
        {
        my $self        = shift;
        my $sep         = shift // ', ';
        my $x = $self->get_attribute('svg:x');
        my $y = $self->get_attribute('svg:y');
        return undef unless (defined $x && defined $y);
        if (wantarray)
                {
                return ($x, $y);
                }
        else    {
                my $r;
                $r = join $sep, $x, $y if (defined $x && defined $y);
                return $r;
                }
        }

sub     set_position
        {
        my $self        = shift;
        my ($x, $y)     = input_2d_value(@_);
        $self->set_attribute('svg:x' => $x);
        $self->set_attribute('svg:y' => $y);
        return $self->get_position;
        }

sub     get_url
        {
        my $self	= shift;
        return $self->get_attribute('xlink:href');
        }

sub     set_url
        {
        my $self	= shift;
        return $self->set_attribute('xlink:href' => shift);
        }

sub     get_style
        {
        my $self        = shift;
        return $self->get_attribute('style name');
        }

sub     set_style
        {
        my $self        = shift;
        my $style       = shift;
        my $name;
        if (ref $style)
                {
                if ($style->isa('ODF::lpOD::Style'))
                        {
                        $name = $style->get_name;
                        }
                else
                        {
                        alert "Wrong style"; return undef;
                        }
                }
        else
                {
                $name = $style;
                }
        return $self->set_attribute('style name' => $name);
        }

sub     insert_element
        {
        my $self        = shift;
        my $tag         = $self->normalize_name(shift) or return undef;
        my %opt         =
                        (
                        position        => 'FIRST_CHILD',
                        @_
                        );
        my $position    = uc $opt{position};
        $position =~ s/ /_/g;
        my $new_elt;
        if (ref $tag)
                {
                if ($tag->parent && $position ne 'PARENT')
                        {
                        alert "Element already belonging to a tree";
                        return FALSE;
                        }
                $new_elt = $tag;
                }
        else
                {
                $new_elt = ODF::lpOD::Element->new($tag);
                }
        if (defined $opt{after})
                {
                $new_elt->paste_after($opt{after}); return $new_elt;
                }
        elsif (defined $opt{before})
                {
                $new_elt->paste_before($opt{before}); return $new_elt;
                }

        given($position)
                {
                when (/^(FIRST_CHILD|LAST_CHILD)$/)
                        {
                        $new_elt->paste((lc $position) => $self);
                        }
                when ('NEXT_SIBLING')
                        {
                        $new_elt->paste_after($self);
                        }
                when ('PREV_SIBLING')
                        {
                        $new_elt->paste_before($self);
                        }
                when ('WITHIN')
                        {
                        if ($opt{offset})
                            {
                            $new_elt->paste_within($self, $opt{offset});
                            }
                        else
                            {
                            $new_elt->paste_first_child($self);
                            }
                        }
                when ('PARENT')
                        {
                        if ($self->parent)
                                {
                                $new_elt->paste_before($self);
                                $self->move(last_child => $new_elt);
                                }
                        else
                                {
                                $self->paste_last_child($new_elt);
                                }
                        }
                default
                        {
                        alert("Wrong insertion option");
                        return FALSE;
                        }
                }
        return $new_elt;
        }

sub     append_element
        {
        my $self        = shift;
        return $self->insert_element(shift, position => 'LAST_CHILD');
        }

sub     insert
        {
        my $self        = shift;
        my $target      = shift         or return undef;
        return $target->insert_element($self, @_);
        }

sub     append
        {
        my $self        = shift;
        my $target      = shift         or return undef;
        return $target->append_element($self);
        }

sub	set_comment
	{
	my $self	= shift;
        unless ($self->parent)
                {
                alert "Not allowed in free element"; return undef;
                }
	my $text        = input_conversion(shift);
        my $cmt = ODF::lpOD::Element->create('#COMMENT' => $text);
        $cmt->paste_before($self);
        return $cmt;
	}

sub     set_annotation
        {
        my $self        = shift;
        my $a = ODF::lpOD::Annotation->create(@_);
        $a->paste_first_child($self);
        return $a;
        }

sub     serialize
        {
        my $self        = shift;
        my %opt         = process_options
                (
                empty_tags      => EMPTY_TAGS,
                @_
                );

        $opt{pretty} //= ($opt{indent} // lpod->debug);
        $self->set_pretty_print(PRETTY_PRINT) if is_true($opt{pretty});
        $self->set_empty_tag_style($opt{empty_tags});
        delete @opt{qw(pretty indent empty_tags)};
        return $self->sprint(%opt);
        }

#=============================================================================

sub     _search_forward
        {
        my $self        = shift;
        my $expr        = shift;
        my %opt         = (@_);

        my $offset      = $opt{offset};

        my ($target_node, $n, $start_pos, $end_pos, $match);
        if ($self->is_text)
                {
                $n = $self;
                }
        elsif ($opt{start_mark})
                {
                if ($opt{start_mark}->is_text)
                        {
                        $n = $opt{start_mark};
                        }
                else
                        {
                        $n = $opt{start_mark}
                                        ->last_descendant
                                        ->next_elt($self, TEXT_SEGMENT);
                        }
                }
        else
                {
                $n = $self->first_descendant(TEXT_SEGMENT);
                }
        my %info = $n->node_info() if $n;
        if (defined $offset)
                {
                while ($n && $offset >= $info{size})
                        {
                        if ($opt{end_mark} && ! $n->before($opt{end_mark}))
                                {
                                $n = undef; last;
                                }
                        $offset -= $info{size};
                        $n = $n->next_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        }
                }
        while ($n && !defined $start_pos)
                {
                if ($opt{end_mark} && ! $n->before($opt{end_mark}))
                        {
                        $n = undef; last;
                        }
                unless (defined $expr)
                        {
                        $start_pos = $offset;
                        $match = defined $opt{range} ?
                                substr($info{text}, $start_pos, $opt{range}) :
                                substr($info{text}, $start_pos);
                        $end_pos = $start_pos + length($match);
                        }
                else
                        {
                        ($start_pos, $end_pos, $match) =
                                search_string
                                        (
                                        $info{text},
                                        $expr,
                                        offset  => $offset,
                                        range   => $opt{range}
                                        );
                        }
                if (defined $start_pos)
                        {
                        $target_node = $n;
                        }
                else
                        {
                        $n = $n->next_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        $offset = 0;
                        }
                }
        return wantarray ?
                ($target_node, $start_pos, $match, $end_pos)    :
                $start_pos;
        }

sub     _search_backward
        {
        my $self        = shift;
        my $expr        = shift;
        my %opt         = (@_);

        my $offset      = $opt{offset};
        if (defined $offset && $offset > 0)
                {
                $offset = -abs($offset);
                }
        my ($target_node, $n, $start_pos, $end_pos, $match);

        if ($self->is_text)
                {
                $n = $self;
                }
        elsif ($opt{start_mark})
                {
                unless ($opt{start_mark}->is_text)
                        {
                        $n = $opt{start_mark}->prev_elt($self, TEXT_SEGMENT);
                        }
                else
                        {
                        $n = $opt{start_mark};
                        }
                }
        else
                {
                $n = $self->last_descendant(TEXT_SEGMENT);
                }
        my %info = $n->node_info() if $n;
        if (defined $offset)
                {
                while ($n && abs($offset) >= $info{size})
                        {
                        if ($opt{end_mark} && ! $n->after($opt{end_mark}))
                                {
                                $n = undef; last;
                                }
                        $offset += $info{size};
                        $n = $n->prev_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        }
                }
        while ($n && !defined $start_pos)
                {
                if ($opt{end_mark} && ! $n->before($opt{end_mark}))
                        {
                        $n = undef; last;
                        }
                unless (defined $expr)
                        {
                        $start_pos = $offset;
                        $match = defined $opt{range} ?
                                substr($info{text}, $start_pos, $opt{range}) :
                                substr($info{text}, $start_pos);
                        $end_pos = $start_pos + length($match);
                        }
                else
                        {
                        ($start_pos, $end_pos, $match) =
                                search_string
                                        (
                                        $info{text},
                                        $expr,
                                        offset  => $offset,
                                        range   => $opt{range}
                                        );
                        }
                if (defined $start_pos)
                        {
                        $target_node = $n;
                        }
                else
                        {
                        $n = $n->next_elt($self, TEXT_SEGMENT);
                        %info = $n->node_info() if $n;
                        $offset = 0;
                        }
                }
        return wantarray ?
                ($target_node, $start_pos, $match, $end_pos)    :
                $start_pos;
        }

sub     search
        {
        my $self        = shift;
        my $expr        = input_conversion(shift);
        my %opt         = process_options
                (
                backward        => FALSE,
                start_mark      => undef,
                end_mark        => undef,
                offset          => undef,
                range           => undef,
                @_
                );
        unless (defined $expr || defined $opt{offset})
                {
                alert("Missing search argument");
                return undef;
                }
        my $backward = $opt{backward}; delete $opt{backward};
        if (defined $opt{offset} && $opt{offset} < 0)
                {
                $backward = TRUE;
                }
        my %r = ();
        my $match = undef;
        if(is_false($backward))
                {
                ($r{segment}, $r{offset}, $match, $r{end}) =
                        $self->_search_forward($expr, %opt);
                }
        else
                {
                ($r{segment}, $r{offset}, $match, $r{end}) =
                        $self->_search_backward($expr, %opt);
                }
        $r{match} = output_conversion($match);
        return wantarray ? %r : { %r };
        }

sub     replace
        {
        my $self        = shift;
        return $self->replace_element(@_) if caller() eq 'XML::Twig::Elt';
        my $expr        = shift;
        my $repl        = shift;
        return $self->count_matches($expr, @_) unless defined $repl;
        my %opt         =
                (
                deep    => TRUE,
                @_
                );
        my $deep = $opt{deep}; delete $opt{deep};
        my $count = 0;
        foreach my $segment ($self->text_segments(deep => $deep))
                {
                $count += $segment->replace_in_text_segment
                                ($expr, $repl, %opt);
                }
        return $count;
        }

sub     count_matches
        {
        my $self        = shift;
        my $expr        = shift;
        my %opt         =
                (
                deep    => TRUE,
                @_
                );
        my $count = 0;
        foreach my $segment ($self->text_segments(deep => $opt{deep}))
                {
                my $t = $segment->get_text;
                $count += count_substrings($t, $expr);
                }
        return $count;
        }

#=============================================================================

our     $AUTOLOAD;

sub     AUTOLOAD
        {
        $AUTOLOAD       =~ /(.*:)(.*)/;
        my $package     = $1;
        my $method      = $2;
        my $element     = shift;

        $method =~ /^([gs]et)_(.*)/;
        my $action      = $1;

        no strict;
        my $target = ${$package . "ATTRIBUTE"}{$2};
        use strict;
        unless ($action && $target)
                {
                alert "Unknown method $method @_";
                return undef;
                }
        my $name = $target->{attribute};
        my $type = $target->{type};

        my $value = undef;
        given ($action)
                {
                when ('get')
                        {
                        $value = $element->get_attribute($name, @_);
                        return ($type and ($type eq 'boolean')) ?
                                                is_true($value) : $value;
                        }
                when ('set')
                        {
                        $value = input_conversion(shift);
                        if ($type)
                                {
                                $value = check_odf_value($value, $type);
                                }
                        return defined $value ?
                                $element->set_att($name => $value) :
                                $element->del_attribute($name);
                        }
                default
                        {
                        alert "Unknown method $method @_";
                        }
                }

        return undef;
        }

sub     not_allowed
        {
        my $self        = shift;
        my $tag         = $self->get_tag;
        my $class       = ref $self;
        alert "Not allowed for this $tag ($class) element";
        return undef;
        }

#=============================================================================
package ODF::lpOD::TextNode;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-02-27T00:44:46';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN
        {
        *create                         = *XML::Twig::Elt::new;
        *get_tag                        = *XML::Twig::Elt::tag;
        *set_tag                        = *ODF::lpOD::Element::set_tag;
        *set_text                       = *ODF::lpOD::Element::set_text;
        *get_parent                     = *XML::Twig::Elt::parent;
        *get_ancestor                   = *XML::Twig::Elt::parent;
        *previous_sibling               = *XML::Twig::Elt::prev_sibling;
        *get_root                       = *XML::Twig::Elt::root;
        *is_element                     = *XML::Twig::Elt::is_elt;
        *is_text_segment                = *XML::Twig::Elt::is_text;
        *_set_text                      = *XML::Twig::Elt::set_text;
        *_get_text                      = *XML::Twig::Elt::text;
        *_set_tag                       = *XML::Twig::Elt::set_tag;
        *replace_element                = *XML::Twig::Elt::replace;
        }

#-----------------------------------------------------------------------------

sub     node_info
        {
        my $self        = shift;
        my %i           = ();
        $i{text}        = $self->_get_text;
        $i{size}        = length($i{text});
        $i{tag}         = TEXT_SEGMENT;
        $i{class}       = __PACKAGE__;
        $i{attributes}  = undef;
        return %i;
        }

sub     get_text
        {
        my $self        = shift;
        return output_conversion($self->text);
        }

#=============================================================================
package ODF::lpOD::BibliographyMark;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:37:35';
#=============================================================================
package ODF::lpOD::Note;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2011-02-22T00:16:40';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_text               = *set_body;
        }

#-----------------------------------------------------------------------------

sub	_create  { ODF::lpOD::Note->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
	my $class	= ref($caller) || $caller;
        my $id          = shift;
        unless ($id)
                {
                alert "Missing mandatory note identifier";
                return FALSE;
                }
        my %opt = process_options
                (
                class           => 'footnote',
                @_
                );
        my $note = ODF::lpOD::Element->create('text:note');
        $note->set_id($id);
        $note->set_citation($opt{citation}, $opt{label});
        $note->{style}  = $opt{style};
        if ($opt{body})
                {
                $note->set_body(@{$opt{body}});
                }
        else
                {
                $note->set_body($opt{text});
                }

        return $note;
        }

#-----------------------------------------------------------------------------

sub     get_citation
        {
        my $self        = shift;
        my $c   = $self->first_child('text:note-citation')
                                or return undef;
        return $c->get_text;
        }

sub     set_citation
        {
        my $self        = shift;
        my $text        = shift;
        my $label       = shift;
        my $c = $self->set_child('text:note-citation');
        $c->set_attribute('label' => $label) if defined $label;
        $c->set_text($text);
        return $c;
        }

sub     set_label
        {
        my $self        = shift;
        my $label       = shift;
        my $c = $self->set_child('text:note-citation');
        $c->set_attribute('label' => $label) if defined $label;
        return $c;
        }

sub     get_label
        {
        my $self        = shift;
        my $c   = $self->first_child('text:note-citation')
                                or return undef;
        return $c->get_attribute('label');
        }

sub     get_body
        {
        my $self        = shift;
        return $self->first_child('text:note-body');
        }

sub     set_body
        {
        my $self        = shift;
        my $body =      $self->get_body();
        if ($body)
                {
                $body->cut_children;
                }
        else
                {
                $body = $self->append_element('text:note-body');
                }
        foreach my $arg (@_)
                {
                if (ref $arg)
                        {
                        $arg->paste_last_child($body);
                        }
                else
                        {
                        my $p = ODF::lpOD::Paragraph->create(
                                text => $arg, style => $self->{style}
                                );
                        $p->paste_last_child($body);
                        }
                }
        return $body;
        }

#=============================================================================
package ODF::lpOD::Annotation;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2011-02-15T11:16:59';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_creator            = *set_author;
        *get_creator            = *get_author;
        }

#-----------------------------------------------------------------------------

sub	_create  { ODF::lpOD::Annotation->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt = @_;
        my $a   = ODF::lpOD::Element->create('office:annotation');
        $a->set_date($opt{date});
        $a->set_author($opt{author});
        $a->set_style($opt{style});
        $a->set_size($opt{size})                if defined $opt{size};
        $a->set_position($opt{position})        if defined $opt{position};
        $a->set_display($opt{display});
        my $content = $opt{content};
        unshift @$content, $opt{text}   if defined $opt{text};
        $a->set_content(@$content)      if $content;
        return $a;
        }

#-----------------------------------------------------------------------------

sub     set_date
        {
        my $self        = shift;
        my $date        = shift;
        my $elt = $self->set_child('dc:date');
        unless ($date)
                {
                return $elt->set_text(iso_date);
                }
        else
                {
                my $d = check_odf_value($date, 'date');
                unless ($d)
                        {
                        alert "Wrong date"; return undef;
                        }
                return $elt->set_text($d);
                }
        }

sub     get_date
        {
        my $self        = shift;
        my $elt = $self->first_child('dc:date')         or return undef;
        return $elt->get_text;
        }

sub     set_author
        {
        my $self        = shift;
        my $elt = $self->set_child('dc:creator');
        return $elt->set_text
                (
                shift
                        //
                (scalar getlogin())
                        //
                (scalar getpwuid($<))
                        //
                $<
                );
        }

sub     get_author
        {
        my $self        = shift;
        my $elt = $self->first_child('dc:creator')      or return undef;
        return $elt->get_text;
        }

sub     get_content
        {
        my $self        = shift;
        return $self->children;
        }

sub     set_content
        {
        my $self        = shift;
        $self->cut_children(qr'^text');
        foreach my $arg (@_)
                {
                if (ref $arg)
                        {
                        $arg->paste_last_child($self);
                        }
                else
                        {
                        my $p = ODF::lpOD::Paragraph->create(
                                text => $arg, style => $self->{style}
                                );
                        $p->paste_last_child($self);
                        }
                }
        return $self->get_content;
        }

sub     set_style
        {
        my $self        = shift;
        return $self->{style} = shift;
        }

sub     get_style
        {
        my $self        = shift;
        return $self->{style};
        }

sub     set_text
        {
        my $self        = shift;
        return $self->set_content(@_);
        }

sub     get_text
        {
        my $self        = shift;
        return $self->get_text_content(@_);
        }

#=============================================================================
package ODF::lpOD::ChangedRegion;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:39:17';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_changed_context
        {
        my $self        = shift;
        my $tcr = $self->parent('text:tracked-changes');
        my $context = $tcr ? $tcr->parent() : undef;
        unless ($context)
                {
                alert "Unknown tracked change context";
                }
        return $context;
        }

sub     get_info
        {
        my $self        = shift;
        my $tag         = shift;
        $tag = 'dc:' . $tag unless $tag =~ /:/;
        my $info = $self->first_descendant($tag)        or return undef;
        return $info->get_text;
        }

sub     get_date
        {
        my $self        = shift;
        return $self->get_info('date');
        }

sub     get_author
        {
        my $self        = shift;
        return $self->get_info('creator');
        }

sub     get_type
        {
        my $self        = shift;
        my $t = $self->first_child      or return undef;
        my $type = $t->get_tag; $type =~ s/^text://;
        return $type;
        }

sub     get_deleted_content
        {
        my $self        = shift;
        my $deleted = $self->first_child('text:deletion') or return undef;
        my @content = ();
        foreach my $e ($deleted->children)
                {
                my $tag = $e->get_tag;
                push @content, $e unless $tag eq 'office:change-info';
                }
        return wantarray ? @content : [ @content ];
        }

sub     get_change_mark
        {
        my $self        = shift;
        my $id = $self->get_id;
        my $context = $self->get_changed_context        or return undef;
        my $type = $self->get_type();
        unless ($type)
                {
                alert "Unknown change type"; return undef;
                }
        my $tag = ($type eq 'deletion') ? 'text:change' : 'text:change-start';
        return $context->get_element(
                        $tag,
                        attribute       => 'change id',
                        value           => $id
                        );
        }

sub     get_insertion_marks
        {
        my $self        = shift;
        my $id = $self->get_id;
        my $context = $self->get_changed_context        or return undef;
        my $start = $context->get_element(
                        'text:change-start',
                        attribute       => 'change id',
                        value           => $id
                        );
        my $end   = $context->get_element(
                        'text:change-end',
                        attribute       => 'change id',
                        value           => $id
                        );
        return wantarray ? ($start, $end) : [ $start, $end ];
        }

#=============================================================================
package ODF::lpOD::FileEntry;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:39:36';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_text       = *not_allowed;
        *insert_element = *not_allowed;
        *append_element = *not_allowed;
        }

#-----------------------------------------------------------------------------

our     @ALLOWED_ATTRIBUTES = ('manifest:media-type', 'manifest:full-path');

sub     set_attribute
        {
        my $self        = shift;
        my $name        = $self->normalize_name(shift);
        unless ($name ~~ [ @ALLOWED_ATTRIBUTES ])
                {
                alert "Attribute $name is not allowed";
                return FALSE;
                }
        return $self->SUPER::set_attribute($name, @_);
        }

sub     get_path
        {
        my $self        = shift;
        return $self->get_attribute('full path');
        }

sub     set_path
        {
        my $self        = shift;
        my $path        = shift;
        unless ($path)
                {
                alert "Missing or wrong path"; return FALSE;
                }
        my $old_path = $self->get_path;
        my $lpod_part = $self->lpod_part;
        my $other = $lpod_part ? $lpod_part->get_entry($path) : undef;
        if ($other)
                {
                if ($other == $self)
                        {
                        return TRUE;
                        }
                else
                        {
                        alert "Non unique entry path $path";
                        return FALSE;
                        }
                }
        $self->set_attribute('full path' => $path);
        if ($path =~ /.\/$/)
                {
                $self->set_attribute('media type' => "");
                }
        return TRUE;
        }

sub     get_type
        {
        my $self        = shift;
        return $self->get_attribute('media type');
        }

sub     set_type
        {
        my $self        = shift;
        my $type        = shift;
        return $self->set_attribute('media type' => $type);
        }

#=============================================================================
1;
