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
#	Style handling package
#=============================================================================
package ODF::lpOD::Style;
use base 'ODF::lpOD::Element';
our $VERSION                    = '1.006';
use constant PACKAGE_DATE       => '2012-02-02T20:43:40';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *insert                 = *register;
        }

#-----------------------------------------------------------------------------

our %STYLE_DEF  =
        (
        'text'          =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_text_style
                },
        'paragraph'     =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_paragraph_style
                },
        'list'          =>
                {
                tag             => 'text:list-style',
                name            => 'style:name',
                class           => odf_list_style
                },
        'outline'       =>
                {
                tag             => 'text:outline-style',
                name            => undef,
                class           => odf_outline_style
                },
        'table'         =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_table_style
                },
        'table column'  =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_column_style
                },
        'table row'     =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_row_style
                },
        'table cell'    =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_cell_style
                },
        'master page'   =>
                {
                tag             => 'style:master-page',
                name            => 'name',
                class           => odf_master_page
                },
        'header footer' =>
                {
                class           => odf_page_end_style
                },
        'page layout'   =>
                {
                tag             => 'style:page-layout',
                name            => 'name',
                class           => odf_page_layout
                },
        'presentation page layout'      =>
                {
                tag             => 'style:presentation-page-layout',
                name            => 'name',
                class           => odf_presentation_page_layout
                },
        'graphic'       =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_graphic_style
                },
        'gradient'      =>
                {
                tag             => 'draw:gradient',
                name            => 'name',
                class           => odf_gradient
                },
        'presentation'  =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_graphic_style
                },
        'drawing page'  =>
                {
                tag             => 'style:style',
                name            => 'name',
                class           => odf_drawing_page_style
                }
        );

#-----------------------------------------------------------------------------

sub     set_class
        {
        my $self        = shift;
        my $family      = shift || $self->get_family;
        my $class;
        unless ($family)
                {
                my $tag = $self->get_tag;
                if ($tag =~ /^number:.*-style$/)
                        {
                        $class = odf_data_style;
                        }
                }
        else
                {
                my $desc = $STYLE_DEF{$family};
                $class = $desc->{class} if $desc;
                }
        return $class ? bless($self, $class) : undef;
        }

sub     get_family_path
        {
        my $self	= shift;
        my $family      = shift;
        my $desc        = $STYLE_DEF{$family};
        unless ($desc)
                {
                alert "Unknown style family"; return FALSE;
                }
        return $desc->{class}->context_path;
        }

sub     required_tag
        {
        my $self	= shift;
        my $family      = $self->get_family()   or return undef;
        return $STYLE_DEF{$family}->{tag};
        }

sub     set_name
        {
        my $self        = shift;
        my $name        = shift;

        return undef unless defined $name;
        return $self->set_tag($name) if (caller() eq 'XML::Twig::Elt');
        my $family = $self->get_family;
        my $attr;
        if ($family)
                {
                my $desc = $STYLE_DEF{$family};
                $attr = $desc->{'name'} if $desc;
                }
        return $attr ?
                $self->set_attribute($attr => $name)    :
                $self->SUPER::set_name($name);
        }

sub     get_name
        {
        my $self	= shift;
        return $self->get_attribute('style:name');
        }

sub     set_display_name
        {
        my $self	= shift;
        $self->set_attribute('style:display-name' => shift);
        }

sub     get_display_name
        {
        my $self	= shift;
        return $self->get_attribute('style:display-name' => shift);
        }

sub     set_family
        {
        my $self        = shift;
        my $tag = $self->get_tag;
        return undef unless ($tag eq 'style:style');
        my $family = shift; $family =~ s/ /-/g;
        return $self->set_attribute(family => $family);
        }

sub     set_parent_style
        {
        my $self	= shift;
        my $style       = shift;
        if (ref $style)
                {
                unless ($style->isa('ODF::lpOD::Style'))
                        {
                        alert "Wrong style reference"; return undef;
                        }
                $style = $style->get_name;
                }
        return $self->set_attribute('parent style name' => $style);
        }

sub     get_parent_style
        {
        my $self        = shift;
        return $self->get_attribute('parent style name');
        }

sub     get_parent_styles
        {
        my $self	= shift;
        my $doc = $self->document;
        unless ($doc)
                {
                alert "Non attached style"; return undef;
                }
        my $family = $self->get_family;
        my $name;
        my @styles;
        my $s = $self;
        while ($s && ($name = $s->get_parent_style))
                {
                $s = $doc->get_style($family, $name);
                push @styles, $s if $s;
                }
        return @styles;
        }

sub     set_style_class
        {
        my $self	= shift;
        return $self->set_attribute(class => shift);
        }

sub     is_default
        {
        my $self        = shift;
        my $tag = $self->get_tag        or return undef;
        return $tag eq 'style:default-style' ? TRUE : FALSE;
        }

sub     could_be_default
        {
        my $self        = shift;
        my $tag = $self->get_tag        or return undef;
        return $tag eq 'style:style' ? TRUE : FALSE;
        }

sub     make_default
        {
        my $self        = shift;
        return $self if $self->is_default;
        if ($self->could_be_default)
                {
                my $ds = $self->clone; $self->delete;
                my $f = $ds->get_family;
                $ds->del_attributes;
                $ds->_set_tag('style:default-style');
                $ds->set_attribute('style:family' => $f);
                return $ds;
                }
        else
                {
                alert "Wrong default style";
                return FALSE;
                }
        }

