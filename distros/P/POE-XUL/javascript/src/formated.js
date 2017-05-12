// ------------------------------------------------------------------
// Copyright 2007-2008 Philip Gwyn.  All rights reserved.
// ------------------------------------------------------------------


// ------------------------------------------------------------------
function FormatedField ( id, input ) {
    this.ID = id;
    this.input_element = input;
    FormatedField.register( id, this );
}

FormatedField.formated = new Object ();

// ------------------------------------------------------------------
FormatedField.register = function ( id, obj ) {
    FormatedField.formated[id] = obj;
}

FormatedField.unregister = function ( id ) {
    if( FormatedField.formated[ id ] ) 
        delete FormatedField.formated[ id ];
}

FormatedField.object = function ( id ) {
    return FormatedField.formated[ id ];
}

// ------------------------------------------------------------------
// Class method to validate all the fields in a form, before allowing
// the submit button to work
FormatedField.form_validate = function () {
    var formated = FormatedField.formated;
    var bad=0;
    var q;
    var msg = $( 'USER-Message' );
    if( msg && msg.clearMessage ) 
        msg.clearMessage();

    for( q in formated ) {
        if( ! formated[q].validate( 1 ) ) {
            if( bad == 0 ) {
                formated[q].focus();    // focus to first bad field
            }
            bad++;
            formated[q].error_show();
        }
    }
    if( bad ) {
        if( msg && msg.addMessage ) 
            msg.addMessage( "SVP r\xE9parez ces erreurs." );
        
        return false;
    }
    return true;
}


// ------------------------------------------------------------------
// XBL's destroy is only called onunload.  So we have to work around this
// http://groups.google.com/group/netscape.public.mozilla.xbl/browse_thread/thread/888f1ff538106542/0472c037cee184dd
// https://bugzilla.mozilla.org/show_bug.cgi?id=83635
FormatedField.clear_formated = function () {

    var q;
    var formated = FormatedField.formated
    for( q in formated ) {
        window.status = q;
        var f = formated[q];
        f.dispose();
    }
    formated = new Object ();
}

// ------------------------------------------------------------------
// Clean out all formated fields that no longer have a element
FormatedField.clean_formated = function () {

    var q;
    var formated = FormatedField.formated
    for( q in formated ) {
        var f = formated[q];
        try { 
            if( !f.has_element() ) {
                delete formated[q];
                f.dispose();
            }
        } catch ( e ) {
            alert( "Error cleaning " + q );
            throw( e );
        }
    }
}




// ------------------------------------------------------------------
FormatedField.prototype.dispose = function () {
    FormatedField.unregister( this.ID );
    delete this[ 'input_element' ];
    delete this[ 'error_element' ];
//    alert( "Dispose " + this.ID );
}



// ------------------------------------------------------------------
FormatedField.prototype.setInput = function (el) {
//    fb_log( "setInput " + this.xul_id );
//    fb_log( "input=" + el );
    this.input_element = el;
    // XUL elements created with XBL don't have IDs :-/
    if( el.id )
        this.ID = el.id;
}

FormatedField.prototype.input = function () {
    if( !this.input_element ) 
        this.input_element = $( this.ID );
    return this.input_element;
}

// ------------------------------------------------------------------
// Does this input still have an element?
FormatedField.prototype.has_element = function () {

    if( !this.ID && this.input_element )
        this.ID = this.input_element.id;

    if( this.ID )                   // does the element still exist
        return !! $( this.ID );
    return false;
}


// ------------------------------------------------------------------
FormatedField.prototype.setError = function (el) {
    this.error_element = el;
}

FormatedField.prototype.error = function () {
    if( !this.error_element ) 
        this.error_element = $( "ERROR_" + this.ID );
    return this.error_element;
}

FormatedField.prototype.error_show = function ( string ) {
    var err = this.error();
    if( err )
        Element.show( err );
    if( !string )
        return;
    var msg = this.user_message();
    if( msg && msg.setMessage ) 
        msg.setMessage( string );
}

