Ext.define('Pcore.grid.ViewController', {
    extend: 'Pcore.ViewController',

    alias: 'controller.pcore-grid-viewcontroller',

    createRecord: function () {
        var model = this.getViewModel().getStore('store').createModel({});

        var formPanel = this._createFormPanel(this.getView().createFormPanelClass, model);

        formPanel.on('recordUpdated', function (record) {
            var store = this.getViewModel().get('store');

            store.addSorted(record);

            store.commitChanges();

            this.fireViewEvent('recordUpdated', this, record);
        }, this);

        formPanel.on('beforeDestroy', function () {
            this.getView().setActiveItem('grid');

            this.getViewModel().set('editModel', null);
        }, this);

        this.getView().setActiveItem(formPanel);
    },

    editRecord: function (model) {
        model.load({
            scope: this,
            success: function (record, operation) {
                var formPanel = this._createFormPanel(this.getView().updateFormPanelClass, record);

                formPanel.on('recordUpdated', function (record) {
                    this.fireViewEvent('recordUpdated', this, record);
                }, this);

                formPanel.on('beforeDestroy', function () {
                    this.getView().setActiveItem('grid');

                    this.getViewModel().set('editModel', null);
                }, this);

                this.getView().setActiveItem(formPanel);
            },
        });
    },

    reloadStore: function () {
        this.getViewModel().getStore('store').reload();
    },

    deleteRecords: function (records) {
        Ext.Msg.confirm('Confirm deletion', 'Are you sure to delete selected records?', function (result) {
            if (result == 'yes') {
                var store = this.getViewModel().getStore('store');

                var operation = store.getModel().getProxy().createOperation('destroy', {
                    records: records,
                    callback: function (records, operation, success) {
                        if (success) {
                            store.beginUpdate();

                            store.remove(records);

                            store.commitChanges();

                            store.endUpdate();
                        }
                    }
                });

                operation.execute();
            }
        }, this);
    },

    deleteSelectedRecords: function () {
        var selectedRecords = this.getView().getLayout().getActiveItem().getSelection();

        this.deleteRecords(selectedRecords);
    },

    onRecordDblClick: function (grid, model, tr, rowIndex, e, eOpts) {
        this.editRecord(model);
    }
});
