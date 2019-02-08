package Pcore::Ext::Lib::modern::PDF;

use Pcore -class;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

# TODO scale to match width
# TODO page navigation
# TODO scale change

sub EXT_controller : Extend('Ext.app.ViewController') : Type('controller') {
    my $pdfjs_root = $cdn->get_resource_root('pdfjs');

    return {
        _isReady => 0,

        control => {
            '#' => {
                onSetSrc   => 'loadPdf',
                onClearPdf => 'clearPdf',
            }
        },

        init => func ['view'], <<"JS",
            var me = this;

            me.callParent(arguments);

            if ( !window.pdfjsLib ) {
                var baseUrl = "$pdfjs_root";

                Ext.Loader.loadScripts({
                    url: [ baseUrl + '/pdf.min.js' ],
                    cache: true,
                    onLoad: function () {
                        me._onReady();
                    }
                });
            }
            else {
                me._onReady();
            }
JS

        _onReady => func <<"JS",
            var me = this,
                baseUrl = "$pdfjs_root",
                src = this.getView().getSrc();

            me._isReady = 1;

            pdfjsLib.GlobalWorkerOptions.workerSrc = baseUrl + "/pdf.worker.min.js";

            if (src) this.loadPdf(src);
JS

        loadPdf => func ['src'], <<"JS",
            var me = this,
                view = me.getView(),
                el = view.innerElement.dom,
                scale = view.getScale();

            if (!me._isReady) return;

            view.fireEvent('beforePdfLoad');

            pdfjsLib.getDocument(src).promise.then( function(pdf) {
                var numPages = pdf.numPages,
                    container = document.createElement("div");

                el.innerHTML = '';
                view.pdf = pdf;

                container.setAttribute("style", "display:flex;flex-direction:column;justify-content:flex-start;text-align:center;width:100%;");

                el.appendChild(container);

                for ( var i = 1; i <= numPages; i++ ) {

                    // fetch page
                    pdf.getPage(i).then( function(page) {
                        var viewport = page.getViewport(scale);

                        // Prepare canvas using PDF page dimensions
                        var div = document.createElement("div");
                        container.appendChild(div);

                        var canvas = document.createElement("canvas");
                        div.appendChild(canvas);

                        var context = canvas.getContext('2d');
                        canvas.height = viewport.height;
                        canvas.width = viewport.width;

                        // Render PDF page into canvas context
                        var renderContext = {
                            canvasContext: context,
                            viewport: viewport,
                        };

                        page.render(renderContext);
                    });
                }

                view.fireEvent('afterPdfLoad', false);
            }).catch( function (error) {
                view.fireEvent('afterPdfLoad', error.message);
            });
JS

        clearPdf => func <<'JS',
            var me = this,
                view = me.getView(),
                el = view.innerElement.dom;

            // clear current pdf
             el.innerHTML = '';

            view.pdf = null;
JS
    };
}

sub EXT_panel : Extend('Ext.Panel') {
    return {
        controller => $type->{controller},

        config => {
            src   => undef,
            scale => 1,
        },

        pdf => undef,

        layout     => 'fit',
        scrollable => \1,

        setSrc => func ['src'], <<'JS',
            this.callParent(arguments);

            this.fireEvent('onSetSrc', src);
JS

        clearPdf => func <<'JS',
            this.fireEvent('onClearPdf');
JS

        reloadPdf => func <<'JS',
            this.fireEvent('onSetSrc', this.getSrc());
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::modern::PDF

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
