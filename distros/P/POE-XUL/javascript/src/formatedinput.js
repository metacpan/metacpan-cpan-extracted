
// ------------------------------------------------------------------
function FormatedInput ( id, cells ) {
    this.ID = id;
    FormatedField.register( id, this );

    if( cells ) {
        this.cells = cells['C'];
        this.pos = cells['P'];
    }
    else {
        alert( "Why no cells for " + this.ID );
    }

    // TODO data integrity
}

FormatedInput.Version = '0.0.1';

// ------------------------------------------------------------------
FormatedInput.prototype.dispose = function () {
    FormatedField.unregister( this.ID );
    delete this[ 'input_element' ];
    delete this[ 'error_element' ];
}

// ------------------------------------------------------------------
FormatedInput.prototype.full_length = function () {
    var last = this.cells[ this.cells.length-1 ];
    return last.offset + last.length;
}

// ------------------------------------------------------------------
FormatedInput.prototype.user_message = function () {
    return $( 'USER-Message' );
}

// ------------------------------------------------------------------
FormatedInput.prototype.setInput = function (el) {
    this.input_element = el;
    // XUL elements created with XBL don't have IDs :-/
    if( el.id )
        this.ID = el.id;
}

FormatedInput.prototype.input = function () {
    if( !this.input_element ) 
        this.input_element = $( this.ID );
    return this.input_element;
}

// ------------------------------------------------------------------
// Does this input still have an element?
FormatedInput.prototype.has_element = function () {

    if( !this.ID && this.input_element )
        this.ID = this.input_element.id;

    if( this.ID )                   // does the element still exist
        return !! $( this.ID );
    return false;
}

// ------------------------------------------------------------------
FormatedInput.prototype.setError = function (el) {
    this.error_element = el;
}

FormatedInput.prototype.error = function () {
    if( !this.error_element ) 
        this.error_element = $( "ERROR_" + this.ID );
    return this.error_element;
}

FormatedInput.prototype.error_show = function ( string ) {
    var err = this.error();
    if( err )
        Element.show( err );
    if( !string )
        return;
    var msg = this.user_message();
    if( msg && msg.setMessage ) 
        msg.setMessage( string );
}

FormatedInput.prototype.error_hide = function ( on_load ) {
    var err = this.error();
    if( ! err ) return;
    Element.hide( err );
}

// ------------------------------------------------------------------
FormatedInput.prototype.setMessage = function (el) {
    this.message_element = el;
}
FormatedInput.prototype.message = function () {
    if( !this.message_element ) 
        this.message_element = $( "MESSAGE_" + this.ID );
    return this.message_element;
}


// ------------------------------------------------------------------
//
FormatedInput.prototype.focus = function () {
    var input = this.input();
    try { input.focus(); } catch (e) {};
    // select() causes the whole input to be highlighted
    // try { input.select(); } catch (e) {};
}


// ------------------------------------------------------------------
// Validate the field after the user moves out
// Putting up the error message when they leave
FormatedInput.prototype.on_blur = function( event ) {
    this.error_hide();

    if( ! this.set_default() )
        return true;            // true or false?

    if( ! this.validate( 0 ) ) {
        this.error_show();
        return false;
    }
    return true;
}

    

// ------------------------------------------------------------------
FormatedInput.prototype.is_insert = function ( ) {
    var input = this.input();
    
    return input.selectionStart == input.selectionEnd
            && input.selectionEnd < input.value.length;
}

// ------------------------------------------------------------------
FormatedInput.prototype.is_substitution = function ( ) {
    var input = this.input();
    
    return input.selectionStart != input.selectionEnd;
}

// ------------------------------------------------------------------
FormatedInput.prototype.is_append = function ( ) {
    var input = this.input();
    
    return input.selectionStart >= input.value.length;
}



// ------------------------------------------------------------------
FormatedInput.prototype.transform = function ( string ) {

    var output = "";
    for( var q=0 ; q< this.cells.length ; q++ ) {
        var C = this.cells[q];
        // window.status = "" + q + "=" + C;
        var substring = string.substr( C.offset, C.length );
        substring = this._transform( substring, C );
        output += substring;
    }
    return output;
}

// ------------------------------------------------------------------
// Do transformation on one substring
FormatedInput.prototype._transform = function ( substring, C ) {
    switch( C.xform ) {
      case 'uppercase': 
        return substring.toUpperCase();
      case 'lowercase':
        return substring.toLowerCase();
      case 'leading-space':
        return substring.replace( /^( +)/, function (m) {
                    var ret = '';
                    for( var w=0; w<m.length; w++ )
                        ret += C.leading;
                    return ret;
                } );
      default:
        return substring;
    }
}