#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::Style->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $family      = shift;
        my $desc = $STYLE_DEF{$family};
        unless ($desc)
	        {
	        alert "Missing or not supported style family"; return FALSE;
	        }
        my %opt         = process_options(@_);
        my $tag = $opt{'tag'} || $desc->{tag}; delete $opt{tag};
        my $style;
        if ($opt{clone})
                {
                $style = $opt{clone}->clone;
                unless ($style)
                        {
                        alert "Style cloning error"; return undef;
                        }
                my $f = $style->get_family;
                unless (($f eq $family) || ($style->convert($family)))
                        {
                        alert "Family mismatch";
                        $style->delete;
                        return undef;
                        }
                delete $opt{clone};
                }
        else
                {
                $style = ODF::lpOD::Element->create($tag);
                }
        $style->set_family($family);
        bless $style, $desc->{class};
        $style->set_name($opt{name});
        $style->set_display_name($opt{display_name});
        $style->set_parent_style($opt{parent});
        $style->register($opt{register})        if $opt{register};
        delete @opt{qw(register name display_name parent)};
        $style->initialize(%opt);
        return $style;
        }

sub     initialize
        {
        my $self	= shift;
        return ($self->set_properties(@_) || undef);
        }

sub     register
        {
        my $self        = shift;
        my $document    = shift         or return undef;
        return $document->register_style($self, @_);
        }

#-----------------------------------------------------------------------------

sub     get_family
        {
        my $self        = shift;
        my $family      = $self->get_attribute('family');
        $family =~ s/-/ /g      if $family;
        return $family;
        }

#-----------------------------------------------------------------------------

sub     properties_tag          {}
sub     attribute_name          { my $self = shift; return shift; }

sub     set_properties_context
        {
        my $self        = shift;
        my $pt          = $self->properties_tag;
        unless ($pt)
                {
                my $area = shift || $self->get_family;
                $area =~ s/[ _]/-/g;
                $pt = $self->ns_prefix() . ':' . $area . '-properties';
                }
        return $self->set_child($pt);
        }

sub     set_properties
        {
        my      $self   = shift;
        my      %opt    = @_;
        my $area = $opt{area} || $self->get_family; delete $opt{area};
        return $self->ODF::lpOD::TextStyle::set_properties(%opt)
                if $area eq 'text';
        my $f = $area; $f =~ s/[ _]/-/g;
        my $pt = $self->properties_tag() || ('style:' . $f . '-properties');
        my $pr = $self->first_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                $pr //= $self->insert_element($pt);

                foreach my $k (keys %opt)
                        {
                        my $att = $STYLE_DEF{$area}
                                                ->{class}
                                                ->attribute_name($k);
                        $pr->set_attribute($att => $opt{$k});
                        }
                }
        return $self->get_properties(area => $area);
        }

sub     get_properties
        {
        my $self        = shift;
        my $pt = $self->properties_tag;
        unless ($pt)
                {
                my %opt = @_;
                my $area = $opt{area} || $self->get_family;
                $area =~ s/[ _]/-/g;
                $pt = $self->ns_prefix() . ':' . $area . '-properties';
                }
        my $pr = $self->get_child($pt);
        return $pr ? $pr->get_attributes() : undef;
        }

#-----------------------------------------------------------------------------

sub     set_background
        {
        my $self        = shift;
        my %opt         = @_;
        $opt{url} //= $opt{image};
        delete $opt{image};
        if (exists $opt{color})
                {
                $self->set_properties
                        (
                        area                    => $opt{area},
                        'fo:background-color'   => $opt{color}
                        );
                }
        if (exists $opt{url})
                {
                my $pr = $self->set_properties_context($opt{area});
                my $im = $pr->get_child('style:background-image');
                $im->delete if $im;
                if (defined $opt{url})
                        {
                        $im = $pr->insert_element('style:background-image');
                        $im->set_attribute('xlink:href' => $opt{url});
                        $im->set_attribute('draw:opacity' => $opt{opacity});
                        $im->set_attribute('filter name' => $opt{filter});
                        delete @opt{qw(area url opacity filter color)};
                        $im->set_attributes(%opt);
                        }
                }
        }

#=============================================================================
package ODF::lpOD::TextStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2011-05-27T09:05:45';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %ATTR =
        (
        font                => 'style:font-name',
        size                => 'fo:font-size',
        weight              => 'fo:font-weight',
        style               => 'fo:font-style',
        variant             => 'fo:font-variant',
        color               => 'fo:color',
        country             => 'fo:country',
        language            => 'fo:language',
        underline           => 'style:text-underline-style',
        background_color    => 'fo:background-color',
        display             => 'text:display'
        );

sub     initialize
        {
        my $self        = shift;
        my %opt         =
                (
                class           => 'text',
                @_
                );
        $self->set_style_class($opt{class}); delete $opt{class};
        my $result = $self->set_properties(%opt);
        return $result ? $self : undef;
        }

#-----------------------------------------------------------------------------

sub     properties_tag          { 'style:text-properties' }

sub     set_properties
        {
        my $self        = shift;
        my %opt         = @_;
        delete $opt{area};
        my $pt = 'style:text-properties';
        my $pr = $self->first_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                $pr //= $self->insert_element($pt);
                foreach my $k (keys %opt)
                        {
                        if ($k =~ /^underline./)
                                {
                                my $a = 'text-' . $k;
                                my $v = $opt{$k};
                                $v = 'skip-white-space'
                                    if (($k =~ /mode$/) && ($v =~ /^word/));
                                $pr->set_attribute($a => $v);
                                }
                        if ($k eq 'display')
                                {
                                my $v;
# Originally this code used the being-discontinued given/when construct 
#   given ($opt{$k}) {
#     when(TRUE)   { $v = 'true' }    # TRUE is 1
#     when(FALSE)  { $v = 'none' }    # FALSE is 0
#     else         { $v = $opt{$k} }
# However that mapped the strings 'true' and 'condition' to 'none' because
# `when(FALSE)` did a numeric == compare, and all non-numeric strings==0.
# I'm fairly sure that was not intended because lpOD/Style.pod documents the
# Text style property "display" to take values 'true', 'none' or 'condition'.
# For this reason the translation uses 'eq' not '=='.  -Jim Avera 9/25/23
                                if    ($opt{$k} eq TRUE)  { $v = 'true'; }
                                elsif ($opt{$k} eq FALSE) { $v = 'none'; }
                                else                      { $v = $opt{$k}; }
                                $pr->set_attribute('text:display' => $v);
                                }
                        else
                                {
                                my $att = $ATTR{$k} // $k;
                                $pr->set_attribute($att => $opt{$k});
                                }
                        }
                }
        return $self->get_properties(area => 'text');
        }

