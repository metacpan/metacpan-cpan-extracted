window.onresize = resizeCalendarEventTitles;
jQuery(function() {
    resizeCalendarEventTitles();
});

/*
* Adjust the max-width of the event title according to the number spanning
* days of an event for each week of the calendar (including MyCalendar
* portlet) so it doesn't escape the event box.
*/
function resizeCalendarEventTitles() {
    if (jQuery('.rtxcalendar').length == 0){
        return;
    }
    var current_width = jQuery('.rtxcalendar')
        .find('.inside-day').first().css('width').replace('px','');
    jQuery('.rtxcalendar').find('tr').each(
        function(i, tr){
            var event_repetions_on_week = {};
            /* Each event day (first and spanning) is marked with the
            * data-object attribute in a format like ticket-123 */
            jQuery(tr).find('[data-object]').each(function(j, event_day){
                if (event_repetions_on_week[jQuery(event_day).attr('data-object')] == undefined){
                    event_repetions_on_week[jQuery(event_day).attr('data-object')] = 1;
                } else {
                    event_repetions_on_week[jQuery(event_day).attr('data-object')]++;
                }
            })
            for (var key in event_repetions_on_week){
                // Find the title of the first day of the event and adjust the max-width
                // we substract 22px to display the icon of the last day of the event
                jQuery(tr).find('.first-day[data-object="' + key + '"]')
                    .each(function(x, first_event_day){
                        jQuery(first_event_day).find('.event-title')
                        .css('max-width',
                            ((event_repetions_on_week[key] * current_width)-22) + 'px');
                    })
            }
        }
    )
}

htmx.onLoad(function(elt) {
    elt.querySelectorAll('.calendar-reload').forEach(elt => {
        elt.addEventListener('click', function(evt) {
            evt.preventDefault();
            const form = elt.closest('form');
            const data = {};
            if ( form ) {
                const formData = new FormData(form);
                for (const [key, value] of formData.entries()) {
                    if (data[key]) {
                        if ( data[key] instanceof Array ) {
                            data[key].push(value);
                        }
                        else {
                            data[key] = [data[key], value];
                        }
                    }
                    else {
                        data[key] = value;
                    }
                }
            }

            if (elt.name) {
                data[elt.name] = elt.value;
            }

            reloadElement(this.closest('[hx-get]'), { 'hx-vals': JSON.stringify(data) });
        });
    });
});
