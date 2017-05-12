// ------------------------------------------------------------------
//  {LLxCC}
//  LL -> lines
//  CC -> columns
// ------------------------------------------------------------------
function FormatedArea( id, cells ) {
    var obj = FormatedInput.call( this, id, cells );

    this.cols = this.cells[0].cols;
    this.rows = this.cells[0].rows;
    this.streamlines = this.cells[0].streamlines;

    return obj;
}

// Inherit from FormatedInput
Object.extend( FormatedArea.prototype, FormatedInput.prototype );

// ------------------------------------------------------------------
// Get the number of rows in a string, up to "offset" if given
FormatedArea.prototype.lines = function ( offset ) {
    var input = this.input();
    if( !input ) return 0;

    var value = input.value;
    if( value == '' ) return 0;         
    if( offset ) {
        value = value.substring( 0, offset );
    }

    value.replace( /\n+$/, '' );
    var ends = value.match( /\n/g );
    if( !ends ) 
        return 1;
    return 1 + ends.length;
}

// ------------------------------------------------------------------
FormatedArea.prototype.line = function ( n ) {
    var input = this.input();
    if( !input ) return;

    var value = input.value;
    if( value == '' ) return;

    value.replace( /\n+$/, '' );
    var ends = value.split( "\n" );
    if( !ends ) 
        return '';
    return ends[ n ];
}

// ------------------------------------------------------------------
FormatedArea.prototype.line_offset = function ( pos ) {
    var at_row = this.lines( pos ) - 1;
    var offset = 0;
    for( q=0 ; q < at_row ; q++ ) {
        offset += 1 + this.line( q ).length;
    }
    return pos - offset;
}

// ------------------------------------------------------------------
FormatedArea.prototype.replace_row = function( n, line )
{
    var input = this.input();
    var lines = input.value.split( "\n" );
    lines[n] = line;
    var s = input.selectionStart;
    var e = input.selectionEnd;
    input.value = lines.join( "\n" );
    input.selectionStart = s;
    input.selectionEnd = e;
}


// ------------------------------------------------------------------
FormatedArea.prototype.validate = function ( on_submit ) {
    var input = this.input();

    if( this.required && on_submit && input.value == '' )
        return false;

    var rows = this.lines();
    if( rows > this.rows ) 
        return false;

    for( var q=0 ; q<rows ; q++ ) {
        if( this.line( q ).length > this.cols )
            return false;
    }

    return true;
}


// ------------------------------------------------------------------
FormatedArea.prototype.keypress = function ( event ) {

    var rows = this.lines();
    if( rows > this.rows )        // too many lines already
        return false;

    var k = event.charCode ? event.charCode : event.which;
    if( k == 0                      // 0 == control
               || event.altKey || event.ctrlKey || event.metaKey ) {
        if( event.keyCode == Event['DOM_VK_DELETE'] ) 
            return this.kp_delete( event );
        return true;
    }

    if( k == 13 || k == 10 ) {          // 13 = carriage return, 10 = linefeed
        return this.kp_newline( event, k );
    }
    else if( k == 8 ) {                 // 8 == backspace
        return this.kp_backspace( event, k );
    }
    else if( this.is_substitution() ) {
        return this.kp_substitution( event, k );
    }
    else if( this.is_append() ) {
        return this.kp_append( event, k );
    } 
    else {
        return this.kp_insert( event, k );
    }
}


// ------------------------------------------------------------------
FormatedArea.prototype.kp_newline = function ( event, k ) {
    var input = this.input();
    var key = String.fromCharCode( k );
    var rows = this.lines();

    // an insert will convert 2 -> 3 (say) which we might want to avoid.
    // Hence the test below is <.  This also prevents any trailing \n, 
    // which I can live with.
    if( rows < this.rows ) {
        this.insert_key( key );
    }
    return false;
}
 
// ------------------------------------------------------------------
FormatedArea.prototype.kp_append = function ( event, k ) {
    var input = this.input();
    var key = String.fromCharCode( k );
    var rows = this.lines();

    var last = this.line( rows-1 );
    if( last && last.length >= this.cols ) {
        // append, but got to the end of a line

        if( rows >= this.rows )         // don't allow anything more
            return false;

        // move to next line
        // TODO: word wrap
        this.insert_key( "\n" );
    }
    this.insert_key( key );
    return false;
}


