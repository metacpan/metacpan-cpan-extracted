Ext.define('Pcore.ViewController', {
    extend: 'Ext.app.ViewController',

    alias: 'controller.pcore-viewcontroller',

    _createFormPanel: function (formPanelClass, model, formPanelCfg) {
        this.getViewModel().set('editModel', model);

        var defaultCfg = {
            editModel: model,
            viewModel: {
                parent: this.getView().getViewModel()
            }
        };

        var formPanel = Ext.create(formPanelClass, Ext.apply(defaultCfg, formPanelCfg));

        return formPanel;
    },

    _createFormPanelWindow: function (formPanel, windowCfg) {
        var defaultCfg = {
            // layout
            layout: 'fit',
            modal: true,
            draggable: false,
            resizable: false,
            constrain: true,
            renderTo: Ext.getBody(),
            autoShow: true,

            // items
            items: formPanel,

            // listeners
            listeners: {
                scope: 'this',
                beforeClose: 'onBeforeClose'
            },

            // methods
            onBeforeClose: function () {
                formPanel.cancelForm();

                return false;
            }
        };

        if (formPanel.title) {
            defaultCfg.title = formPanel.title;

            formPanel.title = null;
        }

        var win = Ext.create('Ext.window.Window', Ext.apply(defaultCfg, windowCfg));

        formPanel.on('destroy', function () {
            win.destroy();
        }, this);

        return win;
    }
});
