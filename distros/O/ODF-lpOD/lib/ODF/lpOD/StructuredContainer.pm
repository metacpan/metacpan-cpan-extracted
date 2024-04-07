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
#       Structured containers : Sections, lists, draw pages, frames, shapes...
#-----------------------------------------------------------------------------
package ODF::lpOD::StructuredContainer;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2011-11-15T19:52:49';
use ODF::lpOD::Common;
#=============================================================================
package ODF::lpOD::Section;
use base 'ODF::lpOD::StructuredContainer';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2011-11-15T19:52:49';
use ODF::lpOD::Common;
#=============================================================================

BEGIN   {
        *set_hyperlink          = *set_source;
        *get_hyperlink          = *get_source;
        *set_url                = *set_source;
        *get_url                = *get_source;
        }

#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Section->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing section name";
                return FALSE;
                }

        my %opt =
                (
                style           => undef,
                url             => undef,
                display         => undef,
                condition       => undef,
                protected       => undef,
                key             => undef,
                @_
                );

        my $s = ODF::lpOD::StructuredContainer->create('text:section');
        if (defined $opt{url} or defined $opt{source})
                {
                my $link = $opt{url} || $opt{source};
                $s->set_source($link);
                $opt{protected} = TRUE;
                }
        $s->set_protected($opt{protected});
        $s->set_name($name);
        $s->set_style($opt{style});
        $s->set_attribute('protection key', $opt{key});
        $s->set_display($opt{display});
        $s->set_attribute('condition', $opt{condition});

        return $s;
        }

#-----------------------------------------------------------------------------

sub     set_display
        {
        my $self        = shift;
        my $value       = shift // 'true';
        unless ($value eq 'true' || $value eq 'none' || $value eq 'condition')
                {
                if ($value == TRUE)
                        {
                        $value = 'true';
                        }
                elsif ($value == FALSE)
                        {
                        $value = 'none';
                        }
                else
                        {
                        alert "Wrong display parameter"; return undef;
                        }
                }
        $self->set_attribute('display' => $value);
        }

sub     get_display
        {
        my $self        = shift;
        my $value = $self->get_attribute('display');
        if (!defined $value)     { return TRUE   }
        elsif ($value eq 'true') { return TRUE   }
        elsif ($value eq 'none') { return FALSE  }
        else                     { return $value }
        }

sub     set_source
        {
        my $self        = shift;
        my $url         = shift;
        my %attr        = @_;

        my $source = $self->insert_element('section source');
        $source->set_attribute('xlink:href', $url);
        $source->set_attributes({%attr});
        $self->set_protected(TRUE);
        return $source;
        }

sub     get_source
        {
        my $self        = shift;
        my $source = $self->get_element('section source') or return undef;
        return wantarray ?
                $source->get_attributes()               :
                $source->get_attribute('xlink:href');
        }

#=============================================================================
package ODF::lpOD::List;
use base 'ODF::lpOD::StructuredContainer';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2012-05-02T09:09:28';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::List->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = process_options(@_);
        my $list = ODF::lpOD::StructuredContainer->create('text:list');
        $list->set_style($opt{style});
        $list->set_id($opt{id});
        return $list;
        }

#-----------------------------------------------------------------------------

sub     get_id
        {
        my $self        = shift;
        return $self->get_attribute('xml:id');
        }

sub     set_id
        {
        my $self        = shift;
        return $self->set_attribute('xml:id', shift);
        }

sub     get_item
        {
        my $self        = shift;
        my $p           = shift;
        if (is_numeric($p))
                {
                return $self->get_element('text:list-item', position => $p);
                }
        push @_, $p;
        return $self->get_element('text:list-item', @_);
        }

sub     get_item_list
        {
        my $self        = shift;
        return $self->get_element_list('text:list-item', @_);
        }

