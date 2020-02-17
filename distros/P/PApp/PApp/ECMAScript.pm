##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::ECMAScript - make javascript horrors less horrible

=head1 SYNOPSIS

 use PApp::ECMAScript;

=head1 DESCRIPTION

=over 4

=cut

package PApp::ECMAScript;

$VERSION = 2.2;
@EXPORT = qw($js escape_string_sq escape_string_dq);

use base Exporter;

=item $obj = new PApp::ECMAScript

Create a new object. Better use the C<init> function.

=cut

sub new {
   my $class = shift;
   bless { @_ }, $class;
}

=item init PApp::ECMAScript

Create a new global PApp::ECMAScript object, storing it in the (exported)
variable C<$js>, which should be shared between all modules for caching
purposes. Consequently, this function should be called once in the request
callback or in the global stylesheet.

=cut

sub init {
   if ($js->{stateid} ne $PApp::stateid) {
      $js = new PApp::ECMAScript stateid => $PApp::stateid;
   }
}

=item unique

Return a unique identifier. This is useful when generating function names
or other identifiers.

=cut

my $unique = "A00";

sub unique {
   return ++$unique;
}

=item escape_string_sq $string [EXPORTED]

=item escape_string_dq $string [EXPORTED]

Escape the given string as required and return it (C<escape_string_sq>
will use single quotes to delimit the string, C<escape_string_dq> will use
double quotes). Remember that many browsers do not like quoting, so use
the right function to minimize impact.

=cut

sub escape_string_sq($) {
   local $_ = shift;
   s{([^\x20-\x25\x28-\x3b\x3d-\x5b\x5d-\x7e])}{
      my $ord = ord $1;
      sprintf $ord < 256 ? '\\x%02x' : '\\u%04x', $ord;
   }ge;
   "'$_'";
}

sub escape_string_dq($) {
   local $_ = shift;
   s{([^\x20-\x21\x23-\x25\x27-\x3b\x3d-\x5b\x5d-\x7e])}{
      my $ord = ord $1;
      sprintf $ord < 256 ? '\\x%02x' : '\\u%04x', $ord;
   }ge;
   "\"$_\"";
}

=item $js->add_headercode($code)

Add the given code fragment to the HTML/HEAD/SCRIPT section.

=item $js->need_headercode($code)

Mark the given code fragment as to be added to the html head section. The
same fragment will only be added once.

=item $js->headercode

Return the code to be put in the head section.

=cut

sub add_headercode($$) {
   my $self = shift;
   $self->{hc} .= $_[0]."\n";
}

sub need_headercode($$) {
   my $self = shift;
   $self->add_headercode($_[0]) unless $self->{_needhc}{$_[0]}++;
}

=item $js->add_onevent("event", "code")

=item $js->need_onevent("event", "code")

Add code that is run when the given event occurs. Event should be
something like "window.onclick" or "document.onload".

=cut

sub add_onevent($$$) {
   my $js = shift;
   $js->{oevent}{$_[0]} .= $_[1]."\n";
}

sub need_onevent($$$) {
   my $js = shift;
   $js->add_onevent(@_) unless $js->{_needoe}{"$_[0]\x00$_[1]"}++;
}

sub headercode($) {
   my $js = shift;
   my $head = $js->{hc};
   while (my ($e, $c) = each %{$js->{oevent}}) {
      (my $e2 = $e) =~ y/./_/;
      $head .= "function papp_oe_$e2(event) { \n$c}\n" .
               "$e = papp_oe_$e2;\n";
   }
   $head;
}

=item $code = $js->is_ns

=item $code = $js->is_ns4

=item $code = $js->is_ie

=item $code = $js->is_ie4

=item $code = $js->is_ie5

=item $code = $js->is_konquerer

Return javascript code that checks wether the code is running under
netscape, netscape 4 (or higher), ie, ie4 (or higher) or ie5 (or higher), respectively.

=cut

sub _agent_test($) {
   $_[0]->need_headercode("var ua=navigator.userAgent.toLowerCase();");
   $_[0]->need_headercode("var is_major = parseInt(navigator.appVersion);");
   $_[0]->need_headercode("var is_minor = parseFloat(navigator.appVersion);");
}

sub ns_version($) {

   $_[0]->_agent_test;
   $_[0]->need_headercode("var ns_version=((ua.indexOf('mozilla')!=-1)"
                          . " && (ua.indexOf('spoofer')==-1)"
                          . " && (ua.indexOf('compatible') == -1)"
                          . " && (ua.indexOf('opera')==-1)"
                          . " && (ua.indexOf('webtv')==-1)"
                          . " && (ua.indexOf('hotjava')==-1))"
                          . " && ((is_major == 2)?2:((is_major == 3)?3"
                          . ":((is_major == 4)?4:((is_major == 5)?6:7))));");
   "ns_version";
}

