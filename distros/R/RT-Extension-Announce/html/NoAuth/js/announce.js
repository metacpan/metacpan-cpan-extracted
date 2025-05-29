function selfServiceAnnounce () {
    jQuery('#more_announcements').hide();
    var hide = true;
    jQuery('#toggle_announcements').click( function() {
        if ( hide == true ) {
            jQuery('#more_announcements').show();
            jQuery('#toggle_announcements').html('Less Announcements');
            hide = false;
        }
        else if ( hide == false ) {
            jQuery('#more_announcements').hide();
            jQuery('#toggle_announcements').html('More Announcements');
            hide = true;
        }
    });
}
if (typeof htmx != "undefined") {
    htmx.onLoad(function(elt) {
        selfServiceAnnounce();
    });
} else {
    jQuery(document).ready(function() {
        selfServiceAnnounce();
    });
}
