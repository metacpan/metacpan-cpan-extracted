/**
 * @fileoverview
 * This is the master JavaScript file that is included with every
 * HTML page that is shown.
 * Changes should be tested thoroughly as they affect every page.
 */


/***********************************************
 * @class Namespace for all solstice javascript, also contains some basic global functionality
 * @constructor
 */
Solstice = function (){};



Solstice.log_window;
/***********************
 * Logs messages to a new window.  Useful for debugging events near a form submit.
 */
Solstice.windowLog = function(log) {
    if (!Solstice.log_window) {
        Solstice.log_window = window.open();
    }
    Solstice.log_window.document.write(log+"<br>\n");
}

/************
 * Returns the HTML document base.
 * @returns {string} document base as a string
 */

Solstice.getDocumentBase = function () {
    return solstice_document_base; //This is printed inline by solstice
}


/**
 * Returns the the ID of the Solstice-provided form element, for use in
 * application javascript.
 * @returns {string} ID of the Solstice form element
 */
Solstice.getAppFormID = function () {
    return 'solstice_app_form';
}


/**
 * Convient method to get the document object, browser safe.
 * @returns {domElement} The browser's document object.
 */
Solstice.document = function() {
    if(document.all){
        return document.all;
    }else{
        return document;
    }
}

/**
 * A method for returning a useful object for an iframe.
 * @param {string} name the name of the frame to be returned.
 * @returns {domElement} The object for the given frame name.
 */

Solstice.getWindow = function(name) {
    var frames = window.frames;
    for(var i=0;i<frames.length;i++){
        if(frames[i].name == name){
            return frames[i].window;
        }
    }
}

/*
 * Ensures that the application occupies the topmost window when called. 
 * @return void
 */
Solstice.escapeFrames = function() {
    if (window.top != window) {
        window.top.location.href = window.location.href;
    }
}

Solstice.ToolTipCounter = -1;
Solstice.ToolTipData = new Array();

Solstice.addToolTip = function(id, tooltip) {
    Solstice.ToolTipCounter++;
    Solstice.ToolTipData.push({ id:id, tooltip:tooltip });
}

Solstice.initializeToolTips = function() {
    if (Solstice.ToolTipCounter >= 0) {
        Solstice._initializeToolTip(0);
    }
}

Solstice._initializeToolTip = function(position) {
    var id = Solstice.ToolTipData[position].id;
    var tooltip = Solstice.ToolTipData[position].tooltip;

    var element = document.getElementById(id);

    // If someone paints a button, but it isn't visible, the element won't be defined
    if (element && tooltip) {
        var tip = Solstice.YahooUI.tooltip("solstice_tooltip_"+Solstice.ToolTipCounter, { context:element, text:tooltip });

        // Without the try/catch block, ie7 sometimes has an error when leaving the page before tooltips are
        // loaded, when it can't read the property that was just set.
        try {
            tip.cfg.setProperty('text', tooltip); 
            if (element.title) element.title = tip.cfg.getProperty('text');
        }
        catch (e) {

        }
    }

    if (position < Solstice.ToolTipCounter) {
        var function_def = "Solstice._initializeToolTip("+(position + 1)+")";
        setTimeout(function_def, 1);
    }
}

/**************************************************
 * @constructor
 * @class Backbutton blocking/hanlding methods.
 */
Solstice.BackButton = function (){ };

/**
 * Controlls whether the back button is blocked always or only on demand
 * @type boolean
 * @private
 */
Solstice.BackButton.disable_back_button = 0;

/** 
 * This is designed as an event handler that intercepts the use of the
 * backspace key to prevent accidental back navigations.  It is attached to 
 * 'onkeypress' and 'onkeydown' automatically
 * @param  {event} e The event to inspect and potentially prevent
 * @returns {boolean} whether or not the event is a back event
 * @private
 */
Solstice.BackButton.stopBackSpace = function (e) {
    if (window.event) {
        if (Solstice.BackButton.isBackAction(window.event)) {
            window.event.cancelBubble = true;
            window.event.returnValue = false;
            return false;
        }
    }
    else {
        if (Solstice.BackButton.isBackAction(e)) {
            return false;
        }
    }
}
window.onkeypress = Solstice.BackButton.stopBackSpace;
document.onkeydown = Solstice.BackButton.stopBackSpace;

/**
 * Checks whether the event passed would result in a browser
 * back action.
 * @param {event} e the event to examine
 * @returns {boolean} whether or not the event is a back event
 * @private
 */
