package CMS::Schema;
use base qw(Oryx::Schema);
1;
__DATA__
<Schema>
  <Class name="CMS::Author">
      <Attribute name="first_name" type="String"/>
      <Attribute name="last_name"  type="String"/>
  </Class>

  <Class name="CMS::Paragraph">
      <Attribute name="content" type="Text"/>
  </Class>

  <Class name="CMS::Page">
      <Attribute name="title" type="String"/>
      <Attribute name="page_num" type="Integer"/>
      <Association role="author" class="CMS::Author" type="Reference"/>
      <Association role="paragraphs" class="CMS::Paragraph" type="Array"/>
  </Class>
</Schema>
