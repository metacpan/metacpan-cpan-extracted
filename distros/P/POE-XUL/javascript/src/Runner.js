// ------------------------------------------------------------------
// Portions of this code based on works copyright 2003-2004 Ran Eilam.
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------
function Throw(a, b) {
    if( window['console'] && console['trace'] )
        console.trace( b );
    var message = a;
    if( b ) {
        message = ( a.description || a.message );
        if( a['filename'] )
            message += "\n  File " + a.filename;
        if( a['lineNumber'] )
            message += " line " + a.lineNumber;
        message += "\n" + b;
    }
    fb_log(message);
    var exception     = new Error( message );
    throw exception;
}


function POEXUL_Runner () {

    if( POEXUL_Runner.singleton ) 
        return POEXUL_Runner.singleton;

    // Document element
    this.document = window.document;
    // <window> node
    var wel = window.document.getElementsByTagNameNS( 
                                $application.xulNS,
                                'window' );
    this.windowEl = wel[0];
    // fb_log( wel[0] );

    // Also used by .deferSelectedIndex()
    this.BLIP = 5;
    // Note : this grows in .runDone()
    this.slice_size = 64;
    this.timeouts = {};
}

var _ = POEXUL_Runner.prototype;

POEXUL_Runner.get = function () {
    if( !POEXUL_Runner.singleton ) 
        POEXUL_Runner.singleton = new POEXUL_Runner;
    return POEXUL_Runner.singleton;
}
 
// ------------------------------------------------------------------
_.run = function ( response ) {

    fb_runner( response.length );

    this.start = Date.now();
    this.resetBuffers();

    var commands = [];
    var accume = {};
    var for_win = window.name;
    var have_accume = 0;
    for( var R=0; R < response.length; R++ ) {
        var I = response[R];
        if( 0==I.length ) {
            // do nothing
        }
        else if( I[0] == 'for' ) {     // which window is this for?
            for_win = I[1];
        }
        else if( for_win == window.name ) { // for our window?
            var cmd = {
                methodName: I[0],
                nodeId: I[1],
                arg1: I[2], 
                arg2: I[3],
                arg3: I[4],
                arg4: I[5],
            };
            commands.push( cmd );           
        }
        else if( accume[ for_win ] ) {      // other window?
            accume[ for_win ].push( I );
        }
        else {
            accume[ for_win ] = [ I ];
            have_accume = 1;
        }
    }

    this.EXs = [];
    this.nCmds = commands.length;

    // fb_log( { nCmds: this.nCmds, slice_size: this.slice_size } );
    if( this.nCmds > 10*this.slice_size && $status ) {
        fb_log( "Running " + this.nCmds + " commands" );
        $status.progress( 0, this.nCmds );
        $status.show();
    }

    this.runCommands( commands );

    if( have_accume ) {
        if( window.name == '' ) {
            // we are the main window
            $application.for_window( accume );
        }
        else {
            window.opener[ '$application' ].for_window( accume );
        }
    }
}

// ------------------------------------------------------------------
// Run the commands
_.runCommands = function ( commands ) {
    if( commands.length )
        this.runBatch( commands, 0 );
    if( ! commands.length ) 
        this.runFinished();
}

// ------------------------------------------------------------------
// Run a batch of commands, then give up a time-slice
_.runBatch = function ( commands, late ) {

    if( late && 0 ) {
        fb_log( 'runBatch n=' + commands.length + " late=" + late );
    }
    var count = 0;
    var accume = {};
    var for_win = window.name || '';

    while( commands.length ) {
        count++;
        try {
            
            var cmd = commands.shift();
            if( late && 0 ) 
                fb_log( 'runBatch count=' + count + 
                        " command=" + cmd.nodeId + "." + cmd.arg1 );
            this.late = late;
            var rv = this.runCommand( cmd );
            this.late = 0;

            if( rv || count > this.slice_size ) {
                if( $status ) 
                    $status.progress( (this.nCmds - commands.length), 
                                           this.nCmds );
                this.deferCommands( commands, late );
                return;
            }
        }
        catch ( ex ) {
            fb_log( 'exception = ' + ex );
            this.EXs.push( ex );
        }
    }
}