sub     add_item
        {
        my $self        = shift;
        my %opt         = process_options
                (
                number          => 1,
                @_
                );
        my $ref_elt     = $opt{after} || $opt{before};
        my $position    = undef;
        if ($ref_elt)
                {
                if ($opt{before} && $opt{after})
                        {
                        alert "'before' and 'after' are mutually exclusive";
                        return FALSE;
                        }
                $position = $opt{before} ? 'before' : 'after';
                $ref_elt = $self->get_item($ref_elt) unless ref $ref_elt;
                unless  (
                        $ref_elt->is('text:list-item')
                                &&
                        $ref_elt->parent() == $self
                        )
                        {
                        alert "Wrong list item $position reference";
                        return FALSE;
                        }
                }
        my $number = $opt{number};
        my $text = $opt{text};
        my $style = $opt{style};
        my $start = $opt{start_value};
        delete @opt{qw(number before after text style start_value)};
        return undef unless $number && ($number > 0);
        my $elt;
        if ($ref_elt)
                {
                $elt = $ref_elt->clone;
                $elt->cut_children;
                }
        else
                {
                $elt = ODF::lpOD::Element->create('text:list-item');
                }
        if (defined $text || defined $style)
                {
                my $p = ODF::lpOD::Paragraph->create
                                (text => $text, style => $style);
                $p->paste_last_child($elt);
                }
        if ($ref_elt)
                {
                $elt->paste($position, $ref_elt);
                }
        else
                {
                $elt->paste_last_child($self);
                }
        my @items = ();
        push @items, $elt;
        if ($number)
                {
                while ($number > 1)
                        {
                        my $cp = $elt->clone;
                        $cp->paste_after($elt);
                        push @items, $cp;
                        $number--;
                        }
                }
        $elt->set_attribute('start value', $start) if defined $start;
        return  wantarray ? @items : $elt;
        }

sub     set_header
        {
        my $self        = shift;
        my $h = $self->get_element('text:list-header');
        $h->delete if $h;
        $h = ODF::lpOD::Element->create('text:list-header');
        $h->paste_first_child($self);
        while (@_)
                {
                my $c = shift;
                my $elt = ref $c ?
                        $c : ODF::lpOD::Paragraph->create(text => $c);
                $elt->paste_last_child($h);
                }
        return $h;
        }

#=============================================================================
package ODF::lpOD::DrawPage;
use base 'ODF::lpOD::StructuredContainer';
our $VERSION    = '1.004';
use constant PACKAGE_DATE => '2011-11-15T19:52:49';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::DrawPage->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $id          = shift;
        unless ($id)
                {
                alert "Missing draw page identifier"; return FALSE;
                }
        my %opt         = @_;
        my $dp = ODF::lpOD::StructuredContainer->create('draw:page');
        $dp->set_id($id);
        $dp->set_name($opt{'name'});
        $dp->set_style($opt{style});
        $dp->set_master($opt{master});
        $dp->set_layout($opt{layout} );
        return $dp;
        }

#-----------------------------------------------------------------------------

sub     get_master
        {
        my $self        = shift;
        return $self->get_attribute('master page name');
        }

sub     set_master
        {
        my $self        = shift;
        return $self->set_attribute('master page name', shift);
        }

sub     get_layout
        {
        my $self        = shift;
        return $self->get_attribute
                ('presentation:presentation-page-layout-name');
        }

sub     set_layout
        {
        my $self        = shift;
        return $self->set_attribute
                ('presentation:presentation-page-layout-name', shift);
        }

sub     get_title_frame
        {
        my $self        = shift;
        return $self->get_element
                (
                'draw:frame',
                attribute       => 'presentation:class',
                value           => 'title'
                );
        }

sub     get_title
        {
        my $self        = shift;
        my $frame = $self->get_title_frame      or return undef;
        my $p = $frame->get_paragraph           or return undef;
        return $p->get_text;
        }

#=============================================================================
package ODF::lpOD::Shape;
use base 'ODF::lpOD::StructuredContainer';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2011-11-15T19:52:49';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Shape->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = process_options(@_);
        my $tag = $opt{tag}; $tag = 'draw:' . $tag unless $tag =~ /:/;
        my $f = ODF::lpOD::StructuredContainer->create($tag);
        $f->set_attribute('name' => $opt{name});
        $f->set_style($opt{style});
        $f->set_text_style($opt{text_style});
        $f->set_position($opt{position});
        if (defined $opt{page})
                {
                $f->set_anchor_page($opt{page});
                }
        else
                {
                $f->set_attribute('text:anchor-type' => $opt{anchor_type});
                }
        $f->set_title($opt{title});
        $f->set_description($opt{description});
        delete @opt
                {qw(
                        tag name style size position page
                        anchor_type title description
                )};
        foreach my $a (keys %opt)
                {
                $f->set_attribute($a => $opt{$a});
                }
        return $f;
        }

#-----------------------------------------------------------------------------