sub     set_background
        {
        my $self        = shift;
        my %opt         = @_;
        $self->set_properties('fo:background-color' => $opt{color});
        }

#=============================================================================
package ODF::lpOD::ParagraphStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-05-27T09:06:14';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %ATTR =
        (
        line_spacing                    => 'style:line-spacing',
        line_height_at_least            => 'style:line-height-at-least',
        font_independent_line_spacing   => 'style:font-independent-line-spacing',
        together                        => 'fo:keep-together',
        auto_text_indent                => 'style:auto-text-indent',
        shadow                          => 'style:shadow'
        );

sub     attribute_name
        {
        my $self        = shift;
        my $property    = shift // return undef;
        my $attribute   = undef;

        if ($property =~ /:/)
                {
                $attribute = $property;
                }
        else
                {
                if ($ATTR{$property})
                        {
                        $attribute = $ATTR{$property};
                        }
                else
                        {
                        $attribute = ($property =~ /^align|^indent/) ?
                                'text-' . $property : $property;
                        my $prefix = ($property =~ /^tab|register/) ?
                                'style' : 'fo';
                        $attribute = $prefix . ':' . $attribute;
                        }
                }
        return $attribute;
        }

#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self        = shift;
        my %opt         =
                (
                class           => 'text',
                @_
                );

        $self->set_style_class($opt{class});
        $self->set_master_page($opt{master_page});
        delete @opt{qw(class master_page)};
        my $result = $self->set_properties(area => 'paragraph', %opt);
        return $result ? $self : undef;
        }

sub     set_master_page
        {
        my $self        = shift;
        return $self->set_attribute('master page name' => shift);
        }

sub     get_master_page
        {
        my $self	= shift;
        return $self->get_attribute('master page name');
        }

#=============================================================================
package ODF::lpOD::ListStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2012-05-04T09:24:07';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family      { 'list' }

sub     get_properties  {}
sub     set_properties  {}

sub     set_background
        {
        alert("Background properties not supported for this object");
        return FALSE;
        }

#-----------------------------------------------------------------------------

sub     level_style_tag
        {
        my $self	= shift;
        my $type        = shift;
        unless ($type)
                {
                alert "Missing item mark type"; return FALSE;
                }
        return ('text:list-level-style-' . $type);
        }

sub     convert
        {
        my $self	= shift;
        my $family      = shift;
        return FALSE unless ($family && ($family eq 'outline'));
        $self->set_name(undef);
        $self->set_tag($STYLE_DEF{outline}->{tag});
        foreach my $ls ($self->get_children(qr'level-style'))
                {
                $ls->set_tag($self->level_style_tag);
                }
        return $self;
        }

#-----------------------------------------------------------------------------

sub     get_level_style
        {
        my $self	= shift;
        my $level       = shift;
        return $self->get_xpath('.//*[@text:level="' . $level . '"]', 0);
        }

sub     set_level_style
        {
        my $self	= shift;
        my $level       = shift;
        unless (defined $level && $level > 0)
                {
                alert "Missing or wrong level"; return FALSE;
                }
        my %opt = process_options(@_);
        my $e;
        if (defined $opt{clone})
                {
                $e = $opt{clone}->clone;
                my $old = $self->get_level_style($level);
                $old && $old->delete;
                $e->set_attribute(level => $level);
                return $self->append_element($e);
                }
        my $type = $opt{type} || 'number';
        $e = ODF::lpOD::ListLevelStyle->create($type) or return FALSE;
        if ($type eq 'number' || $type eq 'outline')
                        {
                        $e->set_attributes
                                (
                                'style:num-format'      => $opt{format},
                                'style:num-prefix'      => $opt{prefix},
                                'style:num-suffix'      => $opt{suffix},
                                'start value'           => $opt{start_value},
                                'display levels'        => $opt{display_levels}
                                );
                        }
        elsif ($type eq 'bullet')
                        {
                        $e->set_attribute('bullet char' => $opt{character});
                        }
        elsif ($type eq 'image')
                        {
                        $e->set_url($opt{url} // $opt{uri});
                        }
        else
                        {
                        $e->delete; undef $e;
                        alert "Unknown item mark type"; return FALSE;
                        }
        $e->set_attribute(level => $level);
        $e->set_style($opt{style});
        my $old = $self->get_level_style($level); $old && $old->delete;
        $e->set_properties(%{$opt{properties}}) if $opt{properties};
        return $self->append_element($e);
        }

#=============================================================================
package ODF::lpOD::ListLevelStyle;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2012-05-03T09:25:19';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

our %ATTR       =
        (
        align           => 'fo:text-align',
        font            => 'style:font-name',
        width           => 'fo:width',
        height          => 'fo:height'
        );

our %PROP = reverse %ATTR;

#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::ListLevelStyle->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $type        = shift;
        my $tag;
        if (! defined $type)
                        {
                        alert "Missing list level type";
                        }
        elsif ($type eq 'bullet' || $type eq 'number' || $type eq 'image')
                        {
                        $tag = 'text:list-level-style-' . $type;
                        }
        elsif ($type eq 'outline')
                        {
                        $tag = 'text:outline-level-style';
                        }
        else
                        {
                        alert "Wrong list level type";
                        }
        return $tag ? ODF::lpOD::Element->create($tag) : undef;
        }

