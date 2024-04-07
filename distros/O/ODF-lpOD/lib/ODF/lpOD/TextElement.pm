#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2011 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_001;
use     strict;
use     experimental    'smartmatch';
#=============================================================================
#       Text Element classes
#=============================================================================
package ODF::lpOD::TextElement;
use base 'ODF::lpOD::Element';
our $VERSION    = '1.006';
use constant PACKAGE_DATE => '2014-04-30T08:30:28';
use ODF::lpOD::Common;
#=============================================================================

BEGIN   {
        *set_link               = *set_hyperlink
        }

#-----------------------------------------------------------------------------

our     $RECURSIVE_EXPORT       = FALSE;

sub     set_recursive_export
        {
        my $caller      = shift;
        $RECURSIVE_EXPORT       = is_true(shift);
        }

#--- constructor -------------------------------------------------------------

sub     _create  { ODF::lpOD::TextElement->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        my %opt = process_options
                (
                tag     => undef,
                style   => undef,
                text    => undef,
                @_
                );
        my $tag = $opt{tag}; $tag = 'text:' . $tag unless $tag =~ /:/;
        my $e = ODF::lpOD::Element->create($tag) or return undef;
        if ($tag eq 'text:h')
                {
                $e->set_attribute('outline level', $opt{level} // 1);
                $e->set_attribute('restart numbering', 'true')
                                if is_true($opt{'restart_numbering'});
                $e->set_attribute('start value', $opt{start_value})
                                if defined $opt{start_value};
                $e->set_attribute('is list header', 'true')
                                if defined $opt{suppress_numbering};
                }
        $e->set_style($opt{style})
                        if defined $opt{style};
        $e->set_text($opt{text})
                        if defined $opt{text};

        return $e;
        }

#=== common tools ============================================================

sub     set_spaces
        {
        my $self        = shift;
        my $count       = shift         or return undef;
        my %opt         = @_;

        my $s = $self->insert_element('s', %opt);
        $s->set_attribute('c', $count);
        return $s;
        }

sub     set_line_break
        {
        my $self        = shift;
        return $self->insert_element('line break', @_);
        }

sub     set_tab_stop
        {
        my $self        = shift;
        return $self->insert_element('tab', @_);
        }

#--- split the content with new child elements -------------------------------

sub     split_content
        {
        my $self        = shift;
        my %opt         = process_options
                (
                tag             => undef,
                search          => undef,
                offset          => undef,
                length          => undef,
                content         => undef,
                insert          => undef,
                attributes      => {},
                @_
                );
        if (defined $opt{search} && defined $opt{length})
                {
                alert "Conflicting search and length parameters";
                return FALSE;
                }
        my $search      = $opt{search};
        $opt{repeat} //= (defined $search && ! defined $opt{offset});
        if (is_true($opt{repeat}))
                {
                delete $opt{repeat};
                my $start = $opt{start_mark};
                if ($opt{offset})
                        {
                        $start = $self->split_content(%opt);
                        }
                $opt{offset} = 0;
                my @elts = ();
                do      {
                        $opt{start_mark} = $start;
                        $start = $self->split_content(%opt);
                        push @elts, $start;
                        }
                while ($start);
                return wantarray ? @elts : $elts[0];
                }
        my $tag         = $self->normalize_name($opt{tag});
        if (defined $opt{start_mark} || defined $opt{end_mark})
                {
                $opt{offset} //= 0;
                }
        my $position = $opt{offset} || 0;
        if ($position eq 'end')
                {
                my $e = $self->append_element($tag);
                $e->set_attributes($opt{attributes});
                $e->set_text($opt{text});
                $e->set_class;
                return $e;
                }
        my $range = $opt{length};
        if ($position == 0 && ! defined $search && ! defined $range)
                {
                my $e = $self->insert_element($tag);
                $e->set_attributes($opt{attributes});
                $e->set_text($opt{text});
                $e->set_class;
                return $e;
                }
        my %r = $self->search
                        (
                        $search,
                        offset          => $position,
                        range           => $range,
                        backward        => $opt{backward},
                        start_mark      => $opt{start_mark},
                        end_mark        => $opt{end_mark}
                        );
        if (defined $r{segment})
                {
                my $e = ODF::lpOD::Element->create($tag);
                unless ($opt{insert})
                        {
                        my $t = $r{segment}->_get_text;
                        $range = $r{end} - $r{offset}
                                        if defined $search;
                        if (defined $range)
                                {
                                substr($t, $r{offset}, $range, "")
                                }
                        else
                                {
                                $t = substr($t, 0, $r{offset});
                                }
                        $r{segment}->_set_text($t);
                        $e->set_text($opt{text} // $r{match});
                        if      (
                                        (
                                        defined $opt{offset}
                                                &&
                                        $opt{offset} >= 0
                                        )
                                        ||
                                        defined $search
                                )
                                {
                                $e->paste_within
                                        ($r{segment}, $r{offset});
                                }
                        else
                                {
                                if ($r{end} < 0)
                                        {
                                        $e->paste_within
                                                ($r{segment}, $r{end});
                                        }
                                else
                                        {
                                        $e->paste_after($r{segment});
                                        }
                                }

                        }
                else
                        {
                        my $p = $opt{insert} eq 'after' ?
                                $r{end} : $r{offset};
                        $e->paste_within($r{segment}, $p);
                        $e->set_text($opt{text});
                        }

                $e->set_attributes($opt{attributes});
                $e->set_class;
                return $e;
                }
        return undef;
        }

#--- lpOD-specific bookmark setting ------------------------------------------

sub     set_lpod_mark
        {
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
        $opt{tag}               = $ODF::lpOD::Common::LPOD_MARK;
        $opt{attributes}        =
                {
                $ODF::lpOD::Common::LPOD_ID     => $id
                };
        return $self->split_content(%opt);
        }

#--- common bookmark, index mark setting tool --------------------------------

sub     set_position_mark
        {
        my $self        = shift;
        my $tag         = shift;
        my %opt         =
                (
                offset          => undef,
                before          => undef,
                after           => undef,
                @_
                );
        if (defined $opt{before} && defined $opt{after})
                {
                alert "Conflicting before and after parameters";
                return FALSE;
                }

        $opt{offset}  //= 0;
        $opt{search}    = $opt{before} // $opt{after};
        if      (defined $opt{after})   { $opt{insert} = 'after'  }
        else                            { $opt{insert} = 'before' }
        $opt{length}    = defined $opt{search} ? undef : 0;

        delete @opt{qw(before after)};
        $opt{tag} = $tag;
        return $self->split_content(%opt);
        }

sub     set_text_mark
        {
        my $self        = shift;
        my %opt         = @_;
        if (defined $opt{length} && $opt{length} > 0)
                {
                unless (ref $opt{offset})
                        {
                        my $start = $opt{offset} // 0;
                        my $end = $start + $opt{length};
                        $opt{offset} = [ $start, $end ];
                        }
                delete $opt{length};
                }
        if (defined $opt{content} || ref $opt{offset})
                {
                my $content = $opt{content};
                my ($p1, $p2, $range_end);
                if (ref $opt{offset})
                        {
                        $p1 = $opt{offset}[0];
                        $p2 = $opt{offset}[1];
                        $range_end = $self->set_lpod_mark
                                        (offset => $p2, length => 0)
                                if defined $p2 && defined $opt{content};
                        $opt{end_mark} = $range_end if $range_end;
                        }
                else
                        {
                        $p1 = $opt{offset};
                        $p2 = $opt{offset};
                        }
                delete @opt{qw(content offset)};
                $opt{offset}  = $p1;
                $opt{before}    = $content      if defined $content;
                $opt{role}      = 'start';
                my $start = $self->set_text_mark(%opt)
                        or return FALSE;
                $opt{offset}  = $p2;
                if (defined $content)
                        {
                        $opt{after}     = $content;
                        delete $opt{before};
                        }
                $opt{role}      = 'end';
                my $end   = $self->set_text_mark(%opt)
                        or return FALSE;
                unless ($start->before($end))
                        {
                        $start->delete; $end->delete;
                        alert("Start is not before end");
                        return FALSE;
                        }
                if ($range_end)
                        {
                        $range_end->delete(); $self->normalize;
                        }
                return wantarray ? $start : ($start, $end);
                }

        my $tag;
        if (!defined $opt{role})
                {
                $tag = $opt{tag};
                }
        elsif ($opt{role} =~ /^(start|end)$/)
                {
                $tag = $opt{tag} . '-' . $_;
                delete $opt{role};
                }
        else
                {
                alert("Wrong role = $_ option");
                return undef;
                }

        delete $opt{tag};
        return $self->set_position_mark($tag, %opt);
        }

#=== text content handling ===================================================

sub     set_text
        {
        my $self        = shift;
        my $text        = shift;
        return $self->SUPER::set_text($text, @_)    unless $text;
        return $self->_set_text($text)  if caller() eq 'XML::Twig::Elt';

        $self->_set_text("");
        my @lines = split("\n", $text, -1);
        while (@lines)
                {
                my $line = shift @lines;
                my @columns = split("\t", $line, -1);
                while (@columns)
                        {
                        my $column = shift @columns;
                        my @words = split(/(\s\s+)/, $column, -1);
                        foreach my $word (@words)
                                {
                                my $l = length($word);
                                if ($word =~ m/^ +$/)
                                        {
                                        $self->set_spaces
                                            ($l, position => 'LAST_CHILD');
                                        }
                                elsif ($l > 0)
                                        {
                                        my $n = $self->append_element
                                                        (TEXT_SEGMENT);
                                        $n->set_text($word);
                                        }
                                }
                        $self->append_element('tab') if @columns;
                        }
                $self->append_element('line break') if @lines;
                }
        $self->normalize;
        bless $_, 'ODF::lpOD::TextNode' for $self->children('#PCDATA');
        return TRUE;
        }

sub     get_text
        {
        my $self        = shift;
        my %opt         = @_;
        return $self->ODF::lpOD::TextNode::get_text
                                if $self->is(TEXT_SEGMENT);
        $opt{recursive} //= $RECURSIVE_EXPORT;
        my $text        = undef;
        NODE: foreach my $node ($self->children)
                {
                if  (
                    $node->isa('ODF::lpOD::TextNode')
                        or
                    $node->isa('ODF::lpOD::TextElement')
                    )
                    {
                    my $t = $node->get_text(%opt);
                    $text .= $t if defined $t;
                    }
                else
                    {
                    if ($node->get_tag eq 'text:tab')
                            {
                            $text .= $ODF::lpOD::Common::TAB_STOP;
                            }
                    elsif ($node->get_tag eq 'text:line-break')
                            {
                            $text .= $ODF::lpOD::Common::LINE_BREAK;
                            }
                    elsif ($node->get_tag eq 'text:s')
                            {
                            my $c = $node->get_attribute('c') // 1;
                            $text .= " " while $c-- > 0;
                            }
                    else
                            {
                            if (is_true($opt{recursive}))
                                    {
                                    my $t = $node->SUPER::get_text(%opt);
                                    $text .= $t if defined $t;
                                    }
                            }
                    }
                }

        return $text;
        }

#=== text internal markup ===================================================

sub     set_span
        {
        my $self        = shift;
        my %opt         = @_;
        unless ($opt{style})
                {
                alert("Missing style name");
                return FALSE;
                }
        $opt{search} = $opt{filter} if exists $opt{filter};
        $opt{attributes} = { 'style name' => $opt{style} };
        delete @opt{qw(filter style)};
        unless (defined $opt{length})   { $opt{search} //= ".*" }
        else                            { $opt{offset} //= 0    }
        return $self->split_content(tag => 'span', %opt);
        }

sub     remove_spans
        {
        my $self	= shift;

        my $tmp = $self->clone;
        $self->delete_children;
        my $count       = 0;
        foreach my $e ($tmp->descendants)
                {
                unless ($e->is('text:span'))
                        {
                        $e->move(last_child => $self);
                        }
                else
                        {
                        $count++;
                        }
                }
        $tmp->delete;
        return $count;
        }

sub     set_hyperlink
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $url         = $opt{url};
        delete $opt{url};
        unless ($url)
                {
                alert("Missing URL"); return FALSE;
                }
        $opt{search} = $opt{filter} if exists $opt{filter};
        $opt{attributes} =
                {
                'xlink:href'            => $url,
                'office:name'           => $opt{name},
                'office:title'          => $opt{title},
                'style name'            => $opt{style},
                'visited style name'    => $opt{visited_style}
                };
        delete @opt{qw(filter name title style visited_style)};
        unless (defined $opt{length})   { $opt{search} //= ".*" }
        else                            { $opt{offset} //= 0    }
        return $self->split_content(tag => 'a', %opt);
        }

sub     set_place_mark
        {
        my $self        = shift;
        my $type        = shift;
        my $name        = shift;
        unless ($name)
                {
                alert "Missing $type name"; return FALSE;
                }

        return $self->set_text_mark
                (
                tag             => $type,
                attributes      =>
                        {
                        name            => $name
                        },
                @_
                );
        }

sub     set_bookmark
        {
        my $self        = shift;
        return $self->set_place_mark('bookmark', @_);
        }

sub     set_reference_mark
        {
        my $self        = shift;
        return $self->set_place_mark('reference mark', @_);
        }

sub     set_reference
        {
        my $self        = shift;
        my %opt         = @_;
        $opt{type}      //= 'reference';
        my $tag = 'text:' . $opt{type} . '-ref';
        $opt{attributes} =
                {
                ref_name                => $opt{name},
                reference_format        => $opt{format}
                };
        delete @opt{qw(type name format)};
        return $self->set_position_mark($tag, %opt);
        }

sub     set_index_mark
        {
        my $self        = shift;
        my $text        = shift;

        unless ($text)
                {
                alert "Missing index entry text";
                return FALSE;
                }

        my %opt         = process_options (@_);

        if ($opt{index_name})
                {
                $opt{type} ||= 'user';
                unless ($opt{type} eq 'user')
                        {
                        alert "Index mark type must be user";
                        return FALSE;
                        }
                }
        else
                {
                $opt{type} ||= 'lexical';
                }
        my $tag;
        my %attr = $opt{attributes} ? %{$opt{attributes}} : ();
        if ($opt{type} eq "lexical" || $opt{type} eq "alphabetical")
                {
                $tag = 'alphabetical index mark';
                }
        elsif ($opt{type} eq 'toc')
                {
                $tag = 'toc mark';
                $attr{'outline level'} = $opt{level} // 1;
                }
        elsif ($opt{type} eq 'user')
                {
                unless ($opt{index_name})
                        {
                        alert "Missing index name";
                        return FALSE;
                        }
                $tag = 'user index mark';
                $attr{'outline level'} = $opt{level} // 1;
                }
        else
                {
                alert "Wrong index mark type ($opt{type})";
                return FALSE
                }

        if (defined $opt{content} || ref $opt{offset} || $opt{role})
                {       # it's a range index mark
                $attr{'id'} = $text;
                }
        else
                {
                $attr{'string value'} = $text;
                }

        delete @opt{qw(type index_name level attributes)};
        $opt{attributes} = {%attr};
        return $self->set_text_mark(tag => $tag, %opt);
        }

sub     set_bibliography_mark
        {
        my $self        = shift;
        my %opt         = process_options(@_);

        my $type_ok;
        foreach my $k (keys %opt)
                {
                if (ref $opt{$k} || $k eq 'content' || $k eq 'role')
                        {
                        alert "Not allowed option";
                        delete $opt{$k};
                        next;
                        }
                unless  (
                            $k =~ /^(before|after|offset|start_mark|end_mark)$/
                        )
                        {
                        if ($k eq 'type')
                                {
                                $type_ok = TRUE;
                                $k = 'bibliography type';
                                }
                        $opt{attributes}{$k} = $opt{$k};
                        delete $opt{$k};
                        }
                }
        alert "Missing type parameter" unless $type_ok;

        return $self->set_position_mark('bibliography mark', %opt);
        }

#=== text notes ==============================================================

sub     set_note
        {
        my $self        = shift;
        my $id          = shift;
        unless ($id)
                {
                alert "Missing note identifier"; return FALSE;
                }
        my %opt         = process_options(@_);
        $opt{attributes} =
                {
                'id'            => $id,
                'note class'    => $opt{class}  || $opt{note_class}
                                                || 'footnote'
                };
        my $style       = $opt{style};
        my $text        = $opt{text};
        my $body        = $opt{body};
        my $citation    = $opt{citation};
        my $label       = $opt{label};
        delete @opt{qw(note_class style text body citation label)};

        my $note        = $self->set_position_mark('note', %opt);
        $note->set_citation($citation, $label);
        $note->{style}  = $style;
        if ($body)
                {
                $note->set_body(@{$body});
                }
        else
                {
                $note->set_body($text);
                }

        return $note;
        }

sub     set_annotation
        {
        my $self        = shift;
        my %opt         = process_options(@_);
        my $date        = $opt{date};
        my $author      = $opt{author};
        my $style       = $opt{style};
        my $content     = $opt{content};
        unshift @$content, $opt{text} if defined $opt{text};
        delete @opt{qw(date author style content text)};
        my $a = $self->set_position_mark('office:annotation', %opt);
        $a->set_date($date);
        $a->set_author($author);
        $a->set_style($style);
        $a->set_content(@$content)    if $content;
        return $a;
        }

#=== text fields =============================================================

sub     set_field
        {
        my $self	= shift;
        my $type        = shift;
        unless ($type)
                {
                alert "Missing field type"; return undef;
                }
        my %opt         = process_options(@_);
        $opt{search} //= $opt{replace}; delete $opt{replace};
        $type = 'user field get' if $type eq 'variable';
        if ($type =~ /^user field/)
                {
                unless ($opt{name})
                        {
                        alert "Missing associated variable name";
                        return undef;
                        }
                }
        else
                {
                unless (ODF::lpOD::TextField::check_type($type))
                        {
                        alert "Unsupported field type"; return undef;
                        }
                }
        OPTION: foreach my $k (keys %opt)
                {
                if (ref $opt{$k} || ($k eq 'role'))
                        {
                        delete $opt{$k};
                        next;
                        }
                unless  (
                            $k =~ /^(before|after|offset|length|start_mark|end_mark|search)$/
                        )
                        {
                        if ($k eq 'fixed')
                                {
                                $opt{attributes}{$k} =
                                        odf_boolean($opt{$k});
                                }
                        elsif ($k eq 'style')
                                {
                                my $a = 'style:data-style-name';
                                $opt{attributes}{$a} = $opt{$k};
                                }
                        else
                                {
                                $opt{attributes}{$k} = $opt{$k};
                                }
                        delete $opt{$k};
                        }
                }
        my $tag = 'text:' . $type;
        my $field;
        if (defined $opt{search} || defined $opt{length})
                {
                $opt{text} = '';
                $field = $self->split_content(tag => $tag, %opt);
                }
        else
                {
                $field = $self->set_position_mark($tag , %opt);
                }
        return $field;
	}

#=============================================================================
package ODF::lpOD::TextHyperlink;
use base 'ODF::lpOD::TextElement';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2011-08-04T20:52:37';
use ODF::lpOD::Common;
#-----------------------------------------------------------------------------

sub     set_type
        {
        my $self        = shift;
        return $self->get_attribute('xlink:type');
        }

sub     get_type
        {
        my $self	= shift;
        return $self->get_attribute('xlink:type');
        }

sub     set_style       {}
sub     get_style       {}

#=============================================================================
package ODF::lpOD::Paragraph;
use base 'ODF::lpOD::TextElement';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:28:58';
use ODF::lpOD::Common;
#--- constructor -------------------------------------------------------------

sub     _create { ODF::lpOD::Paragraph->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return ODF::lpOD::TextElement->create(tag => 'p', @_);
        }

#=============================================================================
package ODF::lpOD::Heading;
use base 'ODF::lpOD::Paragraph';
our $VERSION    = '1.001';
use constant PACKAGE_DATE => '2010-12-29T22:30:12';
use ODF::lpOD::Common;
#--- constructor -------------------------------------------------------------

sub     _create { ODF::lpOD::Heading->create(@_) }

#-----------------------------------------------------------------------------

sub     create
        {
        my $caller      = shift;
        return ODF::lpOD::TextElement->create(tag => 'h', @_);
        }

#--- attribute accessors -----------------------------------------------------

sub     get_level
        {
        my $self        = shift;
        return $self->get_attribute('outline level');
        }

sub     set_level
        {
        my $self        = shift;
        return $self->set_attribute('outline level', @_);
        }

sub     get_suppress_numbering
        {
        my $self        = shift;
        return $self->get_boolean_attribute('is list header');
        }

sub     set_suppress_numbering
        {
        my $self        = shift;
        return $self->set_boolean_attribute('is list header', shift);
        }

sub     set_start_value
        {
        my $self        = shift;
        my $number      = shift;
        unless ($number >= 0)
                {
                alert('Wrong start value');
                return FALSE;
                }
        $self->set_attribute('restart numbering', TRUE);
        $self->set_attribute('start value', $number);
        }

#=============================================================================
1;
