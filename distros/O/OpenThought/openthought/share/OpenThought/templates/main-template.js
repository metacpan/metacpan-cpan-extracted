<!-- Include the OpenThought Javascript Library -->

<script language="JavaScript"><!--

// Are we using Netscape, IE, Mozilla, or Opera?  Set up a global variable
ns4 = false;
ie4 = false;
w3c = false;
opr = false;
knq = false;

// Test for browser types
if (document.layers) {
    ns4 = true;
}
else if (navigator.userAgent.indexOf("Opera")!=-1) {
    opr = true;
}
else if (document.getElementById) {
    w3c = true;
}
else if (document.all) {
    ie4 = true;
}
else {
    var wrong_browser = "<TMPL_VAR NAME=wrong_browser>";

    // Only popup the alert box if there is a message to display
    if(wrong_browser != "") {
        alert(wrong_browser);
    }
}

// The session id for this application
sessionid = '<TMPL_VAR NAME=session_id>';

// Don't allow select boxes to grow larger then this
maxSelectBoxWidth = <TMPL_VAR NAME=max_selectbox_width>;

// Set the current active (visible) layer
currentLayer = "";

// Automatically clear select lists before putting data into them?
autoClear = true;

// Instanciate the form element caching hash
formElement = new Object;

fetchStart   = '<TMPL_VAR NAME=fetch_start>';
fetchDisplay = '<TMPL_VAR NAME=fetch_display>';
fetchFinish  = '<TMPL_VAR NAME=fetch_finish>';

runmode = '';
runmodeParam = '<TMPL_VAR NAME=runmode_param>';

// Set the debug level
debug = <TMPL_VAR NAME=debug>;

if ( debug == 0 ) {
    set_debug( false );
}
else {
    set_debug( true );
}

// This is the function that will be communicating with the server
function CallUrl() {
    var eventType = 'data';

    // Serialize the parameters we were passed into an XML Packet
    var XMLPacket = Hash2XML(GenParams(
                                SortParams(CallUrl.arguments), eventType ));

    Send(CallUrl.arguments[0], eventType, XMLPacket);
}

// This loads a new page in the content frame
function FetchHtml() {
    var eventType = 'ui';

    // Serialize the parameters we were passed into an XML Packet
    var XMLPacket = Hash2XML(GenParams(
                                SortParams(FetchHtml.arguments), eventType ));

    ExpireCache();
    Send(FetchHtml.arguments[0], eventType, XMLPacket);
}

function Send(url, eventType, XMLPacket) {

    //var date = new Date();
    //bench = "Params: " + date.getTime() + "\n";

    // Update the message on the status bar
    if (eventType == "data") {
        window.status = fetchStart;
    }

    //var date = new Date();
    //bench += "Ser: " + date.getTime() + "\n";

    // Now that the XML packet is created, reset the runmode
    set_runmode('');

    // Post request to server via the form in the commFrame
    //var date = new Date();
    //bench += "Sent: " + date.getTime() + "\n";

    if ( get_debug() ) {
        parent.debugFrame.document.write("Data sent to ", url, ":");
        parent.debugFrame.document.write('<pre>', escape_html(XMLPacket), '</pre>')
        parent.debugFrame.document.write("<hr>")
    }
    if (eventType == "ui") {
        parent.contentFrame.location.href = url + "?OpenThought=" + XMLPacket;
    }
    else {
        parent.commFrame.location.replace( url + "?OpenThought=" + XMLPacket );
    }

    // Set the title of the application, based on the title listed in the
    // content frame
    parent.document.title = parent.contentFrame.document.title;

}

// Called by the CommFrame when data has arrived
function OpenThoughtUpdate(Content) {

    //var date = new Date();
    //bench += "Recv: " + date.getTime() + "\n";

    // Update the message on the status bar
    window.status = fetchDisplay;

    // Display everything if we received a decent response
    if (Content != null)
    {
        FillFields(Content);
    }

    // Display text on the status bar stating that we received information
    window.status = fetchFinish;

    //var date = new Date();
    //bench += "Done: " + date.getTime() + "\n";
    //alert(bench);
    return;
}

