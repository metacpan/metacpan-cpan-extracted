Ext.define('Pcore.ckeditor.CkeditorField', {
    extend: 'Ext.form.field.TextArea',

    alias: 'widget.pcore-ckeditorfield',

    editor: null,

    editorDefaultConfig: {
        customConfig: '',
        uiColor: '#FFFFFF',
        toolbarCanCollapse: true,
        removePlugins: '',
        defaultLanguage: 'en',
        language: Ext.locale,
        width: '100%',
        dialog_noConfirmCancel: true,
        //baseFloatZIndex: 99999999,
    },

    editorToolbarGroups: {
        full: [{
                name: 'document',
                groups: ['mode', 'document', 'doctools']
        },
            {
                name: 'tools'
        },
            {
                name: 'clipboard',
                groups: ['clipboard', 'undo']
        },
            {
                name: 'editing',
                groups: ['find', 'selection', 'spellchecker']
        },
            {
                name: 'styles'
        },
            {
                name: 'others'
        },
        '/', {
                name: 'basicstyles',
                groups: ['basicstyles', 'cleanup']
        },
            {
                name: 'paragraph',
                groups: ['list', 'indent', 'blocks', 'align', 'bidi']
        },
            {
                name: 'colors'
        },
            {
                name: 'links'
        },
            {
                name: 'insert'
        },
            {
                name: 'forms'
        }],
        basic: [{
                name: 'tools'
        },
            {
                name: 'basicstyles',
                groups: ['basicstyles', 'cleanup']
        },
            {
                name: 'paragraph',
                groups: ['list', 'indent', 'blocks', 'align', 'bidi']
        },
            {
                name: 'colors'
        },
            {
                name: 'links'
        }]
    },

    editorConfig: {},

    editorToolbar: 'full',
    fileBrowserClass: null,

    editorPlugins: {
        sourcearea: true,
        div: false,
        forms: false,
        format: true,
        font: true,
        iframe: true,
        youtube: true,
        image2: true,
    },

    _attachEditor: function () {
        if (typeof (CKEDITOR) == 'undefined') {
            CKEDITOR_BASEPATH = '/static/ckeditor/';

            Ext.Loader.loadScript({
                url: '/static/ckeditor/ckeditor.js',
                onLoad: function () {
                    this._renderEditor();
                },
                scope: this
            });
        } else {
            this._renderEditor();
        }
    },

    _renderEditor: function () {
        var me = this;

        // create config
        var config = Ext.merge({},
            this.editorDefaultConfig, this.editorConfig);

        // configure toolbarGroups
        config.toolbarGroups = this.editorToolbarGroups[this.editorToolbar];

        // configure resizeable
        config.resize_enabled = this.resizable;

        // set height
        if (me.height) {
            config.height = me.height;
        }

        if (this.fileBrowserClass) {
            config.filebrowserBrowseUrl = '/';
        }

        // disable plugins
        for (var plugin in this.editorPlugins) {
            if (!this.editorPlugins[plugin]) {
                config.removePlugins += ', ' + plugin;
            }
        }

        // attach CKEditor to DOM element
        this.editor = CKEDITOR.replace(this.getInputId(), config);

        // redefne file browser popup dialog
        this.editor.popup = function (url) {
            var re = /CKEditorFuncNum=(\d+)/;
            var match = re.exec(url);
            CKEditorFuncNum = match[1];

            var win;

            win = Ext.create(me.fileBrowserClass, {
                selectCallback: function (model) {
                    CKEDITOR.tools.callFunction(CKEditorFuncNum, model.get('location'));

                    win.destroy();
                }
            }).showWindow();
        },

        // keyboard shortcuts
        this.editor.setKeystroke([
            [CKEDITOR.CTRL + 112, 'toolbarCollapse'], // CTRL + F1
            [CKEDITOR.ALT + 88, 'maximize'] // ALT + X
        ]);

        // change event for wysiwyg mode
        this.editor.on('change', function (e) {
            var newValue = me.editor.getData();
            var oldValue = me.getValue();

            if (newValue != oldValue) {
                me.setValue(newValue, true);
            }
        });

        // change event for source mode
        this.editor.on('mode', function () {
            if (this.mode == 'source') {
                var editable = me.editor.editable();

                editable.attachListener(editable, 'input', function () {
                    var newValue = me.editor.getData();
                    var oldValue = me.getValue();

                    if (newValue != oldValue) {
                        me.setValue(newValue, true);
                    }
                });
            }
        });
    },

    msgTarget: 'under',

    setValue: function (value, fromEditor) {
        var oldValue = this.getValue();

        this.callParent(arguments);

        if (!fromEditor) { // don't update editor if called from editorOnChange event
            var editor = this.editor;

            if (editor) { // update editor only if editor already instantinated
                if (value != oldValue) {
                    editor.setData(value);
                }
            }
        }

        return this;
    },

    listeners: {
        afterrender: function (me) {
            me._attachEditor();
        },
        beforedestroy: function (me) {
            if (me.editor) {
                me.editor.destroy();
            }
        }
    }
});
/* -----SOURCE FILTER LOG BEGIN-----
 *
 * W030, line: 166, col: 10, Expected an assignment or function call and instead saw an expression.
 *
 * -----SOURCE FILTER LOG END----- */
