package Pcore::Ext::Class::ReCaptcha;

use Pcore;

our $EXT_MAP = {    #
    field => 'Ext.form.field.Base',
};

sub EXT_field ($ext) {
    return {
        allowBlank => \0,
        hideLabel  => \0,

        config => {
            reCaptchaSiteKey   => undef,
            reCaptchaBadge     => 'inline',
            reCaptchaHl        => 'en',
            reCaptchaInvisible => \1,
            reCaptchaSize      => 'normal',
            reCaptchaTabIndex  => 0,
            reCaptchaTheme     => 'light',
            reCaptchaType      => 'image',

            reCaptchaExecuteCb => undef,
            reCaptchaWidgetId  => undef
        },

        fieldSubTpl => [    #
            q[<div id="{reCaptchaId}"></div>],
            q[<input id="{id}" data-ref="inputEl" type="hidden" name="{name}" />],
            { disableFormats => \1, }
        ],

        _renderReCaptcha => $ext->js_func(
            <<'JS'
                var me = this;

                var args = {
                    'sitekey': this.reCaptchaSiteKey,
                    'badge': this.reCaptchaBadge,
                    'type': this.reCaptchaType,
                    'tabindex': this.reCaptchaTabIndex,
                    'theme': this.reCaptchaTheme,
                    'callback': function (reCaptchaResponse) {
                        me.setValue(reCaptchaResponse);

                        if (me.reCaptchaExecuteCb) {
                            var cb = me.reCaptchaExecuteCb;

                            me.reCaptchaExecuteCb = null;

                            cb();
                        }
                    },
                    'expired-callback': function () {
                        me.setValue('');
                    }
                };

                if (this.reCaptchaInvisible) {
                    args.size = 'invisible';
                } else {
                    args.size = this.reCaptchaSize;
                }

                this.reCaptchaWidgetId = grecaptcha.render(this.getReCaptchaId(), args);
JS
        ),
        afterRender => $ext->js_func(
            <<'JS'
                this.callParent(arguments);

                // do nothing, if reCaptchaSiteKey is not set
                if (!this.reCaptchaSiteKey) {
                    return;
                }

                if (typeof grecaptcha === 'undefined') {

                    // install global onReCaptchaLoad callback
                    if (typeof onReCaptchaLoad === 'undefined') {
                        reCaptchaLoadCbQueue = [];

                        onReCaptchaLoad = function () {
                            var i;

                            while ((i = reCaptchaLoadCbQueue.shift()) !== undefined) {
                                i._renderReCaptcha();
                            }
                        };
                    }

                    reCaptchaLoadCbQueue.push(this);

                    if (typeof reCaptchaScriptLoad === 'undefined') {
                        reCaptchaScriptLoad = true;

                        var script = document.createElement('script');
                        script.src = 'https://www.google.com/recaptcha/api.js?render=explicit&onload=onReCaptchaLoad&hl=' + this.reCaptchaHl;
                        document.head.appendChild(script);
                    }
                } else {
                    this._renderReCaptcha();
                }
JS
        ),
        getErrors => $ext->js_func(
            ['value'], <<'JS'
                var errors = [];

                // do nothing, if reCaptchaSiteKey is not set
                if (!this.reCaptchaSiteKey) {
                    return errors;
                }

                // in invisible mode field is always valid
                if (this.reCaptchaInvisible) {
                    return errors;
                }

                // in visible mode chack, that reCaptcha is solved
                if (!value) {
                    errors.push('reCaptcha is not solved');
                }

                return errors;
JS
        ),
        getReCaptchaId => $ext->js_func(
            <<'JS'
                return this.reCaptchaId || (this.reCaptchaId = this.id + '-reCaptchaEl');
JS
        ),
        getSubTplData => $ext->js_func(
            ['fieldData'], <<'JS'
                var data = this.callParent(arguments);

                data.reCaptchaId = this.getReCaptchaId();

                return data;
JS
        ),
        reCaptchaExecute => $ext->js_func(
            ['cb'], <<'JS'

                // do nothing, if reCaptchaSiteKey is not set
                if (!this.reCaptchaSiteKey) {
                    cb();
                }

                // not solved
                else if (!this.getValue()) {
                    this.reCaptchaExecuteCb = cb;

                    grecaptcha.execute(this.reCaptchaWidgetId);
                }

                // already solved
                else {
                    cb();
                }
JS
        ),
        reCaptchaReset => $ext->js_func(
            <<'JS'

                // do nothing, if reCaptchaSiteKey is not set
                if (!this.reCaptchaSiteKey) {
                    return;
                }

                this.setValue('');

                grecaptcha.reset(this.reCaptchaWidgetId);
JS
        ),
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Class::ReCaptcha

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
