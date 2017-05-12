combo = new Object();

// --------------------------------------------------------------------------
// Pseudo-combo-box-like input
// --------------------------------------------------------------------------

function PseudoCombo( id ) {
    this.ID = id;
}

// ------------------------------------------------------------------
// Fetch an element associated with this pseudo-combo
PseudoCombo.prototype.element = function ( prefix ) {
    var name = prefix + "_" + this.ID;
    var e = $( name );
    // if( ! e ) alert( "Can't find element id=" + name );
    return e;
}

// ------------------------------------------------------------------
PseudoCombo.prototype.widget_hide = function () {
  for (var i = 0; i < arguments.length; i++) {
        var e = this.element( arguments[i] );
        if( e ) 
            Element.hide( e );
    }
}

// ------------------------------------------------------------------
PseudoCombo.prototype.widget_show = function () {
  for (var i = 0; i < arguments.length; i++) {
        var e = this.element( arguments[i] );
        if( e ) 
            Element.show( e );
    }
}

// ------------------------------------------------------------------
PseudoCombo.prototype.remember = function ( mode, what ) {
    if( what == '' ) 
        return;
    var hidden = this.element( "ADDITIONAL" );
    hidden.value += "\xAD" + mode + "\xAD" + what;
}

// ------------------------------------------------------------------
PseudoCombo.prototype.update_widget = function ( mode, what ) {
    var select = this.element( "SELECT" );
    if( mode == '+' ) {
        // Append an Option to the list
        select.options[ select.options.length ] = 
                            new Option( what, what );
    }
    else {
        // Get rid of the current Option
        select.options[ select.selectedIndex ] = null;
    }
}


// ------------------------------------------------------------------
PseudoCombo.prototype.focus_widget = function () {
    var select = this.element( "SELECT" );
    select.focus();

    // Make sure that Option is visible
    select.selectedIndex = select.options.length -1;
}


// ------------------------------------------------------------------
// User clicked the [+] button for a combo box
PseudoCombo.prototype.add = function () {

    var e = this.element( "TEMPORARY" );
    e.value = '';

    this.activate();

    e.focus();

    return false;
}

// ------------------------------------------------------------------
// User clicked the [-] button for a combo box
PseudoCombo.prototype.del = function () {

    var select = this.element( "SELECT" );
    var option = select.options[ select.selectedIndex ];
    this.remember( '-', option.value );
    this.update_widget( '-', option.value );
    return false;
}

// ------------------------------------------------------------------
// Activate the input box
PseudoCombo.prototype.activate = function () {

    this.widget_hide( 'SELECT', 'ADD', 'DEL' );
    this.widget_show( 'TEMPORARY', 'MESSAGE_TEMPORARY', 'DONE' );

    return false;    
}

// ------------------------------------------------------------------
// Dectivate the input box
PseudoCombo.prototype.deactivate = function () {

    var obj = this;
    this.widget_hide( 'TEMPORARY', 'MESSAGE_TEMPORARY', 'DONE' );
    this.widget_show( 'SELECT', 'ADD', 'DEL' );
}

// ------------------------------------------------------------------
// User pressed a key in the input combo box
PseudoCombo.prototype.press = function( event ) {
    if( !event ) event = window.event;
    var keyCode = event_key_code( event );

    if (keyCode != 13)
        return true;
    focus_next_input( this.element( "TEMPORARY" ) );
    return false;
}

// ------------------------------------------------------------------
// User changed the value in the input combo box
PseudoCombo.prototype.on_change = function () {

    var temp = this.element( "TEMPORARY" );

    // Append the new value the select list
    if( temp.value != '' ) {
        this.remember( '+', temp.value );
        this.update_widget( '+', temp.value );
        temp.value = '';
    }
    else {
        this.remember( '-', temp.value );
        this.update_widget( '-', temp.value );
    }

    this.deactivate();

    // give focus to select list
    this.focus_widget();
    return true;
}


// --------------------------------------------------------------------------
//
// textarea-pseudo-combo-box-like input
//
// --------------------------------------------------------------------------
function PseudoComboTextarea( id, prefix ) {
    if( ! prefix )                  // what goes in front of a new message?
        prefix = '';
    this.text_prefix = prefix;
    PseudoCombo.call( this, id );
}

PseudoComboTextarea.inherit( PseudoCombo );
    
// ------------------------------------------------------------------
// Get the div that we appended to the list of messages
PseudoComboTextarea.prototype.previous_div = function( ) {
    var list = this.element( "LIST" );

    var div = list.lastChild;
    if( div && div.getAttribute( 'class' ) == 'temporary' ) {
        return div;
    }
    return;
}

// ------------------------------------------------------------------
// Don't move the focus
PseudoComboTextarea.prototype.focus_widget = function () {
    var list = this.element( "LIST" );
    var div = this.previous_div();

    // Move the list down to show the text
    var pos = Element.getDimensions( div );
    var top = list.scrollHeight - pos.height;
    if( top < 0 ) {
        top = 0;
    }
    // alert( "scrollHeight=" + list.scrollHeight + " height=" + pos.height );
    list.scrollTop = top;
}

// ------------------------------------------------------------------
PseudoComboTextarea.prototype.remember = function ( mode, what ) {
    var hidden = this.element( "ADDITIONAL" );
    if( mode == '-' )
        hidden.value = '';
    else 
        PseudoCombo.prototype.remember.apply( this, arguments );    
}

// ------------------------------------------------------------------
// Change the text of the widget. 
// In our case, we append/update the list of messages
PseudoComboTextarea.prototype.update_widget = function ( mode, text ) {
    var list = this.element( "LIST" );
    var div = this.previous_div();

    if( mode == '-' ) {
        if( div )
            list.removeChild( div );
    }
    else {
        if( !div ) {
            div = document.createElement( "div" );
            list.appendChild( div );
        }

        text = text.replace( /\n/, "\n" + this.text_prefix );
        div.textContent = this.text_prefix + text;
        div.setAttribute( 'class', 'temporary' );
    }
    return;
}

// ------------------------------------------------------------------
PseudoComboTextarea.prototype.activate = function () {
    PseudoCombo.prototype.activate.apply( this );
    var div = this.previous_div();
    if( div ) {
        // User has previously created a message
        this.widget_hide( 'MODIFY' );
        Element.hide( div );
    }
}

// ------------------------------------------------------------------
PseudoComboTextarea.prototype.deactivate = function () {
    PseudoCombo.prototype.deactivate.apply( this );
    var div = this.previous_div();
    if( div ) {
        // User has created a message
        this.widget_hide( 'ADD' );
        this.widget_show( 'MODIFY' );
        Element.show( div );
    }
}

// ------------------------------------------------------------------
// User wants to modify the message
PseudoComboTextarea.prototype.modify = function () {

    var div = this.previous_div();
    if( !div ) {
        return this.add();
    }
    var hidden = this.element( "ADDITIONAL" );

    var textarea = this.element( 'TEMPORARY' );
    textarea.value = hidden.value.substr( 3 );
    hidden.value = '';

    this.activate();

    textarea.focus();
    return false;
}

PseudoComboTextarea.prototype.on_change = function () {
    PseudoCombo.prototype.on_change.apply( this, arguments );
}
