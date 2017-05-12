// ------------------------------------------------------------------
// Portions of this code based on works copyright 2003-2004 Ran Eilam.
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------

var $application;

function POEXUL_Application () {

    if( POEXUL_Application.singleton ) 
        return POEXUL_Application.singleton;

    this.applicationName = location.search.substr(1) || false;
    var matches = /app=(\w+)/.exec( this.applicationName );
    if( matches ) {
        this.applicationName = matches[1];
    }
    fb_log( "Application name %s", this.applicationName );
    this.crashed = false;
    this.frames = [];
    this.other_windows = {};
    this.BLIP   = 10;
    this.groupbox_style = "border-color: #124578;";
    this.caption_style = "color: white; font-weight: bold; padding: 0px 9px 5px 9px; margin: 0px; -moz-border-radius: 3px; background-color: #124578; border: 1px solid #124578;";

    this.xulNS = "http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul";
    this.htmlNS = "http://www.w3.org/1999/xhtml";

    $application = this;

    this.runner = POEXUL_Runner.get();
    this.conduit = new POEXUL_Conduit ( this.baseURI() );
    var b1 = new POEXUL_Status;
    var b2 = new POEXUL_Blocker;
    this.init_window( window );
}

// ------------------------------------------------------------------
// Get the current application.  Create one if needs be
POEXUL_Application.get = function () {
    if( !POEXUL_Application.singleton ) 
        POEXUL_Application.singleton = new POEXUL_Application;
    return POEXUL_Application.singleton;
}

// ------------------------------------------------------------------
// Boot an instance of the application
POEXUL_Application.boot = function () {
    // Create the application
    window.name = '';           // mark this window as a main window
    POEXUL_Application.get();
    $application.runRequest();
}

// ------------------------------------------------------------------
// Connect the current window to an existing instance of the application
POEXUL_Application.connect = function ( sid ) {
    // Create the application
    POEXUL_Application.get();
    $application.setSID( sid );
    $application.runRequest( { event: 'connect' } );
}

var _ = POEXUL_Application.prototype;


// ------------------------------------------------------------------
// Add the event listeners to a window
_.init_window = function ( win ) {
    var self = this;
    win.addEventListener( 'command',
            function(event) { self.fireEvent_Command(event) }, false );
    win.addEventListener( 'change',
            function(event) { self.fireEvent_Change(event)  }, false );
    win.addEventListener( 'select',
            function(event) { self.fireEvent_Select(event)  }, false );
    win.addEventListener( 'pick',
            function(event) { self.fireEvent_Pick(event)  }, false );
    win.addEventListener( 'keypress',
            function(event) { self.fireEvent_Keypress(event)  }, true );
    win.addEventListener( 'unload',
            function(event) { self.unload(event)  }, true );
    win.addEventListener( 'resize',
            function(event) { self.resize(event)  }, false );
//    win.addEventListener( 'click',
//            function(event) { self.click(event)  }, false );
//    win.addEventListener( 'DOMAttrModified',
//            function(event) { self.attrModified(event)  }, false );
}

// ------------------------------------------------------------------
// Add the required CSS to the sub-window
_.init_fragment = function ( doc, win, id ) {
    if( doc.height < win.innerHeight ) {
//        alert( "doc.height=" + doc.height +
//                " < win.innerHeight=" + win.innerHeight );
        return;
    }

    var box = doc.getElementById( id );
    if( !box )
        this.crash( "Failed to find element " + id + " in the iframe." );
    box = box.parentNode;
    box.style.height = doc.height + "px";
    box.style.width  = doc.width + "px";
    if( doc.width > win.innerWidth ) {
        box.style.overflow = 'scroll';
    }
    else {
        box.style.overflow = '-moz-scrollbars-vertical';
    }

    return;
}


// ------------------------------------------------------------------
_.baseURI = function () {
    var pathname   = location.pathname.replace(/\/[^\/]+$/, "");
    var port       = location.port;
    port           = port? ':' + port: '';
    return location.protocol + '//' + location.hostname + port + 
                                        pathname + "/xul";
}

