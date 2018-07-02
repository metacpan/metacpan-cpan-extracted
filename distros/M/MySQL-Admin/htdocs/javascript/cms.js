
/*
=head2 NAME

    MySQL::Admin::Documentation

=head2 SYNOPSIS

    MySQL administration Web-App and Content Management System

    cpan MySQL::Admin

This System works like following: index.html 

Css Overview:

=begin html

<pre>
#############################################
#  .window                                  #
#  #######################################  #
#  #.tab                                 #  #   
#  #######################################  #
#  #.menu                  #.content     #  #
#  # ##################### #             #  # 
#  # #.menuContainer     # #             #  #
#  # #.verticalMenuLayout# #.ShowTables  #  #
#  # #.menuCaption       # #.caption     #  #
#  # #.menuContent       # #             #  #
#  # ##################### #             #  #
#  #                       #             #  #
#  #######################################  #
#                                           #
#############################################
</pre>

=end html

javascript/cms.js
    
      // In the  function init() a ( xmlhttprequest ) load the Content.
      // <a onclick="requestURI('$ENV{SCRIPT_NAME}?action=HelloWorld','HelloWorld','HelloWorld')">HelloWorld</a>      

=begin html

<pre>
      requestURI(
        url,     // Script url  
        id,      // Tabwidget id
        txt,     // Tabwidget text
        bHistory,// Browser History
        formData,// Form Data 
        method,  // Submit Type GET or POST
       );
    or 
    <form onsubmit="submitForm(this,'$m_sAction','$m_sTitle');return false;" method="GET" enctype="multipart/form-data">
    <input type="hidden" name="action" value="">
</pre>

=end html

    since apache 2.x GET have maxrequestline so use POST for alarge requests.
    
    POST requests don't saved in the Browser history (back button ). 
    
install.sql

    The actions will bill stored in actions.

=begin html

<pre>
    INSERT INTO actions (
        `action`, #Name of the action
        `file`,   #file contain the code
        `title`,  #title 
        `right`,  #right 0 guest 1 user 5 admin
        `sub`     # sub name  main for the while file 
        ) values('HelloWorld','HelloWorld.pl','HelloWorld','0','main');

    INSERT INTO actions (`action`,`file`,`title`,`right`,`sub`) values('HelloSub','HelloSub.pl','HelloWorld','0','HelloSub');
</pre>

=end html

    In action_set:

=begin html

<pre>
    INSERT INTO actions_set (
        `action`,           #action called
        `foreign_action`,   #foreign key
        `output_id`         #output id 
        ) values('HelloWorld','HelloWorld','content');

    INSERT INTO actions_set (`action`,`foreign_action`,`output_id`) values('HelloWorld','HelloSub','otherOutput');
    
    
    INSERT INTO mainMenu (
        `title`,   # link title
        `action`,  # action defined in actions_set
        `right`,   # 0 guest 1 user 5 admin
        `position`,# top 1 ... x bottom 
        `menu`,    #top or left
        `output`   #requestURI or javascript or loadPage  or href
        )  values('HelloWorld','HelloWorld','0','1','top','requestURI');
</pre>

=end html

  This will call 2 files HelloWorld.pl HelloSub.pl with following output.

cgi-bin/Content/HelloWorld.pl

    #Files are called via do ().
    
    #you are in the MySQL::Admin::GUI namespace

    print  "Hello World !"
    
    .br()
    
    .a(
    
      {
      
      -href => "mailto:$m_hrSettings->{admin}{email}"
      
      },'Mail me')
    
    .br()
    
    1;

cgi-bin/Content/HelloSub.pl

    sub HelloSub{

      print "sub called";
    
    }
    
    1;


cgi-bin/mysql.pl

    Returns a actionset stored in the Mysql Database.
    
    One sub for every output id.
    
    <xml>
    
    <output id="otherOutput">sub called</output>

    <output id="content">Hello World !<br /><a href="mailto:">Mail me</a><br /></output>

    </xml>

this file will be transformed trough xslt in main Template     

index.html

    <div id=otherOutput>sub called</div>

    <div id=content>Hello World !<br /><a href="mailto:">Mail me</a><br /></div>

</pre>

I write a whole Documentation soon.No feedback so I'm not in rush.

Look at http://lindnerei.sourceforge.net or http://lindnerei.de for further Details.
 
=cut
 
*/

style = "mysql";
size = 16;
right = 0;
htmlright = 2;
shown = false;
maxLength = 1000;
m_sid = '123';
m_txt = '';

/*

=head2 loadPage(inXml, inXsl, outId, tabId, title)

param inXml

  XmL Document or filename

param inXsl

  XsL Document or filename
  
outId, tabId, title set L<requestURI>
  
=cut

*/

function loadPage(inXml, inXsl, outId, tabId, title) {
    xml = typeof inXml == 'object' ? inXml : loadXMLDoc(inXml);
    xsl = typeof inXsl == 'object' ? inXsl : loadXMLDoc(inXsl);
    if (typeof XSLTProcessor == 'undefined') {
		var xslt = new ActiveXObject("Msxml2.XSLTemplate");
		if (xslt) {
			var xslDoc = new ActiveXObject("Msxml2.FreeThreadedDOMDocument");
			var xmlstr = xsl.xml ? xsl.xml : (new XMLSerializer()).serializeToString(xsl);
			xslDoc.loadXML(xmlstr);
			xslt.stylesheet = xslDoc;
			var xslProc = xslt.createProcessor();
			xslProc.input = xslDoc;
			xslProc.transform();
			document.getElementById(outId).innerHTML =  xslProc.output;
		}else{
			ex = xml.transformNode(xsl);
			document.getElementById(outId).innerHTML = ex;
		}
    } else if (document.implementation && document.implementation.createDocument) {
        xsltProcessor = new XSLTProcessor();
        xsltProcessor.importStylesheet(xsl);
        resultDocument = xsltProcessor.transformToFragment(xml, document);
        node = document.getElementById(outId);
        setText(outId, '');
        if (node.childNodes[0]) node.removeChild(node.childNodes[0]);
        if (node) node.appendChild(resultDocument);
    }
    setCurrentTab(tabId, title);
    if (outId == 'content') disableOutputEscaping('content');
}

