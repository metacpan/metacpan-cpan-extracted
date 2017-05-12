Ext.define('Pcore.toggleslide.ToggleSlideField', {
    extend: 'Ext.form.field.Base',

    alias: 'widget.pcore-toggleslidefield',

    requires: ['Pcore.toggleslide.ToggleSlide'],

    fieldSubTpl: ['<div id="{id}" class="{fieldCls}"></div>', {
        compiled: true,
        disableFormats: true
    }],

    readOnly: false,
    disabled: false,

    value: null,

    initComponent: function () {
        var me = this,
            cfg = {
                id: me.id + '-toggle-slide'
            },
            t = null;

        cfg = Ext.copyTo(cfg, me.initialConfig, ['readOnly', 'disabled', 'onText', 'offText', 'resizeHandle', 'resizeContainer', 'background', 'onLabelCls', 'offLabelCls', 'handleCls', 'state', 'booleanMode']);

        if (me.initialConfig.value) cfg.state = me.initialConfig.value;

        if (me.initialConfig.booleanMode === false) t = me.initialConfig.state ? me.initialConfig.onText || 'ON' : me.initialConfig.offText || 'OFF';
        else t = me.initialConfig.value || me.initialConfig.state || false;

        me.initialConfig.value = t;
        me.value = t;

        me.toggle = new Pcore.toggleslide.ToggleSlide(cfg);

        me.callParent(arguments);
    },

    onRender: function (ct, position) {
        var me = this;

        me.callParent(arguments);

        me.toggle.render(me.inputEl);

        me.setRawValue(me.toggle.getValue());
    },

    initEvents: function () {
        var me = this;

        me.callParent();

        me.toggle.on('change', me.onToggleChange, me);
    },

    onToggleChange: function (toggle, state) {
        return this.setValue(state);
    },

    setValue: function (value) {
        var me = this;
        var toggle = me.toggle;

        if (value === me.value || value === undefined) return;

        me.callParent(arguments);

        if (toggle.getValue() != value) {
            toggle.toggle();
        }

        return me;
    },

    setReadOnly: function (readOnly) {
        this.callParent(readOnly);

        this.toggle.setReadOnly(readOnly);
    },

    onEnable: function () {
        Pcore.form.field.ToggleSlide.superclass.onEnable.call(this);

        this.toggle.enable();
    },

    onDisable: function () {
        Pcore.form.field.ToggleSlide.superclass.onDisable.call(this);

        this.toggle.disable();
    },

    beforeDestroy: function () {
        Ext.destroy(this.toggle);

        this.callParent();
    }
});