sub     get_type
        {
        my $self        = shift;
        my $t = $self->get_tag;
        $t =~ /([a-z])$/;
        return $t;
        }

sub     get_properties
        {
        my $self        = shift;
        my $pr = $self->first_child('style:list-level-properties')
                        or return undef;
        my %prop;
        my %att = $pr->get_attributes;
        foreach my $k (keys %att)
                {
                my $p = $PROP{$k};
                unless ($p)
                        {
                        $p = $k;
                        $p =~ s/^.*://; $p =~ s/-/_/g;
                        }
                $prop{$p} = $att{$k};
                }
        return wantarray ? %prop : { %prop };
        }

sub     set_properties
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $pr = $self->set_child('style:list-level-properties');
        if ($opt{size})
                {
                my ($w, $h) = input_2d_value($opt{size});
                delete $opt{size};
                $opt{width}     //= $w;
                $opt{height}    //= $h;
                }
        foreach my $k (keys %opt)
                {
                my $att;
                if ($k =~ /:/)
                        {
                        $att = $k;
                        }
                else
                        {
                        $att = $ATTR{$k};
                        unless ($att)
                                {
                                $att = 'text:' . $k;
                                }
                        }
                $pr->set_attribute($att => $opt{$k});
                }
        return $pr;
        }

#=============================================================================
package ODF::lpOD::OutlineStyle;
use base 'ODF::lpOD::ListStyle';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:46:31';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family              { 'outline' }

sub     context_path            { STYLES, '//office:styles' }

sub     get_display_name        {}
sub     set_display_name        {}
sub     get_properties          {}
sub     set_properties          {}

#-----------------------------------------------------------------------------

sub     initialize              { return shift; }

sub     level_style_tag { 'text:outline-level-style' }

sub     convert
        {
        my $self	= shift;
        my $family      = shift;
        return FALSE unless ($family && ($family eq 'list'));
        $self->set_tag($STYLE_DEF{list}->{tag});
        foreach my $ls ($self->get_children(qr'level-style'))
                {
                $ls->set_tag($self->level_style_tag('number'));
                }
        return $self;
        }

#-----------------------------------------------------------------------------

sub     set_level_style
        {
        my $self	= shift;
        my $level       = shift;
        my %opt         = @_;
        $opt{type}      = 'outline';
        return $self->SUPER::set_level_style($level, %opt);
        }

#=============================================================================
package ODF::lpOD::AreaStyle;
use base 'ODF::lpOD::Style';
use strict;
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2012-02-01T16:17:09';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_frame_sides        = *set_area_sides;
        *set_margin             = *set_margins;
        *set_border             = *set_borders;
        }

#-----------------------------------------------------------------------------

sub     set_area_sides
        {
        my $self        = shift;
        my %opt         =
                (
                prefix  => 'fo:',
                option  => 'border',
                area    => undef,
                value   => undef,
                @_
                );

        my %attr;
        $attr{area}  = $opt{area};
        $attr{$opt{prefix} . $opt{option} . '_' . $_} = $opt{value}
                for ('left', 'right', 'top', 'bottom');
        $self->set_properties(%attr);
        }

sub     set_borders
        {
        my $self        = shift;
        return $self->set_area_sides
                (option => 'border', value => shift, @_);
        }

sub     set_padding
        {
        my $self        = shift;
        return $self->set_area_sides
                (option => 'padding', value => shift, @_);
        }

sub     set_margins
        {
        my $self        = shift;
        return $self->set_area_sides
                (option => 'margin', value => shift, @_);
        }

#-----------------------------------------------------------------------------

sub     fill
        {
        my $self        = shift;
        my $mode        = shift or return undef;
        my $value       = shift;
        my $attr = undef;
        if ($mode eq 'color' || $mode eq 'solid')
                        {
                        $mode = 'solid';
                        $attr = 'draw:fill-color';
                        }
        elsif ($mode eq 'bitmap' || $mode eq 'hatch')
                        {
                        $attr = 'draw:fill-' . $mode . '-name';
                        }
        elsif ($mode eq 'none' || $mode eq 'empty')
                        {
                        $mode = 'none';
                        }
        else
                        {
                        alert "Unknown shape fill mode";
                        return undef;
                        }
        $self->set_properties
                (
                area            => 'graphic',
                'draw:fill'     => $mode,
                $attr           => $value
                );
        }

#=============================================================================
package ODF::lpOD::TableStyle;
use base 'ODF::lpOD::AreaStyle';
use strict;
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-05-27T09:08:16';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self	= shift;
        my %opt         = @_;

        if ($opt{name}) { $self->set_name($opt{name}); delete $opt{name}; }
        $self->set_properties(%opt);
        return $self;
        }

#-----------------------------------------------------------------------------

sub     properties_tag
        {
        my $self	= shift;
        my $f = $self->get_family;
        $f =~ s/[ _]/-/g;
        return ('style:' . $f . '-properties');
        }

#-----------------------------------------------------------------------------

