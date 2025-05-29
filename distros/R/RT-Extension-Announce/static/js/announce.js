
function announce() {
    jQuery('table #more_announcements').hide();
    var hide = true;
    jQuery('table #toggle_announcements').click( function() {
        if ( hide == true ) {
            jQuery('#more_announcements').show();
            jQuery('#toggle_announcements').text(jQuery('#toggle_announcements').data('text-less'));
            hide = false;
        }
        else if ( hide == false ) {
            jQuery('#more_announcements').hide();
            jQuery('#toggle_announcements').text(jQuery('#toggle_announcements').data('text-more'));
            hide = true;
        }
    });

    jQuery('#more_announcements').on('hide.bs.collapse', function () {
        jQuery('#toggle_announcements').text(jQuery('#toggle_announcements').data('text-more'));
    });
    jQuery('#more_announcements').on('show.bs.collapse', function () {
        jQuery('#toggle_announcements').text(jQuery('#toggle_announcements').data('text-less'));
    });
}

if (typeof htmx != "undefined") {
    htmx.onLoad(function(elt) {
        announce();
    });
} else {
    jQuery(document).ready(function() {
        announce();
    });
}