_.buildURI = function (req) {
    var extra = req.extra;
    delete req.extra;

    this.setupEvent( req );
    this.conduit.setupRequest( req );
    var R = [];
    for( var key in req ) {
        R.push( encodeURIComponent( key ) + "=" + 
                encodeURIComponent( req[key] ) 
              );
    }

    var uri = this.baseURI();
    if( extra && extra.file ) {
        uri += "/file/" + extra.file;
    }

    uri += "?" + R.join( "&" );
    return uri;
}



// ------------------------------------------------------------------
_.setSID = function ( SID ) {
    this.conduit.setSID( SID );
}

// ------------------------------------------------------------------
_.getSID = function ( ) {
    return this.conduit.getSID();
}

// ------------------------------------------------------------------
_.crash = function ( why ) {
    if( $blocker )
        $blocker.unblock();

    this.status( "error" );

    this.crashed = why;

    var data, already, xul, title, message, html;

    // Perl error
    var re = /((PERL|JAVASCRIPT|APPLICATION) ERROR)(\s*:?\s*)/m;
    var m = re.exec( why );
    if( m && m.length ) {
        title = m[1];
        message = why.substr( m[0].length );
        // Make it look nice
        message = this.text2html( message );
        xul = "<html:span style='font-family: monospace;'>" + message + "</html:span>";
    }        
    else if ( why.match( /^\s*<html>/ ) ) {
        // Keep HTML as-is
        html = why;
    }
    else {
        title = "Application crash";
        // Pretty-print any other text
        xul = this.nicerHtml( why ); 
        xul = "<html:p style='width:550px'>" + why + "</html:p>"
    }

    try {
        window.location = this.XUL2uri( { title: title, xul: xul, html: html, 
                                          icon: 'error-icon' } );
    }
    catch( err ) {
        // If that's the case, show the alert (if not already ) and bug out
        if( ! already ) {
            alert( why );
        }
        throw( err );
    }
}

_.XUL2uri = function ( details ) {

    if( details.html ) {
        data = details.html;
        mime = "text/html";
    }
    else {
        // this means it isn't HTML
        // So the alert won't look weird
        var icon = details.icon;
        var width = 600;
        if( details.width )
            width = details.width;
        // see also /usr/local/firefox-2.0.0.3/chrome/classic/skin/classic/global/netError.css
        data = "<?xml version='1.0'?>\n" +
               "<?xml-stylesheet href='chrome://global/skin/' type='text/css'?>\n" +
               "<window xmlns='http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul' "+
                "xmlns:html='http://www.w3.org/1999/xhtml' " +
                "orient='vertical'>\n" +
               "<hbox><spacer flex='1'/><groupbox class='error' style='background-color: white; margin-top: 75px; max-height: 600px;" + this.groupbox_style + "'>" +
                    "<caption style='padding: 0;'><description style='" + this.caption_style + "'>"+ details.title + 
                    "</description></caption>" +
               "<hbox style='max-width:" + width + "px; min-width: 200px;' flex='1'>";
        if( details.icon ) {
            data += "<vbox><image class='" + details.icon + "'/><spacer/></vbox>";
            width -= 50;
        }
        data += "<description style='max-width:" + width + "px; min-width: 200px; margin-bottom: 2em;'>" + details.xul + "</description></hbox>" +
                "</groupbox><spacer flex='1'/></hbox><spacer/></window>";
        mime = "application/vnd.mozilla.xul+xml";
    }
    // btoa fails on unicode
    data = btoa( data );
    return "data:"+mime+";base64," + data;
}


_.text2html = function ( message ) {

//    message = String( message ).escapeHTML();
    message = message.replace( "&", "&amp;", "g" );
    message = message.replace( "<", "&lt;", "g" );
    message = message.replace( ">", "&gt;", "g" );

    return this.nicerHtml( message );
}

_.nicerHtml = function ( message ) {

    message = message.replace( /^\s+/gm, 
                                   function ( match ) {
                                    return String( '    ' ).times( match.length );
                             } );
    message = message.replace( /^ +/gm, 
                                   function (match ) {
                                        return String( "&#160;" ).times( match.length );
                             } );
    return message.replace( "\n", "<html:br />\n", "g" );
}


