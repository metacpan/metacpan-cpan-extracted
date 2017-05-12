/**
 * Create confirmation dialog
 *
 * ref.id    uniq ID
 * ref.title  title
 * ref.text  text to display
 * ref.button text of "ok" button
 * ref.height hight of the dialog
 * ref.ok    callback function if "ok" button pressed
 * ref.cancel callback function if "cancel" button pressed
 */
function dialog_confirm(ref) {
  $( "#diag_" + ref.id ).remove();

  var dlg_html = new Array('<div id="diag_' + ref.id + '" title="' + ref.title + '">');
  dlg_html.push('<p><span class="ui-icon ui-icon-alert" style="float: left; margin: 0 7px 20px 0;"></span>' + ref.text + '</p>');
  dlg_html.push('</div>');

  var the_buttons = {};
  the_buttons[ref.button] = function() {
    $( this ).dialog( "close" );
    ref.ok();

    $( this ).dialog( "destroy" );
    $( "#diag_" + ref.id ).remove();
  };

  the_buttons["Cancel"] = function() {
    $( this ).dialog( "close" );
    $( this ).dialog( "destroy" );

    $( "#diag_" + ref.id ).remove();
    ref.cancel();
  };

  $("body").append(dlg_html.join("\n"));
  $("#diag_" + ref.id).dialog({
      resizable: false,
      height: (ref.height || 200),
      width: (ref.width || 350),
      modal: true,
      autoOpen: true,
      buttons: the_buttons
  });
}

function delete_rexfile(_title, _url) {
  dialog_confirm({
    "id": "dlg_delete_rexfile",
    "title": _title,
    "text": "Do you really want to remove this Rexfile?",
    "button": "Remove",
    "height": 250,
    "ok": function() {
      document.location.href = _url;
    },
    "cancel": function() {},
  });
}

function delete_formular(_title, _url) {
  dialog_confirm({
    "id": "dlg_delete_formular",
    "title": _title,
    "text": "Do you really want to remove this Formular?",
    "button": "Remove",
    "height": 250,
    "ok": function() {
      document.location.href = _url;
    },
    "cancel": function() {},
  });
}

function delete_job(_title, _url) {
  dialog_confirm({
    "id": "dlg_delete_job",
    "title": _title,
    "text": "Do you really want to remove this Job?",
    "button": "Remove",
    "height": 250,
    "ok": function() {
      document.location.href = _url;
    },
    "cancel": function() {},
  });
}

function delete_project(_title, _url) {
  dialog_confirm({
    "id": "dlg_delete_project",
    "title": _title,
    "text": "Do you really want to remove this Project?",
    "button": "Remove",
    "height": 250,
    "ok": function() {
      document.location.href = _url;
    },
    "cancel": function() {},
  });
}


