<!-- -*- sgml -*- -->
<!DOCTYPE spec PUBLIC "-//Ken MacLeod//DTD Grove Simple Spec//EN">
<spec>
  <head>
    <defaultobject>ick-none</defaultobject>
    <defaultprefix>Quilt</defaultprefix>
  <rules>
    <rule>
      <query/Quilt_DO_Document/
      <code><![CDATA[
my $self = shift; my $document = shift; my $parent = shift;
my $title = $document->title;
if (defined $title && $#$title != -1) {
    my $obj = new Quilt::Flow::Paragraph (space_before => 6, space_after => 4,
                     quadding => 'center');
    $parent->push ($obj);
    $document->children_accept_title ($self, $obj, @_);
}
my $subtitle = $document->subtitle;
if (defined $subtitle && $#$subtitle != -1) {
    # force only two lines between title and subtitle
    $parent->push (new Quilt::Flow::DisplaySpace (space => 2, priority => 5));
    my $obj = new Quilt::Flow::Paragraph (space_before => 2, space_after => 4,
                     quadding => 'center');
    $parent->push ($obj);
    $document->children_accept_subtitle ($self, $obj, @_);
}
my $authors = $document->authors;
if (defined $authors && $#$authors != -1) {
    my $author;

    foreach $author (@$authors) {
        my $author_iter = $author->iter($document);
        # FIXME we don't want to push a paragraph if `name' doesn't
        # contain anything, but it's a compound object and we don't
        # have a way to see if there is one without actuall calling it
        my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 0,
                     quadding => 'center');
        $parent->push ($obj);
        $author_iter->name ($self, $obj, @_);

        my $title = $author_iter->title;
        if (defined $title && $#$title != -1) {
            $obj = new Quilt::Flow::Paragraph (space_before => 0, space_after => 0,
                     quadding => 'center');
            $parent->push ($obj);
            $author_iter->children_accept_title ($self, $obj, @_);
        }

        my $org_name = $author_iter->org_name;
        if (defined $org_name && $#$org_name != -1) {
            $obj = new Quilt::Flow::Paragraph (space_before => 0, space_after => 0,
                         quadding => 'center');
            $parent->push ($obj);
            $author_iter->children_accept_org_name ($self, $obj, @_);
        }

        # XXX org_unit
        $parent->push (new Quilt::Flow::DisplaySpace (space => 1));
    }
    $parent->push (new Quilt::Flow::DisplaySpace (space => 4));
}
my $date = $document->date;
if (defined $date && $#$date != -1) {
    my $obj = new Quilt::Flow::Paragraph (space_before => 2, space_after => 4,
                     quadding => 'center');
    $parent->push ($obj);
    $document->children_accept_date ($self, $obj, @_);
}
my $abstract = $document->abstract;
if (defined $abstract) {
    my $obj = new Quilt::Flow::Paragraph (space_before => 6, space_after => 1,
                     quadding => 'center');
    $parent->push ($obj);
    $obj->push ("ABSTRACT");
    # XXX hard coded indent
    my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1,
                     start_indent => "+4", end_indent => "+4");
    $parent->push ($obj);
    $document->children_accept_abstract ($self, $obj, @_);
}
# my $copyright = $document->copyright;
# if (defined $copyright && $#$copyright != -1) {
#    my $obj = new Quilt::Flow::Paragraph (space_before => 2, space_after => 4,
#                     quadding => 'center');
#    $parent->push ($obj);
#    $document->children_accept_copyright ($self, $obj, @_);
#}
my $obj = new Quilt::Flow::Paragraph (space_before => 4, space_after => 2,
                     quadding => 'center');