// Digs through the browsers DOM hunting down a particular form element
function FindObject(element, d) {

    if ( get_debug() ) {
        parent.debugFrame.document.writeln("Searching for element [",
                                            element, "]<br/>");
    }
    // If we have this particular object cached in our hash, use the cached
    // version (Just remember, Dr Suess wrote the "Cat in the Hat".  It's me
    // who wrote "The Cache in the Hash" ;-)
    if(typeof(formElement[element]) == "object") {
        return formElement[element];
    }

    var p,i,x;

    if(!d) {
        d = frames[0].document;
    }
    if((p = element.indexOf("?")) > 0 && parent.frames.length) {
        d = parent.frames[element.substring(p+1)].document;
        element = element.substring(0,p);
    }
    if(!(x = d[element]) && d.all) {
        x = d.all[element];
    }
    for (i=0;!x&&i<d.forms.length;i++) {
        x = d.forms[i][element];
    }
    for(i=0; !x && d.layers && i < d.layers.length; i++) {
        x = FindObject(element, d.layers[i].document);
    }
    if(!x && document.getElementById) {
        x = d.getElementById(element);
    }

    // Now that we found our Object, cache it for later use
    formElement[element] = x;

return x;
}

// Initialize and populate the Select list
function FillSelect(element, data)
{
    // If sent a string, and not an array, we just need to highlight an
    // existing item in the list, and not add anything
    if(typeof data == "string") {
        for (var i=0; i < element.options.length; i++) {
            if( element.options[i].value == data ) {
                element.selectedIndex = i;
            }
        }

    }
    // Actually add the items we were sent to the list
    else {
        // Clear any current OPTIONS from the SELECT
        //element.options.length = 0;
        if(((autoClear) &&
            ((typeof data[0] != "string") && (data[0] != "" ))) ||
            ((typeof data[0] == "string") && (data[0] == ""))) {

            while (element.options.length) element.options[0] = null;
            if((data.length == 1) && (data[0] == "")) {
                return;
            }
        }

        // For each record...
        for (var i=0; i < data.length; i++)
        {

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
            else {
                text = data[i][0];
                value = data[i][1];

                if (data[i][1] == "") {
                    value = text;
                }
            }

            // Text cam't be null
           // if(text != undefined) {
                // If CutSelectBoxText is set, alter the length of the text to
                // lessen the need to the browser to resize the selectbox.
                // Netscape 4 does not resize selectboxes.
                if ((!ns4) && (maxSelectBoxWidth != 0))
                {
                    text = (text.substr(0,maxSelectBoxWidth));
                }

                // Add the new object to the SELECT list
                element.options[element.options.length] =
                                                    new Option(text, value);
            //}
        }
    }
}

// Put values into a text form field
function FillText(element, data)
{
    element.value = data;
}

// Select or unselect a checkbox form field
function FillCheck(element, data)
{
    if((data == "false") || (data == "FALSE") || (data == "False") ||
       (data == "unchecked") || (data < "1"))
    {
        element.checked = false;
    }
    else
    {
        element.checked = true;
    }
}

// Select a radio button
function FillRadio(element, value)
{
    for(var i=0; i<element.length; i++)
    {
        if(element[i].value == value)
        {
            element[i].checked = true;
        }
    }
}

// Take the data we received, and put it in it's appropriate field
function FillFields(Content)
{
    for (var fieldName in Content)
    {
        var object = FindObject(fieldName);

        // This is kinda silly, but radio buttons don't seem to return an
        // object.type, in some versions of Mozilla
        if((!ie4) && (object.type == undefined) && (object.length > 0))
        {
            object.type="radio";
        }

        if((object) && ( object.type )) {
            switch (object.type)
            {
                case "select":
                case "select-one":
                case "select-multiple":
                    FillSelect(object,Content[fieldName]);
                    break;

                case "text":
                case "password":
                case "textarea":
                case "hidden":
                    FillText(object, Content[fieldName]);
                    break;

                case "checkbox":
                    FillCheck(object, Content[fieldName]);
                    break;

                case "radio":
                    FillRadio(object, Content[fieldName]);
                    break;
            }
        }
        else if(((w3c) || (ie4)) && (object.innerHTML)) {
            object.innerHTML = Content[fieldName];
        }
    }

}

// Digs through all the parameters sent to the SendParameters function, and
// organizes them into categories
function SortParams(elements)
{
    var param  = new Object();
    var fields = new Array();
    var values = new Array();

    // The first parameter is the form url
    for(var i=1; i < elements.length; i++) {

        // If the parameter contains an equal sign (=), it's an expression
        if(elements[i].indexOf("=") != -1) {
            values[values.length] = elements[i];
        }
        // Otherwise, it's a form element
        else {
            fields[fields.length] = elements[i];
        }
    }

    param["fields"] = fields;
    param["expr"]   = values;

return param;
}

