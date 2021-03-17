jQuery(function() {
    jQuery("a[data-bug-email]").each(function() {
        var a = jQuery(this);
        a.attr("href", "mailto:bug-"
                       + encodeURIComponent(a.attr("data-bug-email"))
                       + "@" + RT.Config.WebDomain);
    });
});
