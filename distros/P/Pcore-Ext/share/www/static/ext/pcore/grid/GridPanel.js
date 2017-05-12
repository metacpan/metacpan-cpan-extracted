Ext.define('Pcore.grid.GridPanel', {
    extend: 'Ext.grid.Panel',

    alias: 'widget.pcore-grid-gridpanel',

    requires: ['Ext.ux.ProgressBarPager', 'Ext.ux.SlidingPager'],

    bind: {
        store: '{store}',
        selection: '{selectedRecord}',
    },

    multiColumnSort: true,

    selType: 'checkboxmodel',
    selModel: {
        allowDeselect: true,
        checkOnly: true,
        enableKeyNav: true,
        mode: 'MULTI',
    },

    plugins: [
        {
            ptype: 'bufferedrenderer'
        }
    ],

    tbar: {
        enableOverflow: true,
        defaults: {
            scale: 'small',
            iconAlign: 'top',
            minWidth: 70,
        },
        items: [
            {
                text: 'Add',
                glyph: 0xf016,
                handler: 'createRecord',
            },
            {
                text: 'Delete',
                glyph: 0xf014,
                disabled: true,
                handler: 'deleteSelectedRecords',
                bind: {
                    disabled: '{!selectedRecord}',
                },
            },
            '->',
            {
                text: 'Reload',
                glyph: 0xf021,
                handler: 'reloadStore',
            }
        ]
    },

    dockedItems: [
        {
            xtype: 'pagingtoolbar',
            dock: 'bottom',
            displayInfo: true,
            bind: {
                store: '{store}',
            },
            plugins: [{
                ptype: 'ux-progressbarpager'
            }, {
                ptype: 'ux-slidingpager'
            }]
        }
    ],
});