sub     input_2d
        {
        my $self        = shift;
        return input_2d_value(@_);
        }

sub     set_anchor_page
        {
        my $self        = shift;
        my $number      = shift;
        $self->set_attribute('text:anchor-page-number' => $number);
        $self->set_attribute('text:anchor-type' => 'page');
        return $number;
        }

sub     get_anchor_page
        {
        my $self        = shift;
        return $self->get_attribute('text:anchor-page-number');
        }

sub     set_title
        {
        my $self        = shift;
        my $t = $self->set_last_child('svg:title', shift);
        return $t;
        }

sub     get_title
        {
        my $self        = shift;
        my $t = $self->get_element('svg:title') or return undef;
        return $t->get_text;
        }

sub     set_description
        {
        my $self        = shift;
        my $t = $self->set_last_child('svg:desc', shift);
        return $t;
        }

sub     get_description
        {
        my $self        = shift;
        my $t = $self->get_element('svg:desc') or return undef;
        return $t->get_text;
        }

sub     set_text_style
        {
        my $self        = shift;
        return $self->set_attribute('text style name' => shift);
        }

sub     get_text_style
        {
        my $self        = shift;
        return $self->get_attribute('text style name');
        }

#=============================================================================
package ODF::lpOD::Area;
use base 'ODF::lpOD::Shape';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2011-02-19T19:54:55';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Area->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = @_;
        my $size        = $opt{size};
        delete @opt {qw(start end size)};
        my $a = ODF::lpOD::Shape->create(%opt) or return undef;
        $a->set_size($size);
        return $a;
        }

#=============================================================================
package ODF::lpOD::Rectangle;
use base 'ODF::lpOD::Area';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:55:59';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Rectangle->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $r = ODF::lpOD::Area->create(tag => 'rect', @_);
        }

#=============================================================================
package ODF::lpOD::Ellipse;
use base 'ODF::lpOD::Area';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:56:09';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Ellipse->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return ODF::lpOD::Area->create(tag => 'ellipse', @_);
        }

#=============================================================================
package ODF::lpOD::Vector;
use base 'ODF::lpOD::Shape';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:56:38';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Vector->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = @_;
        my $start       = $opt{start};
        my $end         = $opt{end};
        delete @opt {qw(start end position size)};
        my $v = ODF::lpOD::Shape->create(%opt);
        $v->set_start_position($start);
        $v->set_end_position($end);
        return $v;
        }

#-----------------------------------------------------------------------------

sub     set_start_position
        {
        my $self        = shift;
        my ($x, $y)     = input_2d_value(@_);
        $self->set_attribute('svg:x1' => $x);
        $self->set_attribute('svg:y1' => $y);
        return ($x, $y);
        }

sub     set_end_position
        {
        my $self        = shift;
        my ($x, $y)     = input_2d_value(@_);
        $self->set_attribute('svg:x2' => $x);
        $self->set_attribute('svg:y2' => $y);
        return ($x, $y);
        }

sub     get_position
        {
        my $self        = shift;
        my @p           =
                (
                $self->get_attribute('svg:x1'),
                $self->get_attribute('svg:y1'),
                $self->get_attribute('svg:x2'),
                $self->get_attribute('svg:y2')
                );
        return wantarray ? @p : [ @p ];
        }

sub     set_position
        {
        my $self        = shift;
        my $arg         = shift;
        my ($x1, $y1, $x2, $y2);
        if (ref $arg)
                {
                ($x1, $y1, $x2, $y2) = @{$arg};
                }
        else
                {
                ($x1, $y1, $x2, $y2) = ($arg, @_);
                }
        $self->set_attribute('svg:x1' => $x1);
        $self->set_attribute('svg:y1' => $y1);
        $self->set_attribute('svg:x2' => $x2);
        $self->set_attribute('svg:y2' => $y2);
        return wantarray ? ($x1, $y1, $x2, $y2) : [ ($x1, $y1, $x2, $y2) ];
        }

#=============================================================================
package ODF::lpOD::Line;
use base 'ODF::lpOD::Vector';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T18:15:40';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Line->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return ODF::lpOD::Vector->create(tag => 'line', @_);
        }

