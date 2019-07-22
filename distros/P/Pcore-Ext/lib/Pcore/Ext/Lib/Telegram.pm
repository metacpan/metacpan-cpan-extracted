package Pcore::Ext::Lib::Telegram;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_button : Extend('Ext.Container') : Type('widget') {
    return {
        config => {
            telegramBotId         => undef,
            telegramButtonSize    => 'large',    # small. medium, large
            telegramUserPic       => \0,
            telegramRequestAccess => 'write',
            telegramButtonRadius  => 0,
        },

        hidden => \1,

        updateTelegramBotId => func ['value'], <<'JS',
            if (value) {
                this.initTelegram();

                this.show();
            }
            else {
                this.hide();
            }
JS

        initTelegram => func <<'JS',
            var me = this;

            window.onTelegramAuth = function (user) {
                me.lookupController().fireSigninEvent('telegram', user);
            };

            var script = document.createElement('script');
            script.setAttribute('src', 'https://telegram.org/js/telegram-widget.js?6');
            script.setAttribute('data-telegram-login', this.getTelegramBotId());
            script.setAttribute('data-size', this.getTelegramButtonSize());
            script.setAttribute('data-userpic', this.getTelegramUserPic());
            script.setAttribute('data-request-access', this.getTelegramRequestAccess());
            script.setAttribute('data-radius', this.getTelegramButtonRadius());
            script.setAttribute('data-onauth', 'onTelegramAuth(user)');

            this.innerElement.dom.appendChild(script);
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Telegram

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