/*

=head2 intputMask(id, regexp) 

 onkeydown="intputMask(this.id,"(\w+)")"
 
 Would only accept chars for given id as Input.
  
=cut

*/

function intputMask(id, regexp) {
    var rxObj = regexp;
    rxObj.exec(document.getElementById(id).value);
    document.getElementById(id).value = RegExp.$1;
}
var tmpTxt;
var tmpID;

function showPopup(id, hideCloseButton) {
    visible('popup');
    if (hideCloseButton) hide('closeButton');
    else visible('closeButton');
    tmpTxt = getText(id);
    tmpID = id;
    setText(id, '');
    setText('popupTitle', translate(id));
    setText('popupContent', tmpTxt);
    evalId(id);
}

function closePopup() {
    hide('popup');
    setText(tmpID, tmpTxt);
    document.getElementById('popupContent1').style.left = '25%';
    document.getElementById('popupContent1').style.width = '50%';
}

function setCurrentTab(id, title) {
    var body = document.getElementsByTagName('body')[0];
    var nodes = body.getElementsByTagName("td");
    for (var i = 0, j = nodes.length; i < j; i++) {
        if (nodes[i].className == 'headerItemHover') {
            nodes[i].className = 'headerItem';
            nodes[i].firstChild.className = 'menuLink';
        }
    }
    var entry = document.getElementById(id);
    var entryDynamic = document.getElementById('dynamicTab');
    if (entry) {
        var body = document.getElementsByTagName('body')[0];
        var nodes = body.getElementsByTagName("td");
        for (var i = 0, j = nodes.length; i < j; i++) {
            if (nodes[i].className == 'headerItemHover') {
                nodes[i].className = 'headerItem';
                if (nodes[i].firstChild) nodes[i].firstChild.className = 'menuLink';
            }
        }
        if (entry.className == 'headerItem') entry.className = 'headerItemHover';
        if (entryDynamic) {
            entryDynamic.style.display = 'none';
            entryDynamic.className = 'headerItem';
        }
        return;
    }
    if (entryDynamic && title) {
        entryDynamic.style.display = '';
        entryDynamic.className = 'headerItemHover'
        entryDynamic.innerHTML = '<a class="dynamicLink">' + translate(title) + '</a>';
    }
}
var currentId, currentTxt;
var act = 'save';

//requestURI('cgi-bin/mysql.pl?action=loadSidebar',action,action,false,false,'GET',false)
/*
=head2 submitForm(node, tabId, tabTitle, bHistory, method, uri)

=begin html

<pre>
      requestURI(
        node,       // Script url  
        tabId,      // Tabwidget id
        tabTitle,   // Tabwidget text
        bHistory,   // Browser History
        method,     // Form Data 
        uri,        // Submit Type GET or POST
       );
    or 
    <form onsubmit="submitForm(this,'$m_sAction','$m_sTitle');return false;" method="GET" enctype="multipart/form-data">
    <input type="hidden" name="action" value="">
</pre>

=end html

=cut
*/

function submitForm(node, tabId, tabTitle, bHistory, method, uri) {
    bHistory = typeof bHistory !== 'undefined' ? bHistory : true;
    method = typeof method !== 'undefined' ? method : 'POST';
    var url = typeof uri !== 'undefined' ? uri : 'cgi-bin/mysql.pl?';
    if (checkForm(node)) {
        var formData = new FormData();
        formData.append("sid", m_sid);
        formData.append("m_blogin", m_blogin);
        for (var i = 0; i < node.elements.length; i++) {
            if (node.elements[i].type == 'checkbox' || node.elements[i].type == 'radio') {
                if (node.elements[i].checked) {
                    if (method == 'POST') formData.append(node.elements[i].name, node.elements[i].value);
                    else url += node.elements[i].name + "=" + encodeURIComponent(node.elements[i].value) + "&";
                }
            } else if (node.elements[i].name == 'submit') {
                if (method == 'POST') formData.append(node.elements[i].name, act);
                else url += node.elements[i].name + "=" + encodeURIComponent(act) + "&";
            } else if (node.elements[i].type == 'file') {
                var file = node.elements[i];
                if (method == 'POST') formData.append(file.name, file.files[0]);
            } else if (node.elements[i].type == 'select-multiple') {
                for (var j = 0, len = node.elements[i].options.length; j < len; j++) {
                    var opt = node.elements[i].options[j];
                    if (opt.selected) {
                        if (method == 'POST') formData.append(node.elements[i].name, node.elements[i].options[j].value);
                        else url += node.elements[i].name + "=" + encodeURIComponent(node.elements[i].options[j].value) + "&";
                    }
                }
            } else {
                if (method == 'POST') formData.append(node.elements[i].name, node.elements[i].value);
                else url += node.elements[i].name + "=" + encodeURIComponent(node.elements[i].value) + "&";
            }
        }
        requestURI(url, tabId, tabTitle, bHistory, formData, method);
    }
}
var http_request = false;
var oldpage = 0;

function GetEditorLines(){
    var doc = editor.session.getDocument();
    var lines = doc.getAllLines();
    return lines;
}

//requestURI('cgi-bin/mysql.pl?action=loadSidebar',action,action,false,false,'GET',false)
/*
=head2 requestURI(url, id, txt, bHistory, formData, method, bWaid)

=begin html

<pre>
      requestURI(
        url,     // Script url  
        id,      // Tabwidget id
        txt,     // Tabwidget text
        bHistory,// Browser History
        formData,// Form Data 
        method,  // Submit Type GET or POST
       );
    or 
    <form onsubmit="submitForm(this,'$m_sAction','$m_sTitle');return false;" method="GET" enctype="multipart/form-data">
    <input type="hidden" name="action" value="">
</pre>

=end html

=cut
*/