#=============================================================================
package ODF::lpOD::Connector;
use base 'ODF::lpOD::Vector';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:58:03';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Connector->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = process_options(@_);
        my $cs = $opt{connected_shapes};
        my $gp = $opt{glue_points};
        my $type = $opt{type};
        delete @opt{qw(connected_shapes glue_points type)};
        my $connector = ODF::lpOD::Vector->create(tag => 'connector', %opt);
        $connector->set_connected_shapes($cs);
        $connector->set_glue_points($gp);
        $connector->set_type($type);
        return $connector;
        }

#-----------------------------------------------------------------------------

sub     set_connected_shapes
        {
        my $self        = shift;
        my $arg         = shift;
        my $ra = ref $arg       or return undef;
        my ($start, $end);
        if ($ra eq 'ARRAY')
                {
                ($start, $end) = @$arg;
                }
        else
                {
                ($start, $end) = ($arg, @_);
                }
        $self->set_attribute('start shape' => $start);
        $self->set_attribute('end shape' => $end);
        return wantarray ? ($start, $end) : [ ($start, $end) ];
        }

sub     get_connected_shapes
        {
        my $self        = shift;
        my $start = $self->get_attribute('start shape');
        my $end = $self->get_attribute('end shape');
        return wantarray ? ($start, $end) : [ ($start, $end) ];
        }

sub     set_glue_points
        {
        my $self        = shift;
        my $arg         = shift;
        my ($sgp, $egp);
        if (ref $arg)
                {
                ($sgp, $egp) = @$arg;
                }
        else
                {
                ($sgp, $egp) = ($arg, @_);
                }
        $self->set_attribute('start glue point' => $sgp);
        $self->set_attribute('end glue point' => $egp);
        return wantarray ? ($sgp, $egp) : [ ($sgp, $egp) ];
        }

sub     get_glue_points
        {
        my $self        = shift;
        my $sgp = $self->get_attribute('start glue point');
        my $egp = $self->get_attribute('end glue point');
        return wantarray ? ($sgp, $egp) : [ ($sgp, $egp) ];
        }

sub     set_type
        {
        my $self        = shift;
        my $type        = shift         or return undef;
        unless ($type =~ /^(standard|lines|line|curve)$/)
                {
                alert "Not allowed connector type $type";
                return FALSE;
                }
        $self->set_attribute('type' => $type);
        return $type;
        }

sub     get_type
        {
        my $self        = shift;
        return $self->get_attribute('type');
        }

#=============================================================================
package ODF::lpOD::Frame;
use base 'ODF::lpOD::Area';
our $VERSION    = '1.007';
use constant PACKAGE_DATE => '2012-02-20T08:25:26';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Frame->create(@_) }

sub     _create_text
        {
        my $text        = shift;
        return ODF::lpOD::Frame->create(text => $text, @_);
        }

sub     _create_image
        {
        my $link        = shift;
        return ODF::lpOD::Frame->create(image => $link, @_);
        }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = process_options(@_);
        $opt{tag} = 'frame';
        my $fr;
        my $pc = $opt{class}; delete $opt{class};
        if ($opt{image})
                {
                if ($opt{text})
                        {
                        alert   "image and text parameters "    .
                                "are mutually exlusive";
                        return undef;
                        }
                my $link = $opt{image}; delete $opt{image};
                $fr = ODF::lpOD::Area->create(%opt) or return undef;
                $link && $fr->set_image($link);
                }
        elsif ($opt{text})
                {
                my $text = $opt{text}; delete $opt{text};
                $fr = ODF::lpOD::Area->create(%opt) or return undef;
                $fr->set_text_box($text);
                }
        else
                {
                $fr = ODF::lpOD::Area->create(%opt);
                }
        $fr->set_attribute('presentation:class' => $pc) if $pc;
        return $fr;
        }

#-----------------------------------------------------------------------------

sub     get_image
        {
        my $self        = shift;
        return $self->get_element('draw:image');
        }

