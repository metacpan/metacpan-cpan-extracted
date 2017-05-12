<!-- -*- sgml -*- -->
<!DOCTYPE spec PUBLIC "-//Ken MacLeod//DTD Grove Simple Spec//EN">
<spec>
  <head>
    <defaultobject>Quilt::Flow</defaultobject>
    <defaultprefix>Quilt</defaultprefix>
    <use-gi>
  <rules>
    <rule><query/LINUXDOC/     <make/DO::Document/
    <rule><query/ARTICLE/      <holder>
    <rule><query/TITLEPAG/     <holder>
      <rules>
	<rule><query/TITLE/    <port/title/
	<rule><query/AUTHOR/   <make/DO::Author/
	  <port/authors/
	  <rules>
	    <rule><query/NAME/ <port/formatted_name/
	  </rules>
	<rule><query/DATE/     <port/date/
	<rule><query/ABSTRACT/ <port/abstract/
      </rules>
    </rule>

    <rule><query/TOC/  <ignore>

    <rule><query/SECT SECT1 SECT2 SECT3 SECT4/ <make/DO::Struct::Section/
    <rule><query/HEADING/ <port/title/

    <rule><query/P/       <make/DO::Block::Paragraph/
    <rule><query/TSCREEN/ <holder>
    <rule><query/VERB/    <make/DO::Block::Screen/
    <rule><query/CODE/    <make/DO::Block::Screen/
    <rule><query/QUOTE/   <make/DO::Block::Quote/
    <rule><query/TABLE/   <make/DO::Struct::Formal (type: 'Table')/
      <rules>
        <rule><query/CAPTION/  <port/title/
      </rules>
    </rule>
    <rule><query/TABULAR/ <code><![CDATA[
my $self = shift; my $table = shift; my $parent = shift;
my $tabular = new Quilt::Flow::Table::Part;
$parent->push ($tabular);
$table->children_accept_gi ($self, $tabular->iter($parent), @_);

# gather any stray non-table stuff into a cell
my @cell;
my $tabular_contents = $tabular->contents;
while ($#$tabular_contents != -1
       and ref ($tabular_contents->[-1]) !~ /::Table::/) {
    unshift (@cell, pop (@$tabular_contents));
}
if ($#cell != -1) {
    my $cell = new Quilt::Flow::Table::Cell (contents => [@cell]);
    $tabular->push ($cell);
}

# gather cells into a row
my @row;
while ($#$tabular_contents != -1
       and ref ($tabular_contents->[-1]) =~ /::Table::Cell/) {
    unshift (@row, pop (@$tabular_contents));
}
if ($#row != -1) {
    my $row = new Quilt::Flow::Table::Row (contents => [@row]);
    $tabular->push ($row);
}
]]></code>

    <rule><query/ROWSEP/  <code><![CDATA[
my $self = shift; my $rowsep = shift; my $tabular = shift;

# gather any stray non-table stuff into a cell
my @cell;
my $tabular_contents = $tabular->contents;
while ($#$tabular_contents != -1
       and ref ($tabular_contents->[-1]) !~ /::Table::/) {
    unshift (@cell, pop (@$tabular_contents));
}
if ($#cell != -1) {
    my $cell = new Quilt::Flow::Table::Cell (contents => [@cell]);
    $tabular->push ($cell);
}

# gather cells into a row
my @row;
while ($#$tabular_contents != -1
       and ref ($tabular_contents->[-1]) =~ /::Table::Cell/) {
    unshift (@row, pop (@$tabular_contents));
}
if ($#row != -1) {
    my $row = new Quilt::Flow::Table::Row (contents => [@row]);
    $tabular->push ($row);
}
]]></code>

    <rule><query/COLSEP/  <code><![CDATA[
my $self = shift; my $colsep = shift; my $tabular = shift;

# gather any stray non-table stuff into a cell
my @cell;
my $tabular_contents = $tabular->contents;
while ($#$tabular_contents != -1
       and ref ($tabular_contents->[-1]) !~ /::Table::/) {
    unshift (@cell, pop (@$tabular_contents));
}
# unlike ROWSEP, we always create a cell even if it's empty
my $cell = new Quilt::Flow::Table::Cell (contents => [@cell]);
$tabular->push ($cell);
]]></code>

    <rule><query/ENUM/    <make/DO::List (type: 'ordered')/
    <rule><query/ITEMIZE/ <make/DO::List (type: 'itemized')/
    <rule><query/ITEM/    <make/DO::List::Item/
    <rule><query/DESCRIP/     <code><![CDATA[
my $self = shift; my $list = shift; my $parent = shift;

my $obj = new Quilt::DO::List (type => 'variable');
$parent->push ($obj);
$list->children_accept_gi ($self, $obj->iter($parent), @_);

# gather any stray non-list stuff into an item
my $obj_contents = $obj->contents;
my @item;
while ($#$obj_contents != -1
       and ref ($obj_contents->[-1]) !~ /::List::/) {
    push (@item, pop (@$obj_contents));
}
if ($#item != -1) {
    my $item = new Quilt::DO::List::Item (contents => [@item]);
    $obj->push ($item);
}
]]></code>
    <rule><query/TAG/     <code><![CDATA[
my $self = shift; my $tag = shift; my $parent = shift;

# gather any stray non-list stuff into an item
my $parents_contents = $parent->contents;
my @item;
while ($#$parents_contents != -1
       and ref ($parents_contents->[-1]) !~ /::List::/) {
    push (@item, pop (@$parents_contents));
}
if ($#item != -1) {
    my $obj = new Quilt::DO::List::Item (contents => [@item]);
    $parent->push ($obj);
}
my $obj = new Quilt::DO::List::Term;
$parent->push ($obj);
$tag->children_accept_gi ($self, $obj->iter($parent), @_);
]]></code>
    <rule><query/TT/      <make/DO::Inline::Literal/
    <rule><query/CPARAM/  <make/DO::Inline::Emphasis/
    <rule><query/EM/      <make/DO::Inline::Emphasis/
    <rule><query/BF/      <make/DO::Inline/
    <rule><query/SF/      <make/DO::Inline/
    <rule><query/SL/      <make/DO::Inline/
    <rule><query/IT/      <make/DO::Inline/

    <rule><query/HTMLURL URL/
      <code><![CDATA[
  my $self = shift; my $element = shift; my $parent = shift;
  my $obj = new Quilt::DO::XRef::URL (url => $element->attr_as_string ('URL'));
  $parent->push ($obj);
  my $name = $element->attr_as_string ('NAME');
  if ($name ne '@@URLNAM') {
    $obj->{'contents'} = $element->attr ('NAME');
  }
]]></code>
    <rule><query/REF/     <code><![CDATA[
  my $self = shift; my $element = shift; my $parent = shift;
  my $obj = new Quilt::DO::XRef::End (link => $element->attr_as_string ('ID'),
 contents => $element->attr ('NAME'));
  $parent->push ($obj);
]]></code>
    <rule><query/LABEL/     <code><![CDATA[
  my $self = shift; my $element = shift; my $parent = shift;
  my $id = $element->attr_as_string ('ID');
  my $ii;
  for ($ii = $parent; $ii != undef; $ii = $parent->parent) {
    if ("$ii" =~ /:(Section|Formal):/) {
        $ii->id ($id);
        last;
    }
  }
]]></code>

    <rule><query/NEWLINE/ <make/DO::Inline/
  </rules>
</spec>
