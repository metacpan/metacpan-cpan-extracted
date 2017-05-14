//
// OpenThought
//
// Author: Eric Andreychek <eric@openthought.net>
//
// http://openthought.net
//
// The contents of this file are Copyright (c) 2000-2007 Eric Andreychek.  All
// rights reserved.  For distribution terms, please see the LICENSE file
// included with the OpenThought application.


/*
TODO
* Optimize for browsers
    - no need for channels with XMLHttpRequest browsers
    - limit channels for IE4/NS4
    - Better browser detection
* Add more caching, we're doing some work multiple times
* Add support for highlighting multiple items in a select-multiple
    - Possible via selectbox_highlight or selectbox_duplicate_value options


*/
function OpenThoughtConfig() {
//////////////////////////////////////////////////////////////////////////////
//
// Config section
//
// Change any of the following to your preference

/*
   Enable a log window so you can see what's going on behind the scenes.  If
   something in your app isn't working, try enabling this.  This can be very
   useful for debugging, but you probably want it disabled while your app is in
   production.  This, of course, won't work if your popup blocking software
   doesn't allow popups from the site you're running your application from.
*/
this.log_enabled = false;

/*
   What log level to run at.  You have the ability to enable lots of debugging
   output, only serious errors, and various levels in between.
     * options: debug, info, warn, error, fatal
*/
this.log_level = "debug";

/*
   Require what features in a browser.  If the feature is missing, go to the
   corresponding url.  OpenThought itself always requires a 4.0 browser DOM as
   a minimum, but your application may have more specific requirements.
    * options:  40dom -- Needs to have a basic 4.0 browser DOM (needed for OT)
                htmlrewrite -- Needs to support innerHTML
                xmlhttp -- Must support XmlHttpRequest or XMLHTTP
                iframe -- Must support iframes (all but NS4)
                layer -- Must support layers (only NS4)
*/
this.require = { "40dom" : "http://openthought.net?rm=unsupported_browser" };

/* EXPERIMENTAL
   The default request type for communications with the server.  This can be
   overridded at any time by passing in either GET or POST as the first
   parameter to CallUrl().  The default is GET.  POST is not well tested.
     * options: GET or POST
*/
this.http_request_type = "GET"

/*
   The type of channel to use for communicating with the this.browser.  Normally,
   OpenThought will attempt to use the XMLHttpRequest or XMLHTTP functions
   available in recent browsers, then fall back to iframes if the browser
   doesn't support those newer options.  However, XMLHttpRequest and XMLHTTP
   have a limitation -- for any given request, they can only parse data sent
   from the server once, doing so after the request is complete.  Iframes parse
   data as it's sent from the server, and can do so as many times as desired
   for any given request.  XMLHttpRequest/XMLHTTP are fine for most
   uses, but some applications may benefit from being able to have the browser
   receive data a number of times throughtout a single request (ie, irc and
   other realtime chat applications, or a log tailing app).
     * options: auto or iframe
*/
this.channel_type = "auto"

/*
   Normally, the channel used to communicate with the server is invisible.  The
   curious may wish to see whats going on inside it (or perhaps need it for
   debugging).  Enabling the following will make the channel visible.  This only
   works when the channel is an iframe.

   For now, the only way to see the JavaScript being inserted into the channel
   is to right-click the visible iframe and hit 'View Source'.
*/
this.channel_visible = false

/*
   When using iframes and layers, the typical way to send data to the server
   involves using a 'document.location.replace()'.  This means the requests
   aren't being stored in the browser history.  So, the back button will take
   you to the previous *page*, not the previous AJAX request.  This is often
   what people want.  This sometimes isn't what people want :-) Set to 'true'
   to not add AJAX requests to the browser's history, set to 'false' to have
   them added to the history.
     * options: true or false
*/
this.url_replace = true;

/*
   During any call to the server (via CallUrl and FetchHtml), assume the script
   is located in this directory (ie, the file/dir you pass in is relative to
   this path).  If there's no trailing slash, it will add one.  This config
   option can be overridden by beginning the url with 'http' or '/'.

*/
this.url_prefix = "";

/*
   Aside from Netscape 4, all browsers which receive text into a select
   box resize that select box to the width of the longest entry.
   Select box resizing is neat, but sometimes it ends up being much to
   big, and can adversly affect other parts of your visual layout.
   This option allows us to modify the size of text going into a
   select box, so the browser doesn't make the select box too big.
     * options: Any number, or 0 for unlimited resizing
*/
this.selectbox_max_width = "30"

/*
   If the text in a selectbox needs to be resized to fit (due to
   selectbox_max_width), replace the removed text with the following string to
   make it clear that the string was trimmed.
*/
this.selectbox_trim_string = ".."

/*
   Sending in an array reference to a select list will add a single row.  Do
   you want that row to be appended to the existing list of items, or to
   overwrite all the existing data in the select list?  The default mode is
   to append.
    * options: append or overwrite
*/
this.selectbox_single_row_mode = "append"

/*
   Sending in a reference to an array of arrays to a select list will add
   multiple rows.  Do you want that data to be appended to the existing list
   of items, or to overwrite all the existing data in the select list?  The
   default mode is to overwrite.
    * options: append or overwrite
*/
this.selectbox_multi_row_mode = "overwrite"

/* NOTE: selectbox_duplicate_value NOT YET IMPLEMENTED
   TODO: For this to work, we'll probably need to send the data as an array of
   arrays
   What to do if items sent into a selectbox has a value of an item which
   already exists in that selectbox.
    * options:
        - smart: If data is received, where a value in it matches a value
          already in the select list, highlight the item.  If the value
          matches, but the text is different, change the text currently in the
          select list to match.  If either of the above is done, and we receive
          additional data for the list, always append rather than overwrite.
          If none of the above is the case, fall back to checking the current
          select list mode (append or overwrite).
        - default-to-mode: Default to the current value of the single_row_mode
          or multi_row_mode, and display the item as a new element in the list.
this.selectbox_duplicate_value = "smart"
*/

/*
   The value a checkbox will return if it is checked, and no value is
   assigned to the checkbox (via the value= attribute).  This is *not*
   applied to radio buttons, radio buttons return their value attribute, a
   required attribute, when true.
     * options: Any string
*/
this.checkbox_true_value = "1"

/*
   The value a checkbox will return if it isn't checked.  This is also
   applied to radio buttons if none of the radio buttons are selected.
     * options: Any string
*/
this.checkbox_false_value = "0"

/*
   The value a group of radio buttons will return if none of them are
   selected.
     * options: Any string
*/
this.radio_null_selection_value = ""


/*
   Should new data being sent to the browser overwrite, or be appended to,
   existing data?  This does not apply to select boxes, checkboxes, radio
   buttons, and images.
    * options: append or overwrite

*/
this.data_mode = "overwrite"



//
// End Config section (ie, stop changing stuff)
//////////////////////////////////////////////////////////////////////////////






// If there is a function named "OpenThoughtConfigLocal", we've been provided
// with a customized set of config options.... use them overtop of the ones
// listed here.  To work, it *must* be loaded before this file is, it won't be
// noticed otherwise.
var local_options = "";

if(typeof(OpenThoughtConfigLocal) == "function") {
    local_options = new OpenThoughtConfigLocal();
    if (local_options != "") {
        for ( option in local_options ) {
            this[option] = local_options[option];
        }
    }
}

// This will inform us if a given option is included in our list of
// requirements
this.Require = function(param) {
    if (this.require[param]) {
        return this.require[param];
    }
}

}
// Yummy
var OpenThought = new OpenThought();
OpenThought.browser.VerifyRequirements();