FormatedField.prototype.error_hide = function ( on_load ) {
    var err = this.error();
    if( ! err ) return;
    Element.hide( err );
}

// ------------------------------------------------------------------
FormatedField.prototype.setMessage = function (el) {
    this.message_element = el;
}
FormatedField.prototype.message = function () {
    if( !this.message_element ) 
        this.message_element = $( "MESSAGE_" + this.ID );
    return this.message_element;
}


// ------------------------------------------------------------------
//
FormatedField.prototype.focus = function () {
    var input = this.input();
    try { input.focus(); } catch (e) {};
    // select() causes the whole input to be highlighted
    // try { input.select(); } catch (e) {};
}
    

// ------------------------------------------------------------------
FormatedField.prototype.validate = function ( on_submit ) {
    if( this.inactive ) 
        return true;

    if( this.required && on_submit ) {
        var input = this.input();
        if( input.value == '' ) {
            return false;
        }
    }
    return true;
}

// ------------------------------------------------------------------
FormatedField.prototype.user_message = function () {
    return $( 'USER-Message' );
}

// ------------------------------------------------------------------
FormatedField.prototype.valid_key = function ( k ) {
    return true;
}

// ------------------------------------------------------------------
FormatedField.prototype.is_insert = function ( ) {
    var input = this.input();
    
    return input.selectionStart == input.selectionEnd
            && input.selectionEnd > input.value.length;
}

// ------------------------------------------------------------------
FormatedField.prototype.is_substitution = function ( ) {
    var input = this.input();
    
    return input.selectionStart != input.selectionEnd;
}

// ------------------------------------------------------------------
FormatedField.prototype.is_append = function ( ) {
    var input = this.input();
    
    return input.selectionStart >= input.value.length;
}

// ------------------------------------------------------------------
FormatedField.prototype.insert_key = function ( k ) {
    var input = this.input();
    pos0 = input.selectionStart;
    input.value = input.value.substring2( pos0, input.selectionEnd, 
                                          String.fromCharCode( k ) );
    // move after new char
    input.selectionStart = input.selectionEnd = ++pos0;
}

// ------------------------------------------------------------------
FormatedField.prototype.get_key = function ( event ) {

    var k = event.charCode ? event.charCode : event.which;
    if( k == 0 || k == 8                // 0 == control, 8 == backspace
               || event.altKey || event.ctrlKey || event.metaKey ) {    
        return 0;
    }
    return k;
}

// ------------------------------------------------------------------
FormatedField.prototype.keypress = function ( event ) {
    if( !event ) event = window.event;

    this.error_hide();

    var k = this.get_key( event );
    if( k == 0 ) {
        return true;
    }
    if( this.valid_key( k ) ) {
        if( this.is_substitution() || this.validate( 0 ) ) {
            this.insert_key( k );
            if( ! this.validate( 0 ) ) {
                this.error_show();
            }
        }
        else {
            this.error_show();
        }
    }
    else if( k == 13 ) {
        focus_next_input( $( this.ID ) );        
    }

    return false;               // we do all the work
}

// ------------------------------------------------------------------
// Validate the field after the user moves out
// Putting up the error message when they leave
FormatedField.prototype.on_blur = function( event ) {
    this.error_hide();
    if( ! this.validate( 0 ) ) {
        this.error_show();
        return false;
    }
    return true;
}

// ------------------------------------------------------------------
//
// Input a whole number between min and max
//
// ------------------------------------------------------------------
function FormatedNumber( id, min, max, input ) {
    FormatedField.call( this, id, input );

    if( min == Number.NaN ) 
        min = 0;
    this.min = min;
    if( max == Number.NaN ) 
        max = Number.MAX_VALUE;
    this.max = max;

}

// Inherit from FormatedField
Object.extend( FormatedNumber.prototype, FormatedField.prototype );