function requestURI(url, id, txt, bHistory, formData, method, bWaid) {
    setAction(id);
    closePopup();
    if (url.indexOf("sid=") == -1) {
        if (url.indexOf('?') != -1) url += "&sid=" + m_sid;
        else url += "?sid=" + m_sid;
    }
    if (url.indexOf("m_blogin=") == -1) {
        if (url.indexOf('?') != -1) url += "&m_blogin=" + m_blogin;
    }
    if (txt) window.document.title = translate(txt);
    bHistory = typeof bHistory !== 'undefined' ? bHistory : true;
    method = typeof method !== 'undefined' ? method : 'GET';
    if (bHistory && method == 'GET') history.pushState(null, '', '?' + url);
    http_request = false;
    if (window.XMLHttpRequest) { //Firefox
        http_request = new XMLHttpRequest();
        if (http_request.overrideMimeType) http_request.overrideMimeType('text/xml');
    } else if (window.ActiveXObject) { //IE
        try {
            http_request = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                http_request = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e) {}
        }
    }

    m_txt = txt;
    visible('load');
    http_request.onreadystatechange = setContent;
    if (method != 'POST') {
        http_request.open('GET', url, true);
        http_request.send(null);
    } else {
        http_request.open('POST', url, true);
        http_request.setRequestHeader("Content-Type", "multipart/form-data");
        http_request.send(formData);
    }
}

/*
=head2 loadXMLDoc(filename)

var xml = loadXMLDoc(filename);

=cut
*/

function loadXMLDoc(filename) {

    if (window.ActiveXObject) {
        xhttp = new ActiveXObject("Msxml2.XMLHTTP");
    } else {
        xhttp = new XMLHttpRequest();
    }
    xhttp.open("GET", filename, false);
    xhttp.overrideMimeType("text/xml");
	if (window.ActiveXObject) {
		try {
			xhttp.responseType = "msxml-document"
		} catch (err) {
			alert(err);
		}
	}
    xhttp.send(null);
    return xhttp.responseXML;
}

function setContent() {
    if (http_request.readyState == 4) {
        if (http_request.status == 200) {
            hide('load');
            response = http_request.responseXML;
            for (var i = 0; i < response.getElementsByTagName('output').length; i++) {
				var obj = response.getElementsByTagName('output')[i];
                var outID = obj.getAttribute('id');
				var typeName = obj.getAttribute('type');
			
                var txt = response.getElementsByTagName('output')[i].textContent;
	            if (navigator.userAgent.indexOf("Firefox") != -1) 
					txt = txt.replace("<![CDATA[", "").replace("]]>", "");
				if(typeName === 'script'){
					eval(txt);
				}else if(typeName === 'xml'){
					var xsl = obj.getAttribute('xsl');
					var title = obj.getAttribute('title');
					var tabId = obj.getAttribute('tabId');
					var parser = new DOMParser(); 
					var xmlDoc = parser.parseFromString(txt,"text/xml");
					loadPage(xmlDoc, xsl, outID, tabId, title);
					evalId(outID);
				}else{
					setText(outID, txt);
					evalId(outID);
				}
            }
            if (!m_blogin && (bAction == 'login' || bAction == 'logout')) loadMenu();
            setCurrentTab(cAction, m_txt);
        } else {
            if (oldpage.length > 0) {
                setText('content', oldpage);
                setCurrentTab(currentId, currentTxt);
            } else {
                errorPopUp('<div style="overflow:auto">' + http_request.status + " " + http_request.responseText + "</div>", errorMessage);
            }
            return false;
        }
        if (m_sid == '123' && m_blogin && cAction != 'reg') {
           showPopup('loginContent', true);
		   evalId('popupContent');
        } else {
            var closeButton = document.getElementById("closeButton");
            closeButton.addEventListener('click', closePopup);
        }
    }
}

function alert(txt) {
    visible('popup');
    setText('popupContent', '<div align="center">' + txt + '<br/><input  type="submit" id="confirmButton" value="Ok"/></div>');
    var node = document.getElementById("confirmButton");
    node.addEventListener('click', function(evt) {
        hide('popup');
    });
}
// window.onerror = logError;
// 
// function logError(message, file, line) {
//     console.log("Message: " + message + "file: " + file + "line: " + line);
// }

function confirm2(txt, sub, arg, arg2, arg3) {
    visible('popup');
    setText('popupContent', '<b>' + txt +
        '</b><div align="right" style="padding:0.4em;"><input type="submit" name="cancelButton" id="cancelButton" value="Cancel"/>&#160;<input  type="submit" id="confirmButton" value="Ok"/></div>'
    );
    var node = document.getElementById("confirmButton");
    node.addEventListener('click', function(evt) {
        hide('popup');
        sub(arg, arg2, arg3);
    });
    var node2 = document.getElementById("cancelButton");
    node2.addEventListener('click', function(evt) {
        hide('popup');
    });
}

function moveHere(txt, sub, arg, arg2, arg3) {
    visible('moveHere');
    window.document.title = txt;
    setText('moveHere', '<div id="moveButton" class="moveButton" style="padding:0.4em;">' + translate('MoveHere') +
        '</div><div id="moveCancelButton" class="moveButton" style="padding:0.4em;">' + translate('Cancel') + '</div>');
    var node = document.getElementById("moveButton");
    document.getElementById('moveHere').style.position = "absolute";
    document.getElementById('moveHere').style.left = (posX - dragX) + "px";
    document.getElementById('moveHere').style.top = (posY - dragY) + "px";
    document.getElementById('moveHere').style.zIndex = 4;

    node.addEventListener('click', function(evt) {
        stopDrop();
        evt.stopPropagation();
        sub(arg, arg2, arg3);
    });
    var node2 = document.getElementById("moveCancelButton");
    node2.addEventListener('click', function(evt) {
        stopDrop();
        evt.stopPropagation();
        window.document.title = translate('links');
    });
}

function stopDrop() {
    hide('moveHere');
    dragobjekt.style.position = "";
    dropenabled = false;
    dragobjekt.className = "treeviewLink";
    dragobjekt = null;
    m_bNoDrop = false;
}

