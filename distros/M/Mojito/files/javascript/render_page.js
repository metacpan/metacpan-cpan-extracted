// A central place to store application variables
var mojito = {};
var got_content, oneshot, resizeEditArea, fetchPreview;
/* global prettyPrint: false */

var oneshot_preview = oneshot();
var oneshot_pause = 1000; // Time in milliseconds.
var on_change_refresh_rate = 10000;
var resizeTimer;
	
$(document).ready(function() {

	$('#content').each(function() {
		this.focus();
	});

	resizeEditArea();
	$(window).resize(function() {
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(resizeEditArea, 100);
	});
//	$('textarea#content').autoResize({ 
//	    extraSpace : 60
//    }).trigger('change');
	
	// Recall edit view state
	if ($.cookie('mojito.toggle_view') == 'off') {
	    toggle_view_off();
	}
	toggle_view();
	prettyPrint();
	sh_highlightDocument();
	scroll_edit_area();

	$('#content').keyup(function() {
		fetchPreview.only_every(on_change_refresh_rate);
		oneshot_preview(fetchPreview, oneshot_pause);
	});
	
	$('#submit_create').click(function() {
		// if no content : no submit
		return got_content();
	});
	$('#submit_save').click(function() {
		fetchPreview('save');
		return false;
	});
	$('#page_delete').click(function() {
		alert("Are you sure?");
		return false;
	});
	$('#recent_articles_label').click(function() {
		  $('#recent_area').toggle('slow', function() {
		    // Animation complete.
		  });
		  $('.view_area_view_mode').width('90%');
	});
    $('#feeds_label').css( 'cursor', 'pointer' );
    $('#feeds_label').click(function() {
        $('#feeds').toggle(100, function() { });
    });
    $('#collection_label').css( 'cursor', 'pointer' );
    $('#collection_label').click(function() {
        $('#collection_select').toggle(100, function() { });
    });
    $('.sublime').effect("pulsate", { times:2 }, 5400);

});

function got_content() {
	var content = $('textarea#content').val();
	if (!content || content.match(/^\s+$/)) {
		return false;
	}
	else {
		return true;
	}
}

fetchPreview = function(extra_action) {
	var content = $('textarea#content').val();
	var mongo_id = $('#mongo_id').val();
	var page_title = $('#page_title').val();
	// Get wiki language from selected form value on create
	var wiki_language = $('#wiki_language input:radio:checked').val();
	if (!wiki_language) {
		// Get wiki language from the hidden input for edits
		wiki_language = $('input#wiki_language').val();
	}
	
	var data = { 
			 content: content,
			 mongo_id: mongo_id,
			 page_title: page_title,
			 wiki_language: wiki_language,
			 extra_action: extra_action
		   };
	// Don't submit ajax request if we have trivial content
	if (!content || content.match(/^\s+$/)) {
		return false;
	}
	mojito.preview_url = mojito.base_url + 'preview'; 
	var ajaxOptions = {
		type : 'POST',
		url  : mojito.preview_url,
		data : data,
		success : function(response, status) {
			$('#view_area').html(response.rendered_content);
			$('#message_area').html(response.message);
			prettyPrint();
			sh_highlightDocument();
	    },
		error : function(XMLHttpRequest, textStatus, errorThrown) {
			$('#message_area').html("JS Error: " + textStatus + " thrown: " + errorThrown);
		},
		dataType : 'json'
	};

	$.ajax(ajaxOptions);

	return true;
};

function resizeEditArea() {
	// Check that we have an edit_area first.
	if ( $('#edit_area').length ) {
		mojito.edit_area_height_fraction = 0.80;
		mojito.edit_height = Math.floor( $(window).height() * mojito.edit_area_height_fraction);
		//console.log('resizing edit area width to: ' + mojito.edit_width);
		//console.log('resizing edit area height to: ' + mojito.edit_height);
		$('textarea#content').css('width', '100%');
		$('textarea#content').css('height', mojito.edit_height + 'px');
	}
}

function oneshot() {
	var timer;
	return function(fun, time) {
		clearTimeout(timer);
		timer = setTimeout(fun, time);
	};
}

// Based on
// http://www.germanforblack.com/javascript-sleeping-keypress-delays-and-bashing-bad-articles
Function.prototype.only_every = function(millisecond_delay) {
	if (!window.only_every_func) {
		var function_object = this;
		window.only_every_func = setTimeout(function() {
			function_object();
			window.only_every_func = null;
		}, millisecond_delay);
	}
};

// Toggle the View Area (only while in Edit mode)
function toggle_view() {
    $( "#toggle_view" ).button();
    $( "#toggle_view" ).click(
        function() {
            var edit_width = $('#edit_area').css('width');
            var edit_width_digits = edit_width.match(/^\d+/);
            // Assumption: if #edit_area width is more than half the 
            // total window then we are toggling from width to narrow
            if( edit_width_digits > (.50 * $(window).width()) ) {
                toggle_view_on();
            }
            else {
                toggle_view_off();
            };
        }
    );
}

function toggle_view_on() {
    $('.view_area_edit_mode').show();
    $('#edit_area').css('width', '46%');
    $.cookie('mojito.toggle_view', 'on', { expires: 7, path: '/' });
}
function toggle_view_off() {
    $('.view_area_edit_mode').hide();
    $('#edit_area').css('width', '100%');
    $.cookie('mojito.toggle_view', 'off', { expires: 7, path: '/' });
}

function scroll_edit_area() {
    // store the element so we don't have to traverse the DOM each time
    var $edit_area = $("#edit_area");
    $(window).scroll(function(){
        $edit_area
            .stop()
            .animate({"marginTop": ($(window).scrollTop() + 0) + "px"}, 900 );
    });
}