Solstice.BackButton.isBackAction = function (e) {
    var key_pressed;
    var tagname;
    var tagtype;
    if (window.event) {
        tagname = window.event.srcElement.tagName;
        tagtype = window.event.srcElement.getAttribute('type');
        key_pressed = e.keyCode;
    }
    else {
        tagname = e.target.tagName;
        tagtype = e.target.getAttribute('type');
        key_pressed = e.which;
    }
    if ((8 == key_pressed) && !Solstice.BackButton.isTextField(tagname, tagtype)) {
        return true;
    }
    if (Solstice.BackButton.disable_back_button && (37 == key_pressed) && (e.altKey || e.metaKey)) {
        return true;
    }
    // this is here for firefox...
    if (Solstice.BackButton.disable_back_button && (0 == key_pressed) && (e.altKey || e.metaKey)) {
        return true;
    }
    return false;
}

/**
 * Supports other back-button related functions by determining
 * whether an element is an input type (so backspace works in form fields, for example)
 * @param {string} tagname the string name of the html element, (eg DIV or INPUT)
 * @param {string} type the type field of the form element (eg password, input, or hidden)
 * @return {boolean} whether the element described is an input
 * @private
 */
Solstice.BackButton.isTextField = function (tagname, type) {
    if (tagname == 'TEXTAREA') { return true; }
    if ((tagname == 'INPUT') && (!type || type.toLocaleLowerCase() == 'text' || type.toLocaleLowerCase() == 'password')) { return true; };
    return false;
}


/*********************
 * @class Methods for discovering the geometry and position of elements
 * @constructor
 */
Solstice.Geometry = function () {};

/**
 * Calculate top offset of the given element.
 * @param {htmlElement} the element whose offset we want to determine
 * @return {int} the offset of the given element in pixels
 */
Solstice.Geometry.getOffsetTop = function(obj) {
    var currTop = 0;
    if (obj.offsetParent) {
        currTop = obj.offsetTop;
        while (obj = obj.offsetParent) {
            currTop += obj.offsetTop;
        }
    }
    return currTop;
}

/**
 * Calculates the left offest of the given element.
 * @param {htmlElement} the element whose offset we want to determine
 * @return {int} the left offset of the given element in pixels
 */
Solstice.Geometry.getOffsetLeft = function(obj) {
    var currLeft = 0;
    if (obj.offsetParent) {
        currLeft = obj.offsetLeft;
        while (obj = obj.offsetParent) {
            currLeft += obj.offsetLeft;
        }
    }
    return currLeft; 
}

/**
 * Discovers the width of the viewable region of the page
 * @returns {int} the width of the viewable region in pixels
 */
Solstice.Geometry.getBrowserWidth = function() {
    if (window.innerWidth) {
        // all except Explorer
        return window.innerWidth;
    } else if (document.documentElement && document.documentElement.clientWidth) {
        // Explorer 6 Strict
        return document.documentElement.clientWidth;
    } else if (document.body) {
        // other Explorers
        return document.body.clientWidth;
    }
    return;
}
    
/**
 * Discovers the height of the viewable region of the page
 * @returns {int} the height of the viewable region in pixels
 */
Solstice.Geometry.getBrowserHeight = function () {
    if (window.innerHeight) {
        // all except Explorer
        return window.innerHeight;
    } else if (document.documentElement && document.documentElement.clientHeight) {
        // Explorer 6 Strict
        return document.documentElement.clientHeight;
    } else if (document.body) {
        // other Explorers
        return document.body.clientHeight;
    }
    return;
}

/**
 * Discovers the width of the entire page
 * @return {int} the width of the entire page in pixels
 */
Solstice.Geometry.getPageWidth = function () {
    if (document.body.scrollWidth > document.body.offsetWidth) {
        return document.body.scrollWidth;
    } else {
        return document.body.offsetWidth;
    }
}

/**
 * Discovers the height of the entire page
 * @return {int} the height of the entire page in pixels
 */
Solstice.Geometry.getPageHeight = function () {
    if (document.body.scrollHeight > document.body.offsetHeight) {
        return document.body.scrollHeight;
    } else {
        return document.body.offsetHeight;
    }
}



/**
 * Discovers the position of the user's horizontal scrollbar - the offset they've scrolled to horizontally. 
 * @return {int} the horizontal offset of the users viewport in pixels
 */
Solstice.Geometry.getScrollXOffset = function () {
    if (self.pageXOffset) {
        // all except Explorer
        return self.pageXOffset;
    } else if (document.documentElement && document.documentElement.scrollLeft) {
        // Explorer 6 Strict
        return document.documentElement.scrollLeft;
    } else if (document.body) {
        // all other Explorers
        return document.body.scrollLeft;
    }
}