// Generates the key/value pairs to send to the server
function GenSettingParams(eventType)
{
    var param  = new Object();

    param["event"] = eventType;

    param["session_id"] = get_sessionid();

    param["need_script"] = 1;

    param["runmode_param"] = get_runmode_param();

    if(get_runmode != "") {
        param["runmode"] = get_runmode();
    }

return param;
}

// Generates the key/value pairs to send to the server
function GenExprParams(elements)
{
    var param  = new Object();
    var keyval = new Array();

    for(var i=0; i < elements.length; i++) {

        keyval = elements[i].split("=");

        param[keyval[0]] = keyval[1];

        if( get_runmode_param() == keyval[0] ) {
            set_runmode( keyval[1] );
        }
    }

return param;
}

// Generates the field parameters to send to the server
function GenFieldParams(elements)
{
    var param = new Object();

    for(var i=0; i < elements.length; i++)
    {
        var object = FindObject(elements[i]);

        // This is kinda silly, but radio buttons don't seem to return an
        // object.type, in some versions of Mozilla
        if((!ie4) && (object.type == undefined) && (object.length > 0))
        {
            object.type="radio";
        }

        if(( object ) && ( object.type )) {
            switch (object.type)
            {
                case "text":
                case "password":
                case "textarea":
                case "hidden":
                    param[elements[i]] = object.value;
                    break;

                case "select":
                case "select-one":
                case "select-multiple":
                    param[elements[i]] = SelectValue(object);
                    break;

                case "checkbox":
                    param[elements[i]] = CheckboxValue(object);
                    break;

                case "radio":
                    param[elements[i]] = RadioValue(object);
                    break;
            }
        }
        else if(((w3c) || (ie4)) && (object.innerHTML)) {
            param[elements[i]] = object.innerHTML;
        }

        if( get_runmode_param() == elements[i] ) {
            set_runmode( param[elements[i]] );
        }

    }

return param;
}

// Build a single hash containing all the data to be sent to the server
function GenParams(elements, eventType) {

    var params = new Object();

    // Add the fields we were given, but only add it if there is at least one
    if(elements["fields"].length > 0) {
        params["fields"]  = GenFieldParams(elements["fields"]);
    }
    // Add key/pair values, but only if there is at least one
    if(elements["expr"].length > 0) {
        params["expr"]  = GenExprParams(elements["expr"]);
    }
    // Add settings, there will always be at least one
    params["settings"]  = GenSettingParams(eventType);

return params;
}

// Figure out which option is selected in our Select list
function SelectValue(element)
{
    if(element.selectedIndex >= 0) {
        return element.options[element.selectedIndex].value;
    }
    else {
        return "";
    }
}

// Figure out which option is selected in our checkbox
function CheckboxValue(element)
{
    if(element.checked == true)
    {
        if(element.value == "on")
        {
            return "<TMPL_VAR NAME=checked_true_value>";
        }
        else
        {
            return element.value;
        }
    }
    else
    {
        return "<TMPL_VAR NAME=checked_false_value>";
    }

}

// Figure out which option is selected in our radio button
function RadioValue(element)
{
    for (var i=0; i < element.length; i++)
    {
        if(element[i].checked == true)
        {
            return element[i].value;
        }
    }

    return "<TMPL_VAR NAME=checked_false_value>";
}

// Takes a fieldname as an argument, and gives that field the focus
function FocusField(element)
{
    FindObject(element).focus();
}

// Display an error message to the user
function DisplayError(msg)
{
    alert(msg);
}

// Convert our parameter hash into an XML object
function Hash2XML(hash)
{
    // Define the root element
    var xml = "<OpenThought>";

    // Loop through each child in the hash (fields and expr)
    for (var child in hash) {

        xml += "<" + child + ">";

        if(typeof(hash[child]) == "object") {

            // Now get every child of the children elements (grandchild)
            for(var grandchild in hash[child])
            {
                xml += "<" + grandchild + ">";
                xml += escape_xml(hash[child][grandchild]);
                xml += "</" + grandchild + ">";
            }
        }
        else {
            xml += escape_xml(hash[child]);
        }

        xml += "</" + child + ">";
    }
    xml += "</OpenThought>";

return xml;
}