// ------------------------------------------------------------------
// Commands are done
_.runFinished = function () {

    // fb_log( 'runFinished' );
    if( $status ) {
        $status.progress( this.nCmds, this.nCmds );
    }

    this.addNewNodes();
    this.runLateCommands( 1 );
}

// ------------------------------------------------------------------
// Give up a "timeslice" so the UI can be updated
// This is important for XBL anonymous content
_.deferCommands = function ( commands, late ) {
    var self = this;
    var blip = self.BLIP;
    if( late ) 
        blip *= 20;
    if( late && 0 ) 
        fb_log( 'defer n=' + commands.length + 
                        " late=" + late + 
                        " blip=" + blip );
    window.setTimeout( function () { 
                                if( late == 0 ) {
                                    self.runCommands( commands );
                                }
                                else {
                                    self._runLateCommands( commands, late );
                                }
                            }, 
                            blip
                         );
}


// ------------------------------------------------------------------
_.addNewNodes = function () {

    var roots = this.newNodeRoots;
    for( var parentId in roots ) {
        // prototype.js's Object.each is getting into our Array
        if( 'object' == typeof roots[parentId] ) {
            var rootNode = this.getNode( parentId, true );
            if( ! rootNode ) {
                fb_log( "Out of order root %s is a new node", parentId );
                rootNode = this.newNodes[parentId];
            }
            if( ! rootNode ) {
                fb_log( "Failed to find parent ", parentId );
                fb_log( { for: roots[parentId],
                          newNodes: this.newNodes 
                      } );
            }
            else {
                for( var child in roots[parentId] ) {
                    // prototype.js's Object.each is getting into our Array
                    if( 'object' == typeof roots[parentId][child] ) {
                        //fb_log( "parentID="+parentId+ " child=" +
                        //                        roots[parentId][child] );
                        this.addElementAtIndex( rootNode, 
                                                roots[parentId][child] 
                                              );
                    }
                }
            }
        }
    }
    this.newNodeRoots = {};
}

// ------------------------------------------------------------------
_.runLateCommands = function ( age ) {

    // fb_log( 'runLateCommands' );
    if( $status )
        $status.hide();

    if( age > 10 ) {
        alert( "Too many loops! age=" + age );
    }
    else {
        var lateCommands = this.lateCommands;
        if( lateCommands.length ) {
            this.lateCommands = [];
            this.deferCommands( lateCommands, age );
            return;
        }
    }
    this.runDone();
}

// ------------------------------------------------------------------
_._runLateCommands = function ( lateCommands, age ) {
    // fb_log( 'late commands age=' + age + " n=" + lateCommands.length );

    this.runBatch( lateCommands, age );

    if( lateCommands.length )       // defered to later
        return;

    this.runDone();
}

// ------------------------------------------------------------------
_.runDone = function () {
    // we are really finished
    if( $status )
        $status.hide();
    this.slice_size = 256;
    this.resetBuffers();
    this.handleExceptions();

    this.nCmds = 0;
    this.booting = false;
    $application.status( 'done' );
    fb_runnerEnd();
}

// ------------------------------------------------------------------
_.handleExceptions = function () {
    if( this.EXs.length ) {
        var ex = this.EXs;
        this.EXs = [];
        this.largeThrow( ex );
    }
}

_.largeThrow = function ( EXs ) {

    $application.exception( "JAVASCRIPT", EXs );
}

// commands -------------------------------------------------------------------

