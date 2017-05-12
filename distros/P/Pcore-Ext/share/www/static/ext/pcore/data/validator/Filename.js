Ext.define('Pcore.data.validator.Filename', {
    extend: 'Ext.data.validator.Format',

    alias: 'data.validator.filename',

    config: {
        message: 'Allowed characters: letters, digits, spaces and following punctuation chars: "_", "-", "."',
        matcher: /^[^/\?%*:|"><(){}[\]!#$@&\^$,]+$/
    }
});
