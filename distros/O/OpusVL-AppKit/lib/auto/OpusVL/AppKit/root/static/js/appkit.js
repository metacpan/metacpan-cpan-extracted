// appkit.js
//
// Utility functions for OpusVL::AppKit


//--appNav top navigation menu--------------------------------------------------

var appList = {
  show: function() {
    this.active = true;
    $('#appList').show();
    $('#appKitSearch').hide();
  },
  
  hide: function() {
    this.active = false;    
    $('#appList').hide();
  }  
};

$(function() {
  $('#appList_anchor').mousedown(function() {
    if (navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPod/i)) {
      // do nothing on iPhone
    } else {
      appList.show();
    }
  });
  
  $('#appList_anchor').click(function() {
    if (navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPod/i)) {
      if (appList.active) {
        appList.hide();
      } else {
        appKitSearch.hide();
        appList.show();
      }
    }  
    return false;
  });
  
  $('#appList_anchor').mouseover(function() {
    appList.overAnchor = true;
    appList.anchorMouseoverTimeout = setTimeout(function(){appList.show()},250);
  });
  
  $('#appList_anchor').mouseout(function() {
    appList.overAnchor = false;
    clearTimeout(appList.anchorMouseoverTimeout);
    if (appList.active) {
      clearTimeout(appList.viewTimeout);
      appList.viewTimeout = setTimeout(function(){appList.hide()},1000);
    }
  });
  
  $('#appList').mouseover(function() {
    appList.hover = true;
    clearTimeout(appList.viewTimeout);
  });
  
  $('#appList').mouseout(function() {
    appList.hover = false;
    if (appList.active) {
      clearTimeout(appList.viewTimeout);
      appList.viewTimeout = setTimeout(function(){appList.hide()},1000);
    }
  });
});


//--Search top navigation drop-down menu----------------------------------------

var appKitSearch = {
  show: function() {
    this.active = true;
    $('#appKitSearch').show();
    $('#appList').hide();
  },
  
  hide: function() {
    this.active = false;    
    $('#appKitSearch').hide();
  }  
};

$(function() {
  $('#appKitSearch_anchor').mousedown(function() {
    appKitSearch.show();
  });
  
  $('#appKitSearch_anchor').click(function() {
    if (navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPod/i)) {
      if (appKitSearch.active) {
        appKitSearch.hide();
      } else {
        appList.hide();
        appKitSearch.show();
      }
    }
    return false;
  });
  
  $('#appKitSearch_anchor').mouseover(function() {
    appKitSearch.overAnchor = true;
    appKitSearch.anchorMouseoverTimeout = setTimeout(function(){appKitSearch.show()},250);
  });
  
  $('#appKitSearch_anchor').mouseout(function() {
    appKitSearch.overAnchor = false;
    clearTimeout(appKitSearch.anchorMouseoverTimeout);
    if (appKitSearch.active) {
      clearTimeout(appKitSearch.viewTimeout);
      appKitSearch.viewTimeout = setTimeout(function(){appKitSearch.hide()},1000);
    }
  });
  
  $('#appKitSearch').mouseover(function() {
    appKitSearch.hover = true;
    clearTimeout(appKitSearch.viewTimeout);
  });
  
  $('#appKitSearch').mouseout(function() {
    appKitSearch.hover = false;
    if (appKitSearch.active) {
      clearTimeout(appKitSearch.viewTimeout);
      appKitSearch.viewTimeout = setTimeout(function(){appKitSearch.hide()},1000);
    }
  });
});


//--Set up tabbed content blocks------------------------------------------------

$(function() {
    $('.tabbed_content_block').each(function() {
      var tab_block = $(this);
      tab_block.tabs();
      tab_block.children("div").addClass('tab_content_block');
      tab_block.find('.error_message').each(function () {
        var error = $(this);
        var tab = error.closest('div.tab_content_block').attr('id');
        tab_block.find('a.ui-tabs-anchor[href="#' + tab + '"]').addClass('error');
      });
    });
});