/**
 * Discovers the position of the user's scrollbar - the offset they've scrolled to vertically.
 * @return {int} the vertical offset of the users viewport in pixels
 */
Solstice.Geometry.getScrollYOffset = function () {
    if (self.pageYOffset) {
        // all except Explorer
        return self.pageYOffset;
    } else if (document.documentElement && document.documentElement.scrollTop) {
        // Explorer 6 Strict
        return document.documentElement.scrollTop;
    } else if (document.body) {
        // all other Explorers
        return document.body.scrollTop;
    }
}

/**
 * Discovers the horizontal offset of the passed event
 * @param {event} the event to inspect
 * @return {int} the horizontal offset of the event in pixels
 */
Solstice.Geometry.getEventX = function (event) {
    if (self.innerHeight) {
        // all except Explorer
        return event.pageX;
    } else if (document.documentElement && document.documentElement.scrollLeft) {
        // Explorer 6 Strict
        return event.clientX + document.documentElement.scrollLeft;
    } else if (document.body) {
        // other Explorers
        return event.clientX + document.body.scrollLeft;
    }
    return;
}

/**
 * Discovers the vertical offset of the passed event
 * @param {event} the event to inspect
 * @return {int} the vertical offset of the event in pixels
 */
Solstice.Geometry.getEventY = function (event) {
    if (self.innerHeight) {
        // all except Explorer
        return event.pageY;
    } else if (document.documentElement && document.documentElement.scrollTop) {
        // Explorer 6 Strict
        return event.clientY + document.documentElement.scrollTop;
    } else if (document.body) {
        // other Explorers
        return event.clientY + document.body.scrollTop;
    }
    return;
}



/*********************
 * @class Event handling methods.
 * @constructor
 */
Solstice.Event = function(){};

/**
 * Adds the given function as an event handler on the given dom element.
 * See http://www.w3.org/TR/DOM-Level-3-Events/events.html#Events-EventTarget-addEventListener for more info on the "useCapture" arg
 * @param {htmlElement} obj the dom element to attach the event to
 * @param {string} evtType the event to attach to (eg, Click, MouseOver)
 * @param {function} fn a function reference
 * @param {boolean} useCapture some proprietary boolean about how events are propagated through these handlers.
 * @type void
 */
Solstice.Event.add = function (obj, evtType, fn, useCapture) {
    // Just pass off to Yahoo UI.
    return YAHOO.util.Event.addListener(obj, evtType, fn);
}

/**
 * Removes the given function as an event handler on the given dom element.
 * @param {htmlElement} obj the dom element to attach the event to
 * @param {string} evtType the event to attach to (eg, Click, MouseOver)
 * @param {function} fn a function reference
 * @param {boolean} useCapture some proprietary boolean about how events are propagated through these handlers.
 * @type void
 */
Solstice.Event.remove = function (obj, evtType, fn, useCapture) {
    return YAHOO.util.Event.removeListener(obj, evtType, fn);
}




/*****************************
 * @constructor
 * @class Element showing/hiding/selecting methods.
 */
Solstice.Element = function(){};

/**
 * Toggles the display of an element
 * @param {string} block id of the element to be shown/hidden
 * @type void
 */
Solstice.Element.toggleHidden = function (block) {
  var block_obj = document.getElementById(block);
  if (block_obj.style.display == "none")
      block_obj.style.display = "block";
  else
      block_obj.style.display = "none";
}

Solstice.Element.toggleInline = function (block) {
  var block_obj = document.getElementById(block);
  if (block_obj.style.display == "none")
      block_obj.style.display = "inline";
  else
      block_obj.style.display = "none";
}



/**
 * Hides an element
 * @param {string} block id of the element to be hidden
 * @type void
 */
Solstice.Element.hide = function (block) {
  document.getElementById(block).style.display = "none";
}

/**
 * Shows an element
 * @param {string} block id of the element to be shown
 * @type void
 */
Solstice.Element.show = function (block) {
  document.getElementById(block).style.display = "block";
}  

/**
 * selects an element, like a checkbox or multiselet widget.
 * @param {string} element_id id of the element to be selected
 * @type void
 */
Solstice.Element.select = function (element_id) {
    document.getElementById(element_id).checked = "checked";
}


/**
 * checks all of the checkboxes in a given groups
 * @param {htmlElement} field A form field, ie 'doc.form.somecheck'
 * @type void
 */
Solstice.Element.checkAll = function (field) {
  if (field.length) {
    for (i = 0; i < field.length; i++) {
      field[i].checked = true;
    }
  } else {
    field.checked = true;
  }  
}

