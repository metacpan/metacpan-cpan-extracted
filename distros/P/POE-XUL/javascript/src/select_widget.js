// ------------------------------------------------------------------
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------

// select_widget = new Object();

// ------------------------------------------------------------------
function SelectWidget ( id, contingent ) {
    this.ID = id;
    this.contingent = {};
    this.class_name = 'SelectWidget_inactive';

    for( var q=0 ; q<contingent.length ; q++ ) {
        var id = contingent[ q ];
        var group = this.group( id );
        if( group ) {
            Element.addClassName( group, 'SelectWidget_group' );
        }
        var input = this.input( id );
        this.contingent[ id ] = input.value;
    }    

    FormatedField.register( this.ID, this );
}

// ------------------------------------------------------------------
SelectWidget.prototype.validate = function ( on_submit ) {
    return true;
}

// ------------------------------------------------------------------
// Get the radio button for a given contingent ID
SelectWidget.prototype.radio = function ( id ) {
    var name = "RADIO_" + this.ID + "_" + id;
    return $( name );
}

// ------------------------------------------------------------------
// Get the element that groups all the contingent elements
SelectWidget.prototype.group = function ( id ) {
    var name = "GROUP_" + this.ID + "_" + id;
    return $( name );
}

// ------------------------------------------------------------------
// Get the input element for a given contingent ID
SelectWidget.prototype.input = function ( id ) {
    return $( id );
}



// ------------------------------------------------------------------
// 'current_id' is now the active element
// This will switch the CSS class names, check radio buttons, and more
SelectWidget.prototype.choose = function ( current_id ) {
    for( var id in this.contingent ) {
        if( id == current_id ) {
            this.set_active( id );
        }
        else {
            this.set_inactive( id );
        }
    }
}

// ------------------------------------------------------------------
// Has this input changed?  
// That is, has the active element changed
SelectWidget.prototype.changed = function ( on_submit ) {

    var formated = FormatedField.formated;
    for( var id in this.contingent ) {
        var radio = this.radio( id );
        if( radio && radio.checked ) {
            if( formated[ id ] && formated[ id ].changed ) {
                return formated[ id ].changed();
            }
            var input = this.input( id );
            return( input.value != this.contingent[ id ] );
        }
    }
    return false;
}


// ------------------------------------------------------------------
// Turn on this widget
SelectWidget.prototype.set_active = function ( id ) {
    var group = this.group( id );
    Element.extend( group );
    if( group.hasClassName( this.class_name ) ) {
        group.removeClassName( this.class_name );
    }

    var formated = FormatedField.formated;
    if( this.required && formated[id] ) {
        formated[id].required = 1;
    }

    var radio = this.radio( id );
    if( radio )
        radio.checked = true;
    var input = this.input( id );
    if( input ) 
        input.focus();
}

// ------------------------------------------------------------------
// Turn off this widget
SelectWidget.prototype.set_inactive = function ( id ) {
    var group = this.group( id );
    Element.extend( group );
    if( ! group.hasClassName( this.class_name ) ) {
        group.addClassName( this.class_name );
    }


    var radio = this.radio( id );
    if( radio )
        radio.checked = false;
}

// ------------------------------------------------------------------
// Is this the currently active widget?
SelectWidget.prototype.is_active = function ( id ) {
    var group = this.group( id );
    Element.extend( group );
    return !group.hasClassName( this.class_name );
}


// ------------------------------------------------------------------
SelectWidget.prototype.on_focus = function ( id ) {
    this.set_active( id );
}

// ------------------------------------------------------------------
SelectWidget.prototype.on_blur = function ( id ) {
    var input = this.input( id );
}
