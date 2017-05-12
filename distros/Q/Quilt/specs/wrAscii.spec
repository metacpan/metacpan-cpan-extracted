<!-- -*- sgml -*- -->
<!DOCTYPE spec PUBLIC "-//Ken MacLeod//DTD Grove Simple Spec//EN">
<spec>
  <head>
    <defaultobject>ick-hack</defaultobject>
    <defaultprefix>ick-hack</defaultprefix>
  <rules>
    <rule>
      <query/Quilt_Flow/
      <code><![CDATA[
my $self = shift; my $flow = shift; my $writer = shift;
my $inline = $flow->inline;
if ($inline) {
    # XXX `mark' hack
    if ($flow->is_mark) {
        $writer->push_mark ($flow->as_string);
        return;
    } else {
        $writer->push_inline ($flow);
    }
} else {
    $writer->push_display ($flow);
}
$flow->children_accept ($self, $writer, @_);
if ($inline) {
    $writer->pop_inline;
} else {
    $writer->pop_display;
}
]]></code>

    <rule>
      <query/Quilt_Flow_Paragraph/
      <code><![CDATA[ 
my $self = shift; my $paragraph = shift; my $writer = shift;
$writer->push_display ($paragraph);
$paragraph->children_accept ($self, $writer, @_);
$writer->pop_display;
]]></code>

    <rule>
      <query/Quilt_Flow_DisplaySpace/
      <code><![CDATA[
my $self = shift; my $display_space = shift; my $writer = shift;
$writer->push_break ($display_space);
]]></code>

    <rule><query/Quilt_Flow_Table/ <code><![CDATA[
my $self = shift; my $table = shift; my $writer = shift;
$writer->push_display (new Quilt::Flow (space_before => 1, space_after => 1, lines => 'asis'));
$writer->push_data ($writer->format_table ($table->delegate, $self));
$writer->pop_display;
]]></code>

    <rule><query/Quilt_Flow_Table_Part/ <code><![CDATA[
my $self = shift; my $table = shift; my $writer = shift;
$writer->push_display (new Quilt::Flow (space_before => 1, space_after => 1, lines => 'asis'));
$writer->push_data ($writer->format_table ($table->delegate, $self));
$writer->pop_display;
]]></code>

    <rule>
      <query>scalar</query>
      <code><![CDATA[
my $self = shift; my $scalar = shift; my $writer = shift;
$writer->push_data ($scalar->delegate);
]]></code>

    <rule>
      <query>sdata</query>
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
$writer->push_data ($mapping);
]]></code>

    <rule>
      <query>SGML_SData</query>
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
$writer->push_data ($mapping);
]]></code>

  </rules>
</spec>
