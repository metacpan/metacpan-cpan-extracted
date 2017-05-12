package Template::Declare::TagSet::XUL;

use strict;
use warnings;
#use Smart::Comments;
use base 'Template::Declare::TagSet';

our %AlternateSpelling = (
    template => 'xul_tempalte',
);

sub get_alternate_spelling {
    my ($self, $tag) = @_;
    $AlternateSpelling{$tag};
}

sub get_tag_list {
    return [ qw{
  action  arrowscrollbox  bbox  binding
  bindings  body  box  broadcaster
  broadcasterset  browser  button  caption
  checkbox  children  colorpicker  column
  columns  command  commandset  conditions
  constructor  content  deck  description
  destructor  dialog  dialogheader  editor
  field  getter  grid  grippy
  groupbox  handler  handlers  hbox
  iframe  image  implementation  key
  keyset  label  listbox  listcell
  listcol  listcols  listhead  listheader
  listitem  member  menu  menubar
  menuitem  menulist  menupopup  menuseparator
  method  observes  overlay  page
  parameter  popup  popupset  progressmeter
  property  radio  radiogroup  rdf
  resizer  resources  richlistbox row  rows
  rule  script  scrollbar  scrollbox
  separator  setter  spacer  splitter
  stack  statusbar  statusbarpanel  stringbundle
  stringbundleset  stylesheet  tab  tabbox
  tabbrowser  tabpanel  tabpanels  tabs
  template  textbox  textnode  titlebar
  toolbar  toolbarbutton  toolbargrippy  toolbaritem
  toolbarpalette  toolbarseparator  toolbarset  toolbarspacer
  toolbarspring  toolbox  tooltip  tree
  treecell  treechildren  treecol  treecols
  treeitem  treerow  treeseparator  triple
  vbox  window  wizard  wizardpage
    } ];
}

1;
__END__

=head1 NAME

Template::Declare::TagSet::XUL - Template::Declare tag set for XUL

=head1 SYNOPSIS

    # normal use on the user side:
    use base 'Template::Declare';
    use Template::Declare::Tags 'XUL';

    template main => sub {
        xml_decl { 'xml', version => '1.0' };
        groupbox {
            caption { attr { label => 'Colors' } }
        }
    };


    # in Template::Declare::Tags:
    use Template::Declare::TagSet::XUL;
    my $tagset = Template::Declare::TagSet::XUL->new({
        package   => 'MyXUL',
        namespace => 'xul',
    });
    my $list = $tagset->get_tag_list();
    print $_, $/ for @{ $list };

    if ( $altern = $tagset->get_alternate_spelling('template') ) {
        print $altern;
    }

    if ( $tagset->can_combine_empty_tags('button') ) {
        print q{<button label="OK" />};
    }

=head1 DESCRIPTION

Template::Declare::TagSet::XUL defines a full set of XUL tags for use in
Template::Declare templates. You generally won't use this module directly, but
will load it via:

    use Template::Declare::Tags 'XUL';

=head1 METHODS

=head2 new( PARAMS )

    my $html_tag_set = Template::Declare::TagSet->new({
        package   => 'MyXUL',
        namespace => 'xul',
    });

Constructor inherited from L<Template::Declare::TagSet|Template::Declare::TagSet>.

=head2 get_tag_list

    my $list = $tag_set->get_tag_list();

Returns an array ref of all the RDF tags defined by
Template::Declare::TagSet::RDF. Here is the complete list, extracted from
L<http://www.xulplanet.com/references/elemref/refall_elemref.xml> (only C<<
<element name='...'> >> were recognized):

=over

=item C<action>

=item C<arrowscrollbox>

=item C<bbox>

=item C<binding>

=item C<bindings>

=item C<body>

=item C<box>

=item C<broadcaster>

=item C<broadcasterset>

=item C<browser>

=item C<button>

=item C<caption>

=item C<checkbox>

=item C<children>

=item C<colorpicker>

=item C<column>

=item C<columns>

=item C<command>

=item C<commandset>

=item C<conditions>

=item C<constructor>

=item C<content>

=item C<deck>

=item C<description>

=item C<destructor>

=item C<dialog>

=item C<dialogheader>

=item C<editor>

=item C<field>

=item C<getter>

=item C<grid>

=item C<grippy>

=item C<groupbox>

=item C<handler>

=item C<handlers>

=item C<hbox>

=item C<iframe>

=item C<image>

=item C<implementation>

=item C<key>

=item C<keyset>

=item C<label>

=item C<listbox>

=item C<listcell>

=item C<listcol>

=item C<listcols>

=item C<listhead>

=item C<listheader>

=item C<listitem>

=item C<member>

=item C<menu>

=item C<menubar>

=item C<menuitem>

=item C<menulist>

=item C<menupopup>

=item C<menuseparator>

=item C<method>

=item C<observes>

=item C<overlay>

=item C<page>

=item C<parameter>

=item C<popup>

=item C<popupset>

=item C<progressmeter>

=item C<property>

=item C<radio>

=item C<radiogroup>

=item C<rdf>

=item C<resizer>

=item C<resources>

=item C<richlistbox>

=item C<row>

=item C<rows>

=item C<rule>

=item C<script>

=item C<scrollbar>

=item C<scrollbox>

=item C<separator>

=item C<setter>

=item C<spacer>

=item C<splitter>

=item C<stack>

=item C<statusbar>

=item C<statusbarpanel>

=item C<stringbundle>

=item C<stringbundleset>

=item C<stylesheet>

=item C<tab>

=item C<tabbox>

=item C<tabbrowser>

=item C<tabpanel>

=item C<tabpanels>

=item C<tabs>

=item C<template>

=item C<textbox>

=item C<textnode>

=item C<titlebar>

=item C<toolbar>

=item C<toolbarbutton>

=item C<toolbargrippy>

=item C<toolbaritem>

=item C<toolbarpalette>

=item C<toolbarseparator>

=item C<toolbarset>

=item C<toolbarspacer>

=item C<toolbarspring>

=item C<toolbox>

=item C<tooltip>

=item C<tree>

=item C<treecell>

=item C<treechildren>

=item C<treecol>

=item C<treecols>

=item C<treeitem>

=item C<treerow>

=item C<treeseparator>

=item C<triple>

=item C<vbox>

=item C<window>

=item C<wizard>

=item C<wizardpage>

=back

=head2 get_alternate_spelling( TAG )

    $bool = $obj->get_alternate_spelling($tag);

Returns the alternative spelling for a given tag if any or undef otherwise.
Currently, C<template> is mapped to C<xul_template> to avoid conflict with the
C<template> function exported by L<Template::Declare::Tags|Template::Declare::Tags>.

=head1 AUTHOR

Agent Zhang <agentzh@yahoo.cn>

=head1 SEE ALSO

L<Template::Declare::TagSet>, L<Template::Declare::TagSet::HTML>,
L<Template::Declare::Tags>, L<Template::Declare>.