$(function() {
    $('.tabbed_block').each(function() {
      $(this).tabs();
    });
}); 


//--Render any action drop-down controls----------------------------------------

var appKit = {
  windowClick: function() {
    $(".control-edit-small > ul").each(function(){
        $(this).hide();
    });    
  }
};

$(function() {
  $(window).click(function(){appKit.windowClick();
    if (!appList.hover) {
      appList.hide();
    }
    if (!appKitSearch.hover) {
      appKitSearch.hide();
    }
    //$(".control-edit-small > ul").each(function(){
      //if (!$(this).hasClass('nohide')) {
      //  $(this).hide();
      //};
    //});
    //$(".control-edit-small > ul").removeClass('nohide');
  });
    
  $(".control-edit-small").each(function() {
    $('<a href="#"></a>').click(
      function() {
        $(".control-edit-small > ul").each(function(){$(this).hide();});
        var x = $(this).prev();
        if (x.css('display') == 'none') {
          x.show();
          //x.addClass('nohide');
        } else {
          x.hide();
        }
        return false;
      }
    ).appendTo($(this));
  });
});


//--Setup form focus classes----------------------------------------------------

$(function(){
  $("input[type!='file']").focus(function() {
    $(this).parent().addClass("has_focus")
  });
  $("input[type!='file']").blur(function() {
    $(this).parent().removeClass("has_focus")
  });
  $("textarea").focus(function() {
    $(this).parent().addClass("has_focus")
  });
  $("textarea").blur(function() {
    $(this).parent().removeClass("has_focus")
  });
});


//--Form change indicator-------------------------------------------------------

// Needs to ignore search box, i.e. only run on forms within the content block
// part of the template - DONE

// Look at how it interacts with jQuery UI popups - HAVE NOT SEEN PROBLEM

// Stop it from triggering on the login page - DONE

// Only activate if the form method is "POST" (i.e. ignore GET forms for search
// queries etc) - DONE

// Allow form elements to be marked as not triggering the change indicator,
// e.g. elements which trigger AJAX calls and do not affect the main form - DONE

// Support dynamically generated forms

// Potential features to stop change indications on innapropriate forms:
//   * Only attach to forms with two submit elements
//   * Only attach to forms with a "cancel" submit button
//   * Only attach to forms with a "save" submit button

var changes = false;
$(function() {
  $('#application form[method="POST"]').not('.no_change_alert').not('[id="login_form"]').find(':input').not('.no_change_alert').change(function(event) {
    changes = true;
    $('.save_indicator').addClass('unsaved');
  });
  var form_submission_in_progress = false;
  $('#application form[method="POST"]').not('.no_disable_submit').not('[id="login_form"]').find('[type="submit"]').click(function(event) {
    if (form_submission_in_progress) {
      return false;
    } else {
      form_submission_in_progress = true;
      return true;
    }
  });
  $('.form_indicator').dialog({
    title: "Working... please wait",
    show: "fade",
    autoOpen: false,
    modal: true,
    closeOnEscape: false,
    draggable: false,
    beforeClose: function( event, ui ) {return false}
  });
  $('#application form[method="POST"]').not('.no_disable_submit').not('[id="login_form"]').submit(function(event) {
    window.setTimeout(function(){$('.form_indicator').dialog("open")}, 2000);
  });
});

// displays the ajax_loading class items on the page when ajax is in action
// it avoids any url with notification in it.
$(function() {
    var notifications = /notification/;
    $('.ajax_indicator').ajaxSend(function(e, j, s) {
        if(!s.url.match(notifications)) {
            $(this).addClass('ajax_loading');
        }
    }).ajaxComplete(function(e, j, s) {
        if(!s.url.match(notifications)) {
            $(this).removeClass('ajax_loading');
        }
    });
});
