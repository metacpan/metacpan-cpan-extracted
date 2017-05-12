function update_combo(init) { 
    var selected_entity = $("#entitytype").val(); 
    if(selected_entity)
    {
        var request = $.ajax({
            url: "/api/v1/"+selected_entity+"/schema",
            dataType: 'text',
            });
        request.done(function(msg) {
            entity_data = jQuery.parseJSON(msg);
            console.dir(entity_data);
            var options = '<option value="">-- select --</option>';
            options = options+'<optgroup label="Basic">';
            $.each(entity_data.basic, function( index, value ) {
                options = options+'<option value="'+value+'">'+value+'</option>';
            });
            options = options+'</optgroup>';
            if(entity_data.multilanguage.length > 0)
            {
                options = options+'<optgroup label="Multilang">';
                $.each(entity_data.multilanguage, function( index, value ) {
                    options = options+'<option value="'+value+'">'+value+'</option>';
                });
                options = options+'</optgroup>';
            }
            $('#titlefield-select').html(options);
            $('#descriptionfield-select').html(options);
            $('#linkfield-select').html(options);
            if(init == 1)
            {
                if($('#title_field').val())
                {
                    $('#titlefield-select option[value="' + $('#title_field').val() + '"]' ).prop('selected', true);
                }
                if($('#description_field').val())
                {
                    $('#descriptionfield-select option[value="' + $('#description_field').val() + '"]' ).prop('selected', true);
                }
                if($('#link_field').val())
                {
                    $('#linkfield-select option[value="' + $('#link_field').val() + '"]' ).prop('selected', true);
                }
            }
        });
    }   
    else
    {
        $('#image_preview').attr('src', '/strehler/images/no-image.png');
    }
}    
$(document).ready(function() {
        update_combo(1);
        $("#entitytype").on("change", update_combo);
        $("#titlefield-select").on("change", function() {
            var title_value = $("#titlefield-select option:selected").val();
            if(title_value)
            {
                $('#title_field').val(title_value);
            }    
        });
         $("#descriptionfield-select").on("change", function() {
            var description_value = $("#descriptionfield-select option:selected").val();
            if(description_value)
            {
                $('#description_field').val(description_value);
            }    
        });
        $("#linkfield-select").on("change", function() {
            var link_value = $("#linkfield-select option:selected").val();
            if(link_value)
            {
                $('#link_field').val(link_value);
            }    
        });
});