// Run one command.
// Returning 1 means we want to give up a timeslice
_.runCommand = function (command) {
    var methodName = command['methodName'];
    var nodeId     = command['nodeId'];
    var arg1       = command['arg1'];
    var arg2       = command['arg2'];
    var arg3       = command['arg3'];
    var rv         = 0;
    if (methodName == 'new') {
        if (arg1 == 'window')
            this.commandNewWindow(nodeId);
        else
            this.commandNewElement(nodeId, arg1, arg2, arg3);
    }
    else if (methodName == 'textnode' ) {
        this.commandNewTextNode( nodeId, arg1, arg2 );
    }
    else if (methodName == 'SID') {
        $application.setSID( nodeId );
    }
    else if (methodName == 'boot') {
        if( $status )
            $status.title( nodeId );
        this.booting = true;
        rv = 1;
    }
    else if ( methodName == 'bye' ) {
        this.commandByeElement(nodeId);
    }
    else if ( methodName == 'bye-textnode' ) {
        this.commandByeTextNode( nodeId , arg1 );
    }
    else if( methodName == 'set' ) {
        if ( !this.late && ( POEXUL_Runner.lateAttributes[arg1] || 
                        this.isLateCommand( command ) ) ) {
            // fb_log( 'late = ' + nodeId + "." + arg1 + "=" + arg2 );
            this.lateCommands.push(command);
        }
        else {
            rv = this.commandSetNode(nodeId, arg1, arg2);
        }
    }
    else if( methodName == 'remove' ) {
        this.commandRemoveAttribute(nodeId, arg1);
    }
    else if( methodName == 'method' ) {
        this.commandMethod(nodeId, arg1, arg2);
    }
    else if( methodName == 'javascript' ) {
        this.commandJavascript( arg1 );
    }
    else if( methodName == 'ERROR' ) {
        $application.crash( arg1 );
    }
    else if( methodName == 'cdata' ) {
        this.commandCDATA( nodeId, arg1, arg2 );
    }
    else if( methodName == 'style' ) {
        this.commandStyle( nodeId, arg1, arg2 );
    }
    else if( methodName == 'popup_window' ) {
        this.commandPopupWindow( nodeId, arg1 );
    }
    else if( methodName == 'close_window' ) {
        this.commandCloseWindow( nodeId );
    }
    else if( methodName == 'timeslice' ) {
        // fb_log( methodName );
        rv = 2;
    }
    else if( window.name ) {
        fb_log( window.name + ": Unknown command '" + methodName + "'" );
    }
    else {
        fb_log( "Unknown command '" + methodName + "'" );
    }
    return rv;
}

// ------------------------------------------------------------------
_.isLateCommand = function ( command ) {
    var nodeId     = command['nodeId'];
    var key        = command['arg1'];
    var element = this.newNodes[nodeId];
    if (!element) element = this.getNode(nodeId, 1);
    if (!element) return true;
    if( key == 'textNode' && element.nodeName == 'script' ) {
        return true;
    }
    if( key == 'value' && element.nodeName == 'search-list' ) {
        // fb_log( 'late value=' + command['arg2'] );
        return true;
    }
    return false;
}

// ------------------------------------------------------------------
_.commandNewWindow = function (nodeId) {
    this.windowId = nodeId;
}

// ------------------------------------------------------------------
_.commandNewElement = function (nodeId, tagName, parentId, index) { 
    try {
        var element = this.createElement(tagName, nodeId);
        element.setAttribute('_addAtIndex', index);
        this.newNodes[nodeId] = element;

        var parent = this.newNodes[parentId];
        if (parent)
            this.addElementAtIndex(parent, element);
        else {
            // New elements are added to existing nodes in one batch
            // in addNewNodes
            if( ! this.newNodeRoots[parentId] )
                this.newNodeRoots[parentId] = [];
            this.newNodeRoots[parentId].push( element );
        }

        if (tagName == 'listbox') {
            // onselect works but addEventListener( 'select' ) doesn't
            element.setAttribute( 'onselect', 
                                    '$application.fireEvent_Select(event);' );
            //element.addEventListener( 'select', 
            //         function (e) { alert( 'select' ); 
            //                $application.fireEvent_Select( e ) }, true );
        }
        else if (tagName == 'colorpicker') {
            element.setAttribute(
                'onselect',
                '$application.fireEvent_Pick({"targetId":"' +
                    element.id + '"})'
            );
        }
    } catch (e) {
        Throw(e,
            'Cannot create new node : [' + nodeId +
            ', ' + tagName + ', ' + parentId + ']'
        );
    }
}