sub	set_properties
        {
        my $self        = shift;
        my %opt         = @_;
        if ($opt{area} && ($opt{area} eq 'text'))
                {
                alert "Text properties are not allowed for this object";
                return undef;
                }
        delete $opt{name};
        my $pt = $self->properties_tag;
        my $pr = $self->first_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                my $a;
                $pr //= $self->insert_element($pt);
                OPT: foreach my $k (keys %opt)
                        {
                        if ($k eq 'margin')
                                {
                                my $v = $opt{$k};
                                $pr->set_attributes
                                        (
                                        'fo:margin-left'        => $v,
                                        'fo:margin-right'       => $v,
                                        'fo:margin-bottom'      => $v,
                                        'fo:margin-top'         => $v
                                        );
                                next OPT;
                                }
                        elsif ($k eq 'width')
                                {
                                my $v = $opt{$k};
                                $v =~ s/\s*//g; $v =~ s/\*/%/g;
                                my ($v1, $v2) = split(/,/, $v);
                                for ($v1, $v2)
                                        {
                                        next unless defined $_;
                                        if ($_ =~ /%/)
                                                {
                                                $pr->set_attribute
                                                        ('rel width'    => $_)
                                                }
                                        else    {
                                                $pr->set_attribute
                                                        ('width'        => $_)
                                                }
                                        }
                                next OPT;
                                }
                        elsif ($k eq 'together')
                                {
                                next OPT unless defined $opt{$k};
                                my $v = odf_boolean(is_false($opt{$k}));
                                $pr->set_attribute
                                        ('may break between rows' => $v);
                                next OPT;
                                }
                        if ($k =~ /:/)
                                        {
                                        $a = $k;
                                        }
                        elsif ($k =~ /(color|margin|break|keep)/)
                                        {
                                        $a = 'fo:' . $k;
                                        }
                        elsif ($k eq 'align' || $k eq 'display')
                                        {
                                        $a = 'table:' . $k;
                                        }
                        else
                                        {
                                        $a = $k;
                                        }
                        $pr->set_attribute($a => $opt{$k});
                        }
                }
        return $self->get_properties();
        }

sub     set_shadow
        {
        my $self        = shift;
        my %opt         =
                (
                type            => 'visible',
                offset          => ['3mm', '3mm'],
                color           => '#000000',
                @_
                );
        my $t = $opt{type};
        my ($x, $y) = input_2d_value($opt{offset});
        my $c = color_code($opt{color});
        $self->set_properties(shadow => "$c $x $y");
        }

#=============================================================================
package ODF::lpOD::ColumnStyle;
use base 'ODF::lpOD::TableStyle';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:47:03';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     width_values
        {
        my $arg         = shift         or return undef;
        $arg =~ s/\s*//g; $arg =~ s/%/*/g;
        my ($v1, $v2) = split(/,/, $arg);
        my ($av, $rv);
        for ($v1, $v2)
                {
                next unless defined $_;
                if ($_ =~ /\*/) { $rv = $_ }
                else            { $av = $_ }
                }
        return ($av, $rv);
        }

sub     set_properties
        {
        my $self	= shift;
        my %opt         = process_options(@_);
        if ($opt{width})
                {
                ($opt{'column width'}, $opt{'rel column width'}) =
                                                width_values($opt{width});
                delete $opt{width};
                }
        if ($opt{optimal_width})
                {
                $opt{'style:use-optimal-column-width'} =
                        odf_boolean($opt{optimal_width});
                delete $opt{optimal_width};
                }
        return $self->SUPER::set_properties(%opt);
        }

#=============================================================================
package ODF::lpOD::RowStyle;
use base 'ODF::lpOD::TableStyle';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:47:18';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     set_properties
        {
        my $self	= shift;
        my %opt         = process_options(@_);
        if ($opt{height})
                {
                $opt{'row height'} = $opt{height}; delete $opt{height};
                }
        return $self->SUPER::set_properties(%opt);
        }

#=============================================================================
package ODF::lpOD::CellStyle;
use base 'ODF::lpOD::TableStyle';
our $VERSION    = '1.003';
use constant PACKAGE_DATE => '2012-02-02T08:15:46';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_text_properties    = *ODF::lpOD::TextStyle::set_properties;
        *p_attribute_name       = *ODF::lpOD::ParagraphStyle::attribute_name;
        *g_attribute_name       = *ODF::lpOD::GraphicStyle::attribute_name;
        }

#-----------------------------------------------------------------------------

sub     attribute_name
        {
        my $self        = shift;
        my $property    = shift // return undef;
        my $attribute   = undef;
        if ($property =~ /:/)
                {
                $attribute = $property;
                }
        else
                {
                my $prefix = '';
                if ($property =~ /^border|wrap|padding|color/)
                        {
                        $prefix = 'fo';
                        }
                $attribute = $prefix ? $prefix . ':' . $property : $property;
                }
        return $attribute;
        }

#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self	= shift;
        my %opt         = @_;
        if ($opt{data_style})
                {
                $self->set_data_style($opt{data_style});
                delete $opt{data_style};
                }
        $self->set_properties(area => 'table cell', %opt);
        return $self;
        }

sub     set_properties
        {
        my $self	= shift;
        my %opt         = process_options(@_);
        my $area        = $opt{area} // $self->get_family;
        delete $opt{area};
        if ($area eq 'table cell')
                        {
                        return $self->set_cell_properties(%opt);
                        }
        elsif ($area eq 'text')
                        {
                        return $self->set_text_properties(%opt);
                        }
        elsif ($area eq 'paragraph')
                        {
                        return $self->set_paragraph_properties(%opt);
                        }
        elsif ($area eq 'graphic')
                        {
                        return $self->set_graphic_properties(%opt);
                        }
        return undef;
        }

sub     set_cell_properties
        {
        my $self        = shift;
        my %opt         = @_;
        delete $opt{name};
        my $pt = $self->properties_tag;
        my $pr = $self->set_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                foreach my $k (keys %opt)
                        {
                        my $a = $self->attribute_name($k);
                        $pr->set_attribute($a => $opt{$k});
                        }
                }
        }