sub     set_image
        {
        my $self        = shift;
        my $source      = shift;
        my $link;
        if (ref $source)
                {
                if ($source->is('draw:image'))
                        {
                        $source->paste_last_child($self);
                        return $source;
                        }
                else
                        {
                        alert "Non-valid image element";
                        return FALSE;
                        }
                }
        unless ($source)
                {
                alert "Missing image URL"; return FALSE;
                }
        my %opt = @_;
        my ($w, $h) = $self->get_size;
        my $sized = (defined $w && defined $h);
        if (is_true($opt{load}))
                {
                my $doc = $self->document;
                if ($doc && $doc->{container})
                        {
                        unless ($sized || defined $opt{size})
                                {
                                ($link, $opt{size}) =
                                        $doc->add_image_file($source);
                                }
                        else
                                {
                                $link = $doc->add_image_file($source);
                                }
                        }
                else
                        {
                        alert "Image loading not allowed out of a document";
                        return FALSE;
                        }
                }
        else
                {
                $link = $source;
                }
        my $image = $self->set_first_child('draw:image');
        if (defined $opt{size})
                {
                $self->set_size($opt{size});
                delete $opt{size};
                }
        else
                {
                unless ($sized)
                        {
                        my $doc;
                        my $size;
                        $doc = $self->get_document if $source =~ /^Pictures\//;
                        if ($doc)
                                {
                                my $st = $doc->get_stored_part($source);
                                if ($st->{data})
                                        {
                                        $size = is_true($st->{string}) ?
                                                image_size(\$st->{data}) :
                                                image_size($st->{data});
                                        }
                                else
                                        {
                                        $size = image_size
                                                ($source, document => $doc);
                                        }
                                }
                        else
                                {
                                $size = image_size($source);
                                }
                        $self->set_size($size);
                        }
                }
        $image->set_attribute('xlink:href' => $link);
        foreach my $o (keys %opt)
                {
                my $att = ($o =~ /:/) ? $o : 'xlink:' . $o;
                $image->set_attribute($att => $opt{$o});
                }
        return $image;
        }

#-----------------------------------------------------------------------------

sub     get_text_box
        {
        my $self        = shift;
        return $self->get_element('draw:text-box');
        }

sub     set_text_box
        {
        my $self        = shift;
        my $t = $self->set_first_child('draw:text-box');
        my @list        = @_;
        foreach my $e (@list)
                {
                if (ref $e)
                        {
                        $e->paste_last_child($t);
                        }
                else
                        {
                        ODF::lpOD::Paragraph->create(text => $e)
                                                ->paste_last_child($t);
                        }
                }
        return $t;
        }

sub     set_hyperlink
        {
        my $self        = shift;
        unless ($self->parent)
                {
                alert "Not allowed with non-attached frames";
                return FALSE;
                }
        my %opt         = process_options(@_);
        unless ($opt{url})
                {
                alert("Missing URL"); return FALSE;
                }
        $opt{'xlink:href'}      = $opt{url};
        $opt{'office:name'}     = $opt{name};
        delete @opt{qw(url name)};
        return $self->set_parent('draw:a', undef, %opt);
        }

sub     get_hyperlink
        {
        my $self        = shift;
        my $parent = $self->parent;
        return ($parent && $parent->is('draw:a')) ? $parent : undef;
        }

#=============================================================================
package ODF::lpOD::Image;
use base 'ODF::lpOD::StructuredContainer';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2011-11-15T19:52:49';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Image->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt         = @_;
        my $image       = ODF::lpOD::StructuredContainer->create('draw:image');
        my $uri         = $opt{url} || $opt{uri};
        if ($uri)
                {
                $image->set_uri($uri);
                }
        elsif ($opt{content})
                {
                $image->set_content($opt{content});
                }
        else
                {
                alert "Missing image resource URI or content";
                return FALSE;
                }
        return $image;
        }

#-----------------------------------------------------------------------------

sub     set_uri
        {
        my $self        = shift;
        my $uri         = shift;
        $self->set_attribute('xlink:href' => $uri);
        my $bin = $self->first_child('office:binary-data');
        $bin->delete() if $bin;
        return $uri;
        }

sub     get_uri
        {
        my $self        = shift;
        return $self->get_attribute('xlink:href');
        }

sub     set_content
        {
        my $self        = shift;
        my $bin =       $self->first_child('office:binary-data');
        unless ($bin)
                {
                $bin = ODF::lpOD::Element->create('office:binary-data');
                $bin->paste_last_child($self);
                }
        my $content = shift;
        $bin->_set_text($content);
        $self->del_attribute('xlink:href');
        return $content;
        }

sub     get_content
        {
        my $self        = shift;
        my $bin = $self->first_child('office:binary-data') or return undef;
        return $bin->text;
        }

#=============================================================================
package ODF::lpOD::TOC;
use base 'ODF::lpOD::StructuredContainer';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2011-11-15T19:52:49';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

use constant TOC_SOURCE             => 'text:table-of-content-source';
use constant TOC_ENTRY_TEMPLATE     => 'text:table-of-content-entry-template';
use constant TOC_TITLE_TEMPLATE     => 'text:index-title-template';
use constant TOC_BODY               => 'text:index-body';

