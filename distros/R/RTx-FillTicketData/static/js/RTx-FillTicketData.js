jQuery(function($) {

    function jq(myid) {
        return "#" + myid.replace( /(:|\.|\[|\])/g, "\\$1" );
    }

    var fill_value = function(key, val) {

        // Search subject by name
        if (key == 'Subject') {
            $("input[name='Subject']").each(function() {
                $(this).val(val);
            });
            return;
        }

        if (key == 'Body') {
            if (typeof CKEDITOR != 'undefined') {
                // Ticket body is a CKEditor instance
                if (CKEDITOR.instances.Content) {
                    CKEDITOR.instances.Content.setData(val);
                } else if (CKEDITOR.instances.UpdateContent) {
                    CKEDITOR.instances.UpdateContent.setData(val);
                }
            } else {
                // CKEditor can be switched off, so let's try plain textarea
                if ($("#Content")) {
                    $("#Content").val(val);
                } else if ($("#UpdateContent")) {
                    $("#UpdateContent").val(val);
                }
            }

            return;
        }

        // Search other elements (custom fields) by id
        var element = $(jq(key));
        if (element) {
            $(element).val(val);
        } else {
            alert("No element with id: " + key);
        }
    }

    var update_fields = function(cf_data) {
        $.ajax({
            url: '/Helpers/GetTicketData',
            data: cf_data,
            dataType: 'json',
            success: function(data) {
                $.each(data, fill_value);
            },
            error: function(jqXHR, textStatus) {
                alert('Error: ' + textStatus);
            },
        });
    };

    $('.autofill_custom_fields').click(function(ev){
        ev.preventDefault();

        var queue_id = $("input[name=Queue]").first().val();

        var cf_data = { "queue_id": queue_id };

        // Pass custom fields that are currently on page
        $("[class*=CF-]").each(function(){
            // magic value indicating that the field exists on page
            cf_data[$(this).attr('id')] = '__exists__';
        });

        // Store key field value
        var key_field = $(this).parent().prev().children().first().next();
        cf_data[ $(key_field).attr('id') ] = $(key_field).val();

        update_fields(cf_data);
    });
});
