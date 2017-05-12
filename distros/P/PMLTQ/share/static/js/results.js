var base_uri = '';
var files = [ ];
var current_tree = 0;
var tree_offset = 0;
var trees_in_file = 0;
var cur_tree_no = 0;
var q_node = 0;
var q_node_names = 0;
var tree_obj = null;
var tooltip = null;
var q_node_color = [
    '66B032','ff9300','4a01c8','b901f2','0392CE','ffe100',
    '96c944','fe662d','007FFF','C154C1','CC7722','FBFB00',
    '00A86B','feb35b','CCCCFF','8844AA','987654','F0E68C',
    'BFFF00','E68FAC','00FFFF','FFAAFF','996515','f3bd15',
    'ADDFAD','FFCBA4','007BA7','CC99CC','B1A171','dddd00',
    '6B8E23','FF8855','9BDDFF','FF00FF','654321','FFFACD',
    '00FF00','FF2400','1560BD','997A8D','cda23d','FFFF77',
    'D0EA2B','b71c0d','E2F9FF','c11d57','0247FE',
];

function f_windowHeight() {
    var h = window.innerHeight;
    if (h) return h;
    if (document.documentElement) h = document.documentElement.clientHeight;
    if (h) return h;
    if (document.body) h=document.body.clientHeight;
    return h ? h : 0;
}
function fit_window() {
    height = f_windowHeight();
    if (height && tree_obj) {
	var y = findPosY(tree_obj);
	var tree = document.getElementById('tree');
        tree.style.height = "" + (height - y - 20) + "px";
    }
}

var initial_zoom = 2;
window.onresize = fit_window;

var added_css3_rules=0;

window.onSVGMouseOver = function (svg_node) {
    if (svg_node == null) return;
    try {
	var css3=document.styleSheets[1];
	if (!css3) return;
	var cls = svg_node.getAttribute("class");
	if (cls==null) cls="";
	var classes = cls.replace(/[ \t]+/,' ').split(" ");
	for (var i=0; i<added_css3_rules; i++) {
	    css3.deleteRule(0);
	}
	added_css3_rules=0;
	for (var i=0; i<classes.length; i++) {
	    var c = classes[i];
	    if (/^#/.test(c)) {
		var selector = '.' + c.replace(/([^-_A-Za-z0-9])/g,"\\$1");
		var style = selector + ' { background-color: yellow; }';
		css3.insertRule(style,0);
		added_css3_rules++;
		// document.title=c;
	    }
	}
    } catch(e) {
	// alert(e);
    }
};

window.SVGClick = function (evt,el) {
    var classes = el.getAttribute('class');
    var id = /#(\S+)/.exec(classes);
    if (id) {
	toggle_svg_mark(el,id[1]);
    }
};

var selected_nodes = {};
function svg_tree_loaded (svg_document) {
    var container = document.getElementById('svg-tree');
    var svg = svg_document ? svg_document.documentElement : null;
    if (svg==null) return;
    container.setAttribute('width',parseFloat(svg.getAttribute('width')));
    container.setAttribute('height',parseFloat(svg.getAttribute('height')));
    svg_mark_nodes(svg,true);
}
function svg_mark_nodes (svg,select) {
    try {
	var elem = svg.getElementsByTagName('*');
	var mark = {};
	for (var i = 0; i < elem.length; i++) {
	    var classes = elem[i].getAttribute('class');
	    if (/\bnode\b/.test(classes)) {
		var id = /\#(\S+)/.exec(classes);
		if (id) {
		    if (select) elem[i].setAttribute('onclick','top.SVGClick(evt,this);');
		    if (selected_nodes[ id[1] ]) mark[id[1]]=elem[i];
		}
	    }
	}
	for (var id in mark) {
	    if (select && selected_nodes[ id ]) delete selected_nodes[ id ];
	    toggle_svg_mark(mark[id], id );
	}
    } catch (err) {
	if (/:8084/.test(window.location.href)) alert(err);
    }
}

function toggle_svg_mark (el,id) {
    if (selected_nodes[ id ]) {
	// el.setAttribute('stroke-width','5');
	var mark = selected_nodes[ id ];
	if (mark) mark.parentNode.removeChild(mark);
	delete selected_nodes[id];
    } else {
        
	// el.setAttribute('stroke-width','1');
	selected_nodes[id]=mark_svg_element(el);
    }
    update_mark_count();
}

