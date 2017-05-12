function form_GET(form) {
    var getstr = "?";
    for (i=0; i<form.elements.length; i++) {
      var e = form.elements[i];
      switch (e.tagName) {
      case 'INPUT':
          switch (e.type) {
	  case 'text':
	  case 'hidden':
              getstr += e.name + "=" + encodeURIComponent(e.value) + "&";
	      break;
	  case 'checkbox':
              if (e.checked) {
		  getstr += e.name + "=" + encodeURIComponent(e.value) + "&";
              } else {
		  getstr += e.name + "=&";
              }
	      break;
	  case 'radio':
              if (e.checked) {
		  getstr += e.name + "=" + encodeURIComponent(e.value) + "&";
              }
	      break;
	  }
	  break;
      case 'TEXTAREA':
          getstr += e.name + "=" + encodeURIComponent(e.value) + "&";
	  break;
      case 'SELECT':
          getstr += e.name + "=" + encodeURIComponent(e.options[e.selectedIndex].value) + "&";
	  break;
      case 'BUTTON':
	  break;
      default:
      }
    }
    return getstr;
}

function makeRequest(url, parameters, mime_type, method, handler) {
    var http_request = null;
    if (!method) method = 'GET';
    if (window.XMLHttpRequest) { // standard browsers
        http_request = new XMLHttpRequest();
        if (mime_type && http_request.overrideMimeType) {
            http_request.overrideMimeType(mime_type);
        }
    } else if (window.ActiveXObject) { // MSIE
        try {
            http_request = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
		http_request = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e) {}
        }
    }
    if (!http_request) {
        throw 'Cannot create XMLHTTP instance';
    }
    http_request.onreadystatechange = handler;
    if (method == 'POST') {
	http_request.open(method, url, true);
	if (http_request.getRequestHeader) {
	    alert(http_request.getRequestHeader());
	}
	http_request.send(parameters);
    } else {
	http_request.open(method, url + (parameters ? '?' + parameters : ''), true);
	http_request.send();
    }
    return http_request;
}

function update_object_data (oobject, uri) {
    if (oobject == null) return;
    var nobject = oobject.ownerDocument.createElement(oobject.nodeName); 
    var a = ['class','style','type','width','height'];
    for (var i=0; i<a.length; i++) {
	var v = oobject.getAttribute(a[i]);
	if (v!=null && v!='') nobject.setAttribute(a[i],v);
    }
    var id = oobject.getAttribute("id");
    nobject.setAttribute("data", uri);
    oobject.parentNode.replaceChild(nobject,oobject);
    nobject.setAttribute("id", id);
}

function show_query_svg() {
    var div = document.getElementById('query_tree');
    div.onmousedown=start_move_query_tree;
    var obj = document.getElementById('query_tree_img');
    window.svg_loaded = query_tree_loaded;
    window.highlightSVGNodes = highlight_query_nodes;
    window.setSVGTitle = null;
    window.setSVGDesc = null;
    update_object_data(obj,'query_svg' + form_GET(document.qf));
}

// findPosX and findPosY by Peter-Paul Koch & Alex Tingle. 
function findPosX(obj) {
    var curleft = 0;
    if(obj.offsetParent)
        while(1) {
	    curleft += obj.offsetLeft;
	    if(!obj.offsetParent)
		break;
	    obj = obj.offsetParent;
	}
    else if(obj.x)
        curleft += obj.x;
    return curleft;
}
function findPosY(obj) {
    var curtop = 0;
    if(obj.offsetParent)
        while(1) {
            curtop += obj.offsetTop;
            if(!obj.offsetParent)
		break;
            obj = obj.offsetParent;
        }
    else if(obj.y)
        curtop += obj.y;
    return curtop;
}