// ------------------------------------------------------------------
_.commandCDATA = function ( nodeId, index, data ) { 
    try {
        var cdata = this.document.createCDATASection( data );

        var element = this.newNodes[nodeId];
        if (!element) element = this.getNode(nodeId);

        this.addElement( element, cdata, index );

        if( element.nodeName == 'script' &&
                element.getAttribute( 'type' ) == 'text/javascript' ) {
            this.lateCommands.push( { methodName: 'javascript', 
                                      nodeId: nodeId, 
                                      arg1: data 
                                  } );
        }
    } catch (e) {
        Throw(e,
                'Cannot create new CDATA: ' + nodeId +
                        '[' + index + ']=' + data 
            );
    }
}

// ------------------------------------------------------------------
_.commandStyle = function ( nodeId, property, value ) { 
    try {
        var element = this.newNodes[nodeId];
        if (!element) element = this.getNode(nodeId);

        //if( property != 'display' || value != 'none' || 
        //        nodeId == 'XUL-Details' ) 
        //          fb_log( nodeId + ".style."+property+"="+value );
        element.style[property] = value;
        if( property == 'display' && value == 'none' &&
                            element.tagName == 'groupbox' )
            this.clearGroupbox( element );        
    } catch (e) {
        Throw(e,
                'Cannot set style ' + nodeId + '.style.' + property + 
                                      '=' + value 
            );
    }
}

// ------------------------------------------------------------------
_.commandNewTextNode = function ( nodeId, index, text ) { 
    try {
        var tn = this.document.createTextNode( text );

        var element = this.newNodes[nodeId];
        if( !element ) 
            element = this.getNode(nodeId);
        if( index < 0 ) {
//            index = this.firstTextNode( element );
        }
        // fb_log( "Text node = %i", index );
        this.addElement( element, tn, index );
    } catch (e) {
        Throw(e,
                'Cannot create new TextNode: ' + nodeId +
                        '[' + index + ']=' + text 
            );
    }
}

// find the first textnode child
_.firstTextNode = function ( element ) {

    var index = 0;
    var node = element.firstChild;
    while( node ) {
        if( node.nodeName == '#text' ) {
            return index;
        }
        index++;
        node = node.nextSibling;
    }
    return -1;
}


_.addElement = function ( parent, node, index ) {
    var count = parent.childNodes.length;
    if( index == null || count == 0 || index < 0 || index >= count ) {
        parent.appendChild( node )
    }
    else {
        var el = parent.replaceChild( node, parent.childNodes[index] );
        // work around the fact XBL doesn't call destuctor
        if( el.dispose )
            el.dispose();
    }
}


// ------------------------------------------------------------------
_.commandByeTextNode = function ( nodeId, index ) { 
    try {
        var element = this.newNodes[nodeId];
        if (!element) 
            element = this.getNode(nodeId, 1);
        if (!element)
            return;
        if ( index < element.childNodes.length ) {
            element.removeChild( element.childNodes[index] );
        }
    } catch (e) {
        Throw(e,
                'Cannot remove TextNode: ' + nodeId + '[' + index + ']'
             );
    }
}

// ------------------------------------------------------------------
_.commandMethod = function ( nodeId, method, args ) { 
    try {
        var element = this.newNodes[nodeId];
        if( !element ) 
            element = this.getNode(nodeId);
        fb_log( "%s.%s(", nodeId, method, args );
        element[method].apply( element, args );

    } catch (e) {
        Throw(e, 'Cannot call method: ' + nodeId + '.' + method );
    }
}