sub     set_paragraph_properties
        {
        my $self        = shift;
        my %opt         = @_;
        my $pt = 'style:paragraph-properties';
        my $pr = $self->set_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                foreach my $k (keys %opt)
                        {
                        my $a = $self->p_attribute_name($k);
                        $pr->set_attribute($a => $opt{$k});
                        }
                }
        }

sub     set_graphic_properties
        {
        my $self        = shift;
        my %opt         = @_;
        my $pt = 'style:graphic-properties';
        my $pr = $self->set_child($pt);
        if ($opt{clone})
                {
                my $proto = $opt{clone}->first_child($pt) or return undef;
                $pr->delete() if $pr;
                $proto->clone->paste_last_child($self);
                }
        else
                {
                foreach my $k (keys %opt)
                        {
                        my $a = $self->g_attribute_name($k);
                        $pr->set_attribute($a => $opt{$k});
                        }
                }
        }

sub     get_data_style
        {
        my $self	= shift;
        return $self->get_attribute('style:data-style-name');
        }

sub     set_data_style
        {
        my $self	= shift;
        return $self->set_attribute('style:data-style-name' => shift);
        }

sub     set_background
        {
        my $self        = shift;
        my $doctype = $self->document_type;
        if ($doctype && $doctype eq 'presentation')
                {
                return $self->fill(@_);
                }
        return $self->SUPER::set_background(@_);
        }

#=============================================================================
package ODF::lpOD::DataStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.002';
use constant PACKAGE_DATE => '2014-03-05T17:18:31';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $ds = ODF::lpOD::Element->create(@_);
        return bless $ds, __PACKAGE__;
        }

#-----------------------------------------------------------------------------

our		@NUMERIC_FAMILIES	=
        (
        "number", "percentage", "currency", "date", "time", "boolean"
        );
our     @FAMILIES       = (@NUMERIC_FAMILIES, "text");

sub	families
        {
        my $self	= shift;
        return wantarray ? @FAMILIES : [ @FAMILIES ];
        }

sub	numeric_families
        {
        my $self	= shift;
        return wantarray ? @NUMERIC_FAMILIES : [ @NUMERIC_FAMILIES ];
        }

sub is_numeric_family
		{
		my $self	= shift;
		my $f		= shift		or return undef;
		#return ($f ~~ @NUMERIC_FAMILIES) ? TRUE : FALSE;
		return fake_smartmatch($f, \@NUMERIC_FAMILIES) ? TRUE : FALSE;
		}

#-----------------------------------------------------------------------------

sub     get_family
        {
        my $self        = shift;
        my $tag = $self->get_tag;
        my $f;
        if ($tag =~ /^number:(.*)-style$/)
                {
                $f = $1;
                }
        return $f;
        }

sub     classify
        {
        my $arg         = shift;
        if (ref $arg)
                {
                my $f = $arg->ODF::lpOD::DataStyle::get_family;
                if ($f)
                        {
                        bless $arg, __PACKAGE__;
                        }
                return $arg;
                }
        else
                {
                if ($arg =~ /^number:(.*)-style$/)
                        {
                        my $family = $1;
                        #if ($family ~~ [@FAMILIES])
                        if (fake_smartmatch($family, [@FAMILIES]))
                                {
                                return __PACKAGE__;
                                }
                        }
                }
        return undef;
        }

sub     set_name
        {
        my $self        = shift;
        return $self->set_attribute('style:name' => shift);
        }

sub     get_name
        {
        my $self        = shift;
        return $self->get_attribute('style:name');
        }

sub	set_title
        {
        my $self	= shift;
        return $self->set_attribute('title' => shift);
        }

sub	get_title
        {
        my $self	= shift;
        return $self->get_attribute('title');
        }

sub     set_properties  {}
sub     get_properties  {}

#=============================================================================
package ODF::lpOD::MasterPage;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-05-27T09:11:14';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family      { 'master page' }

sub     context_path    { STYLES, '//office:master-styles' }

sub     get_properties  {}
sub     set_properties  {}

sub     set_background
        {
        alert("Background properties not supported for this object");
        return FALSE;
        }

#-----------------------------------------------------------------------------

sub	initialize
        {
        my $self	= shift;
        my %opt         = @_;
        $self->set_layout($opt{layout});
        $self->set_next($opt{next});
        return $self;
        }

#-----------------------------------------------------------------------------

sub     get_header
        {
        my $self        = shift;
        return $self->get_child('style:header');
        }

sub     set_header
        {
        my $self	= shift;
            return $self->replace_child('style:header');
        }

sub     delete_header
        {
        my $self	= shift;
        return $self->delete_child('style:header');
        }

sub     get_footer
        {
        my $self	= shift;
        return $self->get_child('style:footer');
        }

sub     set_footer
        {
        my $self	= shift;
        return $self->replace_child('style:footer');
        }

sub     delete_footer
        {
        my $self	= shift;
        return $self->delete_child('style:footer');
        }

sub     get_layout
        {
        my $self        = shift;
        return $self->get_attribute('page layout name');
        }

sub     set_layout
        {
        my $self        = shift;
        return $self->set_attribute('page layout name' => shift);
        }

sub     get_next
        {
        my $self	= shift;
        return $self->get_attribute('next style name');
        }

sub     set_next
        {
        my $self	= shift;
        return $self->set_attribute('next style name');
        }

#=============================================================================
package ODF::lpOD::PageEndStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-05-27T09:13:35';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family              { 'header footer' };

sub     get_display_name        {}
sub     set_display_name        {}

sub     properties_tag          { 'style:header-footer-properties' }

#-----------------------------------------------------------------------------