function mark_svg_element (el,options) {
    var x,y,rx,ry;
    var shape='circle';
    if (!options) {
	options = {
	    color: 'red',
	    width: '2'
	};
    }
    switch (el.nodeName) {
    case 'rect': 
	rx=el.width.animVal.value ;
	ry=el.height.animVal.value;
	x=el.x.animVal.value + rx/2;
	y=el.y.animVal.value + ry/2;
	shape='ellipse';
	break;
    case 'circle':	
	x=el.cx.animVal.value;
	y=el.cy.animVal.value;
	rx=el.r.animVal.value + 5;
	break;
    case 'ellipse': 
	x=el.cx.animVal.value;
	y=el.cy.animVal.value;
	rx=el.rx.animVal.value + 5;
	ry=el.ry.animVal.value + 5;
	shape = 'ellipse';
	break;
    case 'polygon': 
	var p = el.animatedPoints.getItems(0);
	x=p.x;
	y=p.y;
	rx=15;
	break;
    default:
	return;
    }
    var mark = el.ownerDocument.createElementNS(el.namespaceURI, shape);
    mark.setAttribute('cx',x);
    mark.setAttribute('cy',y);
    if (shape == 'circle') {
	mark.setAttribute('r',rx);
    } else {
	mark.setAttribute('rx',rx);
	mark.setAttribute('ry',ry);
    }
    mark.setAttribute('fill','none');
    mark.setAttribute('stroke',options.color);
    mark.setAttribute('stroke-width',options.width);
    el.parentNode.appendChild(mark);
    return mark;
}

function update_mark_count () {
    var count=0;
    for (var i in selected_nodes) count++;
    var b=document.qf.extract;
    b.value = b.value.replace(/Suggest(?: [0-9]+)?/,'Suggest'+(count>0 ? ' '+count : ''));
    document.qf.extract.disabled=count>0 ? false : true;
}

var script_element;
function _el (name, attributes) {
    var el = document.createElement(name);
    if (attributes != null) {
	for (var a in attributes) {
	    if (a == '_')
		el.appendChild(document.createTextNode(attributes[a]));
	    else if (a == 'innerHTML')
		el.innerHTML = attributes[a];
	    else
		el.setAttribute(a,attributes[a]);
	}
    }
    return el;
}

