jQuery(function(){
    var escapeHTML = function(string) {
        // Lifted from mustache.js
        var entityMap = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': '&quot;',
            "'": '&#39;',
            "/": '&#x2F;'
        };
        return string.replace(/[&<>"'\/]/g, function(s) {
            return entityMap[s];
        });
    };

    var template =
        '<div class="form-row"><div class="label col-3">Status:</div><div class="value col-9"><a href="{{ title_url }}""><span class="travis-status-{{ last_build_state }}">{{ pretty_build_state }}</span></a></div></div>'
        + '<div class="form-row"><div class="label col-3">Build started: </div><div class="value col-9">{{ build_start }}</div></div>'
        + '<div class="form-row"><div class="label col-3">Build ended: </div><div class="value col-9">{{ build_end }}</div></div>'
    ;

    var template_short =
        '<div><a href="{{ title_url }}""><span class="travis-status-{{ last_build_state }}">{{ pretty_build_state }}</span></a></div>'
    ;

    var travisci_fetch = function(template) {
        var _ = this;
        var ticket_id = jQuery(this).attr("data-travisci-ticketid");
        jQuery.getJSON(
            RT.Config.WebPath + "/Helpers/TravisCI?id=" + ticket_id,
            function(data) {
                if (data == null) return;
                if (!data.success) {
                    jQuery(_).html(escapeHTML(data.error));
                    return;
                }
                data = data.result;
                var title_url = data.title_url;
                var last_build_state = data.last_build.state;
                var pretty_build_state = data.last_build.pretty_build_state;
                var build_start = data.last_build.started_at;
                var build_end = data.last_build.finished_at;
                jQuery(_).html(template.replace(
                    /{{\s*(.+?)\s*}}/g,
                    function(m,code){
                        return escapeHTML(eval(code));
                    }
                ));
            }
        );
    };

    jQuery(".ticket-summary .travisci").each(function(){
        travisci_fetch.call(this, template);
    });

    jQuery(".ticket-list .travisci").each(function(){
        travisci_fetch.call(this, template_short);
    });

});