function prompt(txt, sub) {
    visible('popup');
    setText('popupContent', '<b>' + txt +'</b><br/><input  type="text" align="center" id="promptPopUp"/><br/><div align="right" style="padding:0.4em;"><input type="submit" name="cancelButton" id="cancelButton" value="Cancel"/>&#160;<input  type="submit" id="confirmButton" value="Ok"/></div>');
    var node = document.getElementById("confirmButton");
    node.addEventListener('click', function(evt) {
        hide('popup');
        sub(document.getElementById('promptPopUp').value);
    });
    var node2 = document.getElementById("cancelButton");
    node2.addEventListener('click', function(evt) {
        hide('popup');
        evt.stopPropagation();
    });
}

function errorPopUp(txt, sub, arg, arg2, arg3) {
    visible('popup');
    setText('popupContent', '<b>' + txt + '</b><div align="right" style="padding:0.4em;">&#160;<input type="submit" id="confirmButton" value="Ok"/></div>');
    var node = document.getElementById("confirmButton");
    node.addEventListener('click', function(evt) {
        hide('popup');
        sub(arg, arg2, arg3);
    });
}

function checkForm(form) {
    var selectElement = form.querySelectorAll('input');
    var ret = true;
    for (i = 0; i < form.length; i++) {
        if (selectElement[i]) {
            var value = selectElement[i].value;
            var regexp = selectElement[i].dataset.regexp;
            if (regexp) {
                if (eval('value.match(' + regexp + ')')) {
                    selectElement[i].style.borderColor = 'green';
                    selectElement[i].title = selectElement[i].dataset.right;
                } else {
                    selectElement[i].style.borderColor = 'red';
                    selectElement[i].title = selectElement[i].dataset.error;
                    ret = false;
                }
            }
        }
    }
    return ret;
}

function errorMessage(text) {
    location.href = "install.html";
}

/*
=head2 evalId(id)

eval <script></script> tags within given id

=cut
*/

function evalId(id) {
    var content = document.getElementById(id);
    if (content) {
        var node = content.getElementsByTagName("script");
        for (var i = 0, j = node.length; i < j; i++) {
            if (node[i] && node[i].childNodes[0]) eval(node[i].childNodes[0].nodeValue);
        }
    }
}

function showEditor(txt) {
    if(document.getElementById('editor')){
        ace.require("/ace/src-min/chromevox");
        editor = ace.edit("editor");
        editor.session.setMode("ace/mode/perl");
        editor.setTheme("ace/theme/sqlserver");
        if(txt){
            editor.setValue(txt, 1);
        }
    }
}

/*
=head2 translate(string)

use MySQL::Admin for translations.

=cut
*/

function translate(string) {
    var lng = navigator.language.indexOf("de") > -1 ? 'de' : 'en';
    if (typeof Lang != 'undefined') {
        var l = new Lang();
        if (string) {
	    string.replace(/\s/g, '');
            var ret = eval('l.' + lng + string.toLowerCase());
            return ret ? ret : string;
        } else {
            traversTranslate('tab', lng, l);
            traversTranslate('tabwidget', lng, l);
        }
    } else {
        return string;
    }
}

function traversTranslate(id, lng, l) {
    if (document.getElementById(id)) {
        var node = document.getElementById(id).getElementsByTagName("a");
        for (var i = 0, j = node.length; i < j; i++) {
            if (node[i] && node[i].childNodes[0]) {
                var ret = eval('l.' + lng + node[i].childNodes[0].nodeValue.toLowerCase());
                if (ret) {
                    node[i].childNodes[0].nodeValue = ret;
                    node[i].title = ret;
                }
            }
        }
    }
}

function disableOutputEscaping(id) {
 //   if (navigator.userAgent.indexOf("Firefox") != -1) document.getElementById(id).innerHTML = document.getElementById(id).textContent;
}
// //cms
// function document.getElementById(id) {
//     return document.getElementById(id);
// }

function insertAtCursorPosition(txt) {
    var textarea = document.getElementById('sqlEdit');
    if (typeof document.selection != 'undefined') {
        range = document.selection.createRange();
        var txt = range.text;
        range.text = txt;
        range.moveStart('character', txt.length);
        range.select();
    } else if (textarea.selectionStart && (textarea.selectionEnd == textarea.selectionStart)) { //insert at gecko
        var ia = textarea.selectionStart;
        var a = textarea.value.substring(0, ia);
        var b = textarea.value.substring(ia, textarea.value.length);
        textarea.value = a + txt + b;
    } else {
        textarea.value += txt;
    }
}

var nCurrentRow = 0;
function enter(event) {
    var keyCode = event.keyCode ? event.keyCode : event.charCode ? event.charCode : event.which;
    if (keyCode == 13) return true;
    else return false;
}

function setAll() {
    var body = document.getElementsByTagName("body")[0];
    var node = body.getElementsByTagName("option");
    for (var i = 0, j = node.length; i < j; i++)
        if (node[i].className == 'set') node[i].selected = true;
}

function editSet(input, select) {
    document.getElementById(input).value = select.options[select.options.selectedIndex].value;
    nCurrentRow = select.options.selectedIndex;
}

function setEnter(input, select) {
    if (!document.getElementById(select).options[nCurrentRow]) {
        addEntry(select, input.id);
    }
    document.getElementById(select).options[nCurrentRow].value = input.value;
    document.getElementById(select).options[nCurrentRow].text = input.value;
}

function deleteEntry(idSelect) {
    document.getElementById(idSelect).options[document.getElementById(idSelect).options.selectedIndex] = null;
}

function clearSelect(idSelect) {
    document.getElementById(idSelect).innerHTML = '';
    nCurrentRow = 0;
}

function addEntry(idSelect, idEdit) {
    newEntry = new Option('', '', false, true);
    var n = document.getElementById(idSelect).length;
    document.getElementById(idSelect).options[n] = newEntry;
    document.getElementById(idSelect).options[n].className = 'set';
}

/*
=head2 getElementPosition(id) 

 object.x - .y =  getElementPosition(id);

=cut
*/

function getElementPosition(id) {
    var node = document.getElementById(id);
    var offsetLeft = 0;
    var offsetTop = 0;
    while (node) {
        offsetLeft += node.offsetLeft;
        offsetTop += node.offsetTop;
        node = node.offsetParent;
    }
    var position = new Object();
    position.x = offsetLeft;
    position.y = offsetTop;
    return position;
}

/*
=head2 move(id, x, y)


=cut
*/