_.isNotCrashed = function () {
    if( !this.crashed )
        return;
    alert( "This application has crashed\n" + this.crashed );
}


// ------------------------------------------------------------------
_.exception = function ( type, EXs ) {
    var msg = [];
    for( var q=0 ; q<EXs.length ; q++ ) {
        var ex = EXs[q];
        var file = ex.fileName || 'N/A';
        var line = ex.lineNumber || 'N/A';
        msg.push( (ex.message || ex.description) + 
                        "\n  File " + file + " line " + line );
    }

    $application.crash( type + " ERROR " + msg.join( "\n" ) );
}

// events ---------------------------------------------------------------------

_.fireEvent_Command = function (domEvent) {
    var source = domEvent.target;
    // fb_dir( { tagName: source.tagName, Command: domEvent } );
    if (source.tagName == 'menuitem' || source.tagName == 'menulist' ) {
        this.fireEvent_Command_Select( domEvent );
    } 
    else if (source.tagName == 'radio') {
        this.fireEvent_Command_RadioClick( domEvent );
    }
    else if ( source.tagName == 'splitter' ) {
        // ignore the clicks on a splitter
        return;
    }
    else {
        if( FormatedField ) {
            var bp = domEvent.target.getAttribute( 'bypass' );
            if( !bp && !FormatedField.form_validate() ) {
                return;
            }
        }

        // fb_log( "Command->Click " + domEvent.type );
        this.fireEvent('Click', domEvent, {});
    }
}

_.fireEvent_Command_Select = function ( domEvent ) {
    var target = domEvent.target;

    var realTarget = target;
    fb_log( 'target is %s', target.tagName );
    if( target.tagName == 'menuitem' ) {
        realTarget = target.parentNode;
    }
    // realTarget is the menupopup, search-list or menu

    if (realTarget.tagName == 'search-list') {
        // $debug( 'Select SearchList ' + realTarget.selectedIndex );
        this.fireEvent( 'Select', 
                        { 'target': realTarget },
                        { 'selectedIndex': realTarget.selectedIndex }
                      );
        return;
    } 

    fb_log( 'realTarget is %s', realTarget.tagName );
    if( realTarget.tagName == 'menupopup' )
        realTarget = realTarget.parentNode;
    // realTarget must now be the menulist
    fb_log( 'realTarget is finally %s#%s', realTarget.tagName, realTarget.id );

    fb_dir( { selectedIndex: realTarget.selectedIndex, 
                   realTarget: realTarget } );

    if (realTarget.tagName == 'menu') {
        // fb_log( "menu->Click" );
        this.fireEvent('Click', domEvent, {});
    } 
    else {
        // menulist: mozilla doesn't set selectedIndex properly!
        // Same with button, it seems
        var I;
        if (realTarget.tagName == 'button' || 
                realTarget.tagName == 'menulist' ) {
            var children = target.parentNode.childNodes;
            I = children.length;
            var trueI; 
            fb_log( children );
            fb_log( "looking for %s#%s", target.tagName, target.id );
            while (I--) {
                // fb_log( "%i is %s#%s", I, children[I].tagName, children[I].id );
                if (children[I] == target) {
                    trueI = I;
                    break;
                }
            }
            if( trueI === undefined ) {
                I = realTarget.selectedIndex;
                fb_log( "Can't find %s#%s in %s#%s.  I hope %i is the true index.",
                            target.tagName, target.id, 
                            realTarget.tagName, realTarget.id, I );
            }
            else if( trueI == realTarget.selectedIndex ) {
                I = trueI;
                fb_log( "%s#%s had the correct index=%i", 
                        realTarget.tagName, realTarget.id, I );
            }
            else {
                realTarget.selectedIndex = trueI;
                I = trueI;
                fb_log( "%s#%s's true index=%i", 
                        realTarget.tagName, realTarget.id, I );
            }
        } 
        else { 
            I = realTarget.selectedIndex;
        }
        var params = {'selectedIndex': I };

        // Send event to app server
        this.fireEvent( 'Select', {'target': realTarget}, params );
    }
}

