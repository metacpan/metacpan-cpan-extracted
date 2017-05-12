Ext.define('Pcore.tree.ViewController', {
    extend: 'Pcore.ViewController',

    alias: 'controller.pcore-tree-viewcontroller',

    initViewModel: function (viewModel) {
        viewModel.get('store').setRoot({
            id: this.getView().rootId,
            expanded: true
        });
    },

    getNodeControls: function (node) {
        var controls = {
            canCreate: false,
            canDelete: false,
            canEdit: false
        };

        if (node) {
            controls.canCreate = true;
            controls.canDelete = node.isRoot() ? false : true;
            controls.canEdit = node.isRoot() ? false : true;
        }

        return controls;
    },

    createRecord: function (parentNode) {
        if (!parentNode) parentNode = this.getViewModel().get('selectedNode');

        var model = this.getView().getStore().createModel({
            parentId: parentNode.getId()
        });

        var formPanel = this._createFormPanel(this.getView().createFormPanelClass, model, {
            canResetForm: false,
            title: 'Create node'
        });

        formPanel.on('recordUpdated', function (record) {
            record.set('loaded', true);
            record.set('expanded', true);

            var parentNode = this.getViewModel().get('store').getNodeById(record.get('parentId'));

            parentNode.appendChild(record);

            // select added node
            this._selectNode(record);

            this.fireViewEvent('recordUpdated', this, record);
        }, this);

        this._createFormPanelWindow(formPanel);
    },

    editRecord: function (model) {
        var wasLoaded = model.get('loaded');
        var wasExpanded = model.get('expanded');

        var formPanel = this._createFormPanel(this.getView().updateFormPanelClass, model, {
            title: 'Edit node'
        });

        formPanel.on('recordUpdated', function (record) {
            record.set('loaded', wasLoaded);
            record.set('expanded', wasExpanded);

            this.fireViewEvent('recordUpdated', this, record);
        }, this);

        this._createFormPanelWindow(formPanel);
    },

    onCollapseClick: function (button, e, owner, eOpts) {
        if (e.ctrlKey) {
            this.getView().collapseAll();
        } else {
            var node = this.getViewModel().get('selectedNode');

            if (node) this.getView().collapseNode(node, true);
        }
    },

    onExpandClick: function (button, e, owner, eOpts) {
        if (e.ctrlKey) {
            this.getView().expandAll();
        } else {
            var node = this.getViewModel().get('selectedNode');

            if (node) this.getView().expandNode(node, true);
        }
    },

    reloadStore: function () {
        var selectedNode = this.getViewModel().get('selectedNode');
        var selectedNodeId = selectedNode ? selectedNode.getId() : null;

        var store = this.getView().getStore();

        store.reload({
            scope: this,
            callback: function (records, operation, success) {
                if (success) {
                    this._selectNode(selectedNodeId);
                }
            }
        });
    },

    deleteRecords: function (records) {
        Ext.Msg.confirm('Confirm deletion', 'Are you sure to delete selected nodes?', function (result) {
                if (result == 'yes') {
                    var me = this;

                    var store = this.getView().getStore();

                    var parentNode;

                    if (records.length == 1) {
                        parentNode = records[0].parentNode;
                    } else {
                        parentNode = store.root;
                    }

                    var operation = store.getModel().getProxy().createOperation('destroy', {
                        records: records,
                        callback: function (records, operation, success) {
                            if (success) {
                                store.beginUpdate();

                                Ext.each(records, function (record) {
                                    if (record) record.remove(false);
                                }, this);

                                store.commitChanges();

                                store.endUpdate();

                                me._selectNode(parentNode);

                                me.fireViewEvent('deleteRecords', records, parentNode);
                            }
                        }
                    });

                    operation.execute();
                }
            },
            this);
    },

    _selectNode: function (node) {
        if (!node || !Ext.isObject(node)) {
            var store = this.getView().getStore();

            if (!node) {
                node = store.root;
            } else {
                node = store.getNodeById(node);

                if (!node) node = store.root;
            }
        }

        this.getView().getSelectionModel().deselectAll(true);

        if (node.isRoot()) {
            this.getView().getSelectionModel().select(node);
        } else {
            this.getView().expandPath(node.getPath());
            this.getView().getSelectionModel().select(node);
        }

        return node;
    },

    onRecordContextMenu: function (treePanel, node, el, index, e, eOpts) {
        e.stopEvent();

        var selectedNodeControls = this.getNodeControls(node);
        var menuItems = [];

        if (selectedNodeControls.canCreate) {
            menuItems.push(Ext.create('Ext.Action', {
                text: 'Add',
                glyph: 0xf016,
                scope: this,
                handler: function () {
                    this.createRecord(node);
                }
            }));
        }

        if (selectedNodeControls.canEdit) {
            menuItems.push(Ext.create('Ext.Action', {
                text: 'Edit',
                glyph: 0xf044,
                scope: this,
                handler: function () {
                    this.editRecord(node);
                }
            }));
        }

        if (selectedNodeControls.canDelete) {
            menuItems.push(Ext.create('Ext.Action', {
                text: 'Delete',
                glyph: 0xf014,
                scope: this,
                handler: function () {
                    this.deleteRecords([node]);
                }
            }));
        }

        if (menuItems.length) {
            Ext.create('Ext.menu.Menu', {
                items: menuItems,
                listeners: {
                    hide: function (me) {
                        Ext.destroy(me);
                    }
                }
            }).showAt(e.getXY());
        }

        return false;
    },

    onSelectionChange: function (panel, selected, eOpts) {
        if (!selected.length) return false;
    }
});
