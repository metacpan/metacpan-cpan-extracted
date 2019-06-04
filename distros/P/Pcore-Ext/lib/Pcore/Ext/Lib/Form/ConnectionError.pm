package Pcore::Ext::Lib::Form::ConnectionError;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_panel : Extend('Ext.Panel') {
    return {
        layout => {
            type  => 'vbox',
            pack  => 'center',
            align => 'center',
        },

        items => [
            { html => l10n('Error connecting to the application server.'), },
            {   xtype   => 'button',
                iconCls => $FAS_REDO,
                text    => l10n('Try again.'),
                handler => func ['btn'],
                <<'JS',
                    btn.up().callback();
JS
            }
        ],
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Form::ConnectionError

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
