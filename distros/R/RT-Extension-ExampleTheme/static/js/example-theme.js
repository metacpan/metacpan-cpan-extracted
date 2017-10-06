/* Example of modifying the RT UI using jQuery. */
/* This changes "The Basics" to "Ticket State" on ticket display */

jQuery( document ).ready(function() {
    jQuery(".ticket-info-basics .ticket-info-basics .titlebox-title span.left a").text('Ticket State');

});
