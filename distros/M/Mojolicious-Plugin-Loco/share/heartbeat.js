(function ($) {

    var the_hb;  // singleton

    $.fn.heartbeat = function (options) {
	if (the_hb) return the_hb;
	var settings = $.extend(true, {}, $.fn.heartbeat.defaults, options);
	var hcb = $.Callbacks('unique');
	var fcb = $.Callbacks('once');

	var xhr;  // ajax in progress
	var xhr_next_start;
	var tid;  // waiting
	function next_hb() {
	    if (xhr) return;
	    xhr_next_start = $.now() + settings.send_wait;
	    xhr = $.ajax(settings.ajax).then(
		function(j, status) {
		    xhr = undefined;
		    if (tid) window.clearTimeout(tid);
		    var now = $.now();
		    tid = window.setTimeout(next_hb, xhr_next_start < now ? 1 : xhr_next_start - now);
		    hcb.fire(j.h);
		},
		function(xhr, status, err) {
		    fcb.fire(
			((status!='error' && status != 'timeout')
			 || xhr.status != 0),
			{ status: status, msg: err, code: xhr.status }
		    )
		}
	    );
	}
	var started = 0;
	return the_hb = {
	    on_hb: function (fns) { hcb.add(fns); return this; },
	    on_finish: function (fns) { fcb.add(fns); return this; },
	    start: function () { if (!started++) next_hb(); return this; }
	};
    };
    $.fn.heartbeat.defaults = {
	ajax: {
	    url: '/heartbeat',
	    type: 'GET',
	    timeout: 1000,
	    headers: {},
	    dataType: "json",
	    data: {}
	},
	send_wait: 1100
    };
})(jQuery);