var n2p_span;
function n2p (query) {
    if (script_element) document.body.removeChild(script_element);
    n2p_create(query);
}
function n2p_create (query) {
    var d = document.getElementById('n2p-body');
    d.innerHTML='<col class="n2p-col-cb" /><col class="n2p-col-data" />';
    var lines = query.split(/\n/);
    n2p_span=[];
    var stack = [];
    for (var i=0; i<lines.length; i++) {
	n2p_span[i]=i;
	var tr = _el('tr',{'id': "n2p-tr-"+i,'class': ((i%2==0) ? 'odd-row' : 'even-row') });
	var td = _el('td');
	tr.appendChild(td);
	var l = lines[i];
	var disabled = /^\s*#/.test(l);
	var l_id = 'n2p-l-'+i;
	if (/\[\s*$/.test(l)) {
	    stack.push(i);
	}
	if (/^\s*\]\s*[,;]?\s*$/.test(l)) {
	    var pop = stack.pop();
	    n2p_span[pop]=i;
	} else {
	    td.appendChild(_el('a',{
		'class'  : (disabled ? "uncheckbox" : "checkbox"),
		'title' : "include/exclude from query",
		'onclick' : "n2p_toggle("+i+",this); return true;",
		'innerHTML' : ' &#x2716; ',
	    }));
	}
	td = _el('td');
	tr.appendChild(td);
	var m = l.match(/^(\s*)/);
	var space='';
	for (var j=0; j<m[1].length; j++) { space+='&nbsp;'; };
	td.appendChild(_el('span',{'class':'n2p-indent','innerHTML': space}));
	td.appendChild(_el('span',{'_': l,'id': l_id, 'class': (disabled ? 'n2p-disabled' : 'n2p-normal')}));
	d.appendChild(tr);
    }
    var dlgsyle = document.getElementById("n2p-dlg").style;
    dlgsyle.visibility='visible';
    dlgsyle.display='block';
}
function n2p_toggle (i,el) {
    var span = document.getElementById('n2p-l-'+i);
    var enable = (span.getAttribute('class') == 'n2p-disabled') ? true : false;
    var end = n2p_span[i];
    if (enable) {
	el.setAttribute('class', 'checkbox');
	span.setAttribute('class', 'n2p-normal');
	var html = span.innerHTML.replace(/^(\s*)#\s*/,'$1');
	if (i<end) html = html.replace(/ \.\.\.\s*\].$/,'');
	span.innerHTML = html;
    } else {
	el.setAttribute('class', 'uncheckbox');
	span.setAttribute('class', 'n2p-disabled');
	var html = span.innerHTML.replace(/^(\s*)/,'$1# ');
	if (i<end) html += ' ... ];';
	span.innerHTML = html;
    }
    for (var j=i+1; j<=end; j++) {
	var tr = document.getElementById('n2p-tr-'+j);
	if (enable) tr.style.display='table-row';
	else tr.style.display='none';
    }
}
function n2p_collect () {
    var query=[];
    for (var i=0; i<n2p_span.length; i++) {
	var span = document.getElementById('n2p-l-'+i);
	if (span.getAttribute('class') == 'n2p-disabled') {
	    i = n2p_span[i];
	} else {
	    query.push(text_content(span));
	}
    }
    return query.join("\n");
}
function n2p_cleanup () {
    n2p_create(n2p_collect());
}
function n2p_insert () {
    var elem = document.qf.query;
    // elem.focus();
    insertAtCursor(elem, n2p_collect());
    n2p_cancel();
}
function n2p_replace () {
    var elem = document.qf.query;
    // elem.focus();
    elem.value = n2p_collect();
    n2p_cancel();
}
function n2p_clear () {
    var container = document.getElementById('svg-tree');
    svg_mark_nodes(getSVG(container),false);
    selected_nodes={};
    update_mark_count();
    n2p_cancel();
}
function n2p_cancel () {
    var d = document.getElementById("n2p-dlg");
    d.style.visibility='hidden';
    d.style.display='none';
    var table = document.getElementById("n2p-body");
    table.innerHTML='';
    fit_window();
}

function node2pmltq () {
    var ids = [];
    for (var id in selected_nodes) ids.push(id);
    script_element = document.createElement('script');
    script_element.setAttribute('type','text/javascript');
    var vars = [];
    var v;
    do {
	v = /\$([a-zA-Z_][a-zA-Z0-9_]*)\b/g.exec(document.qf.query.value);
	if (v) vars.push(v[1]);
    } while (v);
    var src = '' + base_uri
	+ 'n2q?format=json'
	+ (vars && vars.length ? '&vars='+encodeURIComponent(vars.join(',')) : '')
	+'&cb=n2p&ids='+encodeURIComponent(ids.join('|'));
    if (document.qf.u) src+='&u='+document.qf.u.value;
    if (document.qf.s) src+='&s='+document.qf.s.value;
    script_element.setAttribute('src',src);
    document.body.appendChild(script_element);
}

function zoom_inc (amount) {
    var container = document.getElementById('svg-tree');
    var svg = getSVG(container);
    var w = parseFloat(container.getAttribute('width'));
    var h = parseFloat(container.getAttribute('height'));
    var rescale = amount>=0 ? (1+amount) : 1/(1-amount);
    w=w*rescale;
    h=h*rescale;
    container.setAttribute('width', w);
    container.setAttribute('height', h);
    if (svg) {
	svg.currentScale = svg.currentScale * rescale;
	svg.setAttribute('viewBox', '0 0 ' + w + ' ' + h);
    }
}	

function next_tree ( delta ) {
    var next = current_tree+delta;
    if (next >= 0 && files.length > next) {
	try { show_loading(1000); } catch(err) {}
        // in FF, we would just set 'data', but Opera
        // and other require replacing the object
        current_tree = next;
	cur_tree_no = 0;
	show_tree();
    }
}

function show_tree () {
    window.setSVGTitle = set_title;
    window.setSVGDesc = set_desc;
    window.highlightSVGNodes = highlight_svg_nodes;
    window.svg_loaded = svg_tree_loaded;
    var container = document.getElementById('svg-tree');
    if (container) container.width=0; // to prevent visible zooming
    update_object_data(container,svg_uri());
    update_title();
    // highlight_svg_nodes();
}