// ------------------------------------------------------------------
_.commandSetNode = function (nodeId, key, value) { 
    var rv = 0;
    try {
        if( this.changedIDs[ nodeId ] ) {
            nodeId = this.changedIDs[ nodeId ];
        }

        var freshNode = true;
        var element = this.newNodes[nodeId];
        if (!element) {
            freshNode = false;
            element = this.getNode(nodeId, 1);
        }

        if( !element ) {
            if( !this.late ) 
                alert( "Missing new element" + nodeId );
            return;
        }

        if (key == 'textNode') {
            element.appendChild(this.document.createTextNode(value));
            return;
        }

        if (POEXUL_Runner.booleanAttributes[key]) {
            value = (value == 0 || value == '' || value == null)? false: true;
            if (!value) {
                element.removeAttribute(key);
            }
            else {
                element.setAttribute(key, 'true');
            }
            if( POEXUL_Runner.propertyAttributes[key] ) {
                this.commandSetProperty( element, key, value );
            }
            return;
        }

        if (POEXUL_Runner.simpleMethodAttributes[key]) {
            if (element.tagName == 'window')
                window[key].apply(window, [value]);
            else if( element[key] ) {
                // fb_log( element.id + "." + key + " (late="+this.late+")" );
                element[key].apply(element, [value]);
            }
            else {
                // still too early to run this
                this.lateCommands.push( { methodName: 'set',
                                          nodeId: element.id,
                                          arg1: key,
                                          arg2: value
                                      } );
            }
            return;
        }
        if( key == 'id' ) {
            if( this.newNodes[ nodeId ] ) {
                this.newNodes[ value ] = this.newNodes[ nodeId ];
                delete this.newNodes[ nodeId ];
                this.changedIDs[ nodeId ] = value;
            }
        }
        else if( POEXUL_Runner.activateEvent[ key ] ) {
            this.commandSetEvent( element, key, value );
        }

        if ( POEXUL_Runner.propertyAttributes[key] ) {
            this.commandSetProperty( element, key, value );
            if( key == 'selectedIndex' )
                return;
            // Question : under what circumstances is setting the property
            // and the attribute not good idea?
        }
        // Some attributes are also properties.  And have to be set there
        // also.
        else if( !freshNode && POEXUL_Runner.freshAttributes[ key ] ) {
            if( ! key in element ) {
                fb_log( "Curses!  %s isn't available.  Maybe XBL not activated yet", key );
            }
            // fb_log( "Non-fresh %s.%s='%s'", element.id, key, value );
            this.commandSetProperty( element, key, value );
        }
        // Add (or remove) the attribute
        if( value == undefined ) {
            element.removeAttribute( key );
        }
        else {
            element.setAttribute( key, value );
        }
        //if( POEXUL_Runner.propertyAlso[key] )
        //    element[key] = value

        if( key == 'style' && value && value.match( /display:\s*none/ ) && element.tagName == 'groupbox' )
            this.clearGroupbox( element );        

    } 
    catch (e) {
        throw(e);
        Throw(e,
            'Cannot do set on node: [' + nodeId + ', ' + key + ', ' + value + ']'
        );
    }
    return rv;
}

// ------------------------------------------------------------------
_.commandSetProperty = function ( element, key, value ) {
    try {
        // For some random reason, element['value'] = value isn't always
        // calling our property setter.  So, we create setValue which so far
        // seems to do the trick
        var setter = "set-" + key;
        setter = setter.camelize();
        if ( 'function' == typeof element[setter] ) {
            var array = [ value ];
            element[setter].apply( element, array );
        }
        else if (key == 'selectedIndex') {
            this.commandSelectedIndex( element, value );
            return;
        }
        else if (key == 'callback' ) {
            this.commandCallback( element, value );
            return;
        }
        else {
            element[key] = value;
        }
    }
    catch (e ) {
        Throw( e,
                'Cannot set ' + element.id + '.' + key + '=' + value
             );
    }
}


