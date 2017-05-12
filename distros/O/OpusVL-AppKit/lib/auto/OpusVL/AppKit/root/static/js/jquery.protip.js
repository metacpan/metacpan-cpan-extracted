// jQuery protip - Simple tooltip from Propeller Communications
// version 0.0.2 (uber alpha) (do not use) (pain of death)

// See README for details. https://github.com/Propcom/Protip

(function($) {

var preset = {};
preset.next = function() {
	return $(this).next();
};

function position(what, where, anchor, offset) {
	var relPos = where.split(' ');

	switch (relPos[0]) {
		case 'bottom':
			anchor.top += anchor.height;
			break;
		case 'top':
			anchor.top -= what.outerHeight();
			break;
		case 'centre':
			anchor.top += (anchor.height - what.outerHeight()) / 2;
			break;
	}

	switch (relPos[1]) {
		case 'right':
			anchor.left += anchor.width;
			break;
		case 'left':
			anchor.left -= what.outerWidth();
			break;
		case 'centre':
			anchor.left += (anchor.width - what.outerWidth()) / 2;
			break;
	}

	what.offset({
		'top': anchor.top + offset[1],
		'left': anchor.left + offset[0]
	});
}

$.fn.protip = function(opts){
	var self = this,
		args = opts,
		tip, fixed,
		api;

	if (api = self.data('protip')) {
		if (typeof args == 'object')  {
			return;
		}

		var a = [].slice.apply(arguments);
		a.shift();

		// The events get called on single objects, but the API could be called on
		// a collection, so in this case we have to pick one.
		var ret = api[args].apply(self.first(),a);
		if (ret === undefined)
			return self;
		else
			return ret;
	}
	
	api = {
		show: function(mouseEvent) {
			var anchor = args.anchor;

			tip = args.tip.apply(this);
			if (tip === false) {
				return;
			}
			if (tip.is(':visible') && fix) {
				return;
			}

			if (anchor == 'mouse') {
				anchor = {
					'top': mouseEvent.pageY,
					'left': mouseEvent.pageX,
					'height': 1,
					'width': 1
				};
			}
			else if (anchor == 'element') {
				anchor = this.offset();
				anchor.height = this.outerHeight();
				anchor.width = this.outerWidth();
			}
		
			tip.css({
				display: 'inline-block',
				position: 'absolute'
			}); // have to show it first or we can't find its size
			position(tip, args.position, anchor, args.offset);
			this.trigger('protip.show');
		},
		hide: function() {
			if (fixed) return;

			if (tip) {
				tip.hide();
				this.trigger('protip.hide');
			}
		},
		reposition: function(mouseEvent) {
			if (fixed) return;

			var anchor = {
				'top': mouseEvent.pageY,
				'left': mouseEvent.pageX,
				'height': 1,
				'width': 1
			};
			position(tip, args.position, anchor, args.offset);
		},
		cohort: function() {
			return self;
		},
		fix: function() {
			fixed = true;
		},
		unfix: function() {
			fixed = false;
		}
	};

	args = $.extend({}, {
		position: 'top right',
		anchor: 'mouse',
		offset: [10, -10],
		tip: 'next',
		showEvents: 'mouseenter',
		hideEvents: 'mouseleave'
	}, args);

	if (typeof args.tip != 'function') {
		args.tip = preset[args.tip];
	}

	self.bind(args.showEvents, function(event) {
		if (! args.onBeforeShow 
		||    args.onBeforeShow.call($(this)) !== false) {
			api.show.call($(this), event);
		}
	}).bind(args.hideEvents, function() {
		if (! args.onBeforeHide 
		||    args.onBeforeHide.call($(this)) !== false) {
			api.hide.call($(this));
		}
	}).bind('mousemove', function(event) {
		if (tip && args.anchor == 'mouse') {
			api.reposition.call($(this), event);
		}
	});

	if (args.onShow)
		self.bind('protip.show', args.onShow);
	if (args.onHide)
		self.bind('protip.hide', args.onHide);

	self.data('protip', api);
	return self;
};


})(jQuery);
