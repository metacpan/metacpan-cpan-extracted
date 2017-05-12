Ext.define('Pcore.form.Authorization', {
    extend: 'Ext.window.Window',

    alias: 'widget.common-authorization',

    title: 'Authorization needed',
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
        xtype: 'form',
        layout: 'fit',

        items: [{
            xtype: 'fieldset',
            border: false,
            layout: {
                type: 'vbox',
                align: 'center',
                pack: 'center'
            },
            items: [{
                    xtype: 'textfield',
                    name: 'cookie',
                    hidden: true,
                    value: 1
            },
                {
                    xtype: 'textfield',
                    name: 'login',
                    fieldLabel: 'Login',
                    vtype: 'email'
            },
                {
                    xtype: 'textfield',
                    name: 'password',
                    fieldLabel: 'Password',
                    inputType: 'password'
            }]
        }]
    }],

    initComponent: function () {
        var fbar = [{
            xtype: 'button',
            text: 'Authorize',
            iconCls: 'fa-user',
            handler: function () {
                var w = this;

                this.down('form').getForm().submit({
                    clientValidation: true,
                    jsonSubmit: true,
                    method: 'POST',
                    url: '/api/auth/',
                    success: function (form, action) {
                        w.hide();
                    },
                    failure: function (form, action) {
                        switch (action.failureType) {
                        case Ext.form.action.Action.CLIENT_INVALID:
                            Ext.Msg.alert('Failure', 'Form fields may not be submitted with invalid values');
                            break;
                        case Ext.form.action.Action.CONNECT_FAILURE:
                            //server return non-200 status
                            Ext.Msg.alert('Failure', 'Ajax communication failed');
                            break;
                        case Ext.form.action.Action.SERVER_INVALID:
                            //server return success: false
                            if (action.result.msg) {
                                Ext.Msg.alert('Failure', action.result.msg);
                            }
                        }
                    }
                })
            },
            scope: this
        }];
        Ext.apply(this, {
            fbar: fbar
        });

        this.callParent(arguments);
    }

    // listeners: {
    //     afterRender: function(thisForm, options) {
    //         this.keyNav = Ext.create('Ext.util.KeyNav', this.el, {
    //             enter: this.submit(),
    //             scope: this
    //         });
    //     }
    // }
});
/* -----SOURCE FILTER LOG BEGIN-----
 *
 * W033, line: 84, col: 19, Missing semicolon.
 *
 * -----SOURCE FILTER LOG END----- */
