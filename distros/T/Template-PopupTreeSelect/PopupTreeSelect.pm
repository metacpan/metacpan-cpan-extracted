package Template::PopupTreeSelect;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Template 2.08;

our $VERSION = "0.9";

use base 'HTML::PopupTreeSelect';

=head1 NAME

Template::PopupTreeSelect - HTML popup tree widget

=head1 DESCRIPTION

Subclasses L<HTML::PopupTreeSelect>.

=cut

our $TEMPLATE_SRC;

sub output
{
    my($self, $template) = @_;
    return $self->SUPER::output(
        $template || Template->new(TAG_STYLE => 'star')
    );
}

sub _output_generate
{
    my($self, $template, $param) = @_;
    my $output;
    $template->process(\$TEMPLATE_SRC, $param, \$output);
    return $output;
}

$TEMPLATE_SRC = <<END;
[* IF include_css *]<style type="text/css"><!--

  /* style for the box around the widget */
  .hpts-outer {
     visibility:       hidden;
     position:         absolute;
     top:              0px;
     left:             0px;
     border:           2px outset #333333;
     background-color: #ffffff;
     filter:           progid:DXImageTransform.Microsoft.dropShadow( Color=bababa,offx=3,offy=3,positive=true);
  }

  /* style for the box that contains the tree */
  .hpts-inner {
[* IF scrollbars *]
     overflow:         scroll;
[* END *]
     width:            [* width *]px;
[* IF height *]
     height:           [* height *]px;
[* END *]
  }

  /* title bar style.  The width here will define a minimum width for
     the widget. */
  .hpts-title {
     padding:          2px;
     margin-bottom:    4px;
     font-size:        large;
     color:            #ffffff;
     background-color: #666666;
     width:            [* width *]px;
  }

  /* style of a block of child nodes - indents them under their parent
     and starts them hidden */
  .hpts-block {
     margin-left:      24px;
     display:          none;
  }

  /* style for the button bar at the bottom of the widget */
  .hpts-bbar {
     padding:          3px;
     text-align:       right;
     margin-top:       10px;
     background-color: #666666;
     width:            [* width *]px;
  }

  /* style for the buttons at the bottom of the widget */
  .hpts-button {
     margin-left:      15px;
     background-color: #ffffff;
     color:            #000000;
  }

  /* style for selected labels */
  .hpts-label-selected {
     background:       #98ccfe;
  }

  /* style for labels after being unselected */
  .hpts-label-unselected {
     background:       #ffffff;
  }

