/**
 * @fileoverview Contains the classes for workign with Ajax or remote code. 
 * Automatically included if remote apis are used on the server side while generating the page
 */

/**
 * @class Methods for working with AJAX or Remote code, as Solstice called it.
 * @constructor
 */
Solstice.Remote = function(){};

Solstice.Remote.requests;
Solstice.Remote.request_counter;

/**
 * Run the named remote.
 *<br>
 *<br>
 * For example: Solstice.Remote.run('GroupManager', 'loadGroupMemberList', {group_id: 222, max: 4});
 *
 * @param {string} app Namespace of the application that defines the remote call
 * @param {action} action Name of the remote action
 * @param {object} data Data to pass to the server side.  Can be a scalar or a complex array or hash.
 * @type boolean 
 */
Solstice.Remote.run = function(app, action, data) {
    Solstice.Remote.loadXML(app, action, data);
    return true;
}

/**
 * Run the named remote, for use as a client action.
 *<br>
 *<br>
 * For example: Solstice.Remote.client_action('GroupManager', 'loadGroupMemberList', {group_id: 222, max: 4});
 *
 * @param {string} app Namespace of the application that defines the remote call
 * @param {action} action Name of the remote action
 * @param {object} data Data to pass to the server side.  Can be a scalar or a complex array or hash.
 * @type boolean 
 */

Solstice.Remote.client_action = function(app, action, data) {
    Solstice.Remote.run(app, action, data);
    return false;
}


/**
 * Runs the actual XMLHTTP request.
 * @private
 * @param {string} app Namespace of the application that defines the remote call
 * @param {action} action Name of the remote action
 * @param {object} data Data to pass to the server side.  Can be a scalar or a complex array or hash.
 * @type boolean 
 */
Solstice.Remote.loadXML = function (app, action, data) {
    var url = solstice_document_base + "/solstice_remote_call_url/";
   

    if(data){
        data = encodeURIComponent(JSON.stringify(data));
    }else{
        data = JSON.stringify('');
    }
    
    var postdata = 
        "solstice_session_app_key=" + solstice_session_app_key + 
        "&solstice_remote_app=" + app + 
        "&solstice_remote_action=" + action + 
        "&solstice_subsession_id=" + solstice_subsession +
        "&solstice_subsession_chain=" + solstice_subsession_chain +
        "&solstice_remote_data=" + data;

    var req;
    if (window.XMLHttpRequest) { // branch for native XMLHttpRequest object
        req = new XMLHttpRequest();
    } else if (window.ActiveXObject) { // branch for IE/Windows ActiveX version
        req = new ActiveXObject("Microsoft.XMLHTTP");
    }
    if (req) {
        req.onreadystatechange = Solstice.Remote.processXML;
        req.open("POST", url, true);
        req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        req.send(postdata);
        if (!Solstice.Remote.requests) {
            Solstice.Remote.requests = new Array();
            Solstice.Remote.request_counter = 0;
        }
        Solstice.Remote.requests[Solstice.Remote.request_counter] = req;
        Solstice.Remote.request_counter++;
        return true;
    }
    return false;
}


/**
 * Processes the returned data from the server.
 * @private
 * @type void
 */
Solstice.Remote.processXML = function () {
    for (var req_key in Solstice.Remote.requests) {
        var req = Solstice.Remote.requests[req_key];
        if (req.readyState == 4) {
            if (req.status == 200 || req.status == 0){
                var xmldoc = req.responseXML;
   
                // a bit of debugging information if we have an error in the xml returned from our ajax call
                if(xmldoc && xmldoc.parseError && xmldoc.parseError.errorCode && Solstice.development_mode){
                    var error = xmldoc.parseError;
                    alert("Error Code: "+error.errorCode+ " \nDescription: "+error.reason+'\n Line: ' +error.line+"\n Position: "+error.linepos+ "\n Source: "+error.srcText);
                }

                var actions = xmldoc.getElementsByTagName("action");
                for(var i = 0; i < actions.length; i ++){

                    //childnode[1] is the cdata block in mozilla, childnode[0] in IE
                    if(actions[i].childNodes[1]){
                        var content = actions[i].childNodes[1].nodeValue;
                    }else{
                        var content = actions[i].childNodes[0].nodeValue;
                    }

                    var type = actions[i].getAttribute('type');

                    if(type == 'action'){

                        if(content){
                            try {
                                eval(content);
                            }catch(exception){
                                alert(exception);
                            }
                        }

                    }else if( type == 'update' ){

                        var block_id = actions[i].getAttribute('block_id');
                        var replaced = document.getElementById(block_id);
                        if(replaced){
                            replaced.innerHTML = content;
                        }

                    }else if( type == 'replacement' ){

                        var block_id = actions[i].getAttribute('block_id');
                        var replaced = document.getElementById(block_id);
                        var parent = replaced.parentNode;
                        var new_block = document.createElement("div");
                        new_block.innerHTML = content;
                        if(parent){
                            parent.replaceChild(new_block, replaced);
                        }
                    }
                }
                delete Solstice.Remote.requests[req_key];
            }
        }
    }
}

