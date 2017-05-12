// ------------------------------------------------------------------
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------

// ------------------------------------------------------------------
// Create the Class.inherit() method
Object.extend( Function.prototype, {
    inherit: function( obj ) {
        Object.extend( this.prototype, obj.prototype );
    }
});

// ------------------------------------------------------------------
// Create some useful methods in String
String.prototype.substring2 = function ( pos0, pos1, newS ) {
    return this.substring( 0, pos0 ) + newS + this.substring( pos1 );
}
String.prototype.substr2 = function ( pos0, len, newS ) {
    return this.substring( 0, pos0 ) + newS + this.substring( pos0+len );
}

String.prototype.reverse = function () {
    var ret = '';
    for( q = this.length-1 ; q>-1 ; q-- )
       ret += this.charAt(q);
    return ret;
}

// ------------------------------------------------------------------
String.prototype.html_escape = function () {
    function html_match (match) {
        return '&#' + match.charCodeAt( 0 ) + ';';
    }
    var text = this;
    return text.replace( /[\x80-\xff]/mg, html_match );
}



// ------------------------------------------------------------------
function focus_next_input( field ) {
    if( ! field.form ) {
        field.blur();
        return;
    }
    var i;
    // Find the current field's offset
    for (i = 0; i < field.form.elements.length; i++) {
        if (field == field.form.elements[ i ])
            break;
    }
    // Move focus to next field
    i = (i + 1) % field.form.elements.length;
    field.form.elements[ i ].focus();
    // field.blur();
}

// ------------------------------------------------------------------
function rollup(id, textOFF, textON) {
    var down    = $( "DOWN_" + id);
    var up      = $( "UP_" + id);
    var widget  = $( "WIDGET_" + id );
    
    if( !down )
        alert( "Missing DOWN_" + id );
    if( !widget )
        alert( "Missing WIDGET_" + id );

    if( !down || !widget ) {
        return false;
    }
    if( Element.visible( down ) ) {
        rollup_set( widget, textOFF, up, down );
    }
    else {
        rollup_set( widget, textON, down, up );
    }
    if( rollup.accordion ) {
        rollup_accordion( id, textOFF, textON ) ;
    }

    return false;
}
rollup.accordion = 1;

// ------------------------------------------------------------------
function rollup_set( widget, text, shown, hidden ) {

    if( shown )
        Element.show( shown );
    if( hidden )
        Element.hide( hidden );

    if( widget.textContent ) {
        widget.textContent = text;
    }
    else {
        widget.value = text;
    }
}

// ------------------------------------------------------------------
function rollup_accordion( down_id, textOFF, textON ) {
    
    var droppers = document.getElementsByTagName( 'groupbox' );
    fb_log( "Accordion on " + droppers.length + " elements" );
    for( var q = 0 ; q < droppers.length ; q++ ) {
        var gb = droppers[q];
        if( gb && gb.id && gb.id != down_id && 
                  gb.className && gb.className.match(/drop-down/) ) {
            
            var down    = $( "DOWN_" + gb.id );
            if( down && Element.visible( down ) ) {
                var widget = $( "WIDGET_" + gb.id );
                fb_log( "Drop down " + gb.id + " is down" );
                if( widget ) {
                    rollup_set( widget, textOFF, null, down );

                    fb_log( widget.id + ".onclick=" + 
                            widget.attributes['onclick'] );
                }
            }
        }
    }
}

// ------------------------------------------------------------------
function popup ( id, e ) {
    var el = $( id );
    if( el ) {
        if( Element.visible( el ) ) 
            Element.hide( el );
        else 
            Element.show( el );
    }

    if( e ) {
        e.stopPropagation();
        e.preventDefault();
    }
    return false;
}

// ------------------------------------------------------------------
function to_page( name ) {

    if( window.location.toString().match( /\.xul$/ ) ) {
        window.location = name + ".xul";
    }
    else {
        window.location = name + ".html";
    }
    return false;
}

// ------------------------------------------------------------------
function corner_div( side, width, background ) {
    var line = document.createElement( "div" );
    Element.setStyle( line, {
            height: "1px",
            overflow: "hidden",
            background: background,
        } );
    var m = "margin-"+side;
    line.style[ m.camelize() ] = width+"px";
    return line;
}

function corners ( id ) {
    var el = $( id );
    var dim = Element.getDimensions( el );
    var pos = Position.positionedOffset( el );
    
    // Left-side corner
    var left = document.createElement( "div" );
    var size = dim.height + "px";
    Element.setStyle( left, {
            width: size,
            height: size,
            overflow: "hidden",
            "background-color": "transparent",
            position: "fixed",
            top: pos[1] + "px",
            left: (pos[0] - dim.height) + "px"
        } );

    // Right-side corner
    var right = document.createElement( "div" );
    Element.setStyle( right, {
            width: size,
            height: size,
            overflow: "hidden",
            backgroundColor: "transparent",
            position: "fixed",
            top: pos[1] + "px",
            left: pos[0] + dim.width + "px"
        } );
    
    document.body.appendChild( left );
    document.body.appendChild( right );

    var background = Element.getStyle( el, 'background-color' );
    
    for( var q=0; q< dim.height; q++ ) {        // >
        left.appendChild( corner_div( "left", Math.round(q/2), background ) );
        right.appendChild( corner_div( "right", Math.round(q/2), background ) );
    }
}

// ------------------------------------------------------------------
function flush_right ( id ) {
    var el = $( id );
    var dim = Element.getDimensions( el );
    var pos = Position.positionedOffset( el );

    var body_dim = Element.getDimensions( document.body );

    // width of body - width of div - width of slope to the right - fudge
    el.style.left = (body_dim.width - dim.width - dim.height/2 -5 ) + "px";
    return;
}