// ------------------------------------------------------------------
FormatedNumber.prototype.valid_key = function ( k ) {
    if( this.min < 0 && k == 45 &&      // allow leading -
            this.input().selectionStart == 0 ) 
        return true;
    return ( 48 <= k && k < 58 );       // 48 = '0', 58 = '9'
}

// ------------------------------------------------------------------
FormatedNumber.prototype.validate = function ( on_submit ) {
    var input = this.input();
    // Make sure we have a value at submit time (required)
    if( on_submit && this.required && input.value == '' )
        return false;

    // Otherwise empty is OK
    if( input.value == '' )
        return true;

    // While entering data, a simple - is OK
    if( input.value == '-' )
        return !on_submit;

    if( !on_submit ) 
        return true;

    var i = parseInt( input.value );
    return ( this.min <= i && i <= this.max );
}

// ------------------------------------------------------------------
FormatedNumber.prototype.on_blur = function( event ) {
    if( !event ) event = window.event;
    var input = this.input();

    var v = parseInt( input.value, 10 );
    if( isNaN( v ) ) {
        if( this.required ) {
            if( input.id.match( /min\b/i ) ) {
                v = input.value = this.min;
            }
            else if( input.id.match( /max\b/i ) ) {
                v = input.value = this.max;
            }
        }
        else
            return true;
    }
    if ( this.min <= v && v <= this.max ) {
        // focus_next_input( input );
        return true;
    }
    else {
        input.focus();
        this.error_show( "Min=" + this.min + ", Max=" + this.max );
        // window.status = "Value=" + v + ", Min=" + this.min + ", Max=" + this.max;
        return false;
    }
}

// ------------------------------------------------------------------
FormatedNumber.prototype.on_focus = function ( event ) {
    if( !event ) event = window.event;

    this.error_hide();
}


// ------------------------------------------------------------------
//
//
// ------------------------------------------------------------------
function FormatedDate( id, input ) {
    FormatedField.call( this, id, input );
}

// Inherit from FormatedField
Object.extend( FormatedDate.prototype, FormatedField.prototype );


// ------------------------------------------------------------------
FormatedDate.prototype.validate = function ( on_submit ) {
    var input = this.input();
//    fb_log( "validate " + this.xul_id );
//    fb_log( "input=" + input );
//    fb_log( ".value=" + input.value );
    if( on_submit ) {
        this.set_default();
        if( this.required && input.value == '' )
            return false;
    }
    return true;
}



