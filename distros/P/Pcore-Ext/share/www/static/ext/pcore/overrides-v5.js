Ext.define('Ext.overide.data.Model', {
    override: 'Ext.data.Model',

    compatibility: '5.*',

    identifier: 'negative',
    clientIdProperty: 'client_id', // if defined, server should always return this property in each response row of "create" or "update" methods

    removeErased: function (args) {
        var options = Ext.apply({},
            args, {
                scope: null,
                success: null,
                beforeRemove: null,
                failure: null
            });

        var me = this;

        var operation = me.getProxy().createOperation('destroy', {
            records: [me],
            callback: function (records, operation, success) {
                if (success) {
                    if (options && options.beforeRemove) options.beforeRemove.call(options.scope, [me, operation]);

                    var store;
                    if (me.isNode) {
                        store = me.getTreeStore();
                    } else {
                        store = me.getStore();
                    }

                    if (store) {
                        store.beginUpdate();

                        if (me.isNode) {
                            me.remove(false);
                        } else {
                            store.remove(me);
                        }

                        store.commitChanges();
                        store.endUpdate();
                    }

                    if (options && options.success) options.success.call(options.scope, [me, operation]);
                } else {
                    if (options && options.failure) options.failure.call(options.scope, [me, operation]);
                }
            }
        });

        operation.execute();
    }
});

Ext.define('Ext.overide.data.TreeModel', {
    override: 'Ext.data.TreeModel',

    compatibility: '5.*',

    identifier: 'negative', // can't be inherited from Ext.data.Model
});

Ext.define('Ext.override.data.TreeStore', {
    override: 'Ext.data.TreeStore',

    compatibility: '5.*',

    config: {
        defaultRootProperty: 'data', // used only if parentId isn't present
        parentIdProperty: 'parentId', // This config allows node data to be returned from the server in linear format without having to structure it into children arrays.

        rootVisible: true,
        root: {
            leaf: false,
            expanded: true
        }
    },

    folderSort: true, // Set to true to automatically prepend a leaf sorter

    nodeParam: 'id', // The name of the parameter sent to the server which contains the identifier of the node

    defaultRootId: 0,
    defaultRootText: '/'
});

Ext.define('Ext.override.data.proxy.Direct', {
    override: 'Ext.data.proxy.Direct',

    compatibility: '5.*',

    pageParam: '',

    reader: {
        type: 'json',

        readRecordsOnFailure: false, // true to extract the records from a data packet even if the successProperty returns false

        metaProperty: 'meta',
        messageProperty: 'message', // the name of the property which contains a response message for exception handling
        rootProperty: 'data'
    },

    writer: {
        type: 'json',

        clientIdProperty: 'clientId' // used only for "create" method
    },

    listeners: {
        exception: function (me, request, operation, eOpts) {
            Ext.globalEvents.fireEvent('error', 'Server return "' + operation.getError() + '".');
        }
    }
});

Ext.define('Ext.override.data.Validation', {
    override: 'Ext.data.Validation',

    compatibility: '5.*',

    getErrors: function () {
        var errors = {};

        Ext.iterate(this.getData(), function (field, value) {
                if (true !== value) this[field] = value;
            },
            errors);

        return errors;
    }
});

Ext.define('Ext.override.form.field.File', {
    override: 'Ext.form.field.File',

    compatibility: '5.*',

    getFilename: function () {
        var value = this.getValue();
        var filename = '';

        if (value) {
            filename = value.split('\\').pop().split('/').pop();
        }

        return filename;
    }
});

Ext.define('Ext.override.toolbar.Paging', {
    override: 'Ext.toolbar.Paging',

    compatibility: '5.*',

    // TODO
    // http://www.sencha.com/forum/showthread.php?291950
    // override can be removed when this bug will be fixed
    firstText: null,
    prevText: null,
    nextText: null,
    lastText: null,
    refreshText: null
});
