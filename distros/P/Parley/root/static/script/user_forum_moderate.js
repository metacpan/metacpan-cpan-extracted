(function () {
    var YU  = YAHOO.util,
        Dom = YAHOO.util.Dom;

    var items = Dom.getElementsByClassName('fmod_checkbox');

    update_forummod = function() {
        var elID = this.id,
            checked = (this.checked ? 1 : 0);
        var forumID = elID.split('_')[1];
        var statusDiv = Dom.get('status_' + forumID);

        var handleSuccess = function(o) {
            var data = eval('(' + o.responseText + ')');
            o.argument.msg_node.innerHTML = '';

            // show any returned errors
            if (data.error) {
                if (data.error.message!=undefined) {
                    o.argument.msg_node.innerHTML = data.error.message;
                }

                // reset the checkbox
                Dom.get(o.argument.cb_node).checked =
                    (1 - o.argument.value);
            }

            // if we didn't update on the server, reset the checkbox
            if (0 == data.updated) {
                Dom.get(o.argument.cb_node).checked =
                    (1 - o.argument.value);
            }
        };
        var handleFailure = function(o) {
            // show the status message
            o.argument.msg_node.innerHTML = o.responseText;

            // reset the checkbox
            Dom.get(o.argument.cb_node).checked =
                (1 - o.argument.value);
        };

        // where to post to
        var sUrl = '/site/fmodSaveHandler';

        // postdata is a query string ... how irksome!!
        var postData =
               'person='    + person.id
            +  '&forum='    + forumID
            +  '&value='    + checked
        ;

        // some visual feedback that something is happening
        statusDiv.innerHTML = '<img src="/static/images/loader-bar.gif" />';

        var request = YAHOO.util.Connect.asyncRequest(
            'POST',
            sUrl,
            {
                success:  handleSuccess,
                failure:  handleFailure,
                argument: {
                    msg_node: statusDiv,
                    cb_node:  elID,
                    value:    checked
                }
            },
            postData
        );
    };

    YU.Event.addListener(
        items,
        'change',
        update_forummod
    );
})();