var query_tree_moving=null;
function stop_move_query_tree (e) {
    query_tree_moving=null;
    document.onmousemove=null;
    document.onmouseup=null;

    var types = ['object','iframe'];
    for (var j=0; j<types.length; j++) {
	obj = document.body.getElementsByTagName(types[j]);
	for (var i=0; i<obj.length; i++) {
	    var idoc = obj[i].contentDocument
		? obj[i].contentDocument
		: obj[i].contentWindow 
		? obj[i].contentWindow.document
		: null;
	    if (idoc) {
		idoc.onmousemove=null;
		idoc.onmouseup=null;
	    }
	}
    }
    return false;
}
function start_move_query_tree (e) {
    var types = ['object','iframe'];
    for (var j=0; j<types.length; j++) {
	obj = document.body.getElementsByTagName(types[j]);
	for (var i=0; i<obj.length; i++) {
	    var idoc = obj[i].contentDocument
		? obj[i].contentDocument
		: obj[i].contentWindow 
		? obj[i].contentWindow.document
		: null;
	    if (idoc) {
		idoc.onmousemove=move_query_tree;
		idoc.onmouseup=stop_move_query_tree;
	    }
	}
    }
    query_tree_moving={
	x: e.screenX,
	y: e.screenY,
	dx: findPosX(this),
	dy: findPosY(this),
	o: this,
    };
    document.onmousemove=move_query_tree;
    document.onmouseup=stop_move_query_tree;
    return false;
}
function move_query_tree (e) {
    var m = query_tree_moving;
    if (m) {
	m.o.style.left = "" + (e.screenX-m.x+m.dx) + "px";
	m.o.style.top  = "" + (e.screenY-m.y+m.dy) + "px";
    }
    return false;
}

function highlight_query_nodes (css) {
    if (css && typeof(files)!="undefined") {
	var count = files[current_tree].length;
	var q = files[current_tree];
	for (var i=0; i<count; i++) {
	    var color = q_node_color[i];
	    var selector = '.qnode-' + (i+1);
	    var style = selector + 
	    	' { stroke: #' + color + '; '
	    	+ 'fill: #' + color + '; '
	    	+ 'stroke-width: 3; }';
	    css.insertRule(style ,0);
	}
    }
}

function getSVGContainer (svg_root) {
    if (svg_root==null) return null;
    var objects = document.getElementsByTagName('object');
    for (var i=0; i<objects.length; i++) {
	if (getSVG(objects[i])==svg_root) {
	    return objects[i];
	}
    }
}

function getSVG (container) {
    var svg_document =
	container.contentDocument
	? container.contentDocument
	: container.contentWindow 
	? container.contentWindow.document
	: null;
    return svg_document ? svg_document.documentElement : null;
}

function query_tree_loaded (svg_document) {
    var div = document.getElementById('query_tree');
    var obj = document.getElementById('query_tree_img');
    div.setAttribute('style','visibility:visible');
    var svg = svg_document ? svg_document.documentElement : null;
    if (svg) {
	if (svg.width && svg.width.animVal) {
	    obj.setAttribute('width',svg.width.animVal.valueInSpecifiedUnits);
	}
	if (svg.height && svg.height.animVal) {
	    obj.setAttribute('height',svg.height.animVal.valueInSpecifiedUnits);
	}
    }
}

var show_canceled=0;
function hide_loading() {
    show_canceled=1;
    var el = document.getElementById("loading");
    if (el) el.style.visibility = 'hidden';
}
function show_loading(timeout) {
    show_canceled=0;
    if (timeout) setTimeout(real_show_loading,timeout);
    else real_show_loading();
}
function real_show_loading() {
    if (show_canceled) return;
    var el = document.getElementById("loading");
    if (el) el.style.visibility = 'visible';
    el = document.getElementById("error");
    if (el) el.style.visibility = 'hidden';
    window.scrollTo(0,0);
}
function text_content(el) {
    try { if(el.innerText) { return el.innerText } else { return el.textContent } } catch(e) { return "" }
}
function try_example (el) {
    var q = document.qf.query;
    var text = text_content(el);
    q.value = text.substring(3,text.length);
    window.scrollTo(0,0);
    q.focus();
}