sub     set_properties
        {
        my $self	= shift;
        my %opt         = @_;
        my $pr = $self->set_child($self->properties_tag);
        foreach my $k (keys %opt)
                {
                my $a;
                if ($k =~ /:/)
                                {
                                $a = $k;
                                }
                elsif ($k eq 'height')
                                {
                                $a = 'fo:min-height';
                                }
                elsif ($k =~ /(margin|border|padding|background)/)
                                {
                                $a = 'fo:' . $k;
                                }
                else
                                {
                                $a = $k;
                                }
                $pr->set_attribute($a => $opt{$k});
                }
        return $pr->get_attributes;
        }

#=============================================================================
package ODF::lpOD::PageLayout;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2011-05-27T09:14:03';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family      { 'page layout' }

sub     context_path    { STYLES, '//office:automatic-styles' }

sub     get_display_name        {}
sub     set_display_name        {}

sub     properties_tag  { 'style:page-layout-properties' }

#-----------------------------------------------------------------------------

sub     set_properties
        {
        my $self	= shift;
        my %opt         = @_;
        my $pr = $self->set_child('page layout properties');
        foreach my $k (keys %opt)
                {
                my $a;
                my $v = $opt{$k};
                if ($k eq 'size')
                                {
                                $self->set_size($v);
                                next;
                                }
                elsif ($k eq 'height' || $k eq 'width')
                                {
                                $a = 'fo:page-' . $k;
                                }
                elsif ($k eq 'margin' || $k eq 'margins')
                                {
                                $pr->set_attributes
                                        (
                                        'fo:margin-top'    => $v,
                                        'fo:margin-right'  => $v,
                                        'fo:margin-bottom' => $v,
                                        'fo:margin-left'   => $v
                                        );
                                next;
                                }
                elsif ($k eq 'border' || $k eq 'borders')
                                {
                                $pr->set_attributes
                                        (
                                        'fo:border-top'    => $v,
                                        'fo:border-right'  => $v,
                                        'fo:border-bottom' => $v,
                                        'fo:border-left'   => $v
                                        );
                                next;
                                }
                elsif ($k =~ /(margin|border|padding|background)/)
                                {
                                $a = 'fo:' . $k;
                                }
                elsif ($k =~ /number/)
                                {
                                $a = $k; $a =~ s/ber//;
                                }
                elsif ($k eq 'footnote height')
                                {
                                $a = 'footnote max height';
                                }
                elsif ($k eq 'orientation')
                                {
                                $a = 'print orientation';
                                }
                elsif ($k eq 'paper tray')
                                {
                                $a = 'paper tray name';
                                }
                else
                                {
                                $a = $k;
                                }
                $pr->set_attribute($a => $v);
                }
        return $pr->get_attributes;
        }

sub     get_header
        {
        my $self        = shift;
        return $self->get_child('header style');
        }

sub     set_header
        {
        my $self	= shift;
            return $self->replace_child('header style');
        }

sub     delete_header
        {
        my $self	= shift;
        return $self->delete_child('header style');
        }

sub     get_footer
        {
        my $self	= shift;
        return $self->get_child('footer style');
        }

sub     set_footer
        {
        my $self	= shift;
        return $self->replace_child('footer style');
        }

sub     delete_footer
        {
        my $self	= shift;
        return $self->delete_child('footer style');
        }

sub     get_column_count
        {
        my $self	= shift;
        my $pr = $self->get_child('page layout properties')
                                                    or return undef;
            my $co = $pr->get_child('columns')      or return undef;
            return $co->get_attribute('fo:column-count');
        }

sub     set_columns
        {
        my $self	= shift;
        my $number      = shift;
        unless (defined $number)
                {
                alert "Missing number of columns"; return FALSE;
                }
        my $pr = $self->set_child('page layout properties');
        my $co = $pr->get_child('columns');
        if      ($number < 2)
                {
                $co && $co->delete;
                }
        else
                {
                my %opt         = @_;
                $co = $pr->replace_child
                        (
                        'columns', undef,
                        'fo:column-count'       => $number,
                        'fo:column-gap'         => $opt{gap}
                        );
                }
        return $self->get_column_count;
        }

#-----------------------------------------------------------------------------

