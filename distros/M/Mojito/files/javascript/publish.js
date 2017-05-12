$(document).ready(function() {
	var name = $( "#name" ),
	target_base_url = $( "#target_base_url" ),
	user = $( "#user" ),
	password = $( "#password" ),
	allFields = $( [] ).add( name ).add( user ).add( password );

	$( "#dialog-form" ).dialog({
		autoOpen: false,
		height: 320,
		width: 580,
		modal: true,
		buttons: {
			"Publish": function() {
				allFields.removeClass( "ui-state-error" );
				publishPage();
				$( this ).dialog( "close" );
			},
			Cancel: function() {
				$( this ).dialog( "close" );
			}
		},
		close: function() {
			allFields.val( "" ).removeClass( "ui-state-error" );
		}
	});
	
	$( "#publish-page" )
		.button()
		.click(function() {
			$( "#dialog-form" ).dialog( "open" );
	});
});

publishPage = function() {
	var name = $('#name').val();
	var target_base_url = $('#target_base_url').val();
	var user = $('#user').val();
	var password = $('#password').val();
	var id = $('#page_id').val();
	var post_url = mojito.base_url + 'publish';
	var data = { 
		 id: id,
		 name: name,
		 target_base_url: target_base_url,
		 user: user,
		 password: password
    };

	var ajaxOptions = {
		type : 'POST',
		url  : post_url,
		data : data,
		success : function(response, status) {
			if (response.result) {
				window.location = target_base_url + name;
			}
			else {
				$('#message_area').html('Problem publishing');
			}
	    },
		error : function(XMLHttpRequest, textStatus, errorThrown) {
			alert("Error: " + textStatus + " thrown: " + errorThrown); 
		},
		dataType : 'json'
	};

	$.ajax(ajaxOptions);

	return true;
};
