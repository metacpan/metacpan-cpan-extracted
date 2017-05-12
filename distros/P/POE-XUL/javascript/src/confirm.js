// ------------------------------------------------------------------
function ConfirmChange ( id, text, contingent ) {
    this.ID = id;
    this.text = text;
    this.contingent = {};

    for( var q=0 ; q<contingent.length ; q++ ) {
        var id = contingent[ q ];
        var input = this.input( id );
        this.contingent[ id ] = input ? input.value : '';
    }

    // By doing this, our validate will get called
    FormatedField.register( this.ID, this );
}

// ------------------------------------------------------------------
ConfirmChange.prototype.input = function ( id ) {
    if( ! id ) 
        id = this.ID;
    return $( id );
}

// ------------------------------------------------------------------
ConfirmChange.prototype.validate = function ( on_submit ) {
    if( ! on_submit )
        return true;

    return this.verify();
}


// ------------------------------------------------------------------
ConfirmChange.prototype.verify = function ( on_submit ) {

    var formated = FormatedField.formated;
    // find if any element is changed
    for( var id in this.contingent ) {
        if( formated[ id ] && formated[ id ].changed ) {
            if( formated[ id ].changed() ) {
                return this.confirm( id );
            }
        }
        var input = this.input( id );
        if( input && input.value != this.contingent[ id ] ) {
            return this.confirm( id );
        }
    }
    return true;
}

// ------------------------------------------------------------------
ConfirmChange.prototype.confirm = function ( id ) {
    var input = this.input();
    input.value = 0;
    if( confirm( this.text ) ) {
        input.value = 1;
    }
    return true;
}