//////////////////////////////////////////////////////////////////////////////
//
// OpenThought Class
//
// Okay, this code barely fits on the screen as is... we're just going to have
// to remember that the following is within the 'OpenThought' class, as I
// really don't want to have to push everything over another 4 spaces.  I may
// change my mind on that :-)

function OpenThought() {
this.config       = new OpenThoughtConfig();
this.browser      = new OpenThoughtBrowser(this.config);
this.log          = new OpenThoughtLog(this.config.log_enabled, this.config.log_level);
this.communicator = new OpenThoughtCommunicator(this.browser, this.config, this.log);
this.util         = new OpenThoughtUtil();

var undefined;

// Change to an alternate url, typically because something isn't supported
this.Url = function(url, replace) {
    if (replace) {
        location.replace( url );
    }
    else {
        location.href = url;
    }
}

// Call a url in the background
this.CallUrl = function() {

    this.log.info("Received ajax event");

    var eventType = "data";

    return this.Send(arguments, "ajax");
}

// This loads a new page in the content frame
this.FetchHtml = function() {

    this.log.info("Received ui event");

    var eventType = "ui";

    return this.Send(arguments, "ui");
}

// Called data has arrived from the server
this.ServerResponse = function(content) {

    this.log.info("Received response from server");

    // Display everything if we received a decent response
    if (content != null)
    {
        for (field_name in content) {
            this.SetElement(field_name, content[field_name]);
        }
        this.log.info("All fields filled. -============================-");

    }

    return;
}

// Called by the server whenever it's finished sending the response
this.ResponseComplete = function(channel) {

    return this.communicator.Complete(channel);
}


// Digs through the browsers DOM hunting down a particular element
this.FindElement = function(element, doc) {

    this.log.debug("Searching for element [" + element + "]");

    var p,i,object;

    if(!doc) {
        doc = document;
    }

    if((p = element.indexOf("?")) > 0 && parent.frames.length) {
        doc = parent.frames[element.substring(p+1)].document;
        element = element.substring(0,p);
    }

    if(!(object = doc[element]) && doc.all) {
        object = doc.all[element];
    }

    for (i=0; !object && i < doc.forms.length; i++) {
        object = doc.forms[i][element];
    }

    for(i=0; !object && doc.layers && i < doc.layers.length; i++) {
        object = this.FindElement(element, doc.layers[i].document);
    }

    if(!object && document.getElementById) {
        object = doc.getElementById(element);
    }

    if (this.config.log_enabled) {
        if (object) {
            if((!object.type) && (object.length > 0)) {
                object.type="radio";
            }

            if(( object.type ) && (object.type != "button" )) {
                this.log.debug("Found form element [" + object.name + "] of type [" + object.type + "].");
            }
            else if( typeof(object.innerHTML) == "string") {
                this.log.debug("Found HTML element [" + object.id + "] of type [" + object.tagName + "].");
            }
            else if((object["tagName"]) && (object["tagName"] == "IMG")) {
                this.log.debug("Found image element [" + object.name + "] with src [" + object.src + "].");
            }
            else {
                this.log.debug("It's here, but I dunno what it is");
            }
        }
        else {
            // We'll log as error in the calling function
            this.log.info("Unable to find [" + element + "].");
        }
    }

    return object;
}

// Initialize and populate the Select list
this.FillSelect = function(element, data) {

    this.SelectboxTextTrim = function(text) {
        if ((this.browser.version != "NS4") && (this.config.selectbox_max_width != 0)) {
            if (text && text.length > this.config.selectbox_max_width) {
                text = text.substr(0,this.config.selectbox_max_width) + this.config.selectbox_trim_string;
            }
        }
        return text;
    }

    var i;

    // Prevent ourselves from having to do the element.options lookup too many
    // times
    var element_options = element.options;

    // Null means we want to clear out the select list
    if (data == null) {
        this.log.info("Received null, clearing [" + element.name + "]");
        while (element_options.length) element_options[0] = null;
    }

    // If sent a string, and not an array, we just need to highlight an
    // existing item in the list, and not add anything
    else if(typeof data == "string") {
        this.log.debug("Attempting to highlight [" + data + "] in [" + element.name + "]");
        for (i=0; i < element_options.length; i++) {
            if( element_options[i].value == data ) {
                this.log.info("Found [" + data + "] in [" + element.name + "], highlighting.");
                element.selectedIndex = i;
            }
        }

    }
    // Actually add the items we were sent to the list
    else {
        // Clear any current OPTIONS from the SELECT (but only if overwrite is
        // selected)
        if(( (typeof data[0] == "string") && (data[0] != "") &&
            ( data.constructor != Object ) &&
            ( this.config.selectbox_single_row_mode == "overwrite" )) ||

           ( (typeof data[0] != "string") && (data[0] != "" ) &&
            ( data.constructor != Object ) &&
            ( this.config.selectbox_multi_row_mode == "overwrite" ))) {

            while (element_options.length) element_options[0] = null;
            if((data.length == 1) && (data[0] == "")) {
                return;
            }
        }

        if ( data.constructor == Array ||
             data.constructor.toString().match(/Array/) ) {
            // For each record...
            for (var i=0; i < data.length; i++) {
                var text;
                var value;

                if (typeof data[0] == "string") {
                    text  = data[0];
                    value = data[1];

                    if (data[1] == "") {
                        value = text;
                    }
                    i++;
                }
                else if (data[i].constructor == Object ||
                         data[i].constructor.toString().match(/Object/)) {
                    for (text in data[i]) {
                        value = data[i][text];
                    }
                }
                else if (data[i].constructor == Array ||
                         data[i].constructor.toString().match(/Array/) ) {
                    text = data[i][0];
                    value = data[i][1];

                    if (data[i][1] == "") {
                        value = text;
                    }
                }
                else {
                    this.log.error("Unknown data type sent into select list.");
                }

                text = this.SelectboxTextTrim(text);
                element_options[element_options.length] = new Option(text, value);
            }
        }
        else if (data.constructor == Object ||
                 data.constructor.toString().match(/Object/) ) {
            var text;
            var value;
            for (text in data) {
                value = data[text];
            }
            text = this.SelectboxTextTrim(text);
            element_options[element_options.length] = new Option(text, value);
        }
        else {
            this.log.error("Unknown data type sent into select list");
        }
        this.log.info("Adding data to [" + element.name + "].");
    }
}

// Put values into html
this.FillHtml = function(element, data)
{
    if ( data == null ) {
        this.log.info("Received null, emptying [" + element.id + "].");
        element.innerHTML = "";
    }
    else {
        if (this.config.data_mode == "append") {
            this.log.info("Filling [" + element.id + "] with [" + data + "] (append).");
            if (typeof(element.outerHTML) == "string") {
                 element.outerHTML = element.outerHTML.replace(/(<.*?>)(?:.|\n)*(<\/.*?>)/,"$1"+element.innerHTML+data+"$2");
            }
            else {
                 element.innerHTML += data;
            }
        }
        else {
            this.log.info("Filling [" + element.id + "] with [" + data + "] (overwrite).");
            if (typeof(element.outerHTML) == "string") {
                element.outerHTML = element.outerHTML.replace(/(<.*?>)(?:.|\n)*(<\/.*?>)/,"$1"+data+"$2");
            }
            else {
                element.innerHTML = "";
                element.innerHTML = data;
            }
        }
    }
}

// Put values into a text form field
this.FillText = function(element, data)
{
    if ( data == null ) {
        this.log.info("Received null, emptying [" + element.name + "].");
        element.value = "";
    }
    else {
        if (this.config.data_mode == "append") {
            this.log.info("Filling [" + element.name + "] with [" + data + "] (append).");
            element.value += data;
        }
        else {
            this.log.info("Filling [" + element.name + "] with [" + data + "] (overwrite).");
            element.value = data;
        }
    }

}

// Select or unselect a checkbox form field
this.FillCheck = function(element, data)
{
    this.log.info("Filling [" + element.name + "] with [" + data + "].");

    if(((data == null) || (data == "false") || (data == "FALSE") || (data == "False") ||
       (data == "unchecked") || (data < "1") ||
       (data == this.config.checkbox_false_value )) &&
       (data != this.config.checkbox_true_value ))
    {
        element.checked = false;
    }
    else
    {
        element.checked = true;
    }
}

// Select a radio button
this.FillRadio = function(element, value)
{
    this.log.info("Filling [" + element.name + "] with [" + value + "].");

    for(var i=0; i<element.length; i++) {
        if ( typeof(value) == "object" ) {
            if ( value[element[i].value] ) {
                this.FillCheck(element[i], value[element[i].value]);
            }
        }
        else {
            if(element[i].value == value) {
                element[i].checked = true;
            }
        }
    }
}

// Change an image or image properties
this.FillImage = function(image, data) {

    this.log.info("Filling [" + image.name + "] with [" + data + "].");

    // If we were just sent a string, it contains the url for a new image
    if (typeof data == "string") {
        image.src = data;
    }

    // If we were sent an object, it contains a number of image properties,
    // may or may not include a new url
    else if (typeof data == "object") {

        // If there is a src, change it first
        if (data["src"]) {
            image.src = data["src"];
        }

        for (var property in data) {

            // Don't do the src twice
            if (property != "src") {
                image[property] = data[property];
            }
        }
    }
}

// Take the data we received, and put it in it's appropriate field
this.SetElement = function(fieldName, fieldValue)
{
    var object = this.FindElement(fieldName);

    if( !object ) {
        this.log.error("Error: there is no object named '" + fieldName + "'");

        return;
    }

    // This is kinda silly, but radio buttons don't seem to return an
    // object.type, in some versions of Mozilla and IE
    if((!object.type) && (object.length > 0))
    {
        object.type="radio";
    }

    if(( object.type ) && (object.type != "button" )) {
        switch (object.type)
        {
            case "select":
            case "select-one":
            case "select-multiple":
                this.FillSelect(object,fieldValue);
                break;

            case "text":
            case "password":
            case "textarea":
            case "hidden":
            case "file":
                this.FillText(object, fieldValue);
                break;

            case "checkbox":
                this.FillCheck(object, fieldValue);
                break;

            case "radio":
                this.FillRadio(object, fieldValue);
                break;
        }
    }
    else if( typeof(object.innerHTML) == "string") {
        this.FillHtml(object, fieldValue);
    }
    else if((object["tagName"]) && (object["tagName"] == "IMG")) {
        this.FillImage(object, fieldValue);
    }
    else {
        this.log.error("Error: received unknown field '" + fieldName + "'");
        return false;
    }

    return true;
}


// Retrieves the current value and type of an element
this.GetElement = function(element, type)
{
    var element_value;
    var element_type;

    var object = this.FindElement(element);

    if( !object ) {
        this.log.error("Error: cannot find an object named '" + element + "'\n" +
                  "Be sure you spelled it correctly.  Also, your form " +
                  "elements must be within form tags.");
        return false;
    }

    // This is kinda silly, but radio buttons don't seem to return an
    // object.type in some browsers
    if((!object.type) && (object.length > 0)) {
        object.type="radio";
    }

    if( object.type ) {
        element_type = "fields";

        switch (object.type)
        {
            case "text":
            case "password":
            case "textarea":
            case "hidden":
            case "file":
                element_value = this.TextValue(object);
                break;

            case "select":
            case "select-one":
                element_value = this.SelectValue(object);
                break;

            case "select-multiple":
                element_value = this.SelectMultipleValue(object);
                break;

            case "checkbox":
                element_value = this.CheckboxValue(object);
                break;

            case "radio":
                element_value = this.RadioValue(object);
                break;
        }
    }
    else if( typeof(object.innerHTML) == "string") {
        element_type = "html";
        element_value = object.innerHTML;
    }
    else if((object["tagName"]) && (object["tagName"] == "IMG")) {
        element_type = "images";
        element_value = object.src;
    }

    if (type && type == element_type) {
        return [ element_type, element_value ];
    }
    else if (type && type != element_type) {
        return [false, false];
    }
    else {
        return [ element_type, element_value ];
    }
}

// Value of text/password/textarea/hidden/file (filename only) fields
this.TextValue = function(element) {
    return  element.value;
}

// Figure out which option is selected in our Select list
this.SelectValue = function(element)
{
    if(element.selectedIndex >= 0) {
        return element.options[element.selectedIndex].value;
    }
    else {
        return "";
    }
}

// Figure out which options are selected in our Select Multiple list
this.SelectMultipleValue = function(element)
{
    var values = new Array();

    if(element.selectedIndex >= 0) {
        for(var i=0; i < element.length; i++) {
            if ( element.options[i].selected == true ) {
                values[values.length] = element.options[i].value;
            }
        }
        return values;
    }
    else {
        return "";
    }
}

// Figure out which option is selected in our checkbox
this.CheckboxValue = function(element)
{
    if(element.checked == true)
    {
        if(element.value == "on")
        {
            return this.config.checkbox_true_value;
        }
        else
        {
            return element.value;
        }
    }
    else
    {
        return this.config.checkbox_false_value;
    }

}

// Figure out which option is selected in our radio button
this.RadioValue = function(element)
{
    var values = new Array();

    // This occurrs if there is only one radio button
    if (element.length == null ) {
        if(element.checked == true) {
            values[values.length] = element.value;
        }
    }
    // More than one button
    else {

        for (var i=0, n=element.length; i < n; i++)
        {
            if(element[i].checked == true)
            {
                values[values.length] = element[i].value;
            }
        }
    }

    if ( values.length > 0 ) {
        if ( values.length == 1 ) {
            return values[0];
        }
        else {
            return values;
        }
    }
    else {
        return this.config.radio_null_selection_value;
    }
}

// Takes a fieldname as an argument, and gives that field the focus
this.Focus = function(element)
{
    var object  = this.FindElement(element)

    // If no object is found with the name "element", then either they typed in
    // wrong, or it's an anchor.  There's no way to know for sure, so let's
    // guess the latter.  This should make debugging fun.

    if( !object ) {
        if ( document.anchors[element] ) {
            this.log.info("Jumping to anchor tag ['" + element + "'].");
            location.hash = "#" + element;
        }
        else {
            this.log.error("Can't seem to find the element '" + element + "', unable to focus.");
        }
    }
    else {
        this.log.info("Focusing form element ['" + element + "'].");
        object.focus();
    }
}

// Do the call to the server
this.Send = function(args, eventType) {

    this.log.debug("Preparing to send.");

    var params = this.ParseParams(args);

    return this.communicator.Beam(params.url, params.args, params.method, eventType );
}

this.ParseParams = function(args) {
    var start_index = 0;
    var params = new Object;
    params["args"] = new Array;

    if (args[0] == "GET") {
        params["method"] = args[0];
        params["url"]    = args[1];
        start_index = 2;
    }
    else if (args[0] == "POST") {
        params["method"] = args[0];
        params["url"]    = args[1];
        start_index = 2;
    }
    else {
        params["method"] = this.config.http_request_type;
        params["url"]    = args[0];
        start_index = 1;
    }

    for (var i = start_index; i < args.length; i++) {
        // We allow arrays for parameters, test for them here
        if (typeof(args[i]) == "object" && args[i].length) {
            params["args"] = params["args"].concat(args[i]);
        }
        else {
            params["args"][params["args"].length] = args[i];
        }
    }

    return params;
}

}

