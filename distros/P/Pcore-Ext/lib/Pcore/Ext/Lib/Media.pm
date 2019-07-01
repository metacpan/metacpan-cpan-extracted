package Pcore::Ext::Lib::Media;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    return {};
}

sub EXT_panel : Extend('Ext.Container') {
    return {
        controller => $type{controller},

        config => {
            src     => undef,
            isVideo => \0,
        },

        layout => {
            type => 'vbox',
            pack => 'start',
        },
        scrollable => \1,
        border     => \1,
        style      => 'border:2px dashed blue;',
        flex       => 1,

        setSrc => func ['src'], <<'JS',
            this.callParent(arguments);

            this._updateHtml();
JS

        setIsVideo => func ['isVideo'], <<'JS',
            this.callParent(arguments);

            this._updateHtml();
JS

        _updateHtml => func <<'JS',
            var src = this.getSrc(),
                isVideo = this.getIsVideo();

            if (src) {
                var html;

                if (isVideo) {
                    html = '<video src="' + src + '" style="max-width:100%;max-height:100%;" controls />';

                    this.setHtml(html);
                }
                else if (!isVideo) {
                    html = '<img src="' + src + '" style="max-width:100%;max-height:100%;" />';

                    this.setHtml(html);
                }
                else {
                    this.setHtml(null);
                }
            }
            else {
                this.setHtml(null);
            }
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Media

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