// ------------------------------------------------------------------
FormatedDate.prototype.keypress = function ( event ) {
    if( !event ) event = window.event; 
    var input = this.input();

    var k = this.get_key( event );
    if( k == 0 ) {
        return true;
    }
    if( k == 13 ) {             // 13 == enter
        focus_next_input( input );
        return false;
    }

    if( 48 > k || k > 58 ) {    // 48 = 0, 58 = 9
        return false;           // only numbers please
    }

    // ----------------
    // See what is being selected
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    if( (pos0 == 0 && pos1 == 10 ) ) {   // everything selected
        input.value = '';
        pos0 = pos1 = 0;
        input.selectionStart = pos0;
        input.selectionEnd = pos1;
    }
    else if( (pos0 == pos1 ) ) {         // nothing selected
                                        // do nothing
    } 
    else if( pos0 <= 1 && pos1 >= 3 ) {  // day + past the day
        input.selectionEnd = pos1 = 2;   // only select day
    }
    else {
        if( pos0 == 2 )                 // select just before DAY /
            input.selectionStart = pos0 = 3; // move just after
        if( pos0 == 5 )                 // select just before MONTH /
            input.selectionStart = pos0 = 6; // move just after
            
        if( pos0 <= 5 && pos1 >= 6 ) {   // month + past the /
            input.selectionEnd = pos1 = 5;   // only select month
        }
    }

    // ----------------
    // What keys are allowed depends on in the string
    var start = 48;                     // 48 = '0'
    var stop  = 58;                     // 58 = '9'
    var add_zero = 0;                   // 8 => 08

    if( pos0 == 0 ) {                   // day
                                        // [0123]
        stop  = 51;                     // 51 = '3'
        add_zero = 1;
    }
    else if( pos0 == 1 ) {              // day
        var first = input.value.substr( 0, 1 );
        if( first == '3' ) {            // 3[01]
            stop = 49;                  // 49 = '1'
        }
        else if( first == '0' ) {       // 0[123456789]
            start = 49;                 // 49 = '1'
        }
    }
    else if( pos0 == 3 ) {              // month
        stop = 49;                      // 49 = '1'
        add_zero = 1;
    }
    else if( pos0 == 4 ) {              // month
        var prev = input.value.substr( 3, 1 );
        if( prev == '1' ) {             // 1[012]
            stop = 50;                  // 50 = '2'
        }
        else {                          // 0[123456789]
            start = 49;                 // 49 = '1' 
        }
    }

    // ----------------
    // Is the current key valid
    var l = input.value.length;
    if( start > k || k > stop ) {
        if( add_zero && (48 <= k && k <= 58) ) {
            // pos0 and pos1 have been fixed previously, so we
            // know that if are here, are pointing at first digit of the 
            // day or month sub-field

            if( l == pos1 ) {           // append
                input.value += "0";     // do it the easy way
                l++;                    // and let
                pos0++;
                pos1++;
                l = input.value.length;
            }
            else {                      // insert/substitute
                // turn an insert into a substitution
                pos1 = input.value.indexOf( '/', pos1 );
                if( pos1 == -1 ) {
                    // if we can't find a '/', it means the string
                    // is very messed up. So erase all after this
                    pos1 = pos0;
                }

                // Do the substitution
                input.value = input.value.substring2( pos0, pos1, "0" );

                // Make sure new char is inserted after this
                input.selectionStart = ++pos0;
                input.selectionEnd = pos1 = pos0;
            }            
        }
        else
            return false;               // only numbers please
    }


    // ------------
    // insert the value
    if( l == 10 ) {                     // 12/34/5678 = 10 chars
        if( pos1 == l ) {
            return false;
        }
        pos1++;                         // overwrite?
    }    

    input.value = input.value.substring2( pos0, pos1, 
                                                String.fromCharCode( k ) );

    // move after new char
    input.selectionStart = input.selectionEnd = ++pos0;
    
    // move after the /
    if( pos0 == 2 || pos0 == 5 ) {      // 2 = after day, 5 = after month
        if( input.value.substr( pos0, 1 ) != '/' ) {  
            // automatically append a /
            input.value = input.value.substring2( pos0, pos0, "/" );
        }
        // Move past the /
        input.selectionStart = input.selectionEnd = ++pos0;
    }

    return false;
}

// ------------------------------------------------------------------
// User is entering the field
FormatedDate.prototype.on_focus = function ( event ) {
    if( !event ) event = window.event;
    var input = this.input();

    this.error_hide();

    if( input.value == "JJ/MM/AAAA" ) {
        input.value = '';
    }
}

// ------------------------------------------------------------------
FormatedDate.prototype.auto_default = function ( input ) {
    if( ! input ) {
        var input = this.input();
        var rv = this.auto_default( input );
        if( rv !== undefined )
            return rv;
        input = input.parentNode;
        if( !input )
            return false;
        rv = this.auto_default( input )
        if( rv !== undefined )
            return rv;

        input = input.parentNode;
        if( !input )
            return false;
        rv = this.auto_default( input )
        if( rv !== undefined )
            return rv;

        return false;
    }

    var ad = input.getAttribute( 'auto-default' );
    if( !ad ) 
        return;

//    fb_log( input );
    if( ad == 'non' || ad == 'no' ) 
        return false;
    return true;
}