function move(id, x, y) {
    Element = document.getElementById(id);
    Element.style.position = "absolute";
    Element.style.left = x + "px";
    Element.style.top = y + "px";
}
var openMenu;

function showMenu(linkId, menuId) {
    if (menuId != openMenu) hide(openMenu);
    openMenu = menuId;
    var oLink = document.getElementById(linkId);
    var oMenu = document.getElementById(menuId);
    var o = getElementPosition(linkId);
    var ao = getWindowSize();
    var c = ((o.x + oLink.offsetWidth) - oMenu.offsetWidth);
    c = c > 0 ? c : o.x - 1;
    move(menuId, ao.x > o.x + oMenu.offsetWidth ? o.x - 1 : c + 1, o.y + oLink.offsetHeight);
    displayTree(menuId);
}

/*
=head2 getWindowSize()

 object.x - .y =  getWindowSize();

=cut
*/

function getWindowSize() {
    var nWidth = 0,
        nHeight = 0;
    var o = new Object;
    if (typeof(window.innerWidth) == 'number') { //Gecko
        o.x = window.innerWidth;
        o.y = window.innerHeight;
        return o;
    } else if (document.documentElement && document.documentElement.clientWidth && document.documentElement.clientHeight) { //Ie
        o.x = document.documentElement.clientWidth;
        o.y = document.documentElement.clientHeight;
        return o;
    }
    o.x = 0;
    o.y = 0;
    return o;
}

function ChangeToolTip(sId, sDataTyp) {
    document.getElementById(sId).title = translate(sDataTyp);
}
var pnPageY = 0;

window.onscroll = function () {
    var topUp = document.getElementById('topUp');
    if(topUp && window.pageYOffset >= 250)
        visible('topUp');
    else
        hide('topUp');
}
function scrollToTop() {
    pnPageY = window.pageYOffset;
    var node = document.getElementById('topUp');
    window.setTimeout(pageUp, 1);
}

function pageUp() {
    pnPageY -= 250;
    window.scrollTo(0, pnPageY);
    if (pnPageY > 0) window.setTimeout(pageUp, 1);
}

function maxMin(id) {
    document.getElementById(id).style.width = "";
    if (document.getElementById(id).style.position == "absolute") {
        if (document.getElementById(id).className == 'fmin' || document.getElementById(id).className == 'min') {
            document.getElementById(id).className = 'fmax';
            move(id, 0, window.pageYOffset);
            document.getElementById(id).style.width = wsize.x - ScrolBarWidth() + "px";
        } else {
            document.getElementById(id).className = 'fmin';
            move(id, (wsize.x / 100) * 10 - ScrolBarWidth(), window.pageYOffset + (wsize.x / 100) * 5);
            document.getElementById(id).style.width = "80%";
        }
    } else {
        if (document.getElementById(id).className == 'fmax' || document.getElementById(id).className == 'max') {
            document.getElementById(id).className = 'min';
        } else {
            document.getElementById(id).className = 'max';
        }
    }
}

function undock(id) {
    var wname = id;
    var element = document.getElementById(wname);
    var caption = document.getElementById("tr" + id);
    var pos = element.style.position;
    var o = getElementPosition(wname);
    if (pos == "absolute") {
        element.style.position = "";
        caption.style.cursor = "pointer";
        element.style.width = (element.className == 'fmax' || element.className == 'max') ? "100%" : "90%";
    } else {
        var w = element.offsetWidth;
        move(wname, o.x, o.y);
        element.style.width = w + "px";
    }
}

function checkLength(max) {
    var message = document.getElementById("txt");
    var m = message.value;
    var tmpMax = maxLength;
    if (typeof max != undefined) maxLength = max;
    if (m.length >= maxLength) {
        message.value = m.substring(0, maxLength);
        document.getElementById("msglength").value = 0;
        document.getElementById("msglength").style.color = "red";
    } else {
        var no = (maxLength - m.length);
        document.getElementById("msglength").value = no;
        document.getElementById("msglength").style.color = "green";
    }
    maxLength = tmpMax;
}
//<<editor.pm
JString.prototype = new Array();
JString.prototype.constructor = JString;
JString.superclass = Array.prototype;

function JString(string) {
    for (i = 0; i < string.length; i++) {
        JString.prototype[i] = string[i];
    }
}
JString.prototype.splice = function(i, n, array) {
    JString.superclass.splice.call(this, i, n, array);
    return this.join("");
};
JString.prototype.toString = function() {
    return this.join("");
};

function markInput(bool) {
    var body = document.getElementsByTagName("body")[0];
    var node = body.getElementsByTagName("input");
    for (var i = 0, j = node.length; i < j; i++)
        if (node[i].className == 'markBox') node[i].checked = bool;
    visible(bool ? 'umarkAll' : 'markAll');
    hide(bool ? 'markAll' : 'umarkAll');
}

function markTables(bool) {
    var body = document.getElementsByTagName("body")[0];
    var node = body.getElementsByTagName("option");
    for (var i = 0, j = node.length; i < j; i++)
        if (node[i].className == 'table') node[i].selected = bool;
    visible(bool ? 'umarkAll2' : 'markAll2');
    hide(bool ? 'markAll2' : 'umarkAll2');
}
var html = 0;
markDownEditor = null;

function enableHtml(enable){
    if(typeof enable === 'boolean')
       html = enable;
    else
        html = !html;

    if (html) {
        document.getElementById('htmlButton').checked = true;
        if (document.getElementById('enlarged')) {
            document.getElementById('enlarged').style.display = 'none';
        }
        ace.require("/ace/src-min/chromevox");
        editor = ace.edit("edit");
        editor.session.setMode("ace/mode/perl");
        editor.setTheme("ace/theme/chromevox");
        editor.setValue($('#txt').val(), 1);
        hide('txt');
        visible('edit');
        visible('editorRim');
        $('.md-container').hide();
    } else {
        document.getElementById('htmlButton').checked = false;
        if (document.getElementById('enlarged')) {
            document.getElementById('enlarged').style.display = '';
        }
        if(!markDownEditor){
            markDownEditor = $('#txt').markdownEditor(
            {
                theme:'theme/tomorrow_night_eighties',
                uploadPath:false,
                preview:false
            }
            );
        }
        visible('txt');
        hide('edit');
        hide('editorRim');
        $('.md-container').show();
    }
}