$parent->push ($obj);
$obj->push ("Table of Contents");
my $toc = new Quilt::Flow (start_indent => 2, space_after => 4);
$parent->push ($toc);
$document->children_accept (Quilt::TOC->new, $self, $toc);
my $body = new Quilt::Flow (start_indent => 2);
$parent->push ($body);
$document->children_accept ($self, $body, @_);
]]></code>

    <rule>
      <query/TOC/
      <code><![CDATA[
    my $self = shift; my $toc_visitor = shift; my $section = shift; my $toc = shift;

my $title = $section->title;
if (defined $title) {
    my $section_level = $section->level;
    my $space_around = (1, 0, 0, 0, 0)[$section_level - 1];
    my $indent = $section_level * 3 - 1;
    $space_around = 0
        if !defined $space_around;
    my $obj = new Quilt::Flow::Paragraph (space_before => $space_around,
                      space_after => $space_around, start_indent => $indent);
    $toc->push ($obj);
    my @section_nums = $section->numbers;
    if ($#section_nums != -1) {
        $obj->push (join (".", @section_nums) . ".");
        $obj->push (new SGML::SData ('[nbsp  ]'));
        $obj->push (new SGML::SData ('[nbsp  ]'));
    }
    $section->children_accept_title ($self, $obj, @_);
}
    $section->children_accept ($toc_visitor, $self, $toc, @_);
]]></code>

    <rule>
      <query/Quilt_Flow/
      <code><![CDATA[
my $self = shift; my $flow = shift;
$flow->children_accept ($self, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Struct_Section/
      <code><![CDATA[
my $self = shift; my $section = shift; my $parent = shift;
my $title = $section->title;
if (defined $title) {
    my $space_before = (4, 3, 2, 1, 1)[$section->level - 1];
    $space_before = 1
        if !defined $space_before;
    # change `start_indent' to 0 to outdent
    my $obj = new Quilt::Flow::Paragraph (space_before => $space_before,
                      space_after => 1, start_indent => 0);
    $parent->push ($obj);
    my @section_nums = $section->numbers;
    if ($#section_nums != -1) {
        $obj->push (join (".", @section_nums) . ".");
        $obj->push (new SGML::SData ('[nbsp  ]'));
        $obj->push (new SGML::SData ('[nbsp  ]'));
    }
    $section->children_accept_title ($self, $obj, @_);
}
$section->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Struct_Bridge/
      <code><![CDATA[
my $self = shift; my $bridge = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1);
$parent->push ($obj);
$bridge->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Struct_Formal/
      <code><![CDATA[
my $self = shift; my $formal = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1);
$parent->push ($obj);
$formal->children_accept_title ($self, $obj, @_);
$formal->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Struct_Admonition/
      <code><![CDATA[
my $self = shift; my $admonition = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1);
$parent->push ($obj);
$admonition->children_accept_title ($self, $obj, @_);
$admonition->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Block_Paragraph/
      <code><![CDATA[
my $self = shift; my $paragraph = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1);
$parent->push ($obj);
$paragraph->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Block_Quote/
      <code><![CDATA[
my $self = shift; my $quote = shift; my $parent = shift;
$self->{quoting}++;
# XXX hard coded indent
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1,
                               start_indent => "+4", end_indent => "+4");
$parent->push ($obj);
$quote->children_accept ($self, $obj, @_);
--$self->{quoting};
]]></code>

    <rule>
      <query/Quilt_DO_Block_Line/
      <code><![CDATA[
my $self = shift; my $line = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 0, space_after => 0);
$parent->push ($obj);
$line->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Block_Screen/
      <code><![CDATA[
my $self = shift; my $screen = shift; my $parent = shift;
$self->{quoting}++;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1, lines => 'asis');
$parent->push ($obj);
$screen->children_accept ($self, $obj, @_);
--$self->{quoting};
]]></code>

    <rule><query/Quilt_Flow_Table/      <make/Flow::Table/
    <rule><query/Quilt_Flow_Table_Part/ <make/Flow::Table::Part/
    <rule><query/Quilt_Flow_Table_Row/  <make/Flow::Table::Row/
    <rule><query/Quilt_Flow_Table_Cell/ <make/Flow::Table::Cell/

    <rule>
      <query/Quilt_DO_Block_NoFill/
      <code><![CDATA[
my $self = shift; my $screen = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1, lines => 'asis');
$parent->push ($obj);
$self->{quoting}++;
$screen->children_accept ($self, $obj, @_);
--$self->{quoting};
]]></code>

    <rule>
      <query/Quilt_DO_List/
      <code><![CDATA[
my $self = shift; my $list = shift; my $parent = shift;
my $obj = new Quilt::Flow (space_before => 1, space_after => 1, inline => 0, start_indent => '+4');
$parent->push ($obj);
$list->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_List_Item/
      <code><![CDATA[
my $self = shift; my $item = shift; my $parent = shift;
# XXX hard coded indent
my $obj = new Quilt::Flow (space_before => 1, space_after => 1,
                    inline => 0);
# XXX iterator
my $list_type;
eval {$list_type = $item->parent->type};
$list_type = 'itemized' if !defined $list_type;
$parent->push ($obj);
if ($list_type eq 'itemized' || $list_type eq 'ordered') {
    # XXX `is_mark' hack
    my $mark_obj = new Quilt::Flow (inline => 1, is_mark => 1, first_line_start_indent => '-4');
    if ($list_type eq 'itemized') {
        $mark_obj->push (' *  ');
    } else {
        my $item_num = $item->number;
        my $str = "$item_num)";
        # XXX hard coded indent
        # butt left first
        if (length ($str) < 4) {
            $str .= " ";
        }
        # then shift right if still room left
        while (length ($str) < 4) {
            $str = " " . $str;
        }
        $mark_obj->push ($str);
    }
    $obj->push ($mark_obj);
}
$item->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_List_Term/
      <code><![CDATA[
my $self = shift; my $term = shift; my $parent = shift;
my $obj = new Quilt::Flow::Paragraph (space_before => 1, space_after => 1, start_indent => '-4');
$parent->push ($obj);
$term->children_accept ($self, $obj, @_);
my $obj = new Quilt::Flow::DisplaySpace (space => 0, priority => 5);
$parent->push ($obj);
]]></code>

    <rule>
      <query/Quilt_DO_Inline/
      <code><![CDATA[
my $self = shift; my $quote = shift; my $parent = shift;
$quote->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Inline_Quote/
      <code><![CDATA[
my $self = shift; my $quote = shift; my $parent = shift;
$self->{quoting}++ or $parent->push (new SGML::SData ('[ldquo ]'));
$quote->children_accept ($self, $parent, @_);
--$self->{quoting} or $parent->push (new SGML::SData ('[rdquo ]'));
]]></code>

    <rule>
      <query/Quilt_DO_Inline_Literal/
      <code><![CDATA[
my $self = shift; my $literal = shift; my $parent = shift;
$self->{quoting}++ or $parent->push (new SGML::SData ('[lsquo ]'));
my $obj = new Quilt::Flow (font_family_name => 'iso-monospace', inline => 1);
$parent->push ($obj);
$literal->children_accept ($self, $obj, @_);
--$self->{quoting} or $parent->push (new SGML::SData ('[rsquo ]'));
]]></code>

    <rule>
      <query/Quilt_DO_Inline_Replaceable/
      <code><![CDATA[
my $self = shift; my $replaceable = shift; my $parent = shift;
$self->{quoting}++ or $parent->push (new SGML::SData ('[lsquo ]'));
my $obj = new Quilt::Flow (font_posture => 'italic', inline => 1);
$parent->push ($obj);
$replaceable->children_accept ($self, $obj, @_);
--$self->{quoting} or $parent->push (new SGML::SData ('[rsquo ]'));
]]></code>

    <rule>
      <query/Quilt_DO_Inline_Emphasis/
      <code><![CDATA[
my $self = shift; my $emphasis = shift; my $parent = shift;
my $obj = new Quilt::Flow (font_posture => 'italic', inline => 1);
$parent->push ($obj);
$emphasis->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_XRef_URL/
      <code><![CDATA[
my $self = shift; my $xref = shift; my $parent = shift;
my $url = $xref->url;
if (!defined $url) {
    $url = "";
}
my $name = $xref->as_string;

if (($url eq "") || ($url =~ m/mailto:$name/)) {
    my $obj = new Quilt::Flow (inline => 1);
    $self->{quoting}++ or $parent->push (new SGML::SData ('[lsquo ]'));
    $parent->push ($obj);
    $xref->children_accept ($self, $obj, @_);
    --$self->{quoting} or $parent->push (new SGML::SData ('[rsquo ]'));
} elsif (($name !~ /\s*/s) && ($name ne $url)) {
    my $obj = new Quilt::Flow (inline => 1);
    $parent->push ($obj);
    $xref->children_accept ($self, $obj, @_);
    $parent->push (" <$url>");
} else {
    $parent->push ("<$url>");
}
]]></code>

    <rule><query/Quilt_DO_XRef_End/
      <code><![CDATA[
my $self = shift; my $xref_end = shift; my $parent = shift;
#$xref_end->children_accept ($self, $parent, @_);
my $reference = $self->{references}->{$xref_end->link};
if (!$reference) {
    warn 'No reference for ' . $xref_end->link . "\n";
    return;
}
$parent->push($reference->type);
eval {
    my @section_nums = $reference->numbers;
    if ($#section_nums != -1) {
        $parent->push (" " . join (".", @section_nums));
    }
    $parent->push (",");
};
$parent->push (" ");
$self->{quoting}++ or $parent->push (new SGML::SData ('[ldquo ]'));
$reference->children_accept_title ($self, $parent, @_);
--$self->{quoting} or $parent->push (new SGML::SData ('[rdquo ]'));
]]></code>

    <rule><query/Quilt_DO_XRef_Anchor/  <ignore>

  <rule><query/scalar/
    <code><![CDATA[
my $self = shift; my $scalar = shift; my $parent = shift;
$scalar = $scalar->delegate;
$scalar =~ tr/\r/\n/;
$parent->push ($scalar);
    ]]></code>

  <rule><query/SGML_SData/
    <code><![CDATA[
my $self = shift; my $sdata = shift; my $parent = shift;
$parent->push ($sdata->delegate);
    ]]></code>
  </rules>
</spec>