// ------------------------------------------------------------------
// Set the default value
FormatedDate.prototype.set_default = function () {

    var input = this.input();
    var value = input.value;

    if( value == '' && ! this.auto_default() ) 
        return false;

    // Get rid of non-number and /
    var re = /[^\/0-9]/g;
    value = value.replace( re, '' );
    value = value.replace( /\/$/, "" );

    // Default is today
    var now = new Date();
    if( value.match( /^$/ ) ) {
        var day = now.getDate();
        if( day < 10 ) 
            day = "0" + day 
        value += day;
    }

    // Format the date
    value = value.replace( /^(\d)$/, "0$1" );       // 8  => 08
    value = value.replace( /^(\d)\//, "0$1/" );     // 8/ => 08/
    value = value.replace( /\/(\d)$/, "/0$1" );     // .../8 => .../08
    value = value.replace( /\/(\d)\//, "/0$1\/" );  // ../8/.. => ../08/..

    var found;

    // turn day => day in this month
    if( value.match( /^\d\d$/ ) ) {
        var month = (1+now.getMonth());
        if( month < 10 ) {
            month = "0" + month;
        }
        value = value + "/" + month + "/" + now.getFullYear();
    } 
    // day/month => this year
    else if( value.match( /^\d\d?\/\d\d?$/ ) ) {
        value = value + "/" + now.getFullYear();
    } 
    // partial year => full year in 21st century
    else if( found = value.match( /^(\d\d\/\d\d\/)(\d\d?\d?)$/ ) ) {
        
        var year = found[2].replace( /^0/, "" );
        year = 2000 + parseInt( year, 10 );
        value = found[1] + year;
    }

    input.value = value;
    input.setAttribute( "value", value );
    input.new_value = value;
    input.setAttribute( "new_value", value );
    return true;
}

// ------------------------------------------------------------------
// Reformat the date when user leaves the field
FormatedDate.prototype.on_blur = function ( event ) {
    if( !event ) event = window.event;
    var input = this.input();

    this.error_hide();

    this.set_default();     // build default value

    // everything is OK
    if( this.auto_default() && ! input.value.match( /^\d\d\/\d\d\/2\d\d\d$/ ) ) {
        // NO DON'T GO!
        input.focus();
        this.error_show();
        return false;
    }
//    input.value = value;
    return true;
}



// ------------------------------------------------------------------
//
// Input a formated string that looks like AREA-EXCHANGE-NUMBER
//  Where AREA     = 999
//        EXCHANGE = 999
//        NUMBER   = 999        
// ------------------------------------------------------------------
function FormatedTelephone( id, input ) {
    FormatedField.call( this, id, input );
}

// Inherit from FormatedField
Object.extend( FormatedTelephone.prototype, FormatedField.prototype );


// ------------------------------------------------------------------
FormatedTelephone.prototype.valid_key = function ( k ) {
    return ( 48 <= k && k <= 58 );            // 48 = '0', 58 = '9'
}

// ------------------------------------------------------------------
FormatedTelephone.prototype.keypress = function ( event ) {
    if( !event ) event = window.event; 
    var input = this.input();
    this.error_hide();

    var k = this.get_key( event );
    if( k == 0 ) {
        return true;
    }
    if( k == 13 ) {             // 13 == enter
        focus_next_input( input );
        return false;
    }

    // ----------------
    // See what is being selected
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    var add_dash = false;
    if( (pos0 == 0 && pos1 == 15 ) ) {   // everything selected
        input.value = '';
        pos0 = pos1 = 0;
        input.selectionStart = pos0;
        input.selectionEnd = pos1;
    }
    else if( (pos0 == pos1 ) ) {         // nothing selected
        if( pos0 < input.value.length ) {   // insert
                                            // make sure preceeding char is -
            if( (pos0 == 3 || pos0 == 7) 
                    && input.value.substr( pos0, 1 ) != '-' ) {
                input.value = input.value.substring2( pos0, pos0, '-' );
                input.selectionStart = input.selectionEnd = pos1 = ++pos0;
            }
        }
    } 
    else if( pos0 <= 2 && pos1 >= 4 ) {  
        input.selectionEnd = pos1 = 3;   // only select area code
        add_dash = true;
    }
    else {
        if( pos0 == 3 )                 // select just before AREA-
            input.selectionStart = pos0 = 4; // move just after
        else if( pos0 == 7 )            // select just before EXCHANGE-
            input.selectionStart = pos0 = 8; // move just after
        else if( pos1 == 4 )            // select just before AREA-
            input.selectionEnd = pos1 = 3; // move just after
        else if( pos1 == 8 )                 // select just before EXCHANGE-
            input.selectionEnd = pos1 = 7; // move just after
            
        if( pos0 <= 7 && pos1 >= 8 ) {   // EXCHANGE + past the -
            input.selectionEnd = pos1 = 7;   // only select EXCHANGE
        }
    }

    // ----------------
    var l = input.value.length;

    if( l >= 12 ) {                     // 123-345-5678 = 12 chars
        if( ! this.validate( 0 ) ) {
            this.error_show();
            return false;
        }    
    }
    if( !this.valid_key( k ) ) {
        return false;           // only numbers please
    }

    // ----------------
    // insert the value
    if( l == 12 ) {                     // 123-345-5678 = 12 chars
        if( pos1 == l ) {
            return false;
        }
        if( 0 == pos1-pos0 )
            pos1++;                         // overwrite?
    }
    else if( l > 12 ) {
        this.error_show();
    }

    input.selectionStart = pos0;
    input.selectionEnd   = pos1;
    this.insert_key( k );

    this.post_insert( k );
    return false;
}

// ------------------------------------------------------------------
FormatedTelephone.prototype.post_insert = function ( k ) {
    var input = this.input();

    pos0 = input.selectionStart;    

    // move after the /
    if( pos0 == 3 || pos0 == 7 ) {      // 3 = after AREA, 7 = after EXCHANGE
        if( input.value.substr( pos0, 1 ) != '-' ) {  
            // automatically append a /
            input.value = input.value.substring2( pos0, pos0, "-" );
        }
        // Move past the /
        input.selectionStart = input.selectionEnd = ++pos0;
    }

    return false;
}

// ------------------------------------------------------------------
// Validate a telephone number
FormatedTelephone.prototype.validate = function ( on_submit ) {
    var input = this.input();
    if( input.value == '' ) {
        return true;
    }
    return input.value.match( /^\s*\d\d\d-\d\d\d-\d\d\d\d\s*$/ );
}




// ------------------------------------------------------------------
//  HH:MM
//  HH -> 00-23
//  MM -> 00-59
// ------------------------------------------------------------------
function FormatedHeure( id, input ) {
    FormatedField.call( this, id, input );
}

// Inherit from FormatedField
Object.extend( FormatedHeure.prototype, FormatedDate.prototype );


// ------------------------------------------------------------------
FormatedHeure.prototype.validate = function ( on_submit ) {
    var input = this.input();
    if( on_submit && input.value == '' )
        return false;
    return true;
}



// ------------------------------------------------------------------
FormatedHeure.prototype.keypress = function ( event ) {
    if( !event ) event = window.event; 
    var input = this.input();

    var k = this.get_key( event );
    if( k == 0 ) {
        return true;
    }
    if( k == 13 ) {             // 13 == enter
        focus_next_input( input );
        return false;
    }

    if( 48 > k || k > 58 ) {    // 48 = 0, 58 = 9
        return false;           // only numbers please
    }

    // ----------------
    // See what is being selected
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    if( (pos0 == 0 && pos1 == 10 ) ) {   // everything selected
        input.value = '';
        pos0 = pos1 = 0;
        input.selectionStart = pos0;
        input.selectionEnd = pos1;
    }
    else if( (pos0 == pos1 ) ) {         // nothing selected
                                        // do nothing
    } 
    else if( pos0 <= 1 && pos1 >= 3 ) {  // day + past the day
        input.selectionEnd = pos1 = 2;   // only select day
    }
    else {
        if( pos0 == 2 )                 // select just before MM
            input.selectionStart = pos0 = 3; // move just after
    }

    // ----------------
    // What keys are allowed depends on in the string
    var start = 48;                     // 48 = '0'
    var stop  = 58;                     // 58 = '9'
    var add_zero = 0;                   // 8 => 08

    if( pos0 == 0 ) {                   // Hour
                                        // [012]
        stop  = 50;                     // 50 = '2'
        add_zero = 1;
    }
    else if( pos0 == 1 ) {              // Hour
        var first = input.value.substr( 0, 1 );
        if( first == '2' ) {            // 2[0-3]
            stop = 51;                  // 51 = '3'
        }
        else if( first == '0' ) {       // 0[123456789]
            start = 49;                 // 49 = '1'
        }
    }
    else if( pos0 == 3 ) {              // Minutes (tens)
        stop = 53;                      // 53 = '5'
        add_zero = 1;
    }
    else if( pos0 == 4 ) {              // Minutes
        var prev = input.value.substr( 3, 1 );
        if( prev == '0' ) {             // 0[123456789]
            start = 49;                 // 49 = '1' 
        }
    }

    // ----------------
    // Is the current key valid
    var l = input.value.length;
    if( start > k || k > stop ) {
        if( add_zero && (48 <= k && k <= 58) ) {
            // pos0 and pos1 have been fixed previously, so we
            // know that if are here, are pointing at first digit of the 
            // day or month sub-field

            if( l == pos1 ) {           // append
                input.value += "0";     // do it the easy way
                l++;                    // and let
                pos0++;
                pos1++;
                l = input.value.length;
            }
            else {                      // insert/substitute
                // turn an insert into a substitution
                pos1 = input.value.indexOf( ':', pos1 );
                if( pos1 == -1 ) {
                    // if we can't find a ':', it means the string
                    // is very messed up. So erase all after this
                    pos1 = pos0;
                }

                // Do the substitution
                input.value = input.value.substring2( pos0, pos1, "0" );

                // Make sure new char is inserted after this
                input.selectionStart = ++pos0;
                input.selectionEnd = pos1 = pos0;
            }            
        }
        else
            return false;               // only numbers please
    }


    // ------------
    // insert the value
    if( l == 5 ) {                     // 12:34 = 5 chars
        if( pos1 == l ) {
            return false;
        }
        pos1++;                         // overwrite?
    }    

    input.value = input.value.substring2( pos0, pos1, 
                                                String.fromCharCode( k ) );

    // move after new char
    input.selectionStart = input.selectionEnd = ++pos0;
    
    // move after the :
    if( pos0 == 2 ) {                   // 2 = after hour
        if( input.value.substr( pos0, 1 ) != ':' ) {  
            // automatically append a /
            input.value = input.value.substring2( pos0, pos0, ":" );
        }
        // Move past the /
        input.selectionStart = input.selectionEnd = ++pos0;
    }

    return false;
}

// ------------------------------------------------------------------
// User is entering the field
FormatedHeure.prototype.on_focus = function ( event ) {
    if( !event ) event = window.event;
    var input = this.input();

    this.error_hide();

    if( input.value == "HH:MM" ) {
        input.value = '';
    }
}

// ------------------------------------------------------------------
// Reformat the date when user leaves the field
FormatedHeure.prototype.on_blur = function ( event ) {
    if( !event ) event = window.event;
    var input = this.input();

    this.error_hide();

    var value = input.value;

    // Get rid of non-number and /
    var re = /[^:0-9]/g;
    value = value.replace( re, '' );

    if( value.match( /^\d\d:\d\d$/ ) ) {
        return true;
    } 
    else {
        // NO DON'T GO!
        input.focus();
        this.error_show();
        return false;
    }

    input.value = value;
    return true;
}