sub is_ns($;$) {

   my ($self, $version) = $_;
   
   $self->ns_version;
   $self->need_headercode("var papp_ns=(".$version." == ns_version)?true:false;"); 
   "papp_ns";
}

sub is_ns_up($;$) {

   my ($self, $version) = $_;

   $self->ns_version;
   $self->need_headercode("var papp_ns_up=(papp_ns >= ".$version.")?true:false;");
   "papp_ns_up";
}

sub is_gecko($) {
   $_[0]->need_headercode("var is_gecko=ua.indexOf('gecko') != -1);");
   "is_gecko";
}

sub ie_version($) {

   $_[0]->_agent_test;
   $_[0]->need_headercode("var ie_version=((ua.indexOf('msie') != -1) && (ua.indexOf('opera') == -1))?is_major:0;");
   "ie_version";
}

sub is_ie4($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie4=((".$_[0]->is_ie." && (is_major == 4)) && (ua.indexOf('msie 4') != -1)));");
   "papp_ie4";
}

sub is_ie4up($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie4up=(".$_[0]->is_ie." && (is_major >= 4));");
   "papp_ie4up";
}

sub is_ie5($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie5=(".$_[0]->is_ie." && (ua.indexOf('msie 5.0') != -1));");
   "papp_ie5";
}

sub is_ie5up($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie5up=(".$_[0]->is_ie." && !".$_[0]->is_ie3." && !".$_[0]->is_ie4.");"); 
   "papp_ie5up";
}

sub is_ie5_5($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie5_5=((".$_[0]->is_ie." && (is_major == 4)) && (ua.indexOf('msie 5.5') != -1)));");
   "papp_ie5_5";
}

sub is_ie5_5up($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie5_5up=(".$_[0]->is_ie." && !".$_[0]->is_ie3." && !".$_[0]->is_ie4." && !".$_[0]->is_ie5.");"); 
   "papp_ie5_5up";
}

sub is_ie6($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie6=((".$_[0]->is_ie." && (is_major == 4)) && (ua.indexOf('msie 6.') != -1)));");
   "papp_ie6";
}

sub is_ie6up($) {
   $_[0]->_agent_test;
   $_[0]->need_headercode("var papp_ie6up=(".$_[0]->is_ie." && !".$_[0]->is_ie3." && !".$_[0]->is_ie4." && !".$_[0]->is_ie5." && !".$_[0]->is_ie6.");"); 
   "papp_ie6up";
}

sub aol_version {

   $_[0]->_agent_test;
   $_[0]->need_headercode("var aol_version=(ua.indexOf('aol') != -1) && ("
                          . $_[0]->is_ie3."?3:(".$_[0]->is_ie4
                          . "?4:((ua.indexOf('aol 5') != -1)?5:"
                          . "(ua.indexOf('aol 6') != -1)?6:7)));");
   "aol_version";
}

sub is_aol($;$) {

   my ($self, $version) = $_;

   $self->aol_version;
   $self->need_headercode("var papp_aol=(".$version." == aol_version)?true:false;");
   "papp_aol";
}

sub is_aol_up($;$) {

   my ($self, $version) = $_;

   $self->aol_version;
   $self->need_headercode("var papp_aol_up=(aol_version >= ".$version.")?true:false;");
   "papp_aol_up"
}

sub is_konquerer($) {
   $_[0]->need_headercode("var papp_konq=(navigator.userAgent.indexOf('konqueror')>0)?true:false;");
   "papp_konq";

}

=item $js->can_css

Return wether the browser supports CSS.

=cut

sub can_css($)  {
   $_[0]->need_headercode("var papp_css = document.getElementById || document.layers || document.all;");
   "papp_css";
}

=item $js->visibility_hidden

=item $js->visibility_visible

Return the string that should be used to set the visibility attribute to "hidden" or "visible".

=cut

sub visibility_hidden($) {
   "(".$_[0]->is_ns4."?'hide':'hidden')";
}

sub visibility_visible($) {
   "(".$_[0]->is_ns4."?'show':'visible')";
}

=item $js->event

Return the name of the event object (either window.event or event).

=cut

sub event($) {
   #$_[0]->need_headercode("if (!window.event) { window.event = false; }");
   "(window.event?window.event:event)";
}

=item $js->get_style_object($name)

Return code that finds the style object with the given name and returns it.

=cut

# http://developer.apple.com/internet/_javascript/hideshow_layer.html

