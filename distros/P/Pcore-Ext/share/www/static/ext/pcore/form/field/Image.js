Ext.define('Pcore.form.field.Image', {
    extend: 'Ext.form.field.Text',

    alias: 'widget.pcore-imagefield',

    fileBrowserClass: false,
    width: 100,
    height: 100,

    initComponent: function () {
        this.imgWidth = this.width;
        this.imgHeight = this.height;

        this.width = null;
        this.height = null;

        this.callParent();
    },

    fieldSubTpl: [ //
        '<div id="{id}" data-ref="inputEl" style="width: {width}px; height: {height}px; display: box; cursor: pointer;">',
        '</div>',
        {
            disableFormats: true,
        }
    ],

    getSubTplData: function (fieldData) {
        var ret = this.callParent(arguments);

        ret.width = this.imgWidth;
        ret.height = this.imgHeight;

        return ret;
    },

    afterRender: function () {
        var me = this;

        me.callParent(arguments);

        me.bodyEl.setStyle('min-width', '0px');

        me.imgEl = this.el.getById(this.getInputId());

        me.imgEl.on('dblClick', function () {
                me.browseImage();
            },
            me);
    },

    browseImage: function () {
        if (!this.fileBrowserClass || this.readOnly) return;

        var me = this;
        var win;

        win = Ext.create(this.fileBrowserClass, {
            selectCallback: function (model) {
                me.setValue(model.get('location'));

                win.destroy();
            }
        }).showWindow();
    },

    setRawValue: function (value) {
        this.callParent(arguments);

        if (this.el) {
            var html;

            if (value) {
                html = '<img width="' + this.imgWidth + '" height="' + this.imgHeight + '" src="' + value + '" />';
            } else {
                html = '<table style="width: 100%; height: 100%;"><tr><td style="vertical-align: middle; text-align: center;"><font style="font-family: FontAwesome;">' + String.fromCharCode(0xf1c5) + '</font></td></tr></table>';
            }

            this.imgEl.setHtml(html);
        }
    }
});