// ------------------------------------------------------------------
_.commandSetEvent = function ( element, key, value ) {

    // key = clickable
    var event = POEXUL_Runner.activateEvent[ key ];
    // event = click

    var att = key + "-code";
    // att = clickable-code

    // fb_log( { key: key, event: event, att: att, id: element.getAttribute( 'id' ) } );

    if( value && value != "0" ) {
        // Already active?
        if( element[att] )
            return;

        var ev = event.slice( 0, 1 ).toUpperCase() +
                 event.slice( 1 );
        // ev = Click
        element[att] = function (e) { 
                                // make sure clickable is still set
                                var now = element.getAttribute( key );
                                fb_log( { key: key, now: now } );
                                if( now && now != "0" )
                                    $application.fireEvent( ev, 
                                                        { target: element },
                                                        { from: key, 
                                                          now: now } 
                                                      );
                           };
        element.addEventListener( event, element[att], false );
    }
    else if( element[att] ) {
        var code = element[att];
        delete element[att];
        element.removeEventListener( key, code, false );
    }
}

// ------------------------------------------------------------------
_.commandSelectedIndex = function ( element, value, _try ) {

    var doit = 0, popup = 0;
    if( !_try ) {
        doit = 0;
    }
    else if( element.tagName == 'radiogroup' ) {
        if( element.appendItem ) doit = 1;
    }
    else if( element.tagName == 'menulist' ) {
        popup = element.menupopup;
        if( element.menupopup ) doit = 1;
    }
    else {
        fb_log( "how to tell if %s is active?", element.tagName );
        doit = 1;
    }
    if( !doit ) {
        this.deferSelectedIndex( element, value, _try );
        return;
    }

    var id = element.getAttribute( 'id' );
    var done;
    var sel;
    element.setAttribute("suppressonselect", 'true');
    if( value >= 0 ) {
        // This line should be enough... BUT ISN'T!  
        // I hate you, Milkman Random Behaviour
        element.selectedIndex = value;

        // But this is stupid : menulist.xml does all the following (and more)
        // in <property name="selectedItem">
        // We do it anyway, and pray.
        if( popup ) {
            sel = popup.childNodes[value-0];
            if( sel ) {
                element.selectedItem = sel;
                // Setting .value on editable="true" will cause the 
                // item to disapear
                var editable = element.getAttribute( 'editable' );
                if (!editable || editable != 'true' ) {
                    // Next line forces the display to be updated in 
                    // some situations
                    element.value = sel.getAttribute( 'value' );
                }
            }
        }
        else {
            sel = element.selectedItem;
        }

        if( sel ) {
            sel.setAttribute( 'selected', "true" );
        }
    }
    else {
        element.selectedItem = null;
    }
    element.removeAttribute( "suppressonselect" );
    
    return;
}

// ------------------------------------------------------------------
_.commandCallback = function ( element, value ) {
    
    var req = { attribute: value,
                source_id: element.id,
                event: 'Callback'
              };

    if( 'object' == typeof value ) {
        req.attribute = value.attribute;
        req.extra = value.extra;
    }

    var uri = $application.buildURI( req );
    var att = req.attribute.replace( "hidden-", "" );
    element.setAttribute( att, uri );
}

// ------------------------------------------------------------------
_.deferSelectedIndex = function ( element, value, _try ) {

    if( !_try ) 
        _try = 0;


    var id = element.getAttribute( 'id' );
    // fb_log( element.id + " has no menupopup try=" + _try );
    var tid = "TID.selectedIndex";
    _try++;
    if( _try < 6 ) {
        //if( _try > 1 )
        //    fb_log( "defering %s.selectedIndex try=%i", id, _try );

        // only the last one will stay in the loop
        if( this.timeouts[tid] ) {
            window.clearTimeout( this.timeouts[ tid ] );
        }

        // Do the commands as one batch, all together, after they
        // have all been added to the 'deferred' array
        var self = this;
        this.timeouts[tid] = window.setTimeout( function () {
                        delete self.timeouts[ tid ];
                        self.doDeferredSelectedIndex( tid );
                     }, this.BLIP * 20 );
        // Add the command to the batch
        if( ! this.deferredSelectedIndex ) 
            this.deferredSelectedIndex = [];
        this.deferredSelectedIndex.push( [ element, value, _try ] );
    }
    else {
        element.selectedIndex = value;
        element.setAttribute( 'selectedIndex', value );
        fb_log( 'Giving up on %s.selectedIndex=%i', id, value );
    }
}