#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::TOC->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $name        = shift;
        my %opt         = process_options(@_);
        my $toc = ODF::lpOD::StructuredContainer->create
                ('text:table-of-content');
        $toc->set_name($name);
        $toc->set_style($opt{style});
        $toc->set_protected($opt{protected} // TRUE);
        $toc->set_outline_level($opt{outline_level} // 10);
        $toc->set_use_outline($opt{use_outline} // TRUE);
        $toc->set_use_index_marks($opt{use_index_marks} // FALSE);
        $toc->set_title($opt{title} // $name);
        return $toc;
        }

#-----------------------------------------------------------------------------

sub     get_source
        {
        my $self	= shift;
        return $self->first_child(TOC_SOURCE);
        }

sub     set_source
        {
        my $self	= shift;
        return  $self->set_child(TOC_SOURCE);
        }

sub     get_body
        {
        my $self	= shift;
        return $self->first_child(TOC_BODY);
        }

sub     set_body
        {
        my $self	= shift;
        return $self->set_child(TOC_BODY);
        }

sub     source_attribute
        {
        my $self        = shift;
        my $attr        = shift;
        my %opt         = @_;
        my ($source, $val);
        if (exists $opt{value})
                {
                $source = $self->set_source;
                $val = $opt{value};
                $val = odf_boolean($val) if $attr =~ /^use/;
                $source->set_attribute($attr => $val);
                }
        else
                {
                $source = $self->get_source;
                $val = $source ? $source->get_attribute($attr) : undef;
                $val = TRUE if (is_true($val) && $attr =~ /^use/);
                }
        return $val;
        }

sub     get_title
        {
        my $self	= shift;
            my $title = $self->first_descendant(TOC_TITLE_TEMPLATE);
            return $title ? $title->get_text : undef;
        }

sub     set_title
        {
        my $self	= shift;
            my $text        = shift;
            my %opt         = @_;
        my $source = $self->set_source;
            my $style = $opt{style}; delete $opt{style};
            return $source->set_child
                            (
                            TOC_TITLE_TEMPLATE,
                            $text,
                            'style name'    => $style,
                            @_
                            );
        }

sub     get_outline_level
        {
        my $self	= shift;
            return $self->source_attribute('outline level');
        }

sub     set_outline_level
        {
        my $self	= shift;
            my $level       = shift;
            my $source = $self->set_source;
            $source->set_attribute('outline level' => $level);
            foreach my $l (1..$level)
                    {
                    my $t = $source->get_element
                            (
                            TOC_ENTRY_TEMPLATE,
                            attribute       => 'outline level',
                            value           => $l
                            )
                            //
                    $source->append_element(TOC_ENTRY_TEMPLATE);

                    $t->set_attribute ('outline level' => $l);

                    $t->append_element('text:index-entry-chapter');
                    $t->append_element('text:index-entry-span')
                            ->set_text("  ");
                    $t->append_element('text:index-entry-text');
                    $t->append_element('text:index-entry-tab-stop')
                            ->set_attributes
                                    (
                                    'style:type'            => 'right',
                                    'style:leader-char'     => '.'
                                    );
                    $t->append_element('text:index-entry-page-number');
                    }
        return $level;
        }

sub     get_protected
        {
        my $self	= shift;
        return is_true($self->get_attribute('protected'));
        }

sub     set_protected
        {
        my $self	= shift;
        $self->set_attribute(protected => odf_boolean(shift));
            return $self->get_protected;
        }

sub     get_use_index_marks
        {
        my $self	= shift;
        return $self->source_attribute('use index marks');
        }

sub     set_use_index_marks
        {
        my $self	= shift;
        return $self->source_attribute('use index marks', value => shift);
        }

sub     get_use_outline
        {
        my $self	= shift;
        return $self->source_attribute('use outline');
        }

sub     set_use_outline
        {
        my $self        = shift;
        return $self->source_attribute('use outline', value => shift);
        }

#-----------------------------------------------------------------------------

sub     get_entry_template
        {
        my $self	= shift;
            my $level       = shift;
        my $source = $self->get_source;
            return $source->get_element
                    (
                    TOC_ENTRY_TEMPLATE,
                    attribute       => 'outline level',
                    value           => $level
                    );
        }

#=============================================================================
1;