function next_context_tree (delta) {
    if (0<cur_tree_no+delta && cur_tree_no+delta<=max_tree_no) {
	cur_tree_no += delta;
	show_tree();
    }
}

function parse_qnode (str) {
    str = str.substring(str.indexOf('/')+1,str.length);
    var split_pos = str.indexOf('@'); // new syntax
    if (split_pos<0) split_pos = str.indexOf('+'); // old syntax
    var id = str.substring(split_pos+1, str.length);
    var type = str.substring(0, split_pos);
    return { id: id, type: type };
}

var added_css2_rules = 0;
function highlight_svg_nodes (css) {
    var count = files[current_tree].length;
    var q = files[current_tree];
    var css2=document.styleSheets[0];
    try {
	if (css2) {
	    for (var i=0; i<added_css2_rules; i++) {
		css2.deleteRule(0);
	    }
	    added_css2_rules=0;
	}
    } catch (e) {}
    for (var i=0; i<count; i++) {
        var id = parse_qnode(q[i]).id;
        var color = q_node_color[i];
	if (css || css2) {
	    var selector = '.\\#' + id.replace(/([^-_A-Za-z0-9])/g,"\\$1");
	    var style = selector + 
	    	' { stroke: #' + color + '; '
	    	+ 'fill: #' + color + '; '
	    	+ 'stroke-width: 3; }';
	    if (css) css.insertRule(style ,0);
	    var style2 = selector + 
	    	' { color: #' + color + 
		(i==q_node ? '; text-decoration: underline;' : ';')
	        + ' }';
	    if (css2) css2.insertRule(style2,0);
	    added_css2_rules++;
	}
    }
    if (css) scroll_to_see_node(parse_qnode(q[q_node]).id);
}

var scroll_to_mark = null;
var scroll_to_anim = 0;
var scroll_to_anim_speed = 80;
var scroll_to_anim_step = 0.06;
function animate_mark () {
    if (!scroll_to_mark) return;
    if (scroll_to_anim>0) {
	var n = scroll_to_anim-scroll_to_anim_step;
	scroll_to_anim = n>0 ? n : 0;
	scroll_to_mark.setAttribute('opacity',scroll_to_anim);
	var name = scroll_to_mark.localName;
	if (name == 'circle') {
	    var r = scroll_to_mark.getAttribute('r');
	    r=parseFloat(r)*(2-scroll_to_anim);
	    scroll_to_mark.setAttribute('r',r);
	} else {
	    var rx = scroll_to_mark.getAttribute('rx');
	    var ry = scroll_to_mark.getAttribute('ry');
	    rx=parseFloat(rx)*(1.07);
	    ry=parseFloat(ry)*(1.07);
	    scroll_to_mark.setAttribute('rx',rx);
		scroll_to_mark.setAttribute('ry',ry);
	}
	window.setTimeout(animate_mark,scroll_to_anim_speed);	
    } else {
	if (scroll_to_mark) scroll_to_mark.parentNode.removeChild(scroll_to_mark);
	scroll_to_mark = null;
	scroll_to_anim = 0;
    }
}
function scroll_to_see_node (qnode_id) {
    var container=document.getElementById("svg-tree");
    var scrolled=container.parentNode;
    var w = parseFloat(scrolled.offsetWidth);
    var h = parseFloat(scrolled.offsetHeight);
    var svg = getSVG(container);
    var elem = svg.getElementsByTagName('*');
    var found = null;

    try {
	if (scroll_to_mark) scroll_to_mark.parentNode.removeChild(scroll_to_mark);
    } catch(err) {}

    for (var i = 0; i < elem.length; i++) {
	var classes = elem[i].getAttribute('class');
	if (/\bnode\b/.test(classes)) {
	    var id = /\#(\S+)/.exec(classes);
	    if (id[1] == qnode_id) {
		var x=elem[i].cx;
		if (x==null) x=elem[i].x;
		var y=elem[i].cy;
		if (y==null) y=elem[i].y;
		if (x!=null && y!=null) {
		    x=x.animVal.value * svg.currentScale;
		    y=y.animVal.value * svg.currentScale;
		    x-=w/2;
		    y-=h/2;
		    if (x<0) x=0;
		    if (y<0) y=0;
		    scrolled.scrollLeft = x;
		    scrolled.scrollTop = y;
		    
		    var mark = mark_svg_element(elem[i],{
			color: 'darkblue',
			width: '3'
		    });
		    if (mark) {
			mark.setAttribute('id','scrolled-to');
			/* var anim = mark.ownerDocument.createElementNS(mark.namespaceURI, 'animate');
			anim.setAttribute('attributeType','CSS');
			anim.setAttribute('attributeName','opacity');
			anim.setAttribute('from','1');
			anim.setAttribute('from','0');
			anim.setAttribute('dur','3s');
			anim.setAttribute('repeatCount','1');
			mark.appendChild(anim);
                        */
			scroll_to_mark=mark;
                        scroll_to_anim=1;
			window.setTimeout(animate_mark,scroll_to_anim_speed);
		    }
		}
		found=elem[i];
		break;
	    }
	}
    }
    return found;
}
function svg_uri () {
    if (files.length) {
	var ret= '' + base_uri + 'svg?tree_no=' + cur_tree_no + '&nodes=' + encodeURIComponent(files[current_tree][q_node]) ;
	if (document.qf.u) ret+='&u='+document.qf.u.value;
	if (document.qf.s) ret+='&s='+document.qf.s.value;
	return ret;
    } else {
	return '';
    }
}

