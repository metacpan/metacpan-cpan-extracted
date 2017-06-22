
var rablDefaultTab = 'preview';

//rablDefaultTab = 'attribs';

function rablInitPreviewIframe(iframe,src) {
  if(!src) { throw "rablInitPreviewIframe() requires src as second argument"; }

  // this disables click/nav events
  iframe.contentDocument.addEventListener('click',function(e){ 
    e.stopPropagation(); 
    e.preventDefault(); 
  });

  var AppDV = rablGetAppDV(iframe);
  var activateTab = AppDV.rablLastSelectedTabName;
  
  if(!iframe.rablDoAjaxLoad) {
    // We're doing this manually instead of just setting src to ensure we have control
    // of exactly when and why requests happen. This is important for dev, but may not
    // actually be needed and we can do it the normal way
    iframe.rablDoAjaxLoad = function() {
      var xreq = new XMLHttpRequest();
      xreq.onload = function() {
        iframe.contentWindow.document.open('text/html', 'replace');
        iframe.contentWindow.document.write([
          '<base href="',src,'"/>',
          xreq.responseText
        ].join(""));
        iframe.contentWindow.document.write();
        iframe.contentWindow.document.close();
      };
      xreq.open("GET", src);
      xreq.send();
    }
    if(!AppDV.rablFirstLoad) {
      iframe.rablDoAjaxLoad();
      AppDV.rablFirstLoad = true;
      activateTab = activateTab || rablDefaultTab;
      
    }
  }
  
  if(activateTab) {
    rablActivateTab(iframe,activateTab);
  }
}


function rablGetParentEl(node,cls) {
  if(!node || !cls) { return null; }
  return node.classList.contains(cls)
    ? node
    : rablGetParentEl(node.parentElement,cls);
}

function rablPreviewReload(el) {
  var AppDV = rablGetAppDV(el);
  if(AppDV) {
    AppDV.rablIframeReloadTask.delay(0);
  }
}

function rablActivateTab(target,name,extra,robot) {
  //console.log(' --> rablActivateTab ('+name+','+extra+','+robot+')');
  
  var topEl = rablGetParentEl(target,'rapi-blog-postview');
  var selEl = rablGetParentEl(target,'ra-rowdv-select');
  var AppDV = rablGetAppDV(selEl);
  if(!AppDV) { throw "no AppDV"; }
  
  if(!robot) {
    delete AppDV._editFromPreviewCleared;
  }
  
  if(
    // Do not process tab change during record update
    !selEl || selEl.classList.contains('editing-record')
  ) { return false; }
  
  name == 'preview'
    ? topEl.classList.add   ('rabl-preview-mode')
    : topEl.classList.remove('rabl-preview-mode');
  
  var links = topEl.getElementsByClassName('tab-link');
  var conts = topEl.getElementsByClassName('tab-content');
  
  for (i = 0; i < links.length; i++) {
    var el = links[i];
    el.classList.remove('active');
    el.classList.remove('inactive');
    if(el.classList.contains(name)) {
      el.classList.add('active');
    }
    else {
      el.classList.add('inactive');
    }
  }
  
  for (i = 0; i < conts.length; i++) {
    var el = conts[i];
    if(el.classList.contains(name)) {
      //rablReloadPreviewIframe(el,500);
      el.style.display = 'block';
    }
    else {
      el.style.display = 'none';
    }
  }
  
  if(name == 'source' && extra == 'edit') {
    var controlEl = topEl.getElementsByClassName('edit-record-toggle')[0];
    if(controlEl) {
      var editEl = controlEl.getElementsByClassName('edit')[0];
      if(editEl) {
        AppDV._editFromPreview = true;
        editEl.click();
      }
    }
  }
  
  AppDV.rablActiveTabName = name;
  if(!robot) {
    AppDV.rablLastSelectedTabName = name;
  }
}


function rablGetAppDV(el) {
  var AppDV = null;
  var appdvEl = rablGetParentEl(el,'ra-dsapi-deny-create');
  if(!appdvEl) { console.dir(el); }
  if(appdvEl) {
    AppDV = Ext.getCmp(appdvEl.id);
    if(AppDV && !AppDV.rablInitialized) {
    
    //Ext.ux.RapidApp.util.logEveryEvent(AppDV.store);
    
      AppDV.rablActivateTab = function(name,extra,robot) {
        var target = AppDV.el.dom.getElementsByClassName('rapi-blog-postview')[0]
        return rablActivateTab(target,name,extra,robot);
      }
    
      AppDV.getPreviewIframe = function() {
        return AppDV.el.dom
          ? AppDV.el.dom.getElementsByClassName('preview-iframe')[0]
          : null;
      };
    
      AppDV.rablIframeReloadTask = new Ext.util.DelayedTask(function(){
        var iframe = AppDV.getPreviewIframe();
        if(iframe && iframe.rablDoAjaxLoad) {
           // Call the special, manual ajax load function:
           iframe.rablDoAjaxLoad();
        }
      },AppDV);
      
      AppDV.handleEndEdit = function() {
        if(AppDV._editFromPreview && (AppDV.rablActiveTabName != 'preview' || !AppDV.currentEditRecord)) {
          delete AppDV._editFromPreview;
          AppDV._editFromPreviewCleared = true;
          AppDV.rablLastSelectedTabName = 'preview';
          AppDV.rablActivateTab('preview',null,true);
        }
      };
      
      AppDV.store.on('buttontoggle',AppDV.handleEndEdit,AppDV);

      AppDV.store.on('save',function() {
        AppDV.rablIframeReloadTask.delay(50);
        if(AppDV._editFromPreview || AppDV._editFromPreviewCleared) {
          delete AppDV._editFromPreviewCleared;
          delete AppDV._editFromPreview;
          AppDV.rablActivateTab('preview',null,true);
        }
      },AppDV);

      AppDV.rablInitialized = true;
    }
  }
  return AppDV;
}


function rablDeletePost(el) {
  var realEl = el.parentElement.getElementsByClassName('delete-record')[0];
  if(realEl) {
    Ext.Msg.show({
      title: 'Confirm delete post',
      msg: [
        '<div style="padding:10px;">',
        '<b style="font-size:22px;">Really delete post?</b>',
        '<br><br>This operation cannot be undone.<br>',
        '</div>'
      ].join(''),
      buttons: Ext.Msg.YESNO,
      icon: Ext.Msg.WARNING,
      minWidth: 375,
      fn: function(button_id) {
        if(button_id == 'yes') {
          realEl.click();
        }
      },
      scope: this
    });
  }
}


Ext.apply(Ext.form.VTypes,{

  rablPostName: function(v) { return /^[0-9a-z\.\-\_]+$/.test(v); },
  rablPostNameMask: /[0-9a-z\.\-\_]+/,
  rablPostNameText: 'Post names must be unique, can only contain lowercase alpha characters, dot (.), dash (-) or underscore (_)'

});


function rablTagNamesColumnRenderer(v) {
	if(!v) { return Ext.ux.showNull(v); }
	var tags = v.split(/\s+/);
	return tags.join(', ');
}