_.fireEvent_Command_RadioClick = function ( domEvent ) {
    var source = domEvent.target;
    var realSource = source.parentNode;
    if (realSource.tagName == 'radiogroup') {
        this.fireEvent( 'RadioClick',
                            {'target': realSource},
                            {'selectedId':  source.getAttribute( 'id' ) }
                      );
    }
    else {
        fb_log( "Why a click from "+ realSource.tagName + "." +
                                    realSource.getAttribute( 'id' ) );
    }
}

// In FACT! the select event happens when text is selected in a textbox
// http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-eventgroupings-htmlevents
// Or when a line from a tree is selected!

_.fireEvent_Select = function (domEvent) {
    var source = domEvent.target;

    if( source.tagName == 'tree' ) {
        return this.fireEvent_treeSelect( domEvent );
    }
    fb_log( "Useless select", domEvent );
    return;


    // Prevent a selectIndex=N that comes from Runner going back to XUL
    if( source.getAttribute( 'suppressonselect' ) )
        return;

    fb_dir( { Select: domEvent } );
    var selectedIndex = source.selectedIndex;
    var params = {'selectedIndex': selectedIndex };
    
    // textbox: mozilla fires this event when user selects text
    if (selectedIndex == undefined)
        return;
    // listbox: mozilla fires strange events
    if (selectedIndex == -1 ) {
        var editable = source.getAttribute( 'editable' );
        if( !editable || editable != 'true' )
            return;
        // menulist + editable="true", user entered something
        params['value'] = source.value;
    }
    this.fireEvent( 'Select', {'target': source}, params );
}

_.fireEvent_treeSelect = function ( domEvent ) {

    var source = domEvent.target;

    var rowN = source.currentIndex;
    if( rowN == -1 )
        return;

    var params = { 'selectedIndex': rowN };
    if( source.columns ) {
        // POE::XUL::RDF datasources need this
        var pcol = source.columns.getPrimaryColumn(); 
        if( !pcol ) {
            for( var q=0; q < source.columns.count ; q++ ) {
                var col = source.columns.getColumnAt( q );
                if( col.element.tagName == 'treecol' ||
                    col.element.tagName == 'itemcol' ) {
                    pcol = col;
                    break;
                }
            }
        }
        if( pcol ) {
            params.primary_col = pcol.id;
            params.primary_text = source.view.getCellText( rowN, pcol );
        }
    }

    this.fireEvent( 'Select', {'target': source}, params );
}


_.fireEvent_Pick = function (domEvent) {
    var source = window.document.getElementById(domEvent.targetId);
    this.fireEvent('Pick', {'target': source}, {'color': source.color });
}

_.fireEvent_Change = function (domEvent) { 

    fb_dir( { Change: domEvent } );
    var source = domEvent.target;
    var params = { 'value' : source.value };
    if( source.tagName == 'menulist' ) {    // menuitem + editable='true'
        params.selectedIndex = -1;
        fb_log( "menulist %s changed, doing Select (%s)", 
                                        source.getAttribute( 'id' ),
                                        params.value );
        this.fireEvent( 'Select', domEvent, params );
    }
    else {
        if( source.inputField )
            params.value = source.inputField.value;
        this.fireEvent('Change', domEvent, params);
    }
}

_.fireEvent_Keypress = function (e) { 

    if( e.altKey || e.ctlKey || e.shiftKey || e.metaKey || e.isChar )
        return;
    var f = e.keyCode - 111;
    if( f < 1 || 12 < f )
        return;
    var name = "F" + f;

    e.stopPropagation();
    if( e.cancelable )
        e.preventDefault();

    // fb_log( "Pressed "+name );
    this.fireEvent_KP_F( 'button', name );
    this.fireEvent_KP_F( 'toolbarbutton', name );
}