function put(t) {
    addText(t);
}
//<< markdown buttons
function addText(text) {
    var element = document.getElementById("txt");
    element.value += text;
    element.focus();
}

function left() {
    align("left");
}

function center() {
    align("center");
}

function aright() {
    align("right");
}

function justify() {
    align("justify");
}

function strike() {
    insertT("~~");
}

function underline() {
    insertT("__");
}

function bold() {
    insertT("**");
}

function italicize() {
    insertT("*");
}

function img() {
    var textarea = document.getElementById('txt');
    if (typeof document.selection != 'undefined') {
        var range = document.selection.createRange();
        var txt = range.text;
        range = document.selection.createRange();
        if (txt.length == 0) {
            prompt("Insert Image location:", function(txt) {
                txt = promptValue;
                var o = "";
                if (html) {
                    o = "<img src='" + txt + "'/>";
                } else {
                    o = "![]("  + txt + ")";
                }
                textarea.value += o;
            });
        } else {
            if (html) {
                range.text = "<img src='" + txt + "'/>";
            } else {
                range.text = "![]("  + txt + ")";
            }
            range.moveStart('character', txt.length + 11);
        }
        range.select();
    } else if (textarea.selectionEnd > textarea.selectionStart) {
        var i = textarea.selectionStart;
        var n = textarea.selectionEnd;
        var img = textarea.value.substring(i, n);
        o = new JString(textarea.value);
        if (html) {
            textarea.value = o.splice(i, (n - i), "<img src='" + img + "'/>");
        } else {
            textarea.value = o.splice(i, (n - i), "![]("  + img + ")");
        }
    } else if (textarea.selectionStart && (textarea.selectionEnd == textarea.selectionStart)) { //insert at gecko
        var ia = textarea.selectionStart;
        prompt("Insert Image location:", function(txta) {
            var a = textarea.value.substring(0, ia);
            var b = textarea.value.substring(ia, textarea.value.length);
            if (html) {
                textarea.value = a + "<img src='" + txta + "'/>" + b;
            } else {
                textarea.value = a + "![](" + txta + ")" + b;
            }
        });
    } else {
        prompt("Insert Image location:", function(imga) {
            if (html) {
                if (img) {
                    textarea.value += "<img src='" + imga + "'/>";
                }
            } else {
                if (img) {
                    textarea.value += "![](" + imga + ")";
                }
            }
        });
    }
}

function link() {
    prompt("Insert a url:", function(link) {
        if (html) {
            insertT("a href=\"" + link + "\"", "a");
        } else {
            insertT("[","]("+ link + ")");
        }
    });
}

function insertT(tag, tag2) {
    if (!tag2) tag2 = tag;
    var textarea = document.getElementById('txt');
    if (typeof document.selection != 'undefined') { //IE6
        range = document.selection.createRange();
        var txt = range.text;
        if (txt.length == 0) {
            prompt("Insert text:", function(txt) {
                if (txt.length > 0) {
                    var o = "";
                    if (html) {
                        o = "<" + tag + ">" + txt + "</" + tag2 + ">";
                    } else {
                        o = tag + txt + tag2;
                    }
                    textarea.value += o;
                }
            });
        } else {
            if (html) {
                range.text = "<" + tag + ">" + txt + "</" + tag2 + ">";
            } else {
                range.text = tag + txt + tag2;
            }
            range.moveStart('character', tag.length + txt.length + tag2.length);
        }
        range.select();
    } else if (textarea.selectionEnd > textarea.selectionStart) { //selektieren gecko
        var i = textarea.selectionStart;
        var n = textarea.selectionEnd;
        var txtb = textarea.value.substring(i, n);
        o = new JString(textarea.value);
        if (html) {
            textarea.value = o.splice(i, (n - i), "<" + tag + ">" + txtb + "</" + tag2 + ">");
        } else {
            textarea.value = o.splice(i, (n - i), tag + txtb + tag2 );
        }
    } else if (textarea.selectionStart && (textarea.selectionEnd == textarea.selectionStart)) { //insert at gecko
        var ia = textarea.selectionStart;
        prompt("Insert text:", function(txta) {
            var a = textarea.value.substring(0, ia);
            var b = textarea.value.substring(ia, textarea.value.length);
            if (html) {
                textarea.value = a + "<" + tag + ">" + txta + "</" + tag2 + ">" + b;
            } else {
                textarea.value = a + tag + txta + tag2 + b;
            }
        });
    } else {
        prompt("Insert text:", function(bol) {
            if (html) {
                textarea.value += "<" + tag + ">" + bol + "</" + tag2 + ">";
            } else {
                textarea.value += tag + bol + tag2 ;
            }
        });
    }
}

function clearIt() {
    var element = document.getElementById("txt");
    element.value = "";
    element.focus();
}


function getValue(id) {
    return document.getElementById(id).value;
}

function setValue(id, txt) {
    document.getElementById(id).value = txt;
}
//editor.pm>>
//<<drag&drop
var dragobjekt = null;
var dragX = 0;
var dragY = 0;
var posX = 0;
var posY = 0;
var dropenabled = false;
// document.onmousemove = drag;
// document.onmouseup = drop;
var dropText = null;
var dropzone = null;
var dropid = null;
var m_bOver = true;
var m_bNoDrop = false;
var offsetLeft = 0;

function startdrag(element) {
    dropid = element;
    dragobjekt = document.getElementById(element);
    dragX = posX - dragobjekt.offsetLeft;
    dragY = posY - dragobjekt.offsetTop;
}

function drop() {
    if (dropenabled && dragobjekt && !m_bNoDrop) {
        m_bOver = true;
        dragobjekt.style.cursor = "";
        dragobjekt.style.position = "";
    }
    if (!m_bNoDrop) dragobjekt = null;
}

