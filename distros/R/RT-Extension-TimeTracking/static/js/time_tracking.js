jQuery( function() {
    jQuery('div.time_tracking input[name=Date], div.time_tracking input[name=User]').change( function() {
        jQuery(this).closest('form').submit();
    });

    jQuery("div.time_tracking input[name=UserString]").on("autocompleteselect", function( event, ui ) {
        jQuery(this).closest('form').find('input[name=User]').val(ui.item.id).change();
    });
});