/**
* @class JSON is a class we use to freeze/thaw data sent to the server.  Please see the source for license and attribution
* @constructor
*/

/*
Copyright (c) 2005 JSON.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
    The global object JSON contains two methods.

    JSON.stringify(value) takes a JavaScript value and produces a JSON text.
    The value must not be cyclical.

    JSON.parse(text) takes a JSON text and produces a JavaScript value. It will
    throw a 'JSONError' exception if there is an error.
*/


/**
 * @class JSON is a class we use to freeze/thaw data sent to the server.  Please see the source for license and attribution
 * @constructor
 */
var JSON = {
    copyright: '(c)2005 JSON.org',
    license: 'http://www.crockford.com/JSON/license.html',
/*
    Stringify a JavaScript value, producing a JSON text.
*/
    stringify: function (v) {
        var a = [];

/*
    Emit a string.
*/
        function e(s) {
            a[a.length] = s;
        }

/*
    Convert a value.
*/
        function g(x) {
            var c, i, l, v;

            switch (typeof x) {
            case 'object':
                if (x) {
                    if (x instanceof Array) {
                        e('[');
                        l = a.length;
                        for (i = 0; i < x.length; i += 1) {
                            v = x[i];
                            if (typeof v != 'undefined' &&
                                    typeof v != 'function') {
                                if (l < a.length) {
                                    e(',');
                                }
                                g(v);
                            }
                        }
                        e(']');
                        return;
                    } else if (typeof x.valueOf == 'function') {
                        e('{');
                        l = a.length;
                        for (i in x) {
                            v = x[i];
                            if (typeof v != 'undefined' &&
                                    typeof v != 'function' &&
                                    (!v || typeof v != 'object' ||
                                        typeof v.valueOf == 'function')) {
                                if (l < a.length) {
                                    e(',');
                                }
                                g(i);
                                e(':');
                                g(v);
                            }
                        }
                        return e('}');
                    }
                }
                e('null');
                return;
            case 'number':
                e(isFinite(x) ? +x : 'null');
                return;
            case 'string':
                l = x.length;
                e('"');
                for (i = 0; i < l; i += 1) {
                    c = x.charAt(i);
                    if (c >= ' ') {
                        if (c == '\\' || c == '"') {
                            e('\\');
                        }
                        e(c);
                    } else {
                        switch (c) {
                        case '\b':
                            e('\\b');
                            break;
                        case '\f':
                            e('\\f');
                            break;
                        case '\n':
                            e('\\n');
                            break;
                        case '\r':
                            e('\\r');
                            break;
                        case '\t':
                            e('\\t');
                            break;
                        default:
                            c = c.charCodeAt();
                            e('\\u00' + Math.floor(c / 16).toString(16) +
                                (c % 16).toString(16));
                        }
                    }
                }
                e('"');
                return;
            case 'boolean':
                e(String(x));
                return;
            default:
                e('null');
                return;
            }
        }
        g(v);
        return a.join('');
    },
/*
    Parse a JSON text, producing a JavaScript value.
*/
    parse: function (text) {
        return (/^(\s+|[,:{}\[\]]|"(\\["\\\/bfnrtu]|[^\x00-\x1f"\\]+)*"|-?\d+(\.\d*)?([eE][+-]?\d+)?|true|false|null)+$/.test(text)) &&
            eval('(' + text + ')');
    }
};


/*
 * Copyright  1998-2006 Office of Learning Technologies, University of Washington
 * 
 * Licensed under the Educational Community License, Version 1.0 (the "License");
 * you may not use this file except in compliance with the License. You may obtain
 * a copy of the License at: http://www.opensource.org/licenses/ecl1.php
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 */
