package Pcore::Ext::Override::v6_2_0;

use Pcore;

sub overrides {
    return <<'JS';
Ext.define('Ext.override.data.proxy.Direct', {
    override: 'Ext.data.proxy.Direct',

    compatibility: '6.*',

    batchActions: true,
    pageParam: '',

    reader: {
        type: 'json',
        rootProperty: 'data'
    },

    writer: {
        clientIdProperty: '__client_id__'
    }
});

Ext.define('Ext.override.data.operation.Operation', {
    override: 'Ext.data.operation.Operation',

    compatibility: '6.*',

    getStatus: function () {
        if (this.hasException()) {
            var error = this.getError();

            if (Ext.typeOf(error) == 'object') {
                return error.status;
            } else {

                // TODO get and return XHR status
                return 500;
            }
        } else {
            return this.getResponse().result.status;
        }
    },

    getReason: function () {
        if (this.hasException()) {
            return this.getErrorReason();
        } else {
            return this.getResponse().result.reason;
        }
    },

    getErrorReason: function () {
        var error = this.getError();

        if (Ext.typeOf(error) == 'object') {
            return error.reason;
        } else {
            return error;
        }
    },

    getFormErrors: function () {
        var error = this.getError();

        if (Ext.typeOf(error) == 'object' && Ext.typeOf(error.error) == 'object') {
            return error.error;
        } else {
            return;
        }
    }
});

Ext.define('Ext.override.direct.Event', {
    override: 'Ext.direct.Event',

    compatibility: '6.*',

    getStatus: function () {
        var error = this.message;

        if (error) {
            if (Ext.typeOf(error) == 'object') {
                return error.status;
            } else {

                // TODO get and return XHR status
                return 500;
            }
        } else {
            return this.result.status;
        }
    },

    getReason: function () {
        if (this.message) {
            return this.getErrorReason();
        } else {
            return this.result.reason;
        }
    },

    getErrorReason: function () {
        var error = this.message;

        if (Ext.typeOf(error) == 'object') {
            return error.reason;
        } else {
            return error;
        }
    },

    getFormErrors: function () {
        var error = this.message;

        if (Ext.typeOf(error) == 'object' && Ext.typeOf(error.error) == 'object') {
            return error.error;
        } else {
            return;
        }
    }
});

// fix for Firefox v52+
// https://www.sencha.com/forum/showthread.php?336762-Examples-don-t-work-in-Firefox-52-touchscreen/page2
Ext.define('EXTJS_23846.Element', {
    override: 'Ext.dom.Element'
}, function (Element) {
    var supports = Ext.supports,
        proto = Element.prototype,
        eventMap = proto.eventMap,
        additiveEvents = proto.additiveEvents;

    if (Ext.os.is.Desktop && supports.TouchEvents && !supports.PointerEvents) {
        eventMap.touchstart = 'mousedown';
        eventMap.touchmove = 'mousemove';
        eventMap.touchend = 'mouseup';
        eventMap.touchcancel = 'mouseup';

        additiveEvents.mousedown = 'mousedown';
        additiveEvents.mousemove = 'mousemove';
        additiveEvents.mouseup = 'mouseup';
        additiveEvents.touchstart = 'touchstart';
        additiveEvents.touchmove = 'touchmove';
        additiveEvents.touchend = 'touchend';
        additiveEvents.touchcancel = 'touchcancel';

        additiveEvents.pointerdown = 'mousedown';
        additiveEvents.pointermove = 'mousemove';
        additiveEvents.pointerup = 'mouseup';
        additiveEvents.pointercancel = 'mouseup';
    }
});

Ext.define('EXTJS_23846.Gesture', {
    override: 'Ext.event.publisher.Gesture'
}, function (Gesture) {
    var me = Gesture.instance;

    if (Ext.supports.TouchEvents && !Ext.isWebKit && Ext.os.is.Desktop) {
        me.handledDomEvents.push('mousedown', 'mousemove', 'mouseup');
        me.registerEvents();
    }
});
JS
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Override::v6_2_0

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
