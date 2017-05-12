// ------------------------------------------------------------------
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
//
// Allow multi-key selection of elements in a menulist.
// ------------------------------------------------------------------

// ------------------------------------------------------------------
function MultiKeypress ( textbox, menulist_id, timeout, width ) {
    this.textbox = textbox;
    this.menulist_id   = menulist_id;
    this.menulist = $( menulist_id );
    if( !timeout )
        timeout = 2;
    this.timeout = timeout;
    if( !width ) 
        width = 2;
    this.width = width;
    this.pressed = '';
    this.new_index = -1;
    this.changed = 0;

    var self = this;
//    this.menulist.addEventListener( 'focus', 
//                    function (e) { self.focus_menulist( e ) }, true );
    this.menulist.addEventListener( 'command', 
                    function (e) { self.command_menulist( e ) }, true );
    this.menulist.addEventListener( 'keypress', 
                    function (e) { self.keypress_menulist( e ) }, true );
    this.textbox.addEventListener( 'keypress', 
                    function (e) { self.keypress_textbox( e ) }, true );
}

var _ = MultiKeypress.prototype;


// ------------------------------------------------------------------
// Deal with a keypress on the menulist
_.keypress_menulist = function ( event ) {

    // Stop any timeout from happening
    if( this.tID ) {
        window.clearTimeout( this.tID );
        delete this['tID'];
    }

    var code = event.charCode ? event.charCode : event.which;
    if( code != 0 && event.keyCode != 9 ) {
        return this.keypress( event );
    }
    return true;
}

// ------------------------------------------------------------------
// Deal with a keypress on the textbox
_.keypress_textbox = function (event) {
    
    if( event.keyCode == 9 ) {   // tab
        fb_log( "Multikeypress tab" );
        // we want to prevent the focus from going to the menulist
        // going forwards => one extra advanceFocus()
        if( !event.shiftKey )
            document.commandDispatcher.advanceFocus();
        // backwards -> do nothing
        return true;
    }

    return this.keypress( event );
}

// ------------------------------------------------------------------
// Deal with a user's keypress
_.keypress = function (event) {
    
    var code = event.charCode ? event.charCode : event.which;
    var s, shorter;
    this.pressed = this.textbox.value;

    // other control key
    if( code == 0 || event.altKey || event.ctrlKey || event.metaKey ) {    
        fb_log( "code=" + code );
        return true;
    }
    // Backspace
    else if( code == 8 ) {
        if( this.textbox.selectionStart == 0 ) 
            return false;
        this.pressed = this.pressed.substr( 0, this.textbox.selectionStart-1 )
                        + 
                       this.pressed.substr( this.textbox.selectionEnd );
    
        this.textbox.selectionEnd = this.textbox.selectionStart 
        s = this.textbox.selectionStart -1 ;
        shorter = true;
    }
    // A letter
    else {
        var before = this.pressed;
        this.pressed = this.pressed.substr( 0, this.textbox.selectionStart )
                       + String.fromCharCode( code ) +
                       this.pressed.substr( this.textbox.selectionEnd );
        if( this.pressed != before ) {
            // get this change to the server sooner
            this.changed = 1;
        }
        s = this.textbox.selectionStart + 1;
    }
    this.drop_timeout();

    this.textbox.value = this.pressed;
    this.textbox.selectionEnd = this.textbox.selectionStart = s;

    // Go to the new item
    this.select_item( shorter );

    // Dispite these, mozilla's internal key handler is called.  Grrr.
    event.preventDefault();
    event.stopPropagation();

    // Create a new timeout
    this.create_timeout();
    return false;
}

// ------------------------------------------------------------------
_.create_timeout = function ( now ) {
    var multi = 1000;
    if( this.changed ) {
        multi = 500;
        if( this.textbox.value.length == 2 || this.changed > 2 ) {
            now = 1;
        }
    }
    if( now ) {
        this.changed = 3;   // get the change to the server right now
        multi = 100;
    }
    this.start_timeout( multi );
    return false;
}

// ------------------------------------------------------------------
// 
_.start_timeout = function ( multi ) {
    fb_log( "suppressonselect=%s",
            this.menulist.getAttribute( 'suppressonselect' )
          );
    fb_log( "timeout multiplier=" + multi );
    var self = this;
    this.tID = window.setTimeout( function () { self.timedout() }, 
                                  this.timeout * multi 
                                );
    return false;
}



