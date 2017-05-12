Ext.define('Pcore.form.Panel', {
    extend: 'Ext.form.Panel',

    alias: 'widget.pcore-form-panel',

    editModel: null,
    canResetForm: true,
    canSaveForm: true,
    commitFormOnSave: false,
    closeAfterSave: true,

    viewModel: {
        data: {
            formIsDirty: false
        }
    },

    referenceHolder: true,

    layout: {
        type: 'anchor',
        reserveScrollbar: true,
    },
    autoScroll: true,
    bodyPadding: 10,
    minWidth: 500,
    width: 1,

    api: {},
    baseParams: {},

    modelValidation: true,
    trackResetOnLoad: true,
    fieldDefaults: {
        anchor: '100%',
        msgTarget: 'side',
    },

    fbar: {
        enableOverflow: true,
        items: [
            {
                reference: 'reset_button',
                text: 'Reset form',
                glyph: 0xf0e2,
                disabled: true,
                bind: {
                    disabled: '{!formIsDirty}',
                },
                handler: 'resetForm',
            },
            '->',
            {
                reference: 'save_button',
                text: 'Save',
                glyph: 0xf00c,
                handler: 'saveForm',
            },
            {
                text: 'Cancel',
                glyph: 0xf00d,
                handler: 'cancelForm',
            }
        ]
    },

    // listeners
    defaultListenerScope: true,
    listeners: {
        dirtyChange: function (form, dirty) {
            var viewmodel = this.getViewModel();

            if (viewmodel) viewmodel.set('formIsDirty', dirty);
        }
    },

    // methods
    initComponent: function () {
        this.callParent(arguments);

        if (!this.editModel) {
            this.canResetForm = false;
            this.canSaveForm = false;
        } else {
            this.getViewModel().set('editModel', this.editModel);
        }

        if (this.canResetForm) {
            this.loadRecord(this.editModel);
        } else {
            var resetButton = this.lookupReference('reset_button');

            if (resetButton) {
                resetButton.hide();
                resetButton.setBind({});
            }
        }

        if (!this.canSaveForm) {
            var saveButton = this.lookupReference('save_button');

            if (saveButton) {
                saveButton.hide();
                saveButton.setBind({});
            }
        } else {
            if (this.commitFormOnSave) {
                if (this.editModel) {
                    if (this.editModel.phantom) {
                        this.baseParams.clientId = this.editModel.getId();

                        this.api.submit = this.editModel.getProxy().api.create;
                    } else {
                        this.baseParams.id = this.editModel.getId();

                        this.api.submit = this.editModel.getProxy().api.update;
                    }
                }
            }
        }
    },

    resetForm: function () {
        if (this.canResetForm) {
            this.reset();

            this.getViewModel().get('editModel').reject();
        }
    },

    saveForm: function () {
        if (!this.getForm().isValid()) return;

        if (!this.getForm().isDirty()) {
            if (this.closeAfterSave) {
                return this.destroy();
            } else {
                return;
            }
        }

        if (this.commitFormOnSave) {
            this._commitForm();
        } else {
            this._commitModel();
        }
    },

    cancelForm: function () {
        if (this.getForm().isDirty()) {
            Ext.Msg.confirm('Discard changes?', 'Form was changed. Are you sure to close form and discard changes?', function (result) {
                if (result == 'yes') {
                    this.getViewModel().get('editModel').reject();

                    this.destroy();
                }
            }, this);
        } else {
            this.getViewModel().get('editModel').reject();

            this.destroy();
        }
    },

    _commitForm: function () {
        var model = this.getViewModel().get('editModel');

        this.getForm().submit({
            waitMsg: 'Commit form...',
            scope: this,
            success: function (form, action) {
                model.set(action.result.data[0]);

                model.commit();

                this.fireEvent('recordUpdated', model);

                if (this.closeAfterSave) {
                    this.destroy();
                } else {
                    if (this.canResetForm) {
                        this.loadRecord(model);
                    }
                }
            }
        });
    },

    _commitModel: function () {
        var model = this.getViewModel().get('editModel');

        model.save({
            scope: this,
            success: function (models, operation, success) {
                model.commit();

                this.fireEvent('recordUpdated', model);

                if (this.closeAfterSave) {
                    this.destroy();
                } else {
                    if (this.canResetForm) {
                        this.loadRecord(model);
                    }
                }
            },
            failure: function (models, operation, success) {
                if (operation.getProxy().getReader().rawData.errors) {
                    var form = this.getForm();

                    form.markInvalid(operation.getProxy().getReader().rawData.errors);
                }
            }
        });
    }
});
