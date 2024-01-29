window.onresize = resizeCalendarEventTitles;
jQuery(function() {
    resizeCalendarEventTitles();

    jQuery('div[data-object]>small>div.event-info>a.event-title').hover(
        function(e) {
            loadCalendarEventDetails(e);
        }
    );
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

function changeCalendarMonth() {
    var month = jQuery('.changeCalendarMonth select[name="Month"]').val();
    var year = jQuery('.changeCalendarMonth select[name="Year"]').val();
    var querystring = jQuery('.changeCalendarMonth #querystring').val();
    window.location.href = "?Month=" + month + "&Year=" + year + "&" + querystring;
}

function loadCalendarEventDetails(e) {
    // data-object
    var event = jQuery(e.currentTarget).parents('[data-object]').attr('data-object');
    // remove hover event from the element to run only once
    jQuery(e.currentTarget).off('mouseenter mouseleave');

    var url = RT.Config.WebHomePath + '/Helpers/CalendarEventInfo?event=' + event;

    jQuery.ajax({
        url: url,
        success: function(data) {
            jQuery(e.currentTarget).parents('[data-object]')
                .find('div.event-info>span.tip').html(data);
        }
    });
}
