Ext.define('Pcore.form.DigestAuthentication', {
    extend: 'Ext.window.Window',

    xtype: 'common-digest-authentication',

    title: 'Authentication Required',
    height: 200,
    width: 400,
    modal: true,
    resizable: false,
    draggable: false,
    closable: false,
    onEsc: function () {
        return false;
    },

    layout: 'fit',

    items: [{
        xtype: 'panel',
        html: '<br/><br/><br/><center>User authentication required to continue processing.<br/>Press "<b>Request authentication</b>" button below.</center>'
    }],

    authenticate: function () {
        w = this;
        w.mask();
        Ext.Ajax.request({
            url: '/auth/basic/',
            method: 'GET',
            callback: function (options, success, response) {},
            success: function (response, options) {

                // TODO reload application if user ID was changed
                w.close();
            },
            failure: function (response, options) {
                w.unmask();
            }
        });
    },

    initComponent: function () {
        var fbar = [{
            xtype: 'button',
            text: 'Request authentication',
            iconCls: 'fa-user',
            handler: function () {
                this.authenticate();
            },
            scope: this
        }];
        Ext.apply(this, {
            fbar: fbar
        });

        this.callParent(arguments);
    }
});