// ------------------------------------------------------------------
FormatedInput.prototype.match = function ( string ) {
    this.problem = this._match( string );
    return this.problem == '';
}

// ------------------------------------------------------------------
FormatedInput.prototype._match = function ( string ) {

    if( string.length != this.full_length() )
        return 'LENGTH';

    for( var q=0 ; q< this.cells.length ; q++ ) {
        var C = this.cells[q];
        var substring = string.substr( C.offset, C.length );
        if( C.min != undefined ) {
            if( ! substring.match( C.full_re ) ) 
                return 'NaN';
            var n = parseInt( substring );
            if( C.min > n || n > C.max )
                return 'RANGE';
        }
        else {
            if( C.length && substring.length != C.length ) {
                return 'LENGTH';
            }
            if( C.full_re && ! substring.match( C.full_re ) ) {
                return 'FORMAT';
            }
            if( C['static'] && substring != C['static'] ) {
                return 'FORMAT';
            }
        }
    }
    return '';
}

// ------------------------------------------------------------------
FormatedInput.prototype.validate = function ( on_submit ) {

    if( this.inactive ) 
        return true;

    var input = this.input();
    var ni = this.transform( input.value );

    if( on_submit && input.value == '' ) {
        if( this.required ) {
            return false;
        } else {
            // empty is allowed unless required is true
            return true;
        }
    }

    this.match( ni );
    var p = this.problem;
    if( p && ( on_submit || p != 'LENGTH' ) ) {
        // TODO: p might be interesting to the user
        //$debug( p );
        return false;
    }
    if( on_submit && ni ) {
        input.value = ni;
    }
//    if( p ) alert( p );
    return true;
}

// ------------------------------------------------------------------
FormatedInput.prototype.keypress = function ( event ) {
    if( !event ) event = window.event;

    this.error_hide();

    var k = event.charCode ? event.charCode : event.which;
    if( k == 0 || k == 8                // 0 == control, 8 == backspace
               || event.altKey || event.ctrlKey || event.metaKey ) {    
        // TODO: backspace on a static cell -> delete the entire cell
        return true;
    }
    if( k == 13 ) {
        focus_next_input( $( this.ID ) );        
    }

    // ----------------
    var input = this.input();
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;

    // ----------------
    // too long
    // append
    if( pos0 >= this.full_length() )
        return false;

    // ----------------
    // Get key and cell
    var key = String.fromCharCode( k );
    var C = this.cells[ this.pos[ pos0 ] ];
    var nC = this.cells[ this.pos[ pos0 ] + 1 ];

//    window.status = "pos0="+pos0.toString()+" full_length=" + this.full_length().toString() +
//                    " pos="+this.pos[pos0].toString() + 
//                    " C=" + C.toString();

    // ----------------
    // transform the key
    key = this._transform( key, C );

    // ----------------
    // selected a static cell.  
    if( C['static'] ) {
        // this key valid for the current (static) cell?
        var ok = key.match( C.re );
        // this key valid for the next cell?
        if( !ok && nC )
            ok = key.match( nC.re );
        // If neither are valid, skip out before appending static cell
        if( !ok )
            return false;

        // Insert the static bit.  
        // (this.insert_static() makes sure we don't do it twice)
        this.insert_static( C );

        // move to the next cell
        pos0 = pos1 = C.offset + C.length;
        if( nC ) {
            C = nC;
            nC = undefined;
        }
        else                    // end of the input
            return false;
    }

    // Resync values
    input.selectionStart = pos0;
    input.selectionEnd = pos1;

    // insert too much
    if( this.is_insert() && input.value.length >= this.full_length() )
        return false;


    // ----------------
    // is the key valid?
    if( C.re && !key.match( C.re ) ) {
        return this.tryNext( event, key );
    }

    // ----------------
    // everything selected?
    // Note: this has to come after the previous bit because selecting the
    // everything then pressing an illegal key should be a no-op
    if( (pos0 == 0 && pos1 == this.full_length() ) ) {   
        input.value = '';
        pos0 = pos1 = 0;
    }

    // ----------------
    // crossing a cell boundary?
    if( this.pos[ pos0 ] != this.pos[ pos1 ] ) {
        // Only select within first cell
        pos1 = C.offset + C.length;

        // This is enforced because it solves a bunch of fence-post problems
    }

//    window.status = "pos0="+pos0.toString() + " pos1=" + pos1.toString();


    // ----------------
    // Now, finaly, we can add the key to the value
    input.selectionStart = pos0;
    input.selectionEnd = pos1;
    this.insert_key( key );

    // ----------------
    // And maybe a static cell that follows it
    this.post_insert( C );

    return false;               // we did all the work
}