function drag(EVENT) {
    posX = document.all ? window.event.clientX : EVENT.pageX;
    posY = document.all ? window.event.clientY : EVENT.pageY;
    if (dragobjekt && !m_bNoDrop) {
        dragobjekt.style.left = (posX - dragX) + "px";
        dragobjekt.style.top = (posY - dragY) + "px";
    }
}
//drag&drop>>
function displayTree(id) {
    var e = document.getElementById(id);
    if (!e) return;
    var display = e.style.display;
    if (display == "none") {
        e.style.display = "";
    } else if (display == "") {
        e.style.display = "none";
    }
}

function leaveFrame() {
    if (parent.frames.length > 0) {
        parent.location.href = location.href;
    }
}

function param(name) {
    var lo = location.href;
    var i = 0;
    var suche = name + "=";
    while (i < lo.length) {
        if (lo.substring(i, i + suche.length) == suche) {
            var ende = lo.indexOf(";", i + suche.length);
            ende = (ende > -1) ? ende : lo.length;
            var cook = lo.substring(i + suche.length, ende);
            return unescape(cook);
        }
        i++;
    }
    return 0;
}

function blogThis() {
    var referer = param("referer");
    var headline = param("headline");
    var q = param("quote");
    if (referer && headline && q) {
        var t = "[blog=" + unescape(referer) + "]\n" + unescape(q) + "\n[/blog]";
        document.getElementById('title').value = unescape(headline);
        document.getElementById('txt').value = t;
    }
}

function datum() {
    var z = new Date();
    var j = z.getYear();
    if (j < 999) j += 1900;
    var m = z.getMonth() + 1;
    var t = z.getDate();
    var d = translate("Datum:") + t + "." + m + "." + j;
    return d;
}

/*
=head2 setText(id, string)


=cut
*/

function setText(id, string) {
    var element = document.getElementById(id);
    if (element) element.innerHTML = string;
    else window.status = id + string;
}

/*
=head2 getText(id) 


=cut
*/

function getText(id) {
    var element = document.getElementById(id);
    if (element) return element.innerHTML;
}

/*
=head2 hide(id) 


=cut
*/

function hide(id) {
    if (document.getElementById(id)) document.getElementById(id).style.display = "none";
}

/*
=head2 visible(id) 


=cut
*/

function visible(id) {
    if (document.getElementById(id)) document.getElementById(id).style.display = "";
}

/*
=head2 ScrolBarWidth()


=cut
*/

function ScrolBarWidth() {
    //2 verschachtelte divs erzeugen.
    var ouside = document.createElement('div'); //aussen
    ouside.style.position = 'absolute';
    ouside.style.top = '-1000px'; //in den nicht sichtbaren bereich positionieren
    ouside.style.left = '-1000px';
    ouside.style.width = '100px';
    ouside.style.height = '50px';
    var inside = document.createElement('div'); //innnen
    inside.style.width = '100%';
    inside.style.height = '100px'; //das innere div ist höher damit scrollbars angezeigt werden.
    ouside.appendChild(inside);
    document.body.appendChild(ouside); //outside an body anhängen.
    var nWidthWithScrollBars = nWidthWithoutScrollBars = 0;
    // outside ohne scrollbar anzeigen
    ouside.style.overflow = 'hidden';
    nWidthWithoutScrollBars = inside.offsetWidth; //Breite ohne scrollbar
    //outside mit scrollbar anzeigen
    ouside.style.overflow = 'auto';
    nWidthWithScrollBars = inside.offsetWidth; //Breite mit scrollbar
    document.body.removeChild(document.body.lastChild); //outside wieder entfernen
    //Breite inside ohne Scrollbar  -  inside mit Scrollbar
    return nWidthWithoutScrollBars - nWidthWithScrollBars;
}
//CreateUser
var m_bOver = true;

function prepareMove(id) {
    if (document.body) {
        if (typeof document.body.onselectstart != "undefined") { //ie
            document.body.onselectstart = function() {
                return false
            };
        } else if (typeof document.body.style.MozUserSelect != "undefined") { //gecko
            document.body.style.MozUserSelect = "none";
        } else { //Opera
            document.body.onmousedown = function() {
                return false;
            }
        }
    }
    dragobjekt = document.getElementById(id);
    dragX = posX - dragobjekt.offsetLeft;
    dragY = posY - dragobjekt.offsetTop;
    dropenabled = true;
    m_bOver = false;
    var o = getElementPosition(id);
    move(id, o.x + 25, o.y + 25);
    document.getElementById(id)
    startdrag(id);
}

/*
=head2 enableDropZone(id)


=cut
*/

function enableDropZone(id) {
    if (!dragobjekt) return;
    dropzone = id;
    if (dragobjekt.id != dropzone) document.getElementById(id).className = "dropzone" + size;
}

function disableDropZone(id) {
    document.getElementById(id).className = "treeviewLink" + size;
}

function confirmMove() {
    m_bNoDrop = true;
    if (dropzone && dragobjekt.id != dropzone) {
        moveHere(translate('move') + " " + dragobjekt.innerHTML + " " + translate('before') + " " + document.getElementById(dropzone).innerHTML + " ?", function() {
            requestURI('cgi-bin/mysql.pl?action=MoveTreeViewEntry&dump=' + m_sDump + '&from=' + document.getElementById(dropid).id + "&to=" + document.getElementById(dropzone).id + "#" + document.getElementById(
                dropzone).id);
        });
    }
    m_bOver = true;
}
var bAction = 'ShowDatabases';

function setAction(n) {
    bAction = n;
}
var dbAction = 'ShowTable';

function setDbAction(n) {
    dbAction = n;
}
function showCatList() {
    var o = getElementPosition('catLink');       
    move('catlist', o.x, o.y+24);
    displayTree('catlist');
    var e = document.getElementById('catLink');
    e.className = (e.className == 'catLink') ? 'catLinkPressed' : 'catLink';
}

function showTab(id) {
	if(document.getElementById(id).classList)
		document.getElementById(id).classList.remove('closed');
	else
		document.getElementById(id).className -= 'closed';
    if (document.getElementById(id).firstChild) document.getElementById(id).firstChild.style.display = '';
    var elements = document.getElementsByClassName('cnt');
    for (var i = 0; i < elements.length; i++) {
        if (elements[i].id != id && elements[i].style.display == '') {
            if (elements[i].firstChild) elements[i].firstChild.style.display = 'none';
            if(elements[i].classList)
				elements[i].classList.add('closed');
			else
				elements[i].className -= 'closed';
        }
    }
}