//////////////////////////////////////////////////////////////////////////////////
//
// OpenThoughtCommunicator Class
//

function OpenThoughtCommunicator(browser_l, config_l, log_l) {
this.browser = browser_l;
this.config = config_l;
this.log = log_l;
var channels = new Array;

this.Beam = function(url, args, method, eventType) {

    var params;

    // Add the url_prefix if we have one
    if (( this.config.url_prefix != "" ) &&
        ( url.substr(0, 6) != "http://" ) &&
        ( url.substr(0, 1) != '/' )) {

        seperator = "";

        if (this.config.url_prefix.substr(this.config.url_prefix.length-1) != '/') {
            seperator = '/';
        }
        url = this.config.url_prefix + seperator + url;
    }


    // If there's no ? in the url to seperate the host from the params, add one
    if (method == "GET") {
        if(url.indexOf("?") == -1) {
            url = url + "?";
        }
        else {
            url = url + "&";
        }

        // The browser generally handles this sanely for UI events
        if (eventType != "ui") {
            // Die cache die
            var d = new Date();
            url += "_u=" + d.getTime() + '&';
        }

    }

    // ui events use "href", which keeps the page in the history, allowing the
    // back button to work
    if (eventType == "ui") {
        // TODO: Allow POST via FetchHtml
        this.log.info("Send (ui): " + params + " to " + url);
        if (params == "") {
            url = url.substring(0, url.length-1);
        }
        params = this.Hash2GetParam(this.GenParams(args, eventType ));
        document.location.href = url + params;
        return;
    }

    var channel_info = this.getOpenChannel();
    var type    = channel_info["type"];
    var channel = channel_info["channel"];

    // If using XMLHttp, the parameters still look like a typical query string,
    // we don't need to fake a form submission (yay)
    if (method == "POST" && type == "XMLHttp" && eventType != "ui") {
        params = this.Hash2GetParam(this.GenParams(args, eventType ));
    }
    else if (method == "POST") {
        params = this.Hash2PostParam(this.GenParams(args, eventType ));
    }
    else {
        params = this.Hash2GetParam(this.GenParams(args, eventType ));
    }

    this.log.info("Sending AJAX Request --");
    this.log.info("Url: " + url);
    this.log.info("Params: " + params);

    // Good, we seem to be able to use XMLHTTPRequest
    if (type == "XMLHttp" ) {
        if (method == "GET") {
            url = url + params;
        }
        channel.open(method, url, true);
        channel.onreadystatechange=function() {
            // See if the readyState is 'loaded'
            if (channel.readyState == 4) {
                // only eval if 'OK', otherwise silly things will happen
                if (channel.status == 200 && channel.responseText) {

                    // Ignore the <script> tags, they're only necessary when
                    // using iframes

                    // FIXME: This doesn't handle multiple print statements from within the server-side
                    // OT, that'd generate multiple script tags.
                    // Also, we should probably call ResponseComplete() manually, as that's handled by the
                    // onLoad() when iframes are being used.
                    var javascript = channel.responseText;
                    var front_regex = /\r <OT><body onLoad="parent.OpenThought.ResponseComplete\(self\)"><\/body><script>/g;
                    var back_regex  = /<\/script><OT> \r/g;
                    javascript = javascript.replace( front_regex, "" );
                    javascript = javascript.replace( back_regex, "" );

                    OpenThought.log.info("Received: " + javascript);
                    eval(javascript);
                }
                else {
                    OpenThought.log.fatal("There was a problem accessing the url. Status: " + channel.status);
                }
            }
        }
        if ( method == "POST" ) {
            channel.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
            channel.setRequestHeader('Connection','close'); // This apparently fixes some Firefox issues
            channel.send(params);
        }
        else {
            channel.send(null);
        }
    }
    // Okay, fallback to iframes
    else {
        var content;
        if (this.browser.version == "IE4") {
            content = channel.document;
        }
        else if (channel.contentDocument) {
            content = channel.contentDocument;
        }
        else if ( channel.contentWindow ) {
            content = channel.contentWindow.document;
        }
        else {
            this.log.error("Unable to find the channel document.");
        }

        // This intermittantly fails on Firefox (content.forms['OpenThought']
        // is undefined).  I haven't been able to reproduce it on other
        // browsers, Firefox won't hit this when using XMLHttpRequest.
        // While I'm beginning to think it's a bug in Firefox, it still might
        // be good to test this more.
        if (method == "POST") {
            content.open();
            content.write(params);
            content.close();

            var form = content.forms['OpenThought'];
            form.action = url;
            form.submit();
        }
        else {
            if ( this.channel_url_replace == false ) {
                content.location.href = url + params;
            }
            else {
                if (this.browser.version == "IE4" ) {
                    content.location.replace(url + params);
                }
                else if (content && content.location && content.location.replace) {
                    content.location.replace( url + params );
                }
                else {
                    //channel.src = '';
                    channel.src = url + params;
                }
            }
        }
    }
    return true;
}

// Build a single hash containing all the data to be sent to the server
this.GenParams = function(elements, eventType) {

    this.log.debug("Building payload");

    var param         = new Object();
    param["_fields"]  = new Array();
    param["_html"]    = new Array();
    param["_images"]  = new Array();
    param["_expr"]    = new Array();

    // The first parameter is the form url
    for(var i=0; i < elements.length; i++) {

        // If the parameter contains an equal sign (=), it's an expression
        if(elements[i].indexOf("=") != -1) {
            var keyval               = elements[i].split("=");
            param[keyval[0]]         = keyval[1];
            param["_expr"][param["_expr"].length] = keyval[0];
            this.log.info("Found expression [" + elements[i] + "].");
        }
        // Otherwise, check to see if they want all fields that start with a particular string
        else if (elements[i].indexOf("*") != -1) {

            var pos;
            var pattern;

            // Glob char is at the beginning of the string
            if ( elements[i] == '*' ) {
                pos = "all";
                this.log.info("Found * as only globbing character.");
            }
            else if (elements[i].indexOf("*") == 0) {
                pos = "start";
                pattern = elements[i].substring(1);
                this.log.debug("Found pattern [" + pattern + "] with globbing at [" + pos + "].");

            }
            // Glob char is at the end of the string
            else if (elements[i].indexOf("*") == elements[i].length-1) {
                pos = "end";
                pattern = elements[i].substring(0, elements[i].length-1);
                this.log.debug("Found pattern [" + pattern + "] with globbing at [" + pos + "].");
            }
            // Glob char is in the middle of the string (currently unsupported)
            else {
                pos = "middle";
                pattern = elements[i].split("*");
                this.log.debug("Found patterns [" + pattern[0] + "] and [" + pattern[1] + "] with globbing at [" + pos + "].");
            }

            for (var form_num=0; form_num < document.forms.length; form_num++) {

                for (var element_num=0; element_num < document.forms[form_num].elements.length; element_num++ ) {

                    var element = document.forms[form_num].elements[element_num];
                    var found = false;
                    switch ( pos ) {
                        case "all":
                            found = true;
                            break;

                        case "start":
                            // Verify the element name is >= the length of the
                            // pattern, then test and see if the pattern is at
                            // the end of the string
                            if (element.name.length >= pattern.length &&
                               (element.name.substring(
                                    element.name.length - pattern.length ) == pattern )) {
                                found = true;
                            }
                        break;

                        case "end":
                            // A simple test to see if the pattern is at the
                            // beginning of the string
                            if (element.name.indexOf(pattern) == 0) {
                                found = true;
                            }
                        break;

                        case "middle":
                            // This looks like a mess, but it's just a
                            // combination of the above two tests.  Except that
                            // we're dealing with two patterns, one on each
                            // side of the globbing character
                            if ((element.name.indexOf(pattern[0]) == 0) &&
                               ((element.name.length > (pattern[0].length + pattern[1].length )&&
                               (element.name.substring(
                                    element.name.length - pattern[1].length ) == pattern[1] )))) {
                                found = true;
                            }
                        break;
                    }
                    if (found) {
                        this.log.info("Matched element name [" + element.name + "].");
                        var element_info = OpenThought.GetElement(element.name);

                        // GetElement returns false if it can't find the element
                        if (element_info) {
                            param[element.name] = element_info[1];
                            param["_" + element_info[0]][param["_" + element_info[0]].length] = element.name;
                        }
                    }
                }
            }
        }
        // Otherwise, it's an input, html, or image element
        else {
            var element_info = OpenThought.GetElement(elements[i]);

            this.log.info("Adding param [" + elements[i] + "] as a field (input/html/image/etc).");

            // GetElement returns false if it can't find the element
            if (element_info) {
                param[elements[i]] = element_info[1];
                param["_" + element_info[0]][param["_" + element_info[0]].length] = elements[i];
            }
        }
    }

    if (eventType != "ui") {
        param["_event_type"]  = eventType;
    }

    this.log.debug("Payload ready.");

    return param;
}

// Convert our parameter hash into a set of GET params
this.Hash2GetParam = function(hash)
{
    this.log.debug("Creating get parameter");

    var packet = "";

    for (var child in hash) {
        if(typeof(hash[child]) == "object") {
            for(var grandchild in hash[child])
            {
                if (typeof(hash[child][grandchild]) != "function") {
                    packet += escape(child) + "=" +
                              escape(hash[child][grandchild]) + "&";
                }
            }
        }
        else {
            packet += escape(child) + "=" +
                      escape(hash[child]) + "&";
        }
    }

    // Replace '+' characters with %2B
    packet = packet.replace(/\+/g, "%2B");

    // Drop the trailing &
    packet = packet.substr(0, packet.length - 1);

    this.log.debug("Finished creating get parameter");
    return packet;
}

// Convert our parameter hash into a form for POST params
this.Hash2PostParam = function(hash)
{
    this.log.debug("Creating post params");

    var form = '<html><head><title></title></head><body><form action="" name="OpenThought" method="post" target="">';

    for (var child in hash) {
        if(typeof(hash[child]) == "object") {
            for(var grandchild in hash[child]) {
                form += '<input type="hidden" name="' + escape(child) +
                        '" value="' + escape(hash[child][grandchild]) + '">';
            }
        }
        else {
            form += '<input type="hidden" name="' + escape(child) +
                    '" value="' + escape(hash[child]) + '">';
        }
    }

    form += '</form></body></html>';

    this.log.debug("Finished creating post params");
    return form;
}


this.getOpenChannel = function() {

    var channelName;

    for(var i=0; i < channels.length ;i++) {
        if(! channels[i]["busy"]) {
            channels[i]["busy"] = true;
            this.log.info("Reusing channel [" + i + "].");
            return channels[i];
        }
    }

    var channel = new Object;

    var id       = channels.length;
    channels[id] = channel;

    channels[id]["busy"]    = true;
    var channel_info = this.createChannel(id);
    channels[id]["channel"] = channel_info[0];
    channels[id]["type"]    = channel_info[1];

    return channels[id];
}

this.createChannel = function(channelName) {
    var channel = false;

    if (this.config.channel_type != "iframe") {

        // For the XMLHttp related tests, we need to use try/catch (largely because
        // of IE and varying ActiveX objects).  Unfortunatly, both NS4 and IE4
        // consider 'try' to be invalid syntax.  The best way I know of to handle
        // this is to use eval to hide the 'try' statements from those browsers.

        // native XMLHttpRequest object
        if(window.XMLHttpRequest) {
            eval("try { channel = new XMLHttpRequest(); } catch(e) { channel = false; }");
        }
        // IE/Windows ActiveX version
        else if(window.ActiveXObject && this.browser.version != "IE4") {
            eval("try { channel = new ActiveXObject('Msxml2.XMLHTTP'); } catch(e) { try { channel = new ActiveXObject('Microsoft.XMLHTTP'); } catch(e) { channel = false; } }");
        }

        // If we were able to use the XMLHttp related methods, good, go ahead and
        // return it now
        if ( channel ) {
            this.log.info("Created XMLHttpRequest/XMLHTTP channel");
            return [channel, "XMLHttp" ];
        }
    }

    var type;

    // Most of this layer/iframe code in this function was created by Brent Ashley
    // of AshleyIT for JSRS.  Used with permission.
    switch( this.browser.version ) {
        case 'NS4':
            channel = new Layer(100);
            channel.name = channelName;
            channel.clip.width = 100;
            channel.clip.height = 100;

            if (this.config.channel_visible) {
                channel.visibility = 'visible';
            }
            else {
                channel.visibility = 'hidden';
            }

            type = "layer";
            this.log.info("Created new channel [" + channelName + "], using layers for NS4");
        break;

        // If this gets called before the browser considers the web page
        // loaded, one will get a "Error 8000000a", which basically means it
        // doesn't like us changing stuff that's not ready yet.  That should
        // only ever happen when trying to call CallUrl while the page is
        // loading.  The best way to handle that is to put calls like that
        // within the body tag, using onLoad().
        case 'IE4':
            document.body.insertAdjacentHTML( "afterBegin", '<span id="SPAN' + channelName + '"></span>' );
            var span = document.all( "SPAN" + channelName );
            var html = '<iframe name="' + channelName + '" src=""></iframe>';
            span.innerHTML = html;
            span.style.display = 'none';
            channel = window.frames[ channelName ];

            if (this.config.channel_visible) {
                span.style.display = 'block';
            }
            else {
                span.style.display = 'none';
            }

            type = "iframe";
            this.log.info("Created new channel [" + channelName + "], using iframes for IE4");
        break;

/*
        case 'KNQ':
            var span = document.createElement('SPAN');
            span.id = "SPAN" + channelName;
            document.body.appendChild( span );
            var iframe = document.createElement('IFRAME');
            iframe.name = channelName;
            iframe.id = channelName;
            span.appendChild( iframe );
            channel = iframe;

            if (this.config.channel_visible) {
                span.style.display = block;
                iframe.style.display = block;
                iframe.style.visibility = visible;
                iframe.height = 20;
                iframe.width = 20;
            }
            else {
                span.style.display = none;
                iframe.style.display = none;
                iframe.style.visibility = hidden;
                iframe.height = 0;
                iframe.width = 0;
            }

            type = "iframe";
            this.log.info("Created new channel [" + channelName + "], using iframes for Konqueror");
        break;
*/

        // Handle Mozilla, IE>4, Safari, and folks last (most of these should
        // be handled by the XMLHTTP stuff, this is mostly in case somehow
        // their implementation is borked, or config.channel_type is set to
        // 'iframe')
        case 'W3C':
        case 'SFR':
        case 'KNQ':
        case 'OPR':
            var span = document.createElement('SPAN');
            span.style.display = 'none';
            span.id = "SPAN" + channelName;
            document.body.appendChild( span );
            var iframe = document.createElement('IFRAME');
            iframe.name = channelName;
            iframe.id = channelName;
            span.appendChild( iframe );
            channel = iframe;

            if (this.config.channel_visible) {
                iframe.width = 20;
                iframe.height = 20;
                iframe.frameBorder = 1;
            }
            else {
                iframe.width = 0;
                iframe.height = 0;
                iframe.frameBorder = 0;
                span.style.display = 'block';
            }

            type = "iframe";
            this.log.info("Created new channel [" + channelName + "], using iframes for Mozilla/Safari/Opera/IE5+");

        break;

    }

    return [channel, type];
}

this.Complete = function(channel) {

    if (channel.name && channel.name >= 0) {
        this.log.info('Freeing channel [' + channel.name + ']');
        channels[channel.name]["busy"] = false;
    }

    return true;
}

}

