Ext.define('Pcore.tree.Panel', {
    extend: 'Ext.tree.Panel',

    requires: ['Pcore.tree.ViewController'],

    alias: 'widget.pcore-tree-panel',

    rootId: 0,
    createFormPanelClass: null,
    updateFormPanelClass: null,

    controller: {
        type: 'pcore-tree-viewcontroller'
    },

    viewModel: {
        data: {
            selectedNode: null,
        },
        formulas: {
            selectedNodeControls: {
                bind: {
                    bindTo: '{selectedNode}',
                    deep: true
                },
                get: function (selectedNode) {
                    return this.getView().getController().getNodeControls(selectedNode);
                }
            }
        }
    },

    bind: {
        store: '{store}',
        selection: '{selectedNode}'
    },

    header: {
        items: [
            {
                xtype: 'tool',
                type: 'collapse',
                tooltip: 'Collapse node, CTRL + click to collapse tree',
                listeners: {
                    click: 'onCollapseClick'
                }
            },
            {
                xtype: 'tool',
                type: 'expand',
                tooltip: 'Expand node, CTRL + click to expand tree',
                listeners: {
                    click: 'onExpandClick'
                }
            },
            {
                xtype: 'tool',
                type: 'refresh',
                tooltip: 'Refresh',
                callback: 'reloadStore'
            }
        ]
    },

    listeners: {
        itemContextMenu: 'onRecordContextMenu',
        selectionChange: 'onSelectionChange'
    }
});