window.onpopstate = loadHistory;

function loadHistory() {
    if (window.location.search.match('mysql.pl')) {
        var rxObj = new RegExp(/action=([^&]+)/);
        rxObj.exec(window.location.search);
        var action = RegExp.$1;
        var rxObj2 = new RegExp(/\?(.+)$/);
        rxObj2.exec(window.location.search);
        var uri = RegExp.$1;
        requestURI(uri, action, action);
    } else requestURI('cgi-bin/mysql.pl?action=' + defaultAction, defaultAction, defaultAction);
    return true;
}
var nCurrentShown;

function DisplayTable(id) {
    hide(nCurrentShown);
    visible(id);
    nCurrentShown = id;
}
var aCurrentShown = new Array();

function DisplayTables(i, id) {
    hide(aCurrentShown[i]);
    aCurrentShown[i] = id;
    visible(id);
}

function setIndexType(type) {
    if (type == 'FOREIGN KEY') hideForeign(false);
    else hideForeign(true);
}

function hideForeign(bHide) {
    var body = document.getElementsByTagName("body")[0];
    var node = body.getElementsByTagName("td");
    for (var i = 0, j = node.length; i < j; i++) {
        var a = node[i].classList;
        for (var k = 0, l = node.length; k < l; k++) {
            if (a[k] == 'foreign') node[i].style.display = bHide ? 'none' : '';
        }
    }
}

function DisplayKeyWords(b) {
    if (b) {
        document.getElementById('akeywods').className = 'currentLink';
        document.getElementById('afieldNames').className = 'link';
        hide('divTables');
        hide(nCurrentShown);
        visible('selKeyword');
        document.getElementById('selKeyword').focus();
    } else {
        document.getElementById('akeywods').className = 'link';
        document.getElementById('afieldNames').className = 'currentLink';
        hide('selKeyword');
        visible('divTables');
        document.getElementById('divTables').focus();
    }
}
var action;
var autocomplete = new Array("select", "from", "where", "insert", "set", "update");
var clickA;
var oldDate;
var oldTime;

function breakOut() {
    clickA = clickA ? false : true;
    if (clickA) {
        oldDate = new Date();
        oldTime = oldDate.getTime();
        return false;
    } else {
        var date = new Date();
        var time = date.getTime();
        return (time - oldTime > 1000) ? false : true;
    }
}

/*
=head2 Autocomplete(evt)


oAutocomplete = $("txt");

autocomplete.push("foo");

autocomplete.push("bar");

oAutocomplete.addEventListener('keyup', Autocomplete);

Autocomplete(evt) 

<textarea id="txt"></textarea>

=cut
*/

function Autocomplete(evt) {
    if (breakOut()) return;
    if (evt.which == 8 || evt.which == 16 || evt.which === 37 || evt.which === 38 || evt.which === 39 || evt.which === 39 || evt.which === 40) return;
    var offset = 3;
    while (oAutocomplete.selectionStart - offset >= 0 && offset < 10) { //todo port to IE
        var match = ''
        if (oAutocomplete.value.substr(oAutocomplete.selectionStart - offset - 1, 1) == ' ' || oAutocomplete.value.substr(oAutocomplete.selectionStart - offset - 1,
                1).search(new RegExp("\\b")) == -1 || oAutocomplete.selectionStart - offset == 0) {
            match = oAutocomplete.value.substr(oAutocomplete.selectionStart - offset, offset);
        }
        var i = 0;
        var j = autocomplete.length;
        while (i < autocomplete.length) {
            if (match == autocomplete[i].substr(0, offset)) {
                var selectionStart = oAutocomplete.selectionStart;
                var before = oAutocomplete.value.substr(0, selectionStart - offset);
                var behind = oAutocomplete.value.substr(selectionStart, oAutocomplete.value.length);
                oAutocomplete.value = before + autocomplete[i] + behind;
                oAutocomplete.selectionStart = selectionStart;
                oAutocomplete.selectionEnd = selectionStart + autocomplete[i].length - offset;
                break;
            }
            i++;
        }
        offset++;
    }
}


/*
=head2 selKeyword(id) 

insert vales from an  <select></select> into autocomplete

=cut
*/

function selKeyword(id) {
    for (var i = 0; i < document.getElementById(id).options.length; i++) autocomplete.push(document.getElementById(id).options[i].value);
}
var uno = true;

function showSQLEditor() {
    document.getElementById('popupContent1').style.left = '5%';
    document.getElementById('popupContent1').style.width = '90%';
    showPopup('SqlEditor');
    oAutocomplete = document.getElementById("sqlEdit");
    oAutocomplete.addEventListener('keyup', Autocomplete);
    if (uno) {
        selKeyword('selKeyword');
        selKeyword('tablelist');
        for (var i = 0; i < document.getElementById('tablelist').options.length; i++) selKeyword(document.getElementById('tablelist').options[i].value);
    }
    uno = false;
}

function ShowNewRow() {
    document.getElementById('popupContent1').style.left = '2%';
    document.getElementById('popupContent1').style.width = '96%';
    showPopup('ShowNewRow');
}
/*
=head2 checkButton(id,parent)

fake (styled) checkbox for HTML::Editor 

=cut
*/

function checkButton(id,parent){
    if(parent.className == 'htmlButton' ){
         document.getElementById(id).checked = "checked" 
         parent.className = 'htmlButtonChecked'
    }else{
       parent.className = 'htmlButton'
       document.getElementById(id).checked = "" 
    }
}
/*
=head2 COPYRIGHT

    Copyright (C) 2006-2018 by Hr. Dirk Lindner

    perl -e'sub lze_Rocks{print/(...)/ for shift;}sub{&{"@_"}}->("lze_Rocks")'

    This program is free software; you can redistribute it and/or modify it 
    under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; This program is distributed in the hope 
    that it will be useful, but WITHOUT ANY WARRANTY; without even
    the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details
=cut
*/