/////////////////////////////////////////////////////////////////////////////
//
// OpenThought Browser Check Class
//
function OpenThoughtBrowser(config_l) {

    this.w3c     = W3cCompat();
    this.version = Version();
    this.config  = config_l;

    function W3cCompat() {
        if (document.getElementById) {
            return true;
        }
        else {
            return false;
        }
    }

    function Version() {

        var version = "";

        // Test for browser types
        if (document.layers) {
            version = "NS4";
        }
        else if (document.getElementById) {

            // Obviously, this will break if the user changes who their browser appears
            // as.  At the moment, I'm not sure how else to do this, so we'll shoot for
            // the common case.  There *are* cases where Opera, Safari, and Konqueror
            // act differently than other browsers.
            if(window.opera) {
                version = "OPR";
            }
            else if(navigator.userAgent.indexOf("Safari")!=-1) {
                version = "SFR";
            }
            else if(navigator.userAgent.indexOf("Konqueror")!=-1) {
                version = "KNQ";
            }
            else {
                version = "W3C";
            }
        }
        else if (document.all) {
            version = "IE4";
        }
        else {
            version = "unknown";
        }
        return version;
    }

    this.Has = function (feature) {
        switch (feature) {
            case "htmlrewrite" :
                if ( typeof(document.body.innerHTML) == "string") {
                     return true;
                }
                else {
                     return false;
                }
                break;

            case "xmlhttp" :
                var channel = false;
                if(window.XMLHttpRequest) {
                    eval("try { channel = new XMLHttpRequest(); } catch(e) { channel = false; }");
                }
                else if(window.ActiveXObject && this.version != "IE4") {
                    eval("try { channel = new ActiveXObject('Msxml2.XMLHTTP'); } catch(e) { try { channel = new ActiveXObject('Microsoft.XMLHTTP'); } catch(e) { channel = false; } }");
                }
                if (channel) {
                    return true;
                }
                else {
                    return false;
                }
                break;

            case "layer" :
                if (document.layers) {
                     return true;
                }
                else {
                    return false;
                }
                break;

            case "40dom" :
                if (this.version != "unknown") {
                    return true;
                }
                else {
                    return false;
                }
                break;
            case "iframe" :
                // There has to be a better way to test for iframes
                if (this.version != "NS4") {
                    return true;
                }
                else {
                    return false;
                }
                break;
        }
    }

    this.VerifyRequirements = function() {
        for ( requirement in this.config.require ) {
            if (! this.Has(requirement) ) {
                OpenThought.Url(this.config.Require(requirement), true);
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
//
// OpenThought Log Class
//
// Inspired by Log4perl (thus Log4j)

function OpenThoughtLog(log_enabled, start_level) {

    var logWindow = false;
    var logLevels = new Object();
    logLevels["debug"] = 1;
    logLevels["info"]  = 2;
    logLevels["warn"]  = 3;
    logLevels["error"] = 4;
    logLevels["fatal"] = 5;

    var log_level = logLevels[start_level];

    this.debug = function (text) {
        if (!log_enabled || (logLevels["debug"] < log_level)) {
            return false;
        }

        return log("[debug] " + text);
    }
    this.info = function(text) {
        if (!log_enabled || (logLevels["info"] < log_level)) {
            return false;
        }

        return log("[info] " + text);
    }
    this.warn = function(text) {
        if (!log_enabled || (logLevels["warn"] < log_level)) {
            return;
        }

        return log("[warn] " + text);
    }
    this.error = function(text) {
        if (!log_enabled || (logLevels["error"] < log_level)) {
            return;
        }

        return log("[error] " + text);
    }
    this.fatal = function(text) {
        if (!log_enabled || (logLevels["fatal"] < log_level)) {
            return;
        }

        return log("[fatal] " + text);
    }

    function log(text) {
        if (!logWindow) initLogWindow();

        logWindow.document.write("<pre>" + ((new Date()).getTime().toString().substring(8)) + ": " +
                                 EscapeHtml(text) + "</pre>");

    }

    // Gets the debug window rolling
    function initLogWindow() {

        // Can we test to see if this is already open?
        logWindow = window.open("", "OpenThoughtDebugWindow",
                'resizable=yes,scrollbars=yes,location=no,menubar=yes,width=550,height=350')

        with ( logWindow.document ) {
            write('<html><head><title>OpenThought Log Window</title></head><body>');
            write('<h2>OpenThought Log Window</h2>');
            write('Welcome to the OpenThought log window! ');
            write('This was enabled using the <i>log_enabled</i> option set at the top of OpenThought.js. ');
            write('Logging output follows, good luck! <br/>');
            write('<hr noshade>');
        }
    }

    // Escape chars to be displayed in the log window
    function EscapeHtml( htmlchar ) {

        var regexp;
        if(htmlchar.indexOf("<") != -1) {

            regexp = /\</g;
            htmlchar = htmlchar.replace( regexp, "\&lt;" );
        }

        if(htmlchar.indexOf(">") != -1) {

            regexp = /\>/g;
            htmlchar = htmlchar.replace( regexp, "\&gt;" );
        }

        return htmlchar;
    }

}

function OpenThoughtUtil() {

    var linkArray = new Array();

    // DisableForm(formname, { 'EXCEPT' : [ field1, field2 ] }
    this.DisableElement = function (element_name, except) {
        if (element_name = '*') {
            for (var i=0; i < document.forms.length; i++) {
                DisableFormByNumber(document.forms[i], except);
            }
            DisableLinks(except);
        }
        else {
            var element = OpenThought.FindElement(element_name);
            if(element["tagName"] && (element["tagName"] == "FORM")) {
                DisableFormByName(element, except);
            }
            else if(element["tagName"] && (element["tagName"] == "A")) {
                DisableLinkByName(element, except);
            }
            else {
                element.disabled = true;
            }
        }

        function DisableLinks(except) {
            var objLink = document.links;
            for(var i=0;i < objLink.length;i++) {
                var current_defs = new Object;
                current_defs["href"]    = objLink[i].href.toString();
                current_defs["onclick"] = objLink[i].onclick;
                linkArray[i] = current_defs;
                PerformLinkDisable(objLink[i], except);
            }
        }
        function PerformLinkDisable(link_obj, except) {
            if ((link_obj.name || link_obj.id ) && except) {
                for (var i=0; i < except["EXCEPT"].length; i++) {
                    if ((link_obj.name == except["EXCEPT"][i] ) ||
                        (link_obj.id == except["EXCEPT"][i] ) ) {
                            OpenThought.log.debug("Skipping disable of " + except["EXCEPT"][i]);
                            return;
                        }
                }
            }
            link_obj.disabled=true;
            link_obj.onclick = new Function("return false;");
        }

        function DisableFormByNumber(form, except) {
            for (var element_num=0; element_num < form.elements.length; element_num++ ) {
                PerformElementDisable(form.elements[element_num], except);
            }
        }

        function DisableFormByName(form_name, except) {
            if (!document.forms[form_name]) {
                this.log.error("Form name [" + form_name + "] does not exist.");
                return;
            }
            for (var element_num=0; element_num < document.forms[form_name].elements.length; element_num++ ) {
                PerformElementDisable(document.forms[single_form_name].elements[element_num], except);
            }
        }
        function PerformElementDisable(element, except) {
            if ((element.name || element.id ) && except) {
                for (var i=0; i < except["EXCEPT"].length; i++) {
                    if ((element.name == except["EXCEPT"][i] ) ||
                        (element.id == except["EXCEPT"][i] ) ) {
                            return;
                        }
                }
            }
            element.disabled = true;
        }
    }
    this.EnableElement = function(element_name, except) {
        if (element_name = '*') {
            for (var i=0; i < document.forms.length; i++) {
                EnableFormByNumber(document.forms[i], except);
            }
            EnableLinks(except);
        }
        else {
            var element = OpenThought.FindElement(element_name);
            if(element["tagName"] && (element["tagName"] == "FORM")) {
                EnableFormByName(element, except);
            }
            else {
                element.disabled = false;
            }
        }

        function EnableLinks() {
            var objLink = document.links;
            for(var i=0;i < objLink.length;i++) {
                OpenThought.log.warn("linkarray: " + linkArray[i]["href"]);
                OpenThought.log.warn("linkarray: " + linkArray[i]["onclick"]);
                OpenThought.log.warn("i: " + i);
                objLink[i].disabled = false;
                objLink[i].href     = linkArray[i]["href"];
                objLink[i].onclick  = linkArray[i]["onclick"];
            }
        }

        function EnableFormByNumber(form, except) {
            for (var element_num=0; element_num < form.elements.length; element_num++ ) {
                PerformElementEnable(form.elements[element_num], except);
            }
        }

        function EnableFormByName(form_name, except) {
            if (!document.forms[form_name]) {
                this.log.error("Form name [" + form_name + "] does not exist.");
                return;
            }
            for (var element_num=0; element_num < document.forms[form_name].elements.length; element_num++ ) {
                PerformElementEnable(document.forms[single_form_name].elements[element_num], except);
            }
        }
        function PerformElementEnable(element, except) {
            if ((element.name || element.id) && except) {
                for (var i=0; i < except["EXCEPT"].length; i++) {
                    if ((element.name == except["EXCEPT"][i]) ||
                        (element.id == except["EXCEPT"][i] ) ) {
                       return;
                   }
               }
           }
           element.disabled = false;
        }
    }

    this.ShowElement = function() {
        for (var element_id=0; element_id < arguments.length; element_id++) {
            var element = OpenThought.FindElement(arguments[element_id]);

            if (element) {

                if (OpenThought.browser.version == "NS4") {
                    element.visibility = "show";
                }
                else if (OpenThought.browser.version == "IE4") {
                    element.style.visibility = "visible";
                }
                else {
                    element.style.visibility = "visible";
                }
            }
        }
    }
    this.HideElement = function() {
        for (var element_id=0; element_id < arguments.length; element_id++) {
            var element = OpenThought.FindElement(arguments[element_id]);

            if (element) {

                if (OpenThought.browser.version == "NS4") {
                    element.visibility = "hide";
                }
                else if (OpenThought.browser.version == "IE4") {
                    element.style.visibility = "hidden";
                }
                else {
                    element.style.visibility = "hidden";
                }

            }
        }
    }
    // determine whether a given field has changed value or not
    this.ElementChanged = function(element_name) {
        var object = OpenThought.FindElement(element_name);

        // This is kinda silly, but radio buttons don't seem to return an
        // object.type, in some versions of Mozilla and IE
        if((!object.type) && (object.length > 0)) {
            object.type="radio";
        }

        if(( object.type ) && (object.type != "button" )) {
            switch (object.type) {
                case "select":
                case "select-one":
                case "select-multiple":
                    return SelectModified(object);
                    break;

                case "text":
                case "password":
                case "textarea":
                case "hidden":
                    return object.value != object.defaultValue;
                    break;

                case "checkbox":
                    return object.checked == object.defaultChecked;
                    break;

                case "radio":
                    return RadioModified(object);
                    break;

                default:
                    return -1;
            }
        }
        else {
            // other types of objects can't be changed by the user
            return false;
        }
    }

    function RadioModified(element) {

        // This occurrs if there is only one radio button
        if (element.length == null ) {
            return element.checked == element.defaultChecked;
        }
        // More than one button
        else {
            var checked = false;
            for (var i=0; i < element.length; i++) {
                if (element[i].defaultChecked) {
                    return element[i].checked == element[i].defaultChecked;
                }
                else {
                    if (element[i].checked) {
                        checked = true;
                    }
                }
            }
            return checked;
        }
    }
    function SelectModified(element) {

        var checked = false;
        for(var i=0; i < element.length; i++) {
            // There can be more than one selected item.  If one has changed,
            // we can return immediatly.  If not, keep looping until we find a
            // change, or we discover they're all the same.
            if (element.options[i].defaultSelected) {
                if (element.options[i].selected != element.options[i].defaultSelected) {
                    return true;
                }
                return false;
            }
            // This is incase we discover there are no options with
            // defaultSelected checked.  If thats the case, we can assume that
            // any checks imply that it was changed
            else {
                if (element.options[i].selected) {
                    checked = true;
                }
            }
        }
        return checked;
    }

    // determine whether a given field has changed value or not
    this.ElementReset = function(element_name) {
        var object = FindObject(element_name);

        // This is kinda silly, but radio buttons don't seem to return an
        // object.type, in some versions of Mozilla and IE
        if((!object.type) && (object.length > 0)) {
            object.type="radio";
        }

        if(( object.type ) && (object.type != "button" )) {
            switch (object.type) {
                case "select":
                case "select-one":
                case "select-multiple":
                                        SelectReset(object)
                break;

                case "text":
                case "password":
                case "textarea":
                case "hidden":
                    object.value = object.defaultValue;
                    break;

                case "checkbox":
                    object.checked == object.defaultChecked;
                    break;

                case "radio":
                    RadioReset(object);
                    break;

                default:
                    return -1;
            }
        }
        else {
            // other types of objects can't be changed by the user
            return -1;
        }
    }
    function RadioReset(element) {
        if (element.length == null ) {
            element.checked = element.defaultChecked;
        }
        // More than one button
        else {
            var checked = false;
            for (var i=0; i < n; i++) {
                if (element.defaultChecked) {
                    element.checked = true;
                }
                else {
                    element.checked = false;
                                }
            }
        }
    }
    function SelectReset(element) {

        for(var i=0; i < element.length; i++) {
            if (element.options[i].defaultSelected) {
                                element.options[i].selected = true;
            }
            else {
                element.options[i].selected = false;
            }
        }
    }
}


// The End
////////////