/**
 * unchecks all of the checkboxes in a given groups
 * @param {htmlElement} field A form field, ie 'doc.form.somecheck'
 * @type void
 */
Solstice.Element.uncheckAll = function(field) {
  if (field.length) {
    for (i = 0; i < field.length; i++) {
      field[i].checked = false;
    }
  } else {
    field.checked = false; 
  }  
}  

/**
 * Sets the browsers focus to a particular element
 * @param {string} id id of the element to be focused
 * @type void
 */
Solstice.Element.focus = function (id) {
  if (id) {
    var input = document.getElementById(id);
    if (input && input.type != "hidden") input.focus();
  }
}

/**
 * Scrolls the browser viewport to the given element.
 * @param {string} id the ID of the element to scroll to
 * @type void
 */
Solstice.Element.scrollTo = function (id) {
  if (id) {
    var input = document.getElementById(id);
    if (input) {
      var pos = Solstice.Geometry.getOffsetTop(input) - 40;
      if (pos < 0) pos = 0;
      window.scrollTo(0, pos);
    }
  }
  return false;
}



/****************
 * @class Methods used by Solstice to manage Button-based navigation
 * @constructor
 */

Solstice.Button = function(){};

/**
 * A registry of actions that are attached to each Button
 * @private
 * @type array
 */
Solstice.Button.ClientActions = new Array();

/**
 * The currently selected button name
 * @private
 * @type string
 */
Solstice.Button.currentButton = "";

/**
 * The default button name
 * @private
 * @type string
 */
Solstice.Button.defaultButton = "";

/**
 * The upload button name
 * @private
 * @type string
 */
Solstice.Button.uploadButton  = "";


/**
 * This makes it so a link can submit a form.  The first argument
 * is the name of the 'button' that was/should be clicked.
 * @param {string} button_name the name of the button that was clicked
 * @return {unknown} the return value of the form's onsubmit method
 */
Solstice.Button.submit = function (button_name) {
    Solstice.Button.set(button_name);

    var form = document.getElementById(Solstice.getAppFormID());
    var retval = form.onsubmit();

    var element = document.getElementById(button_name);
    if (element) {

        var original_on_click = element.getAttribute("onclick");
        var original_href = element.getAttribute("href");

        element.setAttribute("onclick", "");
        element.setAttribute("href", "javascript:void(0)");

        window.setTimeout(function() {
            if (original_on_click) {
                element.setAttribute("onclick", original_on_click);
            }
            if (original_href) {
                element.setAttribute("href", original_href);
            }
        }, 60000);
    }

    if (retval){
        form.submit();
    }
    return retval;
}


/**
 * This is used to submit the form with a button, but to a non-default
 * url.  This is for switching applications, for example, while still 
 * running a submit.
 * @param {string} form_action the new url to post to
 * @param {string} button_name the name of the button to click/run client_actions on
 * @return {unknown} the return value of the forms onsubmit method
 */
Solstice.Button.alternateSubmit = function(form_action, button_name) {
    Solstice.Button.set(button_name);

    var form = document.getElementById(Solstice.getAppFormID());
    var action_temp = form.action;
    form.action = form_action;  
    
    var retval = form.onsubmit();
    if (retval) {
        form.submit();
    }
    form.action = action_temp;
    
    return retval;
}

Solstice.Button.keyPressSubmit = function (e, name, url) {
    if (!e) var e = window.event;
    if (e.keyCode) code = e.keyCode;
    else if (e.which) code = e.which;
    if(code == 13){
        if (url != null){
            Solstice.Button.alternateSubmit(url, name);
        }else {
            Solstice.Button.submit(name);
        }
        
        e.returnValue = false;
        e.cancelBubble = true;

        e.stopPropagation();
        e.preventDefault();
    }
}

/**
 * Submits the form to a new window, creating a popup while still running the 
 * solstice form post.
 * @param {string} button_name the name of the button to click/run client_actions on
 * @param {string} window_url the url to open/post to in the new window
 * @param {string} window_attributes your standard window.open popup window attributes
 * @param {string} window_name the name of the new window
 * @returns {unknown} the return value of the form's onSubmit method
 */
Solstice.Button.newWindowSubmit = function(button_name, window_url, window_attributes, window_name) {
    Solstice.Button.set(button_name);
    
    var form = document.getElementById(Solstice.getAppFormID());
    form.target = window_name;
   
    var action_temp = form.action
    if (window_url) {
        form.action = window_url;
    }

    var retval = form.onsubmit();
    if (retval) {
        window.open('', window_name, window_attributes);
        form.submit();
    }
    form.target = '';
    form.action = action_temp;
    
    return retval;
}

