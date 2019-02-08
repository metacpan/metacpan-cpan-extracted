package Pcore::Ext::Lib::modern::Link;

use Pcore;

sub EXT_panel : Extend('Ext.Component') : Type('widget') {
    return {
        element => {
            reference => 'element',
            tag       => 'a',
            href      => '#',
            listeners => { click => 'onClick' },
        },

        config => {
            href    => undef,
            target  => undef,
            handler => undef,
            scope   => undef,
        },

        onClick => func ['e'], <<'JS',
             return this.onTap(e);
JS

        onTap => func ['e'], <<'JS',
             if (this.getDisabled()) return false;

            this.fireAction('tap', [this, e], 'doTap');
JS

        doTap => func [ 'me', 'e' ], <<'JS',
            var handler = me.getHandler();

            if (e && e.preventDefault) e.preventDefault();

            if (handler) {
                Ext.callback(handler, me.getScope(), [me, e], 0, me);
            }
            else {
                var href = me.getHref(),
                    target = me.getTarget();

                if (target) {
                    window.open(href, target);
                }
                else {
                    window.location = href;
                }
            }
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::modern::Link

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