// ------------------------------------------------------------------
FormatedInput.prototype.tryNext = function ( event, key ) {

    var input = this.input();
    var pos0 = input.selectionStart;

    // ----------------
    // Get key and cell
    var C = this.cells[ this.pos[ pos0 ] ];
    var nC = this.cells[ this.pos[ pos0 ] + 1 ];
    var nnC = this.cells[ this.pos[ pos0 ] + 2 ];

    // Maybe we could insert some leading bits?
    if( !nC || !nC['static'] )
        return false;

    if( C.leading == undefined || ( C.leading == '' && C.leading != '0' ) )
        return false;
    
    if( !this.is_append() )
        return false;

    // If we did, would the current key match the next cell, or the 
    // one after it
    var match_next = false;
    if( nC && key.match( nC.re ) )
        match_next = true;

    var match_further = false;
    if( nnC && key.match( nnC.re ) ) {
        match_further = true;
    }

    if( !match_next && !match_further )
        return false;


    // Prepend something to the current cell
    var l = C.length - ( pos0 - C.offset);
    input.selectionStart = input.selectionEnd = C.offset;
    for( var q=0 ; q< l ; q++ ) 
        this.insert_key( C.leading );
    
    input.selectionStart = input.selectionEnd = nC.offset;

    // add any static that might be necessary (next cell)
    this.post_insert( C );

    // And try to add the key again, which will end up in the further cell
    if( match_further )
        return this.keypress( event );

    // otherwise, poot.
    return false;
}

// ------------------------------------------------------------------
FormatedInput.prototype.insert_key = function ( key ) {
    var input = this.input();
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    // window.status = "pos0="+pos0.toString()+ " pos1=" + pos1.toString() +  " value=" + input.value + " key=" + key;
    input.value = input.value.substring2( pos0, pos1, key );
    // move after new char
    input.selectionStart = input.selectionEnd = ++pos0;
}




// ------------------------------------------------------------------
FormatedInput.prototype.post_insert = function ( oC ) {
    var input = this.input();

    var pos0 = input.selectionStart;
    var nC = this.cells[ this.pos[ pos0 ] ];
    if( !nC )
        return;

    // Still in the same cell?
    if( nC == oC )     
        return;

    // next cell is a static cell?
    if( nC['static'] ) {
        this.insert_static( nC );
    }
}

// ------------------------------------------------------------------
FormatedInput.prototype.insert_static = function ( C ) {
    var input = this.input();
    var pos0 = input.selectionStart;

    var v = input.value;

    // window.status = "substring=" +v.substr( C.offset, C.length ) +
    //                 " static=" + C['static'];

    if( this._verify_static( C ) )
        return;

    if( v.length + C['static'].length > this.full_length() )
        return;

    // append/insert the static bit
    input.value = v.substring2( pos0, pos0, C['static'] );    
}

// ------------------------------------------------------------------
// append/insert the static bit
FormatedInput.prototype._insert_static = function ( C ) {
    var input = this.input();

    var v = input.value;
    input.value = v.substr2( C.offset, C.length, C['static'] );    
}

// ------------------------------------------------------------------
// Make sure the static bit looks like we think it should
FormatedInput.prototype._verify_static = function ( C ) {
    var input = this.input();

    var v = input.value;
//    window.status = "substring=" +v.substr( C.offset, C.length ) +
//                     " static=" + C['static'];

    // TODO: what if it's a partial match?
    if( v.substr( C.offset, C.length ) == C['static'] )
        return true;

    return false;
}

// ------------------------------------------------------------------
// Add any trailing cells
FormatedInput.prototype.set_default = function () {

    var input = this.input();
    var posX = input.value.length;
    do {
        var C = this.cells[ this.pos[ posX ] ];
        if( !C )
            return;

        var pos0 = input.value.length;

        if( C['static'] ) {
            if( !this._verify_static( C ) ) {
                this._insert_static( C );
            }
            else {
                return false;
            }
        }
        else if( C.leading == undefined || C.leading === '' ) {       // strict equal
            var bit = input.value.substr( C.offset, C.length );
            if( ! bit.match( C.full_re ) ) 
                return false;
        }                
        else {
            var l = C.length - ( pos0 - C.offset );
            input.selectionStart = input.selectionEnd = C.offset;
            // fb_log( "posX=" + posX + ", l=" + l + ", leading=" + C.leading );
            for( var q=0 ; q< l ; q++ ) 
                this.insert_key( C.leading );
        }

        input.selectionStart = 
                    input.selectionEnd = C.offset + C.length;
        posX++;
    } while( C );    
    return true;
}