_.fireEvent_KP_F = function ( tag, name ) {

    var buttons = document.getElementsByTagName( tag );
    for( var q = 0 ; q < buttons.length ; q++ ) {
        var B = buttons[q];
        if( Element.isVisible( B ) ) {
            var fkey = B.getAttribute( 'fkey' );
            if( fkey && fkey.toUpperCase() == name ) {
                // fb_log( "Clicking " + B.label );
                B.focus();
                B.click();
                return;
            }
        }
    }
}

// private --------------------------------------------------------------------

_.fireEvent = function (name, domEvent, params) {
    var source   = domEvent.target;
    var sourceId = source.id;
    if (!sourceId) return; // event could come from some unknown place
    var event = {
        'source_id' : sourceId,
        'event'   : name,
    };
    if( 0 ) {  // XUL doesn't believe in checked, it seems
        event['checked'] = source.getAttribute('checked');
    }
    else {
        event['checked'] = source.getAttribute('selected');
    }

    var key; for (key in params) event[key] = params[key];
    this.runRequest(event);
}


// ------------------------------------------------------------------
// turn an event into something we should send to the server
_.setupEvent = function ( event ) {
    if( !event ) {
        event = {};
    }
    event.app = this.applicationName;
    if( ! ("window" in event) )
        event.window = window.name;

    // fb_log( event );
    // fb_log( "window name=", window.name );

    if( ! event.app )
        this.crash( "I need an aplication name!" );

    return event;
}


// ------------------------------------------------------------------
// event should be :
//  {
//      event: "Click",
//      source_id: id,
//    For 'Change':
//      value: "new value",
//    For 'RadioClick':
//      selectedId: itemId
//      checked: source.selected
//    For 'Select':
//      selectedIndex:
//      checked: source.selected
//    Conduit will add :
//      SID: current-SID,
//      reqN: 1++,
//    Added in setupEvent :
//      app: "IGDAIP", (or the application name)
//      window: popup-window-name
//  }

_.runRequest = function (event) {
    this.isNotCrashed();

    event = this.setupEvent( event );

    if( !event.event ) 
        event.event = 'boot';
    fb_log( "app=%s event=%s", event.app, event.event );

    if( this.longEvent( event ) )
        this.status( "load" );

    var self = this;
    this.conduit.request( event, 
                          function (json) { self.runResponse( json, event ) } 
                        );
}

// ------------------------------------------------------------------
_.runResponse = function ( json, event ) {

    // fb_log( 'runResponse' );

    if( event && this.longEvent( event ) )
        this.status( "run" );

    // fb_log( json );
    if( json == null ) {
        // fb_log( event );
        // alert( "Response didn't include JSON ", window.name );
        this.crash( "Response didn't include JSON" );
    }
    else if( 'object' != typeof json && 'Array' != typeof json ) {
        this.crash( "Response isn't an array: " + typeof json );
    }
    else {
        this.runner.run( json );
        // this.status( "done" );
    }
    return;
}

// ------------------------------------------------------------------
_.longEvent = function ( event ) {
    if( !event.event )
        return 0;
    if( event.event == 'boot' )
        return 1;
    if( event.event == 'Click' )
        return 1;
    return 0;
}
_.status = function ( status ) {

    var text;
    if( status == 'load' ) {
        // document.documentElement.style.cursor = "wait";
        text = "Chargement...";
    }
    else if( status == 'run' ) {
        text = "Ex\xe9cution...";
    }
    else if( status == 'open' ) {
        document.documentElement.style.cursor = "wait";
        text = "Ouverture d'une fen\xeatre...";
    }
    else if( status == 'done' ) {
        document.documentElement.style.cursor = "auto";
        text = "Pr\xEAt";
    }
    else if( status == 'error' ) {
        document.documentElement.style.cursor = "auto";
        text = "Erreur";
    }
    else {
        test = "En cour : " + text ;
    }

    var message = window.document.getElementById( 'XUL-Status' );
    if( message ) {
        var textNode = window.document.createTextNode( text );
        message.replaceChild( textNode, message.childNodes[0] );
        window.status = ' ';
    }
    else {
        window.status = text;
    }
}

// ------------------------------------------------------------------
_.clearFormated = function () {
    if( FormatedField ) {
        FormatedField.clear_formated();
    }
}

