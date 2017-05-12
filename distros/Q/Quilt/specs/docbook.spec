<!-- -*- sgml -*- -->
<!DOCTYPE spec PUBLIC "-//Ken MacLeod//DTD Grove Simple Spec//EN">
<spec>
  <head>
    <defaultobject>Quilt::Flow</defaultobject>
    <defaultprefix>Quilt</defaultprefix>
    <use-gi>
    <copy-id>
  <rules>
    <rule><query/BOOK ARTICLE/  <make/DO::Document/
      <rules>
        <rule><query/TOC REVHISTORY/    <ignore>
	<rule><query/BOOKINFO/          <holder>
	<rule><query/BOOKBIBLIO ARTHEADER/ <holder>
	  <rules>
	    <rule><query/TITLE/         <port/title/
	    <rule><query/TITLEABBREV/   <port/title_abbr/
	    <rule><query/SUBTITLE/      <port/subtitle/
	    <rule><query/EDITION/       <holder> <!-- <port/edition/ -->
	    <rule><query/ABSTRACT/      <port/abstract/
	    <rule><query/AUTHORGROUP/   <holder>
	    <rule><query/CORPAUTHOR/    <make/DO::Author/
	                                <port/authors/
	    <rule><query/AUTHOR/        <make/DO::Author/
                                        <port/authors/
	      <rules>
		<rule><query/HONORIFIC/     <port/name-prefix/
		<rule><query/FIRSTNAME/     <port/given-name/
		<rule><query/SURNAME/       <port/family-name/
		<rule><query/LINEAGE/       <port/name-suffix/
		<rule><query/OTHERNAME/     <port/formatted-name/
		<rule><query/AFFILIATION/   <holder>
		  <rules>
		    <rule><query/SHORTAFFIL/    <port/org-name-abbr/
		    <rule><query/JOBTITLE/      <port/title/
		    <rule><query/ORGNAME/       <port/org-name/
		    <rule><query/ORGDIV/        <port/org-unit/
		    <rule><query/ADDRESS/       <holder>
		      <rules>
			<rule><query/STREET/        <port/street/
			<rule><query/POB/           <port/postoffice-address/
			<rule><query/POSTCODE/      <port/postal-code/
			<rule><query/CITY/          <port/locality/
			<rule><query/STATE/         <port/region/
			<rule><query/COUNTRY/       <port/country/
			<rule><query/PHONE/         <port/phone/
			<rule><query/FAX/           <port/fax/
			<rule><query/EMAIL/         <port/email/
			<rule><query/OTHERADDR/     <port/otheraddr/
		      </rules> <!-- ADDRESS -->
		    </rule>
		  </rules> <!-- AFFILIATION -->
		</rule>
		<rule><query/AUTHORBLURB/   <port/blurb/
		<rule><query/CONTRIB/       <port/contrib/
	      </rules>
		 <!-- AUTHOR -->
	    </rule>
	    <rule><query/COPYRIGHT/   <ignore>
	      <rules>
		<rule><query/YEAR/      <port/years/
		<rule><query/HOLDER/    <port/holders/
		</rule>
	      </rules> <!-- COPYRIGHT -->
	    </rule>
	    <rule><query/ARTPAGENUMS/   <port/art-page-nums/
	  </rules> <!-- BOOKBIBLIO ARTHEADER -->

	<rule><query/LEGALNOTICE/   <holder>
      </rules>
    </rule> <!-- BOOK ARTICLE -->

    <rule><query/PARA/           <make/DO::Block::Paragraph/
    <rule><query/LITERALLAYOUT/  <make/DO::Block::NoFill/
    <rule><query/SYNOPSIS/       <make/DO::Block::NoFill/
    <rule><query/PROGRAMLISTING/ <make/DO::Block::Screen/
    <rule><query/SCREEN/         <make/DO::Block::Screen/
    <rule><query/BRIDGEHEAD/     <make/DO::Struct::Bridge/
    <rule><query/IMPORTANT/      <make/DO::Struct::Admonition (type: 'Important')/
    <rule><query/WARNING/        <make/DO::Struct::Admonition (type: 'Warning')/
    <rule><query/NOTE/           <make/DO::Struct::Admonition (type: 'Note')/
    <rule><query/HIGHLIGHTS/     <make/DO::Struct::Admonition (type: 'Highlights')/
    <rule><query/FIGURE/         <make/DO::Struct::Formal (type: 'Figure')/
    <rule><query/EXAMPLE/        <make/DO::Struct::Formal (type: 'Example')/
    <rule><query/TABLE/          <make/DO::Struct::Formal (type: 'Table')/

    <rule><query/TGROUP/         <make/Flow::Table/
      <rules>
        <rule><query/COLSPEC SPANSPEC/ <ignore>
	<rule><query/THEAD/        <make/Flow::Table::Part (type: 'head')/
	<rule><query/TBODY/        <make/Flow::Table::Part (type: 'body')/
	<rule><query/TFOOT/        <make/Flow::Table::Part (type: 'foot')/
	<rule><query/ROW/          <make/Flow::Table::Row/
	<rule><query/ENTRY/        <make/Flow::Table::Cell/
	</rule>
      </rules> <!-- TGROUP -->

    <rule><query/CHAPTER/        <make/DO::Struct::Section (type: 'Chapter')/
    <rule><query/PREFACE/        <make/DO::Struct::Section (type: 'Preface')/
    <rule><query/SECT1 SECT2 SECT3 SECT4 SECT5/
                                 <make/DO::Struct::Section/
    <rule><query/APPENDIX/       <make/DO::Struct::Section (type: 'Appendix')/

    <rule><query/TITLE/          <port/title/

    <rule><query/ITEMIZEDLIST/   <make/DO::List (type: 'itemized')/
    <rule><query/VARIABLELIST/   <make/DO::List (type: 'variable')/
    <rule><query/ORDEREDLIST/    <make/DO::List (type: 'ordered')/

    <rule><query/LISTITEM/       <make/DO::List::Item/
    <rule><query/VARLISTENTRY/   <holder>
    <rule><query/TERM/           <make/DO::List::Term/

      <!-- XXX this should use a CDATAATTR element -->
    <rule><query/ULINK/          <make>DO::XRef::URL (url: <attr-as-string/URL/)</make>
    <rule><query/LINK/           <make>DO::XRef (link: <attr-as-string/LINKEND/)</make>
    <rule><query/XREF/           <make>DO::XRef::End (link: <attr/LINKEND/)</make>

    <rule><query/EMPHASIS/       <make/DO::Inline::Emphasis/
    <rule><query/CITETITLE/      <make/DO::Inline::Quote/
    <rule><query/QUOTE/          <make/DO::Inline::Quote/
    <rule><query/LITERAL/        <make/DO::Inline::Literal/
    <rule><query/FILENAME/       <make/DO::Inline::Literal/
    <rule><query/INTERFACE/      <make/DO::Inline::Literal/
    <rule><query/OPTION/         <make/DO::Inline::Literal/
    <rule><query/REPLACEABLE/    <make/DO::Inline::Replaceable/
    <rule><query/OPTIONAL/       <make/DO::Inline::Replaceable/
    <rule><query/LINEANNOTATION/ <make/DO::Inline::Emphasis/
    <rule><query/APPLICATION/    <make/DO::Inline::Package/
    <rule><query/ACRONYM/        <make/DO::Inline::Package/
    <rule><query/GLOSSTERM/      <make/DO::Inline::Index/
    <rule><query/SYMBOL/         <make/DO::Inline::Literal/
    <rule><query/COMMAND/        <make/DO::Inline::Literal/
    <rule><query/PARAMETER/      <make/DO::Inline::Replaceable/
    <rule><query/CLASSNAME/      <make/DO::Inline::Literal/
    <rule><query/RETURNVALUE/    <make/DO::Inline::Literal/
    <rule><query/FOREIGNPHRASE/  <make/DO::Inline::Emphasis/
    <rule><query/FIRSTTERM/      <make/DO::Inline::Emphasis/
    <rule><query/SYSTEMITEM/     <make/DO::Inline::Literal/
    <rule><query/USERINPUT/      <make/DO::Inline::Literal/
    <rule><query/COMPUTEROUTPUT/ <make/DO::Inline::Literal/

    <rule><query/SGMLTAG/        <code><![CDATA[
my $self = shift; my $sgml_tag = shift; my $parent = shift;
$parent->push (new SGML::SData ('[lt    ]'));
$sgml_tag->children_accept ($self, $parent, @_);
$parent->push (new SGML::SData ('[gt    ]'));
]]></code>
  </rules>

  <stuff><![CDATA[

package Quilt::DocBook::Copyright;
@Quilt::DocBook::Copyright::ISA = qw{Quilt};

sub as_string {
    my ($self, $context) = @_;
    my ($data) = "Copyright " . $context->charent('[copy  ]') . " ";

    my ($year, @years);
    foreach $year (@{$self->{'years'}}) {
        push (@years, $year->as_string($context));
    }
    $data .= join (", ", @years);

    $data .= " ";

    my ($holder, @holders);
    foreach $holder (@{$self->{'holders'}}) {
        push (@holders, $holder->as_string($context));
    }
    $data .= join (", ", @holders);

    return $data;
}
]]>
</stuff>
</spec>