/**
 * This is used to prevent frivolous file uploads.  It clears all form entries befores submitting
 * unless the given button is the one that causes the submit.
 * @param {string} button_name the name of the upload button.
 * @type void
 */
Solstice.Button.clearOnAllExcept = function (button_name) {
    Solstice.Button.uploadButton = button_name;
}

/**
 * Used to clear the form.
 * @type void
 * @private
 */
Solstice.Button._clearUploadForm = function() {
    var sol_form = document.getElementById(Solstice.getAppFormID());
    sol_form.reset();

    Solstice.Button.setSelected(Solstice.Button.currentButton);
}

/**
 * Updates the html form's enctype to an upload type, so we only use multipart/form-data
 * when we really need to.
 * @type void
 */
Solstice.Button.setFormToFileUpload = function() {
    document.getElementById(Solstice.getAppFormID()).enctype  = 'multipart/form-data';
    document.getElementById(Solstice.getAppFormID()).encoding = 'multipart/form-data';
}

/**
 * Sets the button that is currently being operated on after a click.
 * @param {string} button the button name that is being worked on.
 * @type void
 */
Solstice.Button.set = function (button) {
        Solstice.Button.currentButton = button;
}    

/**
 * Sets the default button
 * @param {sting} button the button name that should be default.
 * @type void
 */
Solstice.Button.setDefault = function(button) {
    Solstice.Button.defaultButton = button;
}

/**
 * Sets the selected button
 * @param {string} button the name of the button that is selected
 * @type void
 */
Solstice.Button.setSelected = function(button) {
    // Hidden field holds the selected button name
    var selected_button = document.getElementById('solstice_selected_button');
    if (selected_button) selected_button.value = button;
}

/**
 * Registers a client action on a button, to be executed if the button is clicked
 * @param {string} button the name of the button to attach the action to
 * @param {function} action the function to be run
 * @type void
 */
Solstice.Button.registerClientAction = function (button, action) {
    if (action) Solstice.Button.ClientActions[button] = action;
}

/**
 * Runs the client action registered on the current/default button
 * @returns {unknown} The return value of the button's client action
 */
Solstice.Button.performClientAction = function() {
    if (Solstice.Button.currentButton == '') {
        Solstice.Button.currentButton = Solstice.Button.defaultButton;
        
        // Prevent form submissions with no selected button
        if (Solstice.Button.currentButton == '') return false;
    }
        
    var retval = true;
    var action = Solstice.Button.ClientActions[Solstice.Button.currentButton];
    if (typeof(action) != 'undefined' && action != '') {
        // Client action was registered...call it
        retval = eval(action);
    }
    
    if (retval == true) {
        Solstice.Button.setSelected(Solstice.Button.currentButton);

        // Special case for forms with file upload fields
        if (Solstice.Button.uploadButton != '' && Solstice.Button.uploadButton != Solstice.Button.currentButton) {
            Solstice.Button._clearUploadForm();
        }
    }
    Solstice.Button.set('');

    return retval;
}

/**
 * Used to prevent a form submission unless the given element has been filled out.
 * Usually used as a client_action, it focuses the given element if it has no content.
 * @param {string} id the html id of the element that must have content
 * @returns {boolean} whether the element has content
 */
Solstice.Button.stopClickUnlessContent = function (id) {
    var search = document.getElementById(id);
    if (search.value == "" || search.value.match(/^\s+$/)) {
        search.value = "";
        search.focus();
        return false;
    }
    return true;
}


/**
 * Uses a backgrouned/hidden button to navigate the user.
 * @param {string} button_name name of the button to click.
 * @private
 * @type void
 */
Solstice.Button.bounceForward = function(button_name) {
    if(document.getElementById(Solstice.getAppFormID())){
        Solstice.Button.submit(button_name);
    }else{
        setTimeout("Solstice.Button.bounceForward('"+button_name+"')", 10);
    }
}

/****************
 * @class Methods used by Solstice to handle common string functions 
 * @constructor
 */
Solstice.String = function(){};

/**
 * Return a string, after truncating to a specified length.
 * @param {string} the string to truncate
 * @param {integer} the length to truncate
 * @param {string} a string to append, if the string was truncated
 * @returns {string} the truncated string 
 */
Solstice.String.truncate = function(str, len, marker) {
    if (!len) len = 30;
    if (!marker) marker = '...';

    if (marker.length > len) return str;
    if (0 > len) return str;

    if (str.length > len) {
        str = str.substring(0, (len - marker.length));
        str += marker;
    }
    return str;
}

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