sub     get_size
        {
        my $self        = shift;
        my $sep         = shift // ', ';
        my %p = $self->get_properties;
        my $w = $p{'fo:page-width'};
        my $h = $p{'fo:page-height'};
        return wantarray ? ($w, $h) : join $sep, ($w // ""), ($h // "");
        }

sub     set_size
        {
        my $self        = shift;
        my ($w, $h)     = input_2d_value(@_);
        $self->set_properties(width => $w, height => $h);
        return $self->get_size;
        }

#=============================================================================
package ODF::lpOD::PresentationPageLayout;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-05-27T09:16:39';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family      { 'presentation page layout' }
sub     context_path    { STYLES, '//office:styles' }
sub     initialize      { return shift; }

sub     get_properties  {}
sub     set_properties  {}

sub     set_background
        {
        alert("Background properties not supported for this object");
        return FALSE;
        }

#-----------------------------------------------------------------------------

sub     set_placeholder
        {
        my $self	= shift;
        my $shape       = shift;
        unless ($shape)
                {
                alert "Missing object class"; return FALSE;
                }
        my $ph = ref $shape ?
                $shape                                          :
                ODF::lpOD::Element->create('presentation:placeholder');
        $ph->set_attribute(object => $shape);
        my %opt         = @_;
        $ph->set_size($opt{size});
        $ph->set_position($opt{position});
        return $self->append_element($ph);
        }

sub     get_placeholders
        {
        my $self	= shift;
        return $self->get_children('presentation:placeholder');
        }

#=============================================================================
package ODF::lpOD::DrawingPageStyle;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2011-02-20T00:41:54';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     set_background
        {
        alert("Background properties not supported for this object");
        return FALSE;
        }

sub     attribute_name
        {
        my $self        = shift;
        my $p           = shift // return undef;
        my $prefix;
        if ($p =~ /:/)
                        { return $p                }
        elsif ($p =~ /display|visible|transition/)
                        { $prefix = 'presentation' }
        else
                        { $prefix = 'draw'         }
        return $prefix . ':' . $p;
        }

#=============================================================================
package ODF::lpOD::GraphicStyle;
use base 'ODF::lpOD::AreaStyle';
our $VERSION    = '1.004';
use constant PACKAGE_DATE => '2012-02-01T16:18:58';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

BEGIN   {
        *set_borders            = *set_stroke;
        *set_border             = *set_stroke;
        *set_background         = *ODF::lpOD::AreaStyle::fill;
        }

#-----------------------------------------------------------------------------

sub     initialize
        {
        my $self	= shift;
        my %opt         =
		(
		'clip'			=> 'rect(0cm 0cm 0cm 0cm)',
		'style:vertical-rel'	=> 'paragraph',
		'style:horizontal-rel'	=> 'paragraph',
		'style:vertical-pos'	=> 'from-top',
		'style:horizontal-pos'	=> 'from-left',
		'color-mode'		=> 'standard',
                @_
		);

        if ($opt{page})
                {
                $opt{'style:vertical-rel'} //= 'page-content';
                $opt{'style:horizontal-rel'} //= 'page-content';
                }
        foreach my $k (keys %opt)
                {
                if ($k =~ /^background.*color/)
                                {
                                $self->set_background(color => $opt{$k});
                                delete $opt{$k};
                                }
                elsif ($k eq 'border' || $k eq 'borders' || $k eq 'stroke')
                                {
                                my ($w, $t, $c) = split / +/, $opt{$k};
                                $self->set_borders
                                        (
                                        type    => $t,
                                        width   => $w,
                                        color   => $c
                                        );
                                delete $opt{$k};
                                }
                }
        $opt{area} = 'graphic';
        $self->set_properties(%opt);
        return $self;
        }

#-----------------------------------------------------------------------------

sub     attribute_name
        {
        my $self        = shift;
        my $p           = shift;
        my $prefix;
        if (! defined $p)
                        { return $p                     }
        elsif ($p =~ /:/)
                        { return $p                     }
        elsif ($p =~ /^(fill|shadow)/)
                        { $prefix = 'draw'              }
        elsif ($p =~ /(pos$|rel$|wrap$|run|shadow)/)
                        { $prefix = 'style'             }
        elsif ($p =~ /^stroke[ -_]/)
                        { $prefix = 'svg'               }
        elsif ($p =~ /border|color|height|width|padding|margin|clip/)
                        { $prefix = 'fo'                }
        else
                        { $prefix = 'draw'              }
        return $prefix . ':' . $p;
        }

#-----------------------------------------------------------------------------

sub     set_stroke
        {
        my $self        = shift;
        my %opt         =
                (
                'type'  => 'solid',
                'width' => '1pt',
                'color' => '#000000',
                @_
                );
        $self->set_properties
                (
                'draw:stroke'           => $opt{type}   // 'solid',
                'svg:stroke-width'      => $opt{width}  // '1pt',
                'svg:stroke-color'      => $opt{color}  // '#000000'
                );
        }

sub     set_shadow
        {
        my $self        = shift;
        my %opt         =
                (
                type            => 'visible',
                offset          => ['3mm', '3mm'],
                color           => '#000000',
                @_
                );
        my $t = $opt{type};
        my ($x, $y) = input_2d_value($opt{offset});
        my $c = $opt{color};
        delete @opt{qw(type offset color)};
        $self->set_properties
                (
                'draw:shadow'           => $t,
                'draw:shadow-offset-x'  => $x,
                'draw:shadow-offset-y'  => $y,
                'draw:shadow-color'     => $c,
                %opt
                );
        }


#=============================================================================
package ODF::lpOD::Gradient;
use base 'ODF::lpOD::Style';
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2011-05-27T09:18:59';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     get_family              { 'gradient'}

sub     context_path            { STYLES, '//office:styles' }

sub     get_properties          {}
sub     set_properties          {}

sub     get_name
        {
        my $self        = shift;
        return $self->get_attribute('name');
        }

#-----------------------------------------------------------------------------

sub     attribute_name
        {
        my $self	= shift;
        my $p           = shift;
        if (! defined $p)
                        { return $p                     }
        elsif ($p =~ /:/)
                        { return $p                     }
        elsif ($p eq 'style')
                        { return 'draw:style'           }
        else
                        { return $p                     }
        }

sub     initialize
        {
        my $self	= shift;
        my %opt         = @_;
            foreach my $k (keys %opt)
                    {
                    my $a = $self->attribute_name($k);
                    $self->set_attribute($a => $opt{$k});
                    }
            return $self;
        }

sub     set_display_name
        {
        my $self	= shift;
        $self->set_attribute('draw:display-name' => shift);
        }

sub     get_display_name
        {
        my $self	= shift;
        return $self->get_attribute('draw:display-name' => shift);
        }

#=============================================================================
package ODF::lpOD::FontDeclaration;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T23:17:13';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     _create  { ODF::lpOD::FontDeclaration->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my $name        = shift;
        my %opt         =
                (
                family          => $name,
                @_
                );
        unless ($name)
                {
                alert "Missing font name"; return FALSE;
                }
        my $fd = ODF::lpOD::Element->create('style:font-face');
        $fd->set_name($name);
        $fd->set_attribute('svg:font-family' => $opt{family});
        delete $opt{family};
        foreach my $k (keys %opt)
                {
                my $att = $k =~ /:/ ? $k : 'style:font-' . $k;
                $fd->set_attribute($att => $opt{$k});
                }
        return $fd;
        }

#=============================================================================
1;