_.cleanFormated = function () {
    if( FormatedField ) {
        FormatedField.clean_formated();
    }
}


// ------------------------------------------------------------------
_.timing = function ( what, start, end ) {
    var elapsed = end - start;
    var t;
    if( elapsed > 1000 ) {
        t = ( elapsed/1000 ) + "s";
    }
    else {
        t = elapsed + "ms";
    }
    // window.status = window.status + " " + what + ": " + t;
    // $debug( what + ": " + t + "\n" );
}

// ------------------------------------------------------------------
// Open a sub-window
_.openWindow = function ( url, id, features ) {

    fb_log( "Open window id=%s url=%s", id, url );
    this.status( 'open' );
    var win = window;
    // next little bit lifted from text.xml#text-link
    if (window instanceof Components.interfaces.nsIDOMChromeWindow) {
        while (win.opener && !win.opener.closed)
            win = win.opener;
    }

    var w = win.open( url, id, features );

    if( w ) {    
        this.other_windows[ id ] = w;
        var self = this;

        w.addEventListener( 'unload', 
                        function (e) { self.closed( id, e ); return true; }, 
                        false 
                      );
    }
    else {
        alert( "Vous devez permetre des fen\xEAtres 'popup' pour ce site." );
    }
}

// ------------------------------------------------------------------
// Close a sub-window
_.closeWindow = function ( id ) {
    fb_log( id + ".close()" );
    var w = this.other_windows[ id ];

    if( !w ) {
        // either window was already closed, or we are the popup
        if( window.name == id ) {
            w = window;
        }
        else {
            fb_log( "Why don't I have window id", id ); 
            return;
        }
    }

    if( window.name == w.name ) {
        fb_log( "Closing ourself" );
        if( w.opener && w.opener['$application'] ) {
            fb_log( "Getting main window to close us" );
            w.opener['$application'].closeWindow( id );
            return;
        }
    }

    if( w && !w.closed )
        w.close();      // this should provoke .closed()
                        // which handles the 'disconnect'
}

// ------------------------------------------------------------------
// Main window is closing, close sub-windows
_.unload = function ( e ) {
    this.unloading = 1;
    for ( var id in this.other_windows ) {
        fb_log( id + '.close()' );
        this.other_windows[ id ].close();
    }
}

// ------------------------------------------------------------------
// Sub window is closing
_.closed = function ( id, e ) {
    if( this.unloading )        // skip out early
        return;
    if( ! e.target.location ) 
        return;
    if( e.target.location.toString() == 'about:blank' )   
        return;                 // this is unloading the initial about:blank
//    fb_log( e.target.location.toString() );
    fb_log( "Window " + id + " closed" );
    if( this.other_windows[ id ] ) {
        delete this.other_windows[ id ];
        var self = this;
        window.setTimeout( function () { self.disconnect( id ); }, this.BLIP );
    }
}


// ------------------------------------------------------------------
// Disconnect a sub window is closing
_.disconnect = function ( id ) {    // TODO: make sure this is a lateCommand
    this.runRequest( { event: 'disconnect', 
                       window: id 
                   } );
}

// ------------------------------------------------------------------
// Instructions for another window
_.for_window = function ( accume ) {
    for( var id in accume ) {
        var w = this.other_windows[ id ];

        var name = id;
        if( !w && window.name == id ) {
            // either window was already closed, or we are the main window
            w = window;
            name = 'main window';
        }
        var cmds = accume[ id ];
        delete accume[ id ];
        fb_log( "Instructions for |" + name + "|, count=" + cmds.length );
        w['$application'].runResponse( cmds );
    }
}

// ------------------------------------------------------------------
// Debuging some events
_.attrModified = function ( e ) {
    fb_log( e.target.id + "." + e.attrName + "=" + e.newValue );
}

_.click = function ( e ) {
    fb_log( e );
}

_.resize = function ( e ) {
    fb_log( { type: e.type, 
              width: e.currentTarget.innerWidth,
              height: e.currentTarget.innerHeight,
              target: e.currentTarget
          } );
}

