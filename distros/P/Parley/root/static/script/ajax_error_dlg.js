(function () {
    var ajax_dialog_init = function() {
        YAHOO.namespace("parley.ajax_dialog");

        var handleClose = function() {
            this.cancel();
        };

        YAHOO.parley.ajax_dialog.dlg =
            new YAHOO.widget.Dialog(
                "ajax_dialog",
                {
                    postmethod:             'none',
                    modal: true,
                    fixedcenter:            true,
                    visible:                false, 
                    constraintoviewport:    true,

                    buttons: [
                        { text:"Close", handler:handleClose, isDefault:true }
                    ]
                }
            )
        ; // End of new()

        YAHOO.parley.ajax_dialog.dlg.show_message = function(e) {
            try {
                // default title and body
                this.setHeader('Application Error');
                this.setBody('No error message passed to show_message()');

                // check for undefined input
                if(undefined==e) {
                    this.setBody('No data passed to show_message()');
                }
                else {
                    // if we appear to have been passed a request-error object
                    if(undefined!=e.statusText) {
                        this.setHeader('Error');
                        this.setBody(e.status + ' ' + e.statusText);
                    }
                    else { // should be custom user data
                        // set the body of the dialog to the message, if we have one
                        if(undefined!=e.message) {
                            this.setBody(e.message);
                        }

                        // set the dialog header
                        if(undefined!=e.title) {
                            this.setHeader(e.title);
                        }
                    }
                }

                // show the dialog
                this.render();
                this.show();
            } catch(e){alert('show_message: ' + e);}
        }

        // Render the Dialog
        YAHOO.parley.ajax_dialog.dlg.render();
    };


    YAHOO.util.Event.onDOMReady(ajax_dialog_init);
})();