// ------------------------------------------------------------------
// When the wait times out, the pressed buffer is reset to empty and
// the new item is sent to the server
_.timedout = function () {
    this.pressed = '';
    delete this['tID'];

    if( this.new_index != -1 )      // select the new item
        this.select( this.new_index );

    // sync the input to the drop down 
    var len = 2;
    if( this.textbox.value.length != len ) {
        this.textbox.value = 
                this.menulist.selectedItem.label.substr(0, len);
    }

    this.new_index = -1;

    this.submit();
}

// ------------------------------------------------------------------
// Stop any timeout from happening
_.drop_timeout = function () {
    if( this.tID ) {
        window.clearTimeout( this.tID );
        delete this['tID'];
    }
}


// ------------------------------------------------------------------
// Find the item that best matches the pressed buffer.
_.select_item = function ( shorter ) {

    fb_log( "pressed='" + this.pressed + "'" );

    var menumenulist = this.menulist;
    if( this.pressed == '' ) {
        return;
    }

    var items = menumenulist.menupopup.childNodes;
    this.new_index = -1;
    var maybe = -1;
    var pressed = this.pressed.toLowerCase();
    var w = 1;
    if( shorter ) {
        if( menumenulist.selectedItem.label.substr(0,pressed.length).toLowerCase()
            == pressed ) {
            fb_log( "no change" );
            return;
        }
    }

    while( w <= pressed.length ) {
        var match = 0;
        for( var q = (maybe < 0 ? 0 : maybe ) ; 
                 q < items.length && ! match;
                 q++ ) {

            var text = items[q].label.toLowerCase();
            var p0 = pressed.substr( 0, w );
            var t0 = text.substr( 0, w );
            if( p0 == t0 ) {
                maybe = q;
                match = 1;
                // fb_log( "match " + p0 + ">=" + t0 + " label=" + items[maybe].label );
            }
            else if( p0 > t0 ) {
                maybe = q;
                // fb_log( "maybe " + p0 + ">=" + t0 + " label=" + items[maybe].label );
            }
            else {
                // fb_log( "not " + p0 + ">=" + t0 );
            }
        }
        w++;
    }

    if( maybe > -1 ) {
        fb_log( "match " + items[maybe].label );
        this.new_index = maybe;
        this.select( this.new_index );
    }
}

// ------------------------------------------------------------------
// Setting selectedItem randomly triggers onChange.  So we do it explictly.
_.submit = function () {

    this.changed = 0;
    if( $application ) {
        fb_log( "submit #" + this.menulist.selectedIndex );
        
        var pop = this.menulist.childNodes[0];
        var target = pop.childNodes[ this.menulist.selectedIndex ];
        var e = { target: target };
        $application.fireEvent_Command( e );
    }
}


// ------------------------------------------------------------------
// It still does it's fucking around, despite the preventDefault()
// So the selection is done at timeout, when it's time to submit the
// new value
_.select = function ( new_index ) {
    fb_log( "want #" + new_index );
    if( this.menulist.selectedIndex != new_index ) {
        // Get this change to the server fast
        this.changed = 2;
    }
    this.menulist.selectedIndex = new_index;
    fb_log( "selected #" + this.menulist.selectedIndex );
    this.menulist.selectedItem = this.menulist.menupopup.childNodes[new_index];
    fb_log( "select label=" + this.menulist.menupopup.childNodes[new_index].label );

//    this.textbox.value = this.menulist.selectedItem.label.substr( 0, 2 );
}

// ------------------------------------------------------------------
// Wouldn't it be nice to know what element had focus previously? 
// Because we don't, we don't know when to skip this element.  90% of
// users won't know about shift-tab anyway
_.focus_menulist = function (event) {
}

// ------------------------------------------------------------------
// If the user selects something in the menulist, we want to update 
// the textbox
_.command_menulist = function (event) {

    this.textbox.value = event.target.value;
    return;

    var source = event.target;
    var text = source.label;
    fb_log( "select=" + text );
    this.textbox.value = source.substr( 0, this.width );
}
