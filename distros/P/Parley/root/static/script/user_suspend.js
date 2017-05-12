YAHOO.namespace("parley.suspend_reason");

function suspend_init() {
    var YU  = YAHOO.util,
        Dom = YAHOO.util.Dom;

    var suspend_account = function() {
        var elID = this.id,
            checked = (this.checked ? true : false);

        try {
            Dom.get('suspension_reason').value = '';
            YAHOO.parley.suspend_reason.suspend_reason_dialog.show();
        } catch(e) { alert(e); }
    }

    YU.Event.addListener(
        'suspend_account',
        'change',
        suspend_account
    );
}


function suspend_reason_init() {
    var YU  = YAHOO.util,
        Dom = YAHOO.util.Dom;

    // Define various event handlers for Dialog
    var handleSubmit = function() {
        YAHOO.parley.small_loading.wait.show();

        var checked =
            (Dom.get('suspend_account').checked ? 1 : 0);

        var person_id =
            Dom.get('suspend_account').value;
        var reason =
            Dom.get('suspension_reason').value;

        try {
            var request = YU.Connect.asyncRequest(
                'POST',
                '/user/suspend',
                {
                    success: handleSuccess,
                    failure: handleFailure,
                    argument: {
                        node: Dom.get('suspend_account')
                    }
                },
                  'suspend='    + checked
                + '&person='    + person_id
                + '&reason='    + escape(reason)
            );
        } catch(e) { alert(e); }
    };
    var handleCancel = function() {
        YAHOO.parley.small_loading.wait.hide();
        // reset the checkbox
        Dom.get('suspend_account').checked =
            ! (Dom.get('suspend_account').checked);
        // cancel the dialog
        this.cancel();
    };
    var handleSuccess = function(o) {
        YAHOO.parley.small_loading.wait.hide();
        YAHOO.parley.suspend_reason.suspend_reason_dialog.hide();
        var response = o.responseText;
        var data = eval('(' + o.responseText + ')');
    };
    var handleFailure = function(o) {
        YAHOO.parley.small_loading.wait.hide();
        try {
            YAHOO.parley.ajax_dialog.dlg.show_message( o );
        } catch(e) { alert('handleFailure: ' + e); }
    };

    // Instantiate the Dialog
    YAHOO.parley.suspend_reason.suspend_reason_dialog =
        new YAHOO.widget.Dialog("suspend_reason_dialog",
        {
            postmethod:             'async',
            width : "350px",
            fixedcenter : true,
            visible : false, 
            constraintoviewport : true,
            buttons : [ { text:"Submit", handler:handleSubmit, isDefault:true },
                        { text:"Cancel", handler:handleCancel } ]
        }
    );

    // Render the Dialog
    YAHOO.parley.suspend_reason.suspend_reason_dialog.render();
}

YAHOO.util.Event.onDOMReady(suspend_reason_init);
YAHOO.util.Event.onDOMReady(suspend_init);

