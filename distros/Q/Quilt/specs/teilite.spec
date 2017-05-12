<!-- -*- sgml -*- -->
<!DOCTYPE spec PUBLIC "-//Ken MacLeod//DTD Grove Simple Spec//EN">
<spec>
  <head>
    <defaultobject>Quilt::Flow</defaultobject>
    <defaultprefix>Quilt</defaultprefix>
    <use-gi>
    <copy-id>
  <rules>
    <rule><query/TEI.2/     <holder>

      <!-- ignoring TEIHEADER for now -->

    <rule><query/TEXT/  <make/DO::Document/
      <rules>
	<rule><query/FRONT/ <holder>
	  <rules>
	    <rule><query/TITLEPAGE/ <holder>
	      <rules>
		<rule><query/DOCTITLE/ <holder>
		  <rules>
		    <rule><query/TITLEPART/ <port/title/
		  </rules> <!-- DOCTITLE -->
		</rule>
		<rule><query/DOCAUTHOR/ <make/DO::Author/
		  <port/authors/
		<rule><query/DOCDATE/   <port/date/
	      </rules> <!-- TITLEPAGE -->
	    </rule>
	  </rules> <!-- FRONT -->
	</rule>
      </rules> <!-- TEXT -->

    <rule><query/BODY/ <holder>
    <rule><query/BACK/ <holder>

    <rule><query/DIV1 DIV2 DIV3 DIV4 DIV5 DIV6 DIV7/
                            <make/DO::Struct::Section/
    <rule><query/HEAD/      <port/title/

    <rule><query/P/         <make/DO::Block::Paragraph/
    <rule><query/EG/        <make/DO::Block::Screen/

    <rule><query/LIST/ <code><![CDATA[
my $self = shift; my $list = shift; my $parent = shift;
my $type = $list->attr_as_string ('TYPE');

if    ($type =~ /^bullet/i)  { $type = 'itemized'; }
elsif ($type =~ /^ordered/i) { $type = 'ordered'; }
elsif ($type =~ /^gloss/i)   { $type = 'variable'; }
elsif ($type =~ /^simple/i)  { $type = 'simple'; }
else { $type = 'itemized'; }

my $obj = new Quilt::DO::List (type => $type);
$parent->push ($obj);
$list->children_accept_gi ($self, $obj->iter($parent), @_);
]]></code>

    <rule><query/LABEL/     <make/DO::List::Term/
    <rule><query/ITEM/      <make/DO::List::Item/

    <rule><query/PTR/       <make>DO::XRef::End (link: <attr-as-string/TARGET/)</make>

    <rule><query/TERM/      <make/DO::Inline::Quote/
    <rule><query/SOCALLED/  <make/DO::Inline::Quote/
    <rule><query/TITLE/     <make/DO::Inline::Quote/
    <rule><query/MENTIONED/ <make/DO::Inline::Quote/
    <rule><query/GI/        <code><![CDATA[
my $self = shift; my $gi = shift; my $parent = shift;
$parent->push (new SGML::SData ('[lt    ]'));
$gi->children_accept ($self, $parent, @_);
$parent->push (new SGML::SData ('[gt    ]'));
]]></code>

    <rule><query/IDENT/     <make/DO::Inline::Literal/
    <rule><query/CODE/      <make/DO::Inline::Literal/
    <rule><query/KW/        <make/DO::Inline::Literal/
    <rule><query/EMPH/      <make/DO::Inline::Emphasis/
    <rule><query/HI/        <make/DO::Inline::Emphasis/
    <rule><query/Q/  <code><![CDATA[
my $self = shift; my $q = shift; my $parent = shift;
my $rend = $q->attr_as_string ('REND');
my $obj;
if ($rend =~ /display/i) {
    $obj = new Quilt::DO::Block::Quote;
} else {
    $obj = new Quilt::DO::Inline::Quote;
}
$parent->push ($obj);
$q->children_accept_gi ($self, $obj->iter($parent), @_);
]]></code>
  </rules>
</spec>