function escape_xml( xmlchar ) {

    xmlchar = xmlchar.toString();

    if(xmlchar.indexOf("&") != -1) {

        var regexp = /&/g;
        xmlchar = xmlchar.replace( regexp, "\&amp;" );
    }

    if(xmlchar.indexOf("<") != -1) {

        var regexp = /\</g;
        xmlchar = xmlchar.replace( regexp, "\&lt;" );
    }

    if(xmlchar.indexOf(">") != -1) {

        var regexp = /\>/g;
        xmlchar = xmlchar.replace( regexp, "\&gt;" );
    }

    return escape(xmlchar);
}

function escape_html( htmlchar ) {

    if(htmlchar.indexOf("<") != -1) {

        var regexp = /\</g;
        htmlchar = htmlchar.replace( regexp, "\&lt;" );
    }

    if(htmlchar.indexOf(">") != -1) {

        var regexp = /\>/g;
        htmlchar = htmlchar.replace( regexp, "\&gt;" );
    }

    return htmlchar;
}

// Used for the tabs - hide the current layer, show the new one
function showDiv(layerName)
{
   // First hide the layer, then set 'currentLayer' to the new layer, and
   // finally show the new layer
   if (ns4)
   {
      if(currentLayer != "") {
        frames[0].document.layers[currentLayer].visibility = "hide"
      }
      currentLayer = layerName;
      frames[0].document.layers[layerName].visibility = "show";
   }
   else if (ie4)
   {
      if(currentLayer != "") {
        frames[0].document.all[currentLayer].style.visibility = "hidden";
      }
      currentLayer = layerName;
      frames[0].document.all[layerName].style.visibility = "visible";
   }
   else if ((w3c) || (opr) || (knq))
   {

      if(currentLayer != "") {
        frames[0].document.getElementById(currentLayer).style.visibility = "hidden";

      }
      currentLayer = layerName;
      frames[0].document.getElementById(layerName).style.visibility = "visible";
   }
}

// Every call to find a form object is cached for later use.  If the underlying
// HTML is changed though, the values listed in the cache will be incorrect.
// The following function should be called anytime you change the page, or
// directly manipulate the name or location of a form element.
function ExpireCache() {

    formElement = "";

    // Instanciate the form element caching hash
    formElement = new Object;

}

// Called if the debug frame is enabled -- this will send some basic
// information into the frame so users understand what it does
function DebugFrameInfo() {

    with ( parent.debugFrame.document ) {
        write('<html><head><title>Debug</title></head><body>');
        write('<table border="0" width="100%"><tr valign="top"><td width="20%">');
        write('<h2>Debug Frame</h2>');
        write('</td><td>');
        write('Welcome to the OpenThought debug frame! ');
        write('This was enabled using the <i>debug</i> option in the config file. ');
        write('Debugging info will be sent to this frame, which hopefully will help you to correct any problems you are having. ');
        write('You can use the frame border above to make this frame bigger or smaller, and you can also use the scoll bar to scroll up and down. ');
        write('Some browsers based on the Mozilla engine may act as if they are still loading a page upon enabling this frame, the icon in the top right corner of your browser might keep spinning. ');
        write('This appears to be an unfortunate browser bug, but simply hitting the <i>Stop</i> button will correct it. ');
        write('Good luck, and have fun! ');
        write('</td></tr>');
        write('<tr><td colspan="2">');
        write('Debug debug info follows: <br/>');
        write('<hr noshade>');
        write('</td></tr></table>');
        write('</body></html>');
    }
}

// ------------------------------------------------------------------------//
//   Accessor Methods
//
//   The following methods are to access & change the values of
//   existing variables
// ------------------------------------------------------------------------//

function set_maxselectboxwidth(width) { maxSelectBoxWidth = width; }
function set_autoclear(val) {
    if(val < 1) {
         autoClear = false;
    }
    else {
        autoClear = true;
    }

}
function set_fetch_start(msg)   { fetchStart   = msg; }
function set_fetch_display(msg) { fetchDisplay = msg; }
function set_fetch_finish(msg)  { fetchFinish  = msg; }
function set_runmode(msg)       { runmode      = msg; }
function set_runmode_param(msg) { runmodeParam = msg; }
function set_debug(msg)         { debug        = msg; }

function get_sessionid()           { return sessionid;    }
function get_max_selectbox_width() { return maxSelectBoxWidth; }
function get_auto_clear()          { return autoClear;    }
function get_fetch_start()         { return fetchStart;   }
function get_fetch_display()       { return fetchDisplay; }
function get_fetch_finish()        { return fetchFinish;  }
function get_runmode()             { return runmode;      }
function get_runmode_param()       { return runmodeParam; }
function get_debug()               { return debug;        }

// -->
</script>

<!-- And they lived happily ever after, The End -->
