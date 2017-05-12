jQuery(document).ready(function() {

    jQuery("select[name|='action']").change(function() {
        var $this = jQuery(this);
        var selected_action = $this.val();
        if ( selected_action.match('(replace|merge)') ) {
            var user_id = $this.attr('data-autocreated-userid');
            var $merge_field = jQuery('input[name="merge-user-' +  user_id + '"]');
            if ( !$merge_field.val() ) {
                $merge_field.val( $merge_field.attr('placeholder') );
            }
        }
    });

});