// ------------------------------------------------------------------
function isalpha ( c ) {
    c = c.substr( 0, 1 );
    return ( c.toLowerCase() != c.toUpperCase() ? true : false );
}

// ------------------------------------------------------------------
// Set the size of some of the XUL elements based on window size
function set_window_style() {

}


// ------------------------------------------------------------------
// show a message in the firebug console, if it exists
function fb_log () {
    if( window['console'] && window['console']['log'] ) {
        console.log.apply( console, arguments );
    }
}

function fb_dir () {
    if( window['console'] && window['console']['dir'] ) {
        console.dir.apply( console, arguments );
    }
}

function fb_runner ( cmds ) {
    if( window['console'] && window['console']['group'] ) {
        console.group( 'Runner cmds=%i', cmds );
    }
    if( 0 && window['console'] && window['console']['profile'] ) {
        console.profile();
    }
    fb_time( 'Runner' );
}

function fb_runnerEnd () {
    fb_timeEnd( 'Runner' );
    if( 0 && window['console'] && window['console']['profileEnd'] ) {
        console.profileEnd();
    }
    if( window['console'] && window['console']['groupEnd'] ) {
        console.groupEnd.apply( console, arguments );
    }
}

function fb_time () {
    if( window['console'] && window['console']['time'] ) {
        console.time.apply( console, arguments );
    }
}

function fb_timeEnd () {
    if( window['console'] && window['console']['timeEnd'] ) {
        console.timeEnd.apply( console, arguments );
    }
}

// ------------------------------------------------------------------
function $debug ( string ) {
    if( window['console'] && window['console']['log'] ) {
        console.log.apply( console, arguments );
    }
}

// ------------------------------------------------------------------
function $message ( string ) {
    var msg = $( 'USER-Message' );
    if( msg && msg.addMessage ) {
        msg.addMessage( string, 1 );
    }
}


// ------------------------------------------------------------------
// Create some useful methods in Element
// Lifted from prototype's unittest.js
Element.isVisible = function(element) {
    element = $(element);
    if(!element) return false;
    if(!element.parentNode) return true;
    if(element.style && Element.getStyle(element, 'display') == 'none')
        return false;
    
    return Element.isVisible( element.parentNode );
}

// ------------------------------------------------------------------
// Make a XUL node draggable
function xulDraggable ( params ) {
    this.maxLeft = params.maxLeft;
    this.maxTop = params.maxTop;
    this.startPos = 0;
    this.waiting = 0;
    if( params['node'] ) {
        this.node( params.node );
    }
    if( params['activeNode'] ) {
        this.activeNode( params.activeNode );
    }
    else if( this['mNode' ] ) {
        this.activeNode( this.mNode );
    }
}

// ------------------------------------------------------------------
xulDraggable.prototype.node = function ( el ) {
    this.mNode = el;
}

// ------------------------------------------------------------------
xulDraggable.prototype.activeNode = function ( el ) {
    this.aNode = el;

    var self = this;
    el.addEventListener("mousedown", function (e) { self.mouseDown(e) }, false);
    this.mMove = function (e) {self.mouseMove(e) };
    this.mUp = function (e) {self.mouseUp(e) };

    // 2008/05 while mouseout seems like a good idea, it can cause
    // us to loose "hold" if the mouse moves faster then mouseMove
    // events are sent
//  el.addEventListener("mouseout", function (e) { self.mouseUp(e) }, false);

}

// ------------------------------------------------------------------
xulDraggable.prototype.mouseDown = function (event) {
    this.startPos = { X: event.clientX,
                      Y: event.clientY,
                      top: parseInt( this.mNode.style.top ),
                      left: parseInt( this.mNode.style.left )
                    };
    window.addEventListener("mousemove", this.mMove, false);
    window.addEventListener("mouseup", this.mUp, false);
    // fb_log( this.startPos );
}

// ------------------------------------------------------------------
xulDraggable.prototype.mouseUp = function (event) {
    this.startPos = 0;
    window.removeEventListener("mousemove", this.mMove, false);
    window.removeEventListener("mouseup", this.mUp, false);
}

// ------------------------------------------------------------------
xulDraggable.prototype.mouseMove = function (event) {
    if (this.startPos != 0) {
        var deltaX = event.clientX-this.startPos.X;
        var deltaY = event.clientY-this.startPos.Y;
        this.moveBy( deltaX, deltaY );
    }
}

// ------------------------------------------------------------------
xulDraggable.prototype.moveBy = function (deltaX, deltaY) {
    if( this.startPos != 0 ) {

        var X = this.startPos.left + deltaX;
        X = Math.max( X, 0 );
        X = Math.min( X, this.maxLeft );

        var Y = this.startPos.top + deltaY;
        Y = Math.max( Y, 0 );
        Y = Math.min( Y, this.maxTop );

        // fb_log( { deltaX: deltaX, deltaY: deltaY, X: X, Y: Y } );
        this.moveTo( X, Y );
    }
}

// ------------------------------------------------------------------
xulDraggable.prototype.moveTo = function (X, Y) {
    this.left = X;
    this.top = Y;
    if( ! this.waiting ) {
        // this.__moveTo();
        this.waiting = 1;
        var self = this;
        window.setTimeout( function () { self.__moveTo() }, 100 );
    }
}

xulDraggable.prototype.__moveTo = function () {
    this.mNode.style.left = this.left + "px";
    this.mNode.style.top = this.top + "px";
    this.waiting = 0;
    // fb_log( { left: this.left, top: this.top } );
}
