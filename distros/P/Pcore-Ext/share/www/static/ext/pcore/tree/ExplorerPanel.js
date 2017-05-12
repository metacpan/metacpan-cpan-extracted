Ext.define('Pcore.tree.ExplorerPanel', {
    extend: 'Ext.panel.Panel',

    alias: 'widget.pcore-tree-explorerpanel',

    treeRootId: 0,
    treePanelType: null,
    viewPanelType: null,
    showBreadcrumb: true,
    defaultViewType: 'small',

    canCreate: true,
    canEdit: true,
    canDelete: true,
    selectCallback: null,

    // layout
    layout: 'border',
    items: [
        {
            region: 'north',
            reference: 'north_region',
            layout: 'fit',
        },
        {
            region: 'center',
            reference: 'center_region',
            layout: 'card',
        }
    ],

    // listeners
    defaultListenerScope: true,
    referenceHolder: true,

    // methods
    initComponent: function () {
        this.callParent(arguments);

        var foldersPanel = this.add({
            region: 'west',

            xtype: this.treePanelType,

            layout: 'fit',
            collapsible: true,
            split: true,
            maxWidth: 400,
            minWidth: 270,
            width: 270,

            rootId: this.treeRootId
        });

        this.viewType = this.defaultViewType;

        if (this.showBreadcrumb) {
            this.lookupReference('north_region').add({
                xtype: 'breadcrumb',

                viewModel: {
                    parent: foldersPanel.getViewModel()
                },

                bind: {
                    store: '{store}',
                    selection: '{selectedNode}',
                },

                showIcons: true
            });
        }

        foldersPanel.getViewModel().bind('{selectedNode}', function (selectedNode) {
            this.onSelectNode(selectedNode);
        }, this);

        foldersPanel.getViewModel().getStore('store').on('beforeLoad', function () {
            this.onBeforeNodesStoreLoad();
        }, this);

        foldersPanel.on({
            deleteRecords: {
                fn: this.onDeleteNodes,
                scope: this
            },
            recordUpdated: {
                fn: function (panel, record) {
                    this.onDeleteNodes([record]);

                    this.onSelectNode(record);
                },
                scope: this
            }
        });
    },

    showWindow: function () {
        var title = this.title || '';
        this.title = '';

        var win = Ext.create('Ext.window.Window', {
            title: title,

            modal: true,
            draggable: true,
            resizable: true,
            maximizable: true,

            width: '90%',
            height: '90%',
            monitorResize: true,
            constrain: true,

            layout: 'fit',

            items: this
        });

        win.show();

        return win;
    },

    onSelectNode: function (node) {
        if (node) {
            var centerRegion = this.lookupReference('center_region');

            var itemId = 'node_view_' + node.getId();

            var nodeView = centerRegion.getComponent(itemId);

            if (!nodeView) {
                nodeView = Ext.widget({
                    itemId: itemId,
                    xtype: this.viewPanelType,
                    folderId: node.getId(),
                    canCreate: this.canCreate,
                    canEdit: this.canEdit,
                    canDelete: this.canDelete,
                    selectCallback: this.selectCallback,
                    defaultViewType: this.viewType,
                });

                nodeView.on('viewTypeChange', function (viewType) {
                    this.viewType = viewType;
                }, this);
            } else {
                nodeView.controller.setViewType(this.viewType);
            }

            centerRegion.setActiveItem(nodeView);
        }
    },

    onBeforeNodesStoreLoad: function () {
        var centerRegion = this.lookupReference('center_region');

        centerRegion.items.each(function (item) {
            item.destroy();
        });
    },

    onDeleteNodes: function (folders, selectedFolder) {
        var centerRegion = this.lookupReference('center_region');

        // https://www.sencha.com/forum/showthread.php?294334-Bug-with-activate-card-layout-item
        if (selectedFolder) centerRegion.setActiveItem('node_view_' + selectedFolder.getId());

        var deleteRecursively = function _deleteRecursively(node) {
            node.eachChild(function (childNode) {
                _deleteRecursively(childNode);
            });

            centerRegion.remove('node_view_' + node.getId());
        };

        Ext.each(folders, function (folder) {
            if (folder) deleteRecursively(folder);
        }, this);
    }
});
