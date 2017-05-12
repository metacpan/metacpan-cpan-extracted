<!-- -*- sgml -*- -->
<!DOCTYPE spec PUBLIC "-//Ken MacLeod//DTD Grove Simple Spec//EN">
<spec>
  <head>
    <defaultobject>ick-none</defaultobject>
    <defaultprefix>ick-none</defaultprefix>
  <rules>
    <rule>
      <query/Quilt_Flow/
      <code><![CDATA[
my $self = shift; my $flow = shift; my $context = shift;
my $inline = $flow->inline;
#if ($inline) {
#    $builder->push_inline ($node->attributes);
#} else {
#    $builder->push_display ($node->attributes);
#}
$flow->children_accept ($self, $context, @_);
#if ($inline) {
#    $builder->pop_inline;
#} else {
#    $builder->pop_display;
#}
]]></code>

    <rule>
      <query/Quilt_Flow_Paragraph/
      <code><![CDATA[ 
my $self = shift; my $paragraph = shift; my $context = shift;
$self->print_ ("<P>");
$paragraph->children_accept ($self, $context, @_);
$self->print_ ("</P>\n\n");
]]></code>

    <rule>
      <query/Quilt_HTML_Title/
      <code><![CDATA[
my $self = shift; my $title = shift; my $context = shift;
my $level = $title->level;
$self->print_ ("<H$level>");
$title->children_accept ($self, $context, @_);
$self->print_ ("</H$level>\n\n");
]]></code>

    <rule>
      <query/Quilt_HTML_Pre/
      <code><![CDATA[
my $self = shift; my $pre = shift; my $context = shift;
$self->print_ ("<TABLE cellpadding='5' border='1' bgcolor='#80ffff' width='100%'>\n");
$self->print_ ("<TR><TD>\n");
$self->print_ ("<PRE>");
$pre->children_accept ($self, $context, @_);
$self->print_ ("</PRE>\n\n");
$self->print_ ("</TD></TR></TABLE>\n");
]]></code>

    <rule>
      <query/Quilt_HTML_NoFill/
      <code><![CDATA[
my $self = shift; my $pre = shift; my $context = shift;
$self->print_ ("<TABLE cellpadding='5' border='1' bgcolor='#80ffff' width='100%'>\n");
$self->print_ ("<TR><TD>\n");
$self->print_ ("<PRE>");
$pre->children_accept ($self, $context, @_);
$self->print_ ("</PRE>\n\n");
$self->print_ ("</TD></TR></TABLE>\n");
]]></code>

    <rule>
      <query/Quilt_HTML_List/
      <code><![CDATA[
my $self = shift; my $list = shift; my $context = shift;
my $type = $list->type;
$type = 'UL' if !defined $type;
my $continued = $list->continued ? " CONTINUED" : "";
$self->print_ ("<$type$continued>");
$list->children_accept ($self, $context, @_);
$self->print_ ("</$type>\n\n");
]]></code>

    <rule>
      <query/Quilt_HTML_List_Item/
      <code><![CDATA[
my $self = shift; my $list_item = shift; my $context = shift;
my $type = 'LI';
$type = 'DD' if ($list_item->parent->type eq 'DL');
$self->print_ ("<$type>");
$list_item->children_accept ($self, $context, @_);
$self->print_ ("</$type>\n\n");
]]></code>

    <rule>
      <query/Quilt_HTML_List_Term/
      <code><![CDATA[
my $self = shift; my $list_term = shift; my $context = shift;
$self->print_ ("<DT>");
$list_term->children_accept ($self, $context, @_);
$self->print_ ("</DT>\n\n");
]]></code>

    <rule>
      <query/Quilt_HTML_Table/
      <code><![CDATA[
my $self = shift; my $table = shift; my $context = shift;
my $border = ($table->frame =~ /none/i) ? "" : " BORDER";
$self->print_ ("<TABLE$border>\n");
$table->children_accept ($self, $context, @_);
$self->print_ ("</TABLE>\n\n");
]]></code>

    <rule>
      <query/Quilt_HTML_Table_Row/
      <code><![CDATA[
my $self = shift; my $row = shift; my $context = shift;
$self->print_ ("  <TR>\n");
$row->children_accept ($self, $context, @_);
$self->print_ ("  </TR>\n");
]]></code>

    <rule>
      <query/Quilt_HTML_Table_Data/
      <code><![CDATA[
my $self = shift; my $data = shift; my $context = shift;
$self->print_ ("    <TD>");
my $data_str = $data->as_string;
if ($data_str =~ /^\s*$/s) {
    $self->print_ ("&nbsp;");
} else {
    $data->children_accept ($self, $context, @_);
}
$self->print_ ("</TD>\n");
]]></code>

    <rule>
      <query/Quilt_HTML_Anchor/
      <code><![CDATA[
my $self = shift; my $anchor = shift; my $context = shift;
$self->print_ ("<A url=\"" . $anchor->url_as_string . "\">");
$anchor->children_accept ($self, $context, @_);
$self->print_ ("</A>\n\n");
]]></code>

    <rule>
      <query/scalar/
      <code><![CDATA[
my $self = shift; my $data = shift; my $context = shift;
print ($data->delegate);
]]></code>

    <rule>
      <query/SGML_SData/
      <code><![CDATA[
my $self = shift; my $sdata = shift; my $writer = shift;

# XXX we need to move this whole thing into $writer
my $data = $sdata->data;
my $mapping = $writer->{entity_map}->lookup ($data);
if (!defined $mapping) {
    $mapping = "[[" . $data . "]]";
    if (!$writer->{warn_map}{$data}) {
        warn "no entity map for \`$data'\n";
        $writer->{warn_map}{$data} = 1;
    }
}
# XXX this is only because we're using Ascii replacements
$mapping =~ s/&/&amp;/;
$mapping =~ s/</&lt;/;
$self->print_ ($mapping);
]]></code>

  </rules>
</spec>
