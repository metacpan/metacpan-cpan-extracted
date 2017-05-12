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
    my $obj = new Quilt::HTML::Title (level => 1, quadding => 'center');
    $parent->push ($obj);
    $document->children_accept_title ($self, $obj, @_);
}
my $subtitle = $document->subtitle;
if (defined $subtitle && $#$subtitle != -1) {
    my $obj = new Quilt::HTML::Title (level => 2, quadding => 'center');
    $parent->push ($obj);
    $document->children_accept_title ($self, $obj, @_);
}
my $authors = $document->authors;
if (defined $authors && $#$authors != -1) {
    my $author;

    my $author_count = $#$authors;
    foreach $author (@$authors) {
        my $author_iter = $author->iter($document);
        # FIXME we don't want to push a paragraph if `name' doesn't
        # contain anything, but it's a compound object and we don't
        # have a way to see if there is one without actuall calling it
        my $obj = new Quilt::HTML::Title (level => 2, quadding => 'center');
        $parent->push ($obj);
        $author_iter->name ($self, $obj, @_);

        my $title = $author_iter->title;
        if (defined $title && $#$title != -1) {
            $obj = new Quilt::HTML::Title (level => 3, quadding => 'center');
            $parent->push ($obj);
            $author_iter->children_accept_title ($self, $obj, @_);
        }

        my $org_name = $author_iter->org_name;
        if (defined $org_name && $#$org_name != -1) {
            $obj = new Quilt::HTML::Title (level => 3, quadding => 'center');
            $parent->push ($obj);
            $author_iter->children_accept_org_name ($self, $obj, @_);
        }

        if ($author_count-- != 0) {
            $parent->push (new Quilt::Flow::DisplaySpace (space => 1));
        }
    }
}
my $date = $document->date;
if (defined $date && $#$date != -1) {
    my $obj = new Quilt::Flow::Paragraph (quadding => 'center');
    $parent->push ($obj);
    $document->children_accept_date ($self, $obj, @_);
}
my $abstract = $document->abstract;
if (defined $abstract) {
    my $obj = new Quilt::HTML::Title (level => 3, quadding => 'center');
    $parent->push ($obj);
    $obj->push ("ABSTRACT");
    my $obj = new Quilt::Flow ();
    $parent->push ($obj);
    $document->children_accept_abstract ($self, $obj, @_);
}
my $obj = new Quilt::HTML::Title (level => 3, quadding => 'center');
$parent->push ($obj);
$obj->push ("Table of Contents");
my $toc = new Quilt::HTML::List (type => 'UL');
$parent->push ($toc);
$document->children_accept (Quilt::TOC->new, $self, $toc);
$document->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/TOC/
      <code><![CDATA[
    my $self = shift; my $toc_visitor = shift; my $section = shift; my $toc = shift;

    my $id = $section->generated_id;
    $id = $section->id if (!defined $id || $id eq "");
    if (!defined $id || $id eq "") {
        $id = "t" . ++$main::unique;
        $section->generated_id ($id);
    }
    my $li = new Quilt::HTML::List::Item;
    $toc->push ($li);
    # FIXME needs sub-doc URL
    my $a = new SGML::Element ([], "A", {href => ["#$id"]});
    $li->push ($a);
    my @section_nums = $section->numbers;
    if ($#section_nums != -1) {
        $a->push (join (".", @section_nums) . ".");
        $a->push (new SGML::SData ('[nbsp  ]'));
        $a->push (new SGML::SData ('[nbsp  ]'));
    }
    $section->children_accept_title ($self, $a, @_);

    my $sub_toc = new Quilt::HTML::List (type => 'UL');
    $li->push ($sub_toc);
    $section->children_accept ($toc_visitor, $self, $sub_toc, @_);
]]></code>

    <rule>
      <query/Quilt_Flow/ <holder>

    <rule>
      <query/Quilt_DO_Struct_Section/
      <code><![CDATA[ 
my $self = shift; my $section = shift; my $parent = shift;
# XXX div
my $title = $section->title;
if (defined $title) {
    my $obj = new Quilt::HTML::Title (level => $section->level);
    $parent->push ($obj);

    my $id = $section->generated_id;
    $id = $section->id if (!defined $id || $id eq "");
    if (!defined $id || $id eq "") {
        $id = "t" . ++$main::unique;
        $section->generated_id ($id);
    }
    my $a = new SGML::Element ([], "A", {name => [$id]});
    $obj->push ($a);

    my @section_nums = $section->numbers;
    if ($#section_nums != -1) {
        $a->push (join (".", @section_nums) . ".");
        $a->push (new SGML::SData ('[nbsp  ]'));
        $a->push (new SGML::SData ('[nbsp  ]'));
    }
    $section->children_accept_title ($self, $a, @_);
}
$section->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Struct_Formal Quilt_DO_Struct_Admonition/
      <code><![CDATA[
my $self = shift; my $formal = shift; my $parent = shift;
my $title = $formal->title;
if (defined $title) {
    my $obj = new Quilt::HTML::Title (level => 4);
    $parent->push ($obj);
    $formal->children_accept_title ($self, $obj, @_);
}
$formal->children_accept ($self, $parent, @_);
]]></code>

    <rule>
      <query/Quilt_DO_Struct_Bridge/ <make/HTML::Title (level: 4, quadding: 'center');/

    <rule>
      <query/Quilt_DO_Block_Paragraph/ <make/Flow::Paragraph/

    <rule>
      <query/Quilt_DO_Block_Screen/
      <code><![CDATA[
my $self = shift; my $screen = shift; my $parent = shift;
$self->{quoting}++;
my ($obj) = new Quilt::HTML::Pre ();
$parent->push ($obj);
$screen->children_accept ($self, $obj, @_);
$self->{quoting}--;
]]></code>

    <rule>
      <query/Quilt_DO_Block_NoFill/
      <code><![CDATA[
my $self = shift; my $screen = shift; my $parent = shift;
$self->{quoting}++;
my ($obj) = new Quilt::HTML::NoFill ();
$parent->push ($obj);
$screen->children_accept ($self, $obj, @_);
$self->{quoting}--;
]]></code>

    <rule>
      <query/Quilt_DO_List/
      <code><![CDATA[
my $self = shift; my $list = shift; my $parent = shift;
my $type = { 'itemized' => 'UL', 'ordered' => 'OL',
    'variable' => 'DL' }->{$list->type};
$type = 'UL' if !defined $type;
my $obj = new Quilt::HTML::List (type => $type, continued => $list->continued);
$parent->push ($obj);
$list->children_accept ($self, $obj, @_);
]]></code>

    <rule>
      <query/Quilt_DO_List_Item/ <make/HTML::List::Item/

    <rule>
      <query/Quilt_DO_List_Term/ <make/HTML::List::Term/

    <rule>
      <query/Quilt_DO_XRef_URL/
      <code><![CDATA[
my $self = shift; my $xref = shift; my $parent = shift;
my $url = $xref->url;
my $name = $xref->as_string;

if (!defined $url) {
    my $obj = new SGML::Element ([], "A", {href => $xref->contents});
    $parent->push ($obj);
    if ($name =~ /^mailto:(.*)/) {
        $obj->push ($1);
    } else {
        $xref->children_accept ($self, $obj, @_);
    }
} elsif ($name =~ /\s*/s || $name eq $url) {
    my $obj = new SGML::Element ([], "A", {href => [$url]});
    $parent->push ($obj);
    $url =~ s/^mailto://;
    $obj->push ($url);
} else {
    my $obj = new SGML::Element ([], "A", {href => [$url]});
    $parent->push ($obj);
    $xref->children_accept ($self, $obj, @_);
}
]]></code>

    <rule><query/Quilt_DO_XRef_Anchor/
      <code><![CDATA[
my $self = shift; my $anchor = shift; my $parent = shift;
my $obj = new SGML::Element ([], "A", {name => [$anchor->id]});
$parent->push ($obj);
]]></code>

    <rule><query/Quilt_DO_XRef_End/
      <code><![CDATA[
my $self = shift; my $xref_end = shift; my $parent = shift;
my $obj = new SGML::Element ([], "A", {href => ["#" . $xref_end->link]});
$parent->push ($obj);
#$xref_end->children_accept ($self, $obj, @_);
my $reference = $self->{references}->{$xref_end->link};
$obj->push($reference->type);
eval {
    my @section_nums = $reference->numbers;
    if ($#section_nums != -1) {
        $obj->push (" " . join (".", @section_nums));
    }
    $obj->push (",");
};
$obj->push (" ");
$self->{quoting}++ or $obj->push (new SGML::SData ('[ldquo ]'));
$reference->children_accept_title ($self, $obj, @_);
--$self->{quoting} or $obj->push (new SGML::SData ('[rdquo ]'));
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
my $obj = new SGML::Element ([], "TT");
$parent->push ($obj);
$literal->children_accept ($self, $obj, @_);
--$self->{quoting} or $parent->push (new SGML::SData ('[rsquo ]'));
]]></code>

    <rule>
      <query/Quilt_DO_Inline_Replaceable/
      <code><![CDATA[
my $self = shift; my $replaceable = shift; my $parent = shift;
$self->{quoting}++ or $parent->push (new SGML::SData ('[lsquo ]'));
my $obj = new SGML::Element ([], "I");
$parent->push ($obj);
$replaceable->children_accept ($self, $obj, @_);
--$self->{quoting} or $parent->push (new SGML::SData ('[rsquo ]'));
]]></code>

    <rule>
      <query/Quilt_DO_Inline_Emphasis/
      <code><![CDATA[
my $self = shift; my $replaceable = shift; my $parent = shift;
my $obj = new SGML::Element ([], "EM");
$parent->push ($obj);
$replaceable->children_accept ($self, $obj, @_);
]]></code>


    <rule><query/Quilt_Flow_Table/ <code><![CDATA[
my $self = shift; my $table = shift; my $parent = shift;
my $obj = new Quilt::HTML::Table;
$parent->push ($obj);
my $ii;
my $parts = $table->delegate->parts;
for ($ii = 0; $ii <= $#$parts; $ii ++) {
    my $iter = $parts->[$ii]->iter ($table, $parts, $ii);
    $iter->children_accept ($self, $obj, @_);
}
]]></code>

    <rule><query/Quilt_Flow_Table_Part/      <make/HTML::Table/
    <rule><query/Quilt_Flow_Table_Row/  <make/HTML::Table::Row/
    <rule><query/Quilt_Flow_Table_Cell/ <make/HTML::Table::Data/

  <rule><query/scalar/
    <code><![CDATA[
my $self = shift; my $scalar = shift; my $parent = shift;
$scalar = $scalar->delegate;
$scalar =~ tr/\r/\n/;
$scalar =~ s/&/&amp;/g;
$scalar =~ s/</&lt;/g;
$parent->push ($scalar);
    ]]></code>

  <rule><query/SGML_SData/
    <code><![CDATA[
my $self = shift; my $sdata = shift; my $parent = shift;
$parent->push ($sdata->delegate);
    ]]></code>
  </rules>
</spec>