function tree_no_keypress (e,value) {
    var keynum,keychar,numcheck;
    if(window.event)  { // IE
	keynum = e.keyCode;
    } else if(e.which) { // Netscape/Firefox/Opera
	keynum = e.which;
    }
    keychar = String.fromCharCode(keynum);
	/* alert(" " + keychar + " " + value); */

    numcheck = /\d/;
    if (numcheck.test(keychar)) {
	return true;
    } else if( keynum == 13 )  {
	set_tree(value);
	return false;
    } else if ( !keynum || (keynum < 32) ) {
	return true;
    }
    return false;

}

function set_tree (n) {
    n = parseInt(n) - 1;
    if (n < 0) n = 0;
    if (files.length <= n) n = files.length - 1;
    current_tree = n;
    next_tree(0);
}

function set_q_node (i) {
    q_node = i;

    var q = files[current_tree];
    if (scroll_to_see_node(parse_qnode(q[q_node]).id)) {
	update_title();
	highlight_svg_nodes(null);
    } else {
	next_tree(0);
    }
}
function update_title () {
    var n = document.getElementById("cur_tree");
    if (n.firstChild) {
	n.firstChild.nodeValue = current_tree + 1;
    } else {
	n.value = current_tree + 1;
    }
    // update_tree_offset();
    n = document.getElementById("tree_count");
    if (n && n.firstChild) n.firstChild.nodeValue = files.length;
    var q = document.getElementById("q_nodes");
    if (q) {
        var html = '';
        for (var i=0; i<files[current_tree].length; i++) {
            var n = files[current_tree][i];
	    if (/^[0-9]+\/\//.test(n)) continue;
            var style = (q_node == i) ? 'qnode-current' : 'qnode';
            var color = q_node_color[i];
            html +=  '<span class="' + style + '">' 
                +     '<span style="color: #' + color + '">' + (i+1) + '</span>'
                +    ' <a href="javascript:set_q_node(' + i + ')">'
                +         parse_qnode(n).type // node type
                +      ((q_node_names[i].length>0) ? 
                        ' <span style="color: #' + color + '">$' + q_node_names[i] + '</span>' : '') // q-node name
                +    '</a></span> '
        }
        html += '';
        q.innerHTML = html;
    }
}

function init (base,urls,names) {
    base_uri=base;
    files = urls;
    q_node_names = names;
    tooltip = document.getElementById('tooltip');
    tree_obj = document.getElementById("tree");
    document.changeToolTip = changeToolTip;
    document.placeTip = placeTip;
    try { hide_loading(); } catch(err) {}
    if (files.length==0) {
	set_title('No match!');
	try { document.getElementById("context").setAttribute('style','visibility:hidden'); }
	catch (err) { }
    } else {
	next_tree(0);
    }
    fit_window();
}
function set_title (title) {
    document.getElementById("title").firstChild.nodeValue = title;
    update_tree_offset();
    try { hide_loading(); } catch(err) {}
}
function update_tree_offset () {
    var title = document.getElementById("title").firstChild.nodeValue;
    var re = / \(([0-9]+)\/([0-9]+)\)$/;
    var m = title.match(re);
    if (m) {
	cur_tree_no = parseInt(m[1]);
	max_tree_no = parseInt(m[2]);
	title = title.replace(re,'') + (' (' + cur_tree_no + '/' + max_tree_no + ')');
    }
    document.getElementById("title").firstChild.nodeValue = title;
}

var ltrChars      = 'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590\u0800-\u1FFF'+'\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF',
    rtlChars      = '\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC',
    ltrDirCheckRe = new RegExp('^[^'+rtlChars+']*['+ltrChars+']'),
    rtlDirCheckRe = new RegExp('^[^'+ltrChars+']*['+rtlChars+']');
var user_agent=navigator.userAgent.toLowerCase();
var bidi_support_in_svg = (((user_agent.indexOf("gecko") != -1)
			    ||
			    (user_agent.indexOf("chrome") != -1)
			   ) ? 0 : 1);
function textDirection (text) {
    return rtlDirCheckRe.test(text) ? 'rtl'
        : (ltrDirCheckRe.test(text) ? 'ltr' : '');
}

function set_bidi (container,text) {
    var dir = textDirection(text);
    if (container) {
	container.style.direction = dir;
	container.style.unicodeBidi = 'embed';
	if (dir=='rtl') {
	    container.style.textAlign = 'right';
	} else {
	    container.style.textAlign = 'left';
	}
    }
    return dir;
}

function translate_desc(lang) {
    var txt  = text_content(document.getElementById('desc-content'));
    google_translate(lang,txt.replace(/[ \n\t]+/g,' '),0);
}
function ms_translate_desc(lang) {
    var txt  = text_content(document.getElementById('desc-content'));
    ms_translate(lang,txt.replace(/[ \n\t]+/g,' '),0);
}
function ms_translate (lang,txt,append) {
    leaveMenu();
    if (!(Microsoft && Microsoft.Translator)) return;
    if (txt && txt != '') {
        Microsoft.Translator.translate(
	    txt,
            "", 
            lang, 
            function (translation) { 
		var container = document.getElementById("ms-translation");
		set_bidi(container,translation);
		translation=translation.replace('&','&amp;').replace('<','&lt;')
		if (append) container.innerHTML += translation;
		else container.innerHTML = '<span style="color:gray">'+msTranslatorLangNames[lang]+' translation by Microsoft:</span> ' + translation;
		/*if (etc.length>0) {
		    container.innerHTML +=' <span style="color: gray">//</span> ';
		    ms_translate(lang,etc,1);
		}*/
	    }); 
    }
}


function google_translate (lang,txt,append) {
    leaveMenu();
    if (!google || !google.language) return;
    if (txt && txt != '') {
	var etc='';
	if (encodeURIComponent(txt).length>900) {
	    var part = txt.substring(0,300);
	    var br = part.lastIndexOf(' ');
	    if (br>0) part=part.substring(0,br+1); /* otherwise we break on character, which is probably not quite optimal */
	    etc=txt.substring(part.length,txt.length);
	    txt=part;
	}
	google.language.translate({text: txt, type: google.language.ContentType["TEXT"]},
				  "", google.language.Languages[lang], function(result) {
	    if (!result.error) {
		var container = document.getElementById("translation");
		var lang_name = lang.substring(0,1)+
		    lang.substring(1,lang.length).toLowerCase();
		var translation = result.translation;
		set_bidi(container,translation);
		translation=translation.replace('&','&amp;').replace('<','&lt;')
		if (append) container.innerHTML += translation;
		else container.innerHTML = '<span style="color:gray">'+lang_name+' translation by Google:</span> ' + translation;
		if (etc.length>0) {
		    container.innerHTML +=' <span style="color: gray">//</span> ';
		    google_translate(lang,etc,1);
		}
	    } else {
		container.innerHTML = "ERROR returned from Google Translation API:" + result.error.message;
	    }
	});

    }
}
function add_language_tools (el) {
    // if (/:8084/.test(window.location.href)) return;
    var g = add_google_translator(el);
    var m = add_ms_translator(el);
    if (g || m) {
      var menu=[];
      if (g) menu.push(g);
      if (m) menu.push(m);
      document.getElementById("tools-menu").innerHTML = build_menu([['Tools',0,menu]], 'lang-tools-menu', 'menuBar','span')+'&nbsp;';
    }
}

function add_google_translator (el) {
    try {
	if (!(typeof google == "undefined")) {
	    var menu = [
		['google',2,google.language.getBranding().innerHTML],
		['',2],
		['english',1,'javascript:translate_desc("ENGLISH")'],
		['',2]
	    ];
	    var i=0;
	    var languages = google.language.Languages;
	    for (var l in languages) {
	        i++;
		if (google.language.isTranslatable(languages[l]))
		    menu.push([l.toLowerCase(),1,'javascript:translate_desc("'+l+'")'])
	    }
	    if (i>0) {
	      el.innerHTML += "<div id=\"translation\"></div>";
	      return ['Google Translate', 0, menu];
            }
	}
    } catch (e) {}
    return null;
}

var msTranslatorLangNames;
function add_ms_translator (el) {
    try {
	if (!(typeof Microsoft == "undefined") && Microsoft.Translator != null) {
	    var menu = [
		['ms',2,'<span style="font-size:7pt">Powered by Microsoft</span>'],
		['',2],
		['english',1,'javascript:ms_translate_desc("en")'],
		['',2]
	    ];
	    var languages = Microsoft.Translator.getLanguages();
	    var langNames = Microsoft.Translator.getLanguageNames('en');
	    msTranslatorLangNames = { "en": "english" };
	    var i=0;
	    for (; i<languages.length; i++) {
		var l = languages[i];
		msTranslatorLangNames[l]=langNames[i];
		menu.push([langNames[i].toLowerCase(),1,'javascript:ms_translate_desc("'+l+'")'])
	    }
            if (i>0) {
	      el.innerHTML += "<div id=\"ms-translation\"></div>";
              return ['Bing Translator',0,menu];
            }
	}
    } catch (e) {}
    return null;
}

function set_desc (desc) {
    var el = document.getElementById("desc");
    var text = text_content(desc);
    try {
	var s = new XMLSerializer();
	var str = s.serializeToString(desc).replace(/ xmlns=(?:\"[^\"]*\"|\'[^\']*\')/g ,'');
	el.innerHTML = '<div id="desc-content">'+str+'</div>';
    } catch(e) {
	el.innerHTML = '<div id="desc-content">'+text.replace('&','&amp;').replace('<','&lt;')+'</div>';
    }

    try {
	var spans = el.getElementsByTagName('span');
	for (var i=0; i<spans.length; i++) {
	    var classes=spans[i].getAttribute('class');
	    if (classes) {
		var id = /\#(\S+)/.exec(classes);
		if (id) {
		    spans[i].setAttribute('onclick','desc_span_clicked(event)');
		}
	    }
	}
    } catch(err) {}

    var dir = set_bidi(document.getElementById("result-text"),text);
    if ( dir!='ltr' && bidi_support_in_svg==0) {
        el.innerHTML += '<div style="color: gray; direction: ltr; font-size: 8pt;">WARNING: Your browser may obscure right-to-left text in HTML or SVG; try e.g. Opera!</div>';
    }
    fit_window();
    /*
    if (/:8105/.test(window.location.href)) { 
	return;
    } // TEST instance only
    */

    add_language_tools(el);
}
function placeTip (x,y,svg_root,event) {
    var left = 0;
    var object = getSVGContainer(svg_root);
    if (object==null) object=tree_obj;
    x = 20 + x - object.parentNode.scrollLeft + findPosX(tooltip.parentNode);
    y = 10 + y - object.parentNode.scrollTop + findPosY(tooltip.parentNode);
    tooltip.style.left = "" + x + "px";
    tooltip.style.top  = "" + y + "px";
}
function changeToolTip (html) {
    if ('' != html) {
        tooltip.innerHTML = html;
	tooltip.style.visibility = 'visible';
    } else {
	tooltip.style.visibility = 'hidden';
    }
}

function desc_span_clicked (event) {
    var el = event.target;
    var classes=el.getAttribute('class');
    if (!classes) return;
    var id = /\#(\S+)/.exec(classes);
    if (!id) return;
    for (var j=1; j<id.length; j++) {
	if (scroll_to_see_node(id[j])) break;
    }
}