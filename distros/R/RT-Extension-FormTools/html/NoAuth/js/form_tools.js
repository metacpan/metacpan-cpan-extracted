function disable_form_field(disable, selector) {
    if ( disable ) {
        jQuery(selector).addClass('hidden')
            .find('input,select,textarea,button')
            .add(jQuery(selector).filter('input,select,textarea,button,option'))
            .attr('disabled', 'disabled')
            .filter('option').attr('selected', false);
    } else {
        jQuery(selector).removeClass('hidden');
        jQuery(selector)
            .find('input,select,textarea,button,option')
            .add(jQuery(selector).filter('input,select,textarea,button,option'))
            .filter( function() {
                return jQuery(this).closest('.hidden').length == 0
            } )
            .removeAttr('disabled');
    }
}

function should_disable_form_field( fields, values ) {
    for ( var i = 0; i<fields.length; i++ ) {
        var field = fields[i];
        var selector = 'input[name="'+ field +'"]'
            +', input[name="'+ field +'s"]'
            +', select[name="'+ field +'"]>option'
            +', select[name="'+ field +'s"]>option'
            +', span.readonly[name="'+ field +'"]'
            +', li.readonly[name="'+ field +'"]'
        ;
        var active = jQuery( selector ).filter(function() {
            if ( jQuery(this).attr('disabled') ) {
                return 0;
            }
            var value;
            if ( this.tagName == 'SPAN' || this.tagName == 'LI' ) {
                value = jQuery(this).text();
            } else if ( this.tagName == 'INPUT' ) {
                if ( this.type == 'radio' || this.type == 'checkbox' ) {
                    if ( !jQuery(this).is(':checked') ) return 0;
                    value = this.value;
                } else if ( this.type == 'hidden' ) {
                    value = this.value;
                }
            } else if ( this.tagName == 'OPTION' ) {
                if ( !jQuery(this).is(':selected') ) return 0;
                value = this.value;
            }
            for ( var i = 0; i < values[field].length; i++ ) {
                if ( value == values[field][i] ) { return 1 }
            }
            return 0;
        }).length;
        if ( active ) return 0;
    }
    return 1;
}
