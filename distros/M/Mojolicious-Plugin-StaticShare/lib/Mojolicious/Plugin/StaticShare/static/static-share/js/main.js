(function(window){
  if(window.Package){
    Materialize = {};
  } else {
    window.Materialize = {};
  }
})(window);

// Velocity has conflicts when loaded with jQuery, this will check for it
// First, check if in noConflict mode
var Vel;
if (jQuery) {
  Vel = jQuery.Velocity;
} else if ($) {
  Vel = $.Velocity;
} else {
  Vel = Velocity;
}

$( document ).ready(function() {
  console.log('Доброго всем ALL GLORY TO GLORIA');
  /**********************************************/
  var progress = $('.progress-file .determinate');
  $('#fileupload').fileupload({
    dataType: 'json',
    ////singleFileUploads: false,
    ////formData: function(){ return filenames; },
    add: function (e, data) {
      var table = $('#fileupload').closest('.col').find('table.files');
      var tbody = $('tbody', table);
      var tr = $('thead tr', table);
      data.files.map(function (file, idx) {
        var ntr = tr.clone(true);
        $('td.chb input', ntr).prop('checked', true).on('change.cancel', function(ev){ ntr.remove(); });
        var namefield = $('td.name input[type="text"]', ntr).val(file.name);
        $('td.action a.file-upload', ntr).click(function () {
          data.context = namefield;
          namefield.siblings('.error').html('');
          $(this).hide();
          data.submit();
        });
        $('td.size', ntr).text(file.size);
        $('td.mtime', ntr).text((file.lastModified && new Date(file.lastModified).toLocaleString()) || (file.lastModifiedDate && file.lastModifiedDate.toLocaleString()) || '');
        ntr.prependTo(tbody);
        namefield.focus();
      });
    },// end add file
    progressall: function (e, data) {
      var ex = parseInt(data.loaded / data.total * 100, 10);
      progress.css('width',  ex + '%');
    },
    done: function (e, data) {//Upload finished
      if(data.result.error) {
        Materialize.toast(data.result.error, 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
        data.context.siblings('.error').html(data.result.error).closest('tr').find('td.action a.file-upload').show();
        return;
      }
      var name = data.context.val();
      var tr = data.context.closest('tr');
      $('td.chb input', tr).off('change.cancel');
      $('td.name a.file-view', tr).attr('href', data.result.ok).text(name).toggleClass('hide');
      $('td.name input', tr).toggleClass('hide');
      $('td.name .error', tr).html('');
      $('a', tr).toggleClass('white-text');
      $('svg', tr).toggleClass('light-blue-fill white-fill');
      $('td.action a.file-download', tr).attr('href', data.result.ok+'?attachment=1').toggleClass('hide');
      $('td.action a.file-rename', tr).attr('_href', data.result.ok);
      $('td.action a.file-upload', tr).remove();
      progress.css('width',  '0%');
      Materialize.toast("upload success", 3000, 'fw500 green-text text-darken-3 green lighten-5 border');
    },
    fail: function (e, data) {
      data.context.siblings('.error').html("upload fail");
    }
  }).bind('fileuploadsubmit', function (e, data) {
    data.formData = {};//files: JSON.stringify(data.files)
    data.files.map(function(file, idx){
      for (var key in file){
        data.formData[key] = file[key];
      }
      if(data.context && data.context.val) data.formData.name = data.context.val();
      
    });
    return true;
  });// end fileupload
  /*****************
  File functions
  *****************/
  var ToggleFileCheckbox = function(chb, rename, href) {
    var tr = chb.closest('tr');
    $('input[type="text"]', tr).toggleClass('hide').focus();
    var av = $('a.file-view', tr);
    av.toggleClass('hide');
    var ad = $('a.file-download', tr);
    var ae = $('a.file-edit', tr);
    ae.toggleClass('hide');
    var ar = $('a.file-rename', tr);
    ar.toggleClass('hide');
    if (rename !== undefined) av.text(rename);
    if (href !== undefined) {
      av.attr('href', href);
      ad.attr('href', href+'?attachment=1');
      ae.attr('href', href+'?edit=1');
      ar.attr('_href', href);
    }
  };
  /*********************/
  $('table.files input[type="checkbox"]').on('change', function(ev){
    var chb = $(this);
    var tr = chb.closest('tr').toggleClass('light-blue');
    $('a', tr).toggleClass('white-text');
    $('svg', tr).toggleClass('light-blue-fill white-fill');
    var btn = $('.files-col .btn-panel a');
    if ($('table.files input[type="checkbox"]').filter(':checked').length)  btn.removeClass('hide');
    else btn.addClass('hide');
    
    var ad = $('a.file-download', tr);
    ad.toggleClass('hide');
    var ae = $('a.file-edit', tr);
    ae.toggleClass('hide');

    if (!chb.is(':checked') && !$('input[type="text"]', tr).is(':hidden')) ToggleFileCheckbox(chb);
    
  });
  /************************************
  file buttons panel
  ************************************/
  $('.files-col .btn-panel a.renames').on('click', function(ev){
    var chb = $('table.files input[type="checkbox"]:checked');
    chb.each(function(){ ToggleFileCheckbox($(this)); });
    var tr  = chb.first().closest('tr');
    $('input[type="text"]', tr).focus();
    
  });
  /*********************/
  $('table.files a.file-rename').on('click', function(ev){
    var a = $(this);
    var tr = a.closest('tr');
    var chb = $(' input[type="checkbox"]', tr);
    var input = $('input[type="text"]', tr);
    var err = $('.error', tr).html('');
    $.post( a.attr('_href'), { "rename": input.val(), })
      .done(function(data) {
        if (data.error) {
          console.log("rename error:", data);
          Materialize.toast(data.error, 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
          return err.html(data.error);
        }
        if (data.ok) {
          Materialize.toast("renamed success", 3000, 'fw500 green-text text-darken-3 green lighten-5 border');
          f_ToggleFileCheckbox(chb, input.val(), data.ok);
        }
        
      })
      .fail(function() {
        Materialize.toast("rename fail", 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
        err.html('something fail');
      })
    ;
  });
  /*********************/
  function confirm_delete(rows, items, ul, hclass){// items - files or dirs
    var m = $('#confirm-modal');
    var h = $('.modal-header .'+hclass, m).clone();
    h.find('sup').text(items.length);
    $('.modal-content', m).empty().append(h).append(ul);
    var a = $('a.modal-close', m);
    a.off('click.confirm-ok').on('click.confirm-ok', function(ev){
      $.post( decodeURI(location.pathname).replace(/\/$/, '')+'/'+items[0], { "delete": items, })
        .done(function(data) {
          if(data.ok) {
            Materialize.toast("success deleted", 3000, 'fw500 green-text text-darken-3 green lighten-5 border');
            data.ok.map(function(val, idx){
              if (val == 1 ) rows[idx].remove();
              else $('.error', rows[idx]).html(val);
            });
          }
          else {
            console.log("delete error:", data);
            Materialize.toast(data.error, 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
          }
        })
        .fail(function() {
          Materialize.toast("delete fail", 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
          rows.map(function(row){
            $('.error', row).html('something fail');
          });
        })
      ;
      
    });
    m.modal('open');
  }
  /*********************/
  $('.files-col .btn-panel a.del-files').on('click', function(ev){
    var rows = [],
      files = [],
      ul = $('<ul class="collection card">');
    $('table.files input[type="checkbox"]:checked').each(function(){
      var chb = $(this);
      var tr = chb.closest('tr');
      var a = $('a.file-view', tr);
      if (a.text() == '' || a.attr('href') == '') return;
      rows.push(tr);
      files.push(a.text());
      ul.append($('<li class="collection-item">').text(a.attr('href')));
    });
    confirm_delete(rows, files, ul, 'del-files');
  });
  /*********************************************
  Dirs functions
  **********************************************/
  function  ToggleDirCheckbox(chb, rename, href) {
    var tr = chb.closest('tr');
    $('.input-field', tr).toggleClass('hide');
    $('a.dir, a.save-dir', tr).toggleClass('hide');
    //~ var action = tr.hasClass('new-dir') ? 'dir' : 'rename';
  }
  /****************/
  $('#add-dir').on('click', function(ev){
    var dirs = $('table.dirs');
    var tr = $('thead tr', dirs).clone(true).prependTo($('tbody', dirs));
    $('input[type="checkbox"]', tr).prop('checked', true).on('change.cancel', function(ev){ tr.remove(); });
    $('input[type="text"]', tr).focus();
    //~ $(this).addClass('hide');
    
    
  });
  /************************/
  $('table.dirs input[type="checkbox"]').on('change', function(ev){
    var chb = $(this);
    var tr = chb.closest('tr').toggleClass('lighten-5 darken-4');
    $('a', tr).toggleClass('text-darken-4 text-lighten-5');
    $('svg', tr).toggleClass('fill-darken-4 fill-lighten-5');
    var btn = $('.dirs-col .btn-panel a');
    if ($('table.dirs input[type="checkbox"]').filter(':checked').length)  btn.removeClass('hide');
    else {
      btn.addClass('hide');
      $('#add-dir').removeClass('hide');
    }

    if (!chb.is(':checked') && !$('input[type="text"]', tr).is(':hidden')) ToggleDirCheckbox(chb);
  });
  /************************/
  $('table.dirs a.save-dir').on('click', function(ev){//:first-child
    var a = $(this);
    var tr = a.closest('tr');
    var input = $('input[type="text"]', tr);
    var action = tr.hasClass('new-dir') ? 'dir' : 'rename';
    var err = $('.error', tr).html('');
    $.post( a.attr('_href'), [[action, input.val() ]].reduce(function(prev,curr){prev[curr[0]]=curr[1];return prev;},{}))// as map to plain object
      .done(function(data) {
        if(data.error) {
          console.log(action+" error: ", data);
          Materialize.toast(data.error, 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
          return err.html(data.error);
        }
        Materialize.toast(action+" successed", 3000, 'fw500 green-text text-darken-3 green lighten-5 border');
        var dir =  input.val();
        var ad = $('a.dir', tr);
        ad.text(dir);
        ad.attr('href', data.ok).removeClass('hide');
        $('input[type="checkbox"]', tr).off('change.cancel');
        a.attr('_href', data.ok).addClass('hide');
        $('div.input-field', tr).addClass('hide');
        tr.removeClass('new-dir');
        $('.dirs-col .btn-panel a').removeClass('hide');
      })
      .fail(function() {
        Materialize.toast(action+" fail", 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
        err.html('something fail');
      });
  });
  /**************
  dirs buttons panel
  **************/
  $('.dirs-col .btn-panel a.renames').on('click', function(ev){
    var chb = $('table.dirs input[type="checkbox"]:checked');
    chb.each(function(){ ToggleDirCheckbox($(this)); });
    var tr  = chb.first().closest('tr');
    $('input[type="text"]', tr).focus();
  });
  /******************/
  $('.dirs-col .btn-panel a.del-dirs').on('click', function(ev){
    var rows = [],
      dirs = [],
      ul = $('<ul class="collection card">');
    $('table.dirs input[type="checkbox"]:checked').each(function(){
      var chb = $(this);
      var tr = chb.closest('tr');
      var a = $('a.dir', tr);
      if (a.text() == '' || a.attr('href') == '') return;
      rows.push(tr);
      dirs.push(a.text());
      ul.append($('<li class="collection-item">').text(a.attr('href')));
    });
    confirm_delete(rows, dirs, ul, 'del-dirs');
  });
  /******************
  EDIT content
  ******************/
  if(window.ace) {
    var editor = ace.edit("editor");
    //~ editor.setTheme("ace/theme/textmate");//monokai
    editor.getSession().setUseWrapMode(true);
    editor.setOptions({
      autoScrollEditorIntoView: true,
      ///maxLines: 8
    });
    
    var saveBtn = $('.action a.save');
    var success = $('.success', saveBtn.parent());
    var fail = $('.fail', saveBtn.parent());
    saveBtn.on('click', function(event){
      //~ console.log("save", editor.getValue().length);
      var $this = $(this);
      $.post(
        decodeURI(window.location.pathname),
        {"edit":editor.getValue()}
      ).done(function( data ) {//
        //~ console.log("done save", data);
        Materialize.toast("save success", 3000, 'fw500 green-text text-darken-3 green lighten-5 border');
        $this.hide();
        success.removeClass('hide');
        fail.addClass('hide');
      }).fail(function(data){
        //~ console.log("fail save", data);
        Materialize.toast("save fail", 3000, 'fw500 red-text text-darken-3 red lighten-5 border');
        fail.removeClass('hide');
        success.addClass('hide');
      });
    });
    
    
    editor.getSession().on('change', function() {
      //~ console.log("edit changed");
      saveBtn.show();
      success.addClass('hide');
      fail.addClass('hide');
    });
  }
  
  /******************/
  
  
});

$( document ).ready(function() {
  $('input[type="checkbox"]').prop('checked', false);
  $('.modal').modal();
  $('.show-on-ready').slideDown();
});