// ------------------------------------------------------------------
// Do all the commands in the deferred batch
_.doDeferredSelectedIndex = function (tid) {
    var todo = this.deferredSelectedIndex;
    this.deferredSelectedIndex = [];

    var l = todo.length;
    for( var q=0; q<l; q++ ) {
        // fb_log( q, todo[q] );
        this.commandSelectedIndex( todo[q][0], todo[q][1], todo[q][2] );
    }
}

// ------------------------------------------------------------------
_.commandRemoveAttribute = function (nodeId, key, value) { 
    try {
        var element = this.newNodes[nodeId];

        if (!element) element = this.getNode(nodeId);
        element.removeAttribute( key );
        if( key in element && element.__lookupSetter__( key ) ) {
            fb_log( "remove %s.%s", element.id, key );
            element[key] = '';          // also clear the property
        }
    } catch (e) {
        Throw(e,
            'Cannot remove attribute from node: [' + nodeId + ', ' + key + ']'
        );
    }
}

// ------------------------------------------------------------------
_.commandSetTextNode = function ( element, nodeId, value ) {

    if (element.nodeName == 'script') {
        this.commandJavascript( value );
        return;
    }

    var textNode = this.document.createTextNode(value);
    // Look for an existing textNode
    if ( element.hasChildNodes() ) {
        var children = element.childNodes;
        for( var q=0 ; q < children.length ; q++ )  {
            var child = children[ q ];
            // HTML nodes might need .tagName
            if( child.nodeName == '#text' ) {
                // And replace it
                element.replaceChild( textNode, child );
                return;
            }
        }
    }
    // None exist.  So append one
    element.appendChild( textNode );
    return;
}

// ------------------------------------------------------------------
_.commandJavascript = function ( value ) {
    try {
        eval( value );
    } catch( e ) {
        Throw(e, 'Cannot evaluate javascript: ['+ value + ']' );
    }
}

// ------------------------------------------------------------------
// Delete an element
_.commandByeElement = function (nodeId) {
    // fb_log( 'bye ' + nodeId );

    var node = this.newNodes[nodeId];
    if( node ) {
        delete this.newNodes[nodeId];
        // fb_log( 'bye new node %s', nodeId );
        // above is probably enough... but one can never be too paranoid
    }
    else {
        node = this.getNode( nodeId, 1 );
        if( !node ) {
            // fb_log( 'Attempt to remove unknown node ' + nodeId );
            return;
        }
    }

    // Remove from DOM
    var p = node.parentNode;
    if( p ) 
        p.removeChild( node );

    // work around the fact XBL doesn't always call destuctor
    if( node.dispose )
        node.dispose();
}

// ------------------------------------------------------------------
_.commandFramify = function (nodeId) {
    $application.framify( nodeId );
}

// ------------------------------------------------------------------
_.commandPopupWindow = function (id, win) {
    // fb_log( "Open window "+id );
    var feat = "resizable=yes,dependent=yes";
    if( win.width ) {
        feat += ",width="+win.width;
    }
    if( win.height ) {
        feat += ",height="+win.height;
    }
    feat += ",location="+( win.location ? 'yes' : 'no' );
    feat += ",menubar="+( win.menubar ? 'yes' : 'no' );
    feat += ",toolbar="+( win.toolbar ? 'yes' : 'no' );
    feat += ",status="+( win.status ? 'yes' : 'no' );
    feat += ",scrollbars="+( win.status ? 'yes' : 'no' );

    if( ! win.url ) {
        win.url = $application.baseURI();
        win.url = win.url.replace( "/xul", 
                         "/popup.xul?SID=" + $application.getSID() +
                         "&app=" + $application.applicationName );
    }
    $application.openWindow( win.url, id, feat );
}

// ------------------------------------------------------------------
_.commandCloseWindow = function (id) {
    fb_log( "Close window "+id );
    $application.closeWindow( id );
}

// private --------------------------------------------------------------------

_.getNode = function (nodeId, safe) {
    var node = this._getNode(nodeId);
    if ( !node && !safe ) Throw("Cannot find node by Id: " + nodeId);
    return node;
}