// ------------------------------------------------------------------
FormatedArea.prototype.kp_substitution = function ( event, k ) {
    var input = this.input();
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    var key = String.fromCharCode( k );
    var rows = this.lines();
    var row0 = this.lines( pos0 ) - 1;
    var row1 = this.lines( pos1 ) - 1;

    if( row0 != row1 ) {                // crossing lines
        pos1 -= this.line_offset( pos1 ) + 1; // move end to start of row1
        input.selectionEnd = pos1;
    }

    this.insert_key( key );

    return false;
}

// ------------------------------------------------------------------
FormatedArea.prototype.kp_insert = function ( event, k ) {
    var input = this.input();
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    var key = String.fromCharCode( k );
    var rows = this.lines();
    var row0 = this.lines( pos0 ) - 1;
    var row1 = this.lines( pos1 ) - 1;

    var at_row = this.lines( input.selectionStart )-1;
    var current = this.line( at_row );

    // find the position within the row
    var row_offset = this.line_offset( input.selectionStart );
    // alert( "insert" );
    if( row_offset >= this.cols ) {     // at end of row
        input.selectionStart =          // move past the newline
            input.selectionEnd += 1;
        at_row++;
        current = this.line( at_row );
    }
    // alert( current );
    if( current && current.length >= this.cols ) {
        this.replace_row( at_row, 
                            current.substr2( current.length-1, 1, '' )
                        );
    }
    this.insert_key( key );

    return false;
}

// ------------------------------------------------------------------
FormatedArea.prototype.kp_backspace = function ( event, k ) {
    var input = this.input();
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;

    if( pos0 != pos1 ) {                // act like a delete key
        return this.kp_delete( event );

    }

    var row0 = this.lines( pos0 ) - 1;
    var row1 = this.lines( pos1 ) - 1;
    var rows = this.lines();
    var lines = input.value.split( "\n" );

    if( pos0 == 0 ) {               // beginging of the string
        return true;                // just ignore it
    }

    var prev = input.value.charCodeAt( pos0-1 );
//    fb_log( { prev: prev } );
    if( prev != 13 && prev != 10 ) {    // 13 = CR, 10 = LF
        return true;                    // real backspace
    }

    var line0 = lines[ row0-1 ];
    var line1 = lines[ row0 ];
    var off1  = 0;

    if( this.streamlines ) {

        if( line0.length >= this.cols ) {
            return false;
        }
        
        lines[row0-1] = line0 + line1.substr( 0, 1 );                
        lines[row0] = line1.substr( 1 );                
    }
    else {
        var total = line0.length + line1.length;
        if( total < this.cols ) {
            return true;            // lines are short enough
        }
        // joining lines that are too long.  We want to find a 
        // "word break" in line1 that will come under the total length
        off1 = this.cols - line0.length;
        while( off1 > 0 && off1 < line1.length && 
                line1.charCodeAt( off1 ) != 32 ) {  // 32 = space
            off1--;
        }
        if( off1 <= 0 ) {           // failed to do so
            return false;           // so we can't join the lines
            // Q: should we move the selection to end of previous line?
        }

        lines[ row0-1 ] = line0.substr( 0, line0.length )
                             + line1.substr( 0, off1 );
        if( off1 < line1.length )
            // NOTE +1 on next line will remove the space
            lines[ row0 ] = line1.substr( off1 );
        else 
            lines[ row0 ] = '';
    }            
    // new value
    input.value = lines.join( "\n" );

    // position end of prev line
    var offset = 0;
    for( var l=0; l<row0; l++ )
        offset += lines[l].length + 1; // +1 for the LF

    if( this.streamlines ) 
        offset--;
    else
        offset -= off1;
    input.selectionStart =
        input.selectionEnd = offset -1 ; // -1 before last LF
    return false;
}


// ------------------------------------------------------------------
FormatedArea.prototype.kp_delete = function ( event ) {
    var input = this.input();
    var pos0 = input.selectionStart;
    var pos1 = input.selectionEnd;
    var row0 = this.lines( pos0 ) - 1;
    var row1 = this.lines( pos1 ) - 1;
    var lines = input.value.split( "\n" );

    if( row0 != row1 ) {        // crossing a line
        // Move pos0 to the begin of row1.  This saves us the pain
        // of joining too lines
        pos0 = 0;
        for( var l=0; l<row1; l++ )
            pos0 += lines[l].length + 1; // +1 for the LF
        input.selectionStart = pos0;
    }
    else if( pos0 == pos1 ) {
        pos1++;
        input.selectionEnd = pos1;
    }

    this.insert_key( '' );
    pos1 = input.selectionEnd = input.selectionStart = pos0;
    return false;
}


// ------------------------------------------------------------------
FormatedArea.prototype.set_default = function () { }