--></style>[* END; #include_css *]

<script language="javascript">
  /* record location of mouse on each click */
  var hpts_mouseX;
  var hpts_mouseY;
  var hpts_offsetX;
  var hpts_offsetY;
  var hpts_locked_obj;

  document.onmousedown = hpts_lock;
  document.onmousemove = hpts_drag;
  document.onmouseup   = hpts_release;

  function hpts_lock(evt) {
        evt = (evt) ? evt : event;
        hpts_set_locked(evt);
        hpts_update_mouse(evt);

        if (hpts_locked_obj) {
            if (evt.pageX) {
               hpts_offsetX = evt.pageX - ((hpts_locked_obj.offsetLeft) ? 
                              hpts_locked_obj.offsetLeft : hpts_locked_obj.left);
               hpts_offsetY = evt.pageY - ((hpts_locked_obj.offsetTop) ? 
                              hpts_locked_obj.offsetTop : hpts_locked_obj.top);
            } else if (evt.offsetX || evt.offsetY) {
               hpts_offsetX = evt.offsetX - ((evt.offsetX < -2) ? 
                              0 : document.body.scrollLeft);
               hpts_offsetY = evt.offsetY - ((evt.offsetY < -2) ? 
                              0 : document.body.scrollTop);
            } else if (evt.clientX) {
               hpts_offsetX = evt.clientX - ((hpts_locked_obj.offsetLeft) ? 
                              hpts_locked_obj.offsetLeft : 0);
               hpts_offsetY = evt.clientY - ((hpts_locked_obj.offsetTop) ? 
                               hpts_locked_obj.offsetTop : 0);
            }
            return false;
        }

        return true;
  }

  function hpts_update_mouse(evt) {
      if (evt.pageX) {
         hpts_mouseX = evt.pageX;
         hpts_mouseY = evt.pageY;
      } else {
         hpts_mouseX = evt.clientX + document.documentElement.scrollLeft + document.body.scrollLeft;
         hpts_mouseY = evt.clientY + document.documentElement.scrollTop  + document.body.scrollTop;
      }
  }


  function hpts_set_locked(evt) {
    var target = (evt.target) ? evt.target : evt.srcElement;
    if (target && target.className == "hpts-title") { 
       hpts_locked_obj = target.parentNode;
       return;
    }
    hpts_locked_obj = null;
    return;
  }

  function hpts_drag(evt) {
        evt = (evt) ? evt : event;
        hpts_update_mouse(evt);

        if (hpts_locked_obj) {
           hpts_locked_obj.style.left = (hpts_mouseX - hpts_offsetX) + "px";
           hpts_locked_obj.style.top  = (hpts_mouseY - hpts_offsetY) + "px";
           evt.cancelBubble = true;
           return false;
        }
  }

  function hpts_release(evt) {
     hpts_locked_obj = null;
  }

  var [* name *]_selected_id = -1;
  var [* name *]_selected_val;
  var [* name *]_selected_elem;

  /* expand or collapse a sub-tree */
  function [* name *]_toggle_expand(id) {
     var obj = document.getElementById("[* name *]-desc-" + id);
     var plus = document.getElementById("[* name *]-plus-" + id);
     var node = document.getElementById("[* name *]-node-" + id);
     if (obj.style.display != 'block') {
        obj.style.display = 'block';
        plus.src = "[* image_path *]minus.png";
        node.src = "[* image_path *]open_node.png";
     } else {
        obj.style.display = 'none';
        plus.src = "[* image_path *]plus.png";
        node.src = "[* image_path *]closed_node.png";
     }
  }

  /* select or unselect a node */
  function [* name *]_toggle_select(id, val) {
     if ([* name *]_selected_id != -1) {
        /* turn off old selected value */
        var old = document.getElementById("[* name *]-line-" + [* name *]_selected_id);
        old.className = "hpts-label-unselected";
     }

     if (id == [* name *]_selected_id) {
        /* clicked twice, turn it off and go back to nothing selected */
        [* name *]_selected_id = -1;
     } else {
        /* turn on selected item */
        var new_obj = document.getElementById("[* name *]-line-" + id);
        new_obj.className = "hpts-label-selected";
        [* name *]_selected_id = id;
        [* name *]_selected_val = val;
     }
  }

  /* it's showtime! */
  function [* name *]_show() {
        var obj = document.getElementById("[* name *]-outer");
        var x = Math.floor(hpts_mouseX - ([* width *]/2));
        x = (x > 2 ? x : 2);
        var y = Math.floor(hpts_mouseY - ([* IF height *][* height *]/5 * 4[* ELSE *]100[* END *]));
        y = (y > 2 ? y : 2);

        obj.style.left = x + "px";
        obj.style.top  = y + "px";
        obj.style.visibility = "visible";

      [* IF hide_selects *]
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.options) {
                e.style.visibility = "hidden";
             }
          }
        }
     [* END *]

     [* IF hide_textareas *]
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.rows) {
                e.style.visibility = "hidden";
             }
          }
        }
     [* END *]
  }

  /* user clicks the ok button */
  function [* name *]_ok() {
        if ([* name *]_selected_id == -1) {
           /* ahomosezwha? */
           alert("Please select an item or click Cancel to cancel selection.");
           return;
        }

        /* fill in a form field if they spec'd one */
        [* IF form_field *][* IF form_field_form *]document.forms["[* form_field_form *]"][* ELSE *]document.forms[0][* END *].elements["[* form_field *]"].value = [* name *]_selected_val;[* END *]

        /* trigger onselect */
        [* IF onselect *][* onselect *]([* name *]_selected_val)[* END *]

        [* name *]_close();
  }

  function [* name *]_cancel() {
        [* name *]_close();
  }

  function [* name *]_close () {
        /* hide window */
        var obj = document.getElementById("[* name *]-outer");
        obj.style.visibility = "hidden";

        /* clear selection */
        if ([* name *]_selected_id != -1) {
                [* name *]_toggle_select([* name *]_selected_id);
        }

      [* IF hide_selects *]
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.options) {
                e.style.visibility = "visible";
             }
          }
        }
      [* END *]

      [* IF hide_textareas *]
        for(var f = 0; f < document.forms.length; f++) {
          for(var x = 0; x < document.forms[f].elements.length; x++) {
             var e = document.forms[f].elements[x];
             if (e.rows) {
                e.style.visibility = "visible";
             }
          }
        }
      [* END *]
  }

</script>

<div id="[* name *]-outer" class="hpts-outer">
  <div class="hpts-title" id="[* name *]-title">[* title *]</div>
  <div class="hpts-inner">
  [* FOREACH leaf = loop *]
    [* UNLESS leaf.end_block *]
       <div nowrap>
          [* IF leaf.has_children *]
              <img id="[* name *]-plus-[* leaf.id *]" width=16 height=16 src="[* image_path *][* IF leaf.open *]minus[* ELSE *]plus[* END *].png" onclick="[* name *]_toggle_expand([* leaf.id *])"><span id="[* name *]-line-[* leaf.id *]" ondblclick="[* name *]_toggle_expand([* leaf.id *])" onclick="[* name *]_toggle_select([* leaf.id *], '[* leaf.value | html *]')">
          [* ELSE *]
              <img width=16 height=16 src="[* image_path *]L.png"><span id="[* name *]-line-[* leaf.id *]" onclick="[* name *]_toggle_select([* leaf.id *], '[* leaf.value | html *]')">
          [* END *]
                 <img id="[* name *]-node-[* leaf.id *]" width=16 height=16 src="[* image_path *]closed_node.png">
                 <a href="javascript:void(0);">[* leaf.label *]</a>
              </span>
       </div>
       [* IF leaf.has_children *]
          <div id="[* name *]-desc-[* leaf.id *]" class="hpts-block" [* IF leaf.open *]style="display: block"[* ELSE *]style="display: none"[* END *] nowrap>
       [* END *]
    [* ELSE *]
      </div>
    [* END *]
  [* END *]
  </div>
  <div class="hpts-bbar" nowrap>
    <input class=hpts-button type=button value=" Ok " onclick="[* name *]_ok()">
    <input class=hpts-button type=button value="Cancel" onclick="[* name *]_cancel()">
  </div>
</div>

<input class=hpts-button type=button value="[* button_label *]" onmouseup="[* name *]_show()">
END

1;
