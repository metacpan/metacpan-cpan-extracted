package Pcore::Ext::Class::PayPal;

use Pcore;

sub EXT_button ($ext) : Extend('Ext.Component') {
    return {
        config => {
            onCreatePayment    => undef,    # mandatory
            onAuthorizePayment => undef,    # mandatory

            payPalEnv    => 'sandbox',      # sandbox, production
            payPalLocale => 'en_US',
            payPalColor  => 'blue',         # gold, blue, silver
            payPalShape  => 'rect',         # rect, pill
            payPalSize   => 'medium',       # tiny 80x20, small 144x39, medium 226x47
        },

        initComponent => $ext->js_func(
            <<'JS'
                if (!this.width && !this.height) {
                    if (this.payPalSize == 'small') {
                        this.width = 144;
                        this.height = 39;
                    } else if (this.payPalSize == 'tiny') {
                        this.width = 80;
                        this.height = 20;
                    } else if (this.payPalSize == 'medium') {
                        this.width = 226;
                        this.height = 47;
                    }
                }

                this.callParent(arguments);
JS
        ),

        afterRender => $ext->js_func(
            <<'JS'
                this.callParent(arguments);

                if (typeof paypal === 'undefined') {

                    // install global onReCaptchaLoad callback
                    if (typeof onPayPalLoad === 'undefined') {
                        payPalLoadCbQueue = [];

                        onPayPalLoad = function () {
                            var i;

                            while ((i = payPalLoadCbQueue.shift()) !== undefined) {
                                i._renderPayPal();
                            }
                        };
                    }

                    payPalLoadCbQueue.push(this);

                    if (typeof payPalScriptLoad === 'undefined') {
                        payPalScriptLoad = true;

                        var script = document.createElement('script');
                        script.src = 'https://www.paypalobjects.com/api/checkout.js';
                        script.onload = onPayPalLoad;
                        script.setAttribute('data-log-level', 'error');
                        document.head.appendChild(script);
                    }
                } else {
                    this._renderPayPal();
                }
JS
        ),

        _renderPayPal => $ext->js_func(
            <<'JS'
                var me = this;

                paypal.Button.render({
                    env: this.payPalEnv,
                    locale: this.payPalLocale,
                    style: {
                        size: this.payPalSize,
                        color: this.payPalColor,
                        shape: this.payPalShape
                    },
                    payment: function (resolve, reject) {
                        me.onCreatePayment(resolve, reject);
                    },
                    onAuthorize: function (data) {
                        me.onAuthorizePayment(data);
                    }
                }, '#' + this.getId());
JS
        ),
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Class::PayPal

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