sub get_style_object($$) {
   my $js = shift;
   $js->need_headercode("
function papp_gso(name) {
   return document.getElementById ? document.getElementById(name).style
                                  : ".$js->is_ns." ? document.layers[name]
                                  : document.all[name].style;
}");
   "papp_gso($_[0])";
}

=item $js->event_page_x

=item $js->event_page_y

Return the window x or y coordinate from the current event relative to the
current page.

=cut


sub event_page_x($) {
   my $event = $_[0]->event;
   $_[0]->need_headercode("
function papp_evpx(event) {
   return $event.pageX?$event.pageX:$event.x+(document.body.scrollLeft?document.body.scrollLeft:0);
}");
   "papp_evpx(event)";
}

sub event_page_y($) {
   my $event = $_[0]->event;
   $_[0]->need_headercode("
function papp_evpy(event) {
   return $event.pageY?$event.pageY:$event.y+(document.body.scrollTop?document.body.scrollTop:0);
}");
   "papp_evpy(event)";
}

=item $js->window_height

=item $js->window_width

Return the (approximate) height and width of the scrollable area, i.e. the
inner width and height of the window.

=cut

sub window_height($) {
   $_[0]->need_headercode("
function papp_ih() {
   return document.body.scrollHeight ? document.body.scrollHeight : window.innerHeight;
}");
   "papp_ih()";
}

sub window_width($) {
   $_[0]->need_headercode("
function papp_iw() {
   return document.body.scrollWidth ? document.body.scrollWidth : window.innerWidth;
}");
   "papp_iw()";
}

package PApp::ECMAScript::Layer;

=back

=head2 The PApp::ECMAScript::Layer Class

This class manages floating cxx objects (i.e. objects with style invisible
that can be shown, hidden, moved etc... using javascript).

=cut

use PApp::HTML qw(tag);

my $papp_layer = "papplayer000";

=over

=item $layer = new PApp::ECMAScript::Layer arg => val, ...

Create a new layer object (does not output anything).

   js      => the javascript object to use (default $PApp::ECMAScript::js)
   id      => the name (html id), default autogenerated
   content => the content of the layer/div element
   element => the element used for the layer

=cut

sub new($;@) {
   my $class = shift;
   bless {
      js => $PApp::ECMAScript::js,
      id => ++$papp_layer,
      @_,
   }, $class;
}

=item $layer->id([newid])

Return the current object id (optionally setting it).

=item $layer->content([newcontent])

Return the current object content (optionally setting it).

=cut

sub id($;$) {
   $_[0]->{id} = $_[1] if $#_;
   $_[0]->{id};
}

sub content($;$) {
   $_[0]->{content} = $_[1] if $#_;
   $_[0]->{content};
}

=item $layer->code

Return the javascript code used to create the (initially hidden)
layer. The best place for this is the top of the document, just below the
BODY tag, but that's not a requirement for working browsers ;)

Please note that all javascript code returned is not quoted, which is
not a problem when outputting it directly since browsers actually EXPECT
misquoted input, but it is a problem when you output strict html (xml)
or want to feed this into an XSLT stylesheet, in which case you need to
C<escape_html()> the code first and use C<disable-output-escaping> in your
stylesheet to deliberatly create broken HTML on output.

=cut

sub code {
   my $self = shift;
   "if (".$self->{js}->can_css.") { document.write (".PApp::ECMAScript::escape_string_sq(
      (
         tag "style", {
            type => "text/css",
         },
         "#$self->{id} { position:absolute;left:0px;top:0px;visibility:hidden;z-index:20 }"
      ).(
         tag $self->{element} || "div", {
               id => $self->{id},
            },
            delete $self->{content}
      )
   ).") }";
}

=item $layer->style_object

Return an expression that evaluates to the style object used by the code.

=cut

sub style_object {
   my $self = shift;
   $self->{js}->get_style_object("'$self->{id}'");
}

=item $layer->showxy($x,$y)

Return code to display the layer object at position ($x,$y) (which should
be valid javascript expressions).

=item $layer->show_relmouse($x,$y)

Same as C<howxy>, but use the current mouse position as origin.

=item $layer->show

Return code to display the layer object.

=item $layer->hide

Return code to hide the layer object.

=cut

sub showxy {
   my $self = shift;
   $self->{js}->need_headercode("
function papp_div_showxy(name,x,y) {
   var idiv = ".$self->{js}->get_style_object("name").";
   idiv.left = x; idiv.top = y;
   idiv.visibility = ".$self->{js}->visibility_visible.";
}");
   "papp_div_showxy('$self->{id}', $_[0], $_[1])";
}

sub show_relmouse {
   my $self = shift;
   $self->showxy($self->{js}->event_page_x . "+$_[0]",
                 $self->{js}->event_page_y . "+$_[1]");
}

sub show {
   my $self = shift;
   $self->style_object.".visibility = ".$self->{js}->visibility_visible;
}

sub hide {
   my $self = shift;
   $self->style_object.".visibility = ".$self->{js}->visibility_hidden;
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