_._getNode = function (nodeId) {
    if( this.windowId == nodeId ) {
        return this.windowEl;
    }
    else {
        return this.document.getElementById(nodeId);
    }
}   

_.createElement = function (tagName, nodeId) {
    var NS = $application.xulNS;
    if( tagName.match(/^html_/) ) {
        NS = $application.htmlNS;
        tagName = tagName.replace(/^html_/, '');
    }

    var element = this.document.createElementNS( NS, tagName );
    element.id = nodeId;
    return element;
}

_.addElementAtIndex = function ( parent, child ) {

    var index = child.getAttribute('_addAtIndex');
    child.removeAttribute('_addAtIndex');
    
    var count = parent.childNodes.length;
    if (index == null || index < 0 || count == 0 || index >= count ) {
        parent.appendChild(child);
        return;
    }
    else {
        parent.insertBefore( child, parent.childNodes[ index ] );
    }
}

// Node is being hidden, we clear its content
// This is a work around for Mozilla keeping old values in XBL nodes.
// This technique sucks, because our node is now out of sync with the 
// POE::XUL::Node.  This should propably be implemented in the widgets, but...
_.clearGroupbox = function ( node ) {
    if( node.nodeName != '#text' )
        this.clearNodes( node );
}

_.clearNodes = function ( node ) {
    try {
        if( node.hasAttribute( 'value' ) ) {
            this.commandSetNode( node.id, 'value', '' );
        }
    }
    catch (e) {
        fb_log( "Failed to setNode %s", node.id );
        fb_log(node);
        fb_log(e);
    }
    if( ! node.hasChildNodes() )
        return;

    var child = node.firstChild;
    while( child ) {
        if( child.nodeName != '#text' )
            this.clearNodes( child );
        child = child.nextSibling;
    }
}

_.resetBuffers = function () {
    this.newNodeRoots = {}; // top level parent nodes of those not yet added
    this.newNodes     = []; // nodes not yet added to document
    this.lateCommands = []; // commands to run at latest possible time
    this.changedIDs   = {}; // old ID -> new ID
}

// These attributes should be true or non-existant
POEXUL_Runner.booleanAttributes = {
    'disabled'     : true,
    'multiline'    : true,
    'readonly'     : true,
    'checked'      : true,
    'selected'     : true,
    'hidden'       : true,
    'default'      : true,
    'grippyhidden' : true
};

// These attributes should be set as node properties ( node["key"] = value )
POEXUL_Runner.propertyAttributes = {
    'selectedIndex' : true,
    'scrollTop'     : true,
    'scrollBottom'  : true,
    'callback'      : true,
//    'label'         : true,
//    'value'         : true,
//  'selected'      : true,
    'checked'       : true
};

// These attributes should be set as an attribute, and then as a property
POEXUL_Runner.propertyAlso = {
//    'label'         : true,
    'value'         : true,
//  'selected'      : true,
};


// These attributes should be set as node properties after the node is
// part of the document (ie, after XBL activation), before that, as attributes
// PROBLEM : there is a race condition if we get the command after the node
// is added to the DOM, but before the XBL is fully activated.  Grrrr...
POEXUL_Runner.freshAttributes = {
    'value'         : true,
    'splitTop'      : true,
    'id'            : true,
    'checked'       : true,
    'selected'      : true,
    'disabled'      : true
};

// These attributes should be set after the node is added to the document
POEXUL_Runner.lateAttributes = {
    'selectedIndex' : true,
    'sizeToContent' : true,
    'focus'         : true,
    'blur'          : true,
    'scrollTop'     : true,
    'scrollBottom'  : true,
    'recalc'        : true
};
// These aren't in fact attributes, but methods
POEXUL_Runner.simpleMethodAttributes = {
    'sizeToContent'       : true,
    'ensureIndexIsVisible': true,
    'focus'               : true,
    'blur'                : true,
    'recalc'              : true
};

POEXUL_Runner.activateEvent = {
    'clickable'       : 'click',
};

