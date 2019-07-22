package Pcore::Ext::Lib::Upload;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

# accept
# https://www.w3schools.com/tags/att_input_accept.asp
# image/*,video/*,.jpeg

sub EXT_controller : Extend('Ext.app.ViewController') {
    return {
        mixins => [ $class{'/pcore/Mixin/upload'} ],

        uploads    => {},
        uploadId   => 0,
        dropTarget => undef,    # drop target

        init => func ['view'], <<'JS',
            this.callParent(arguments);

            var fileButton = this.lookup('file-button'),
                dropZone = this.lookup('drop-zone').innerElement.dom.firstChild;

            fileButton.setAccept(view.getAccept());
            fileButton.setMultiple(view.getMultiple());

            dropZone.style.width = '100%';

            this.dropTarget = new Ext.drag.Target({
                element: dropZone,
                listeners: {
                    scope: this,
                    dragenter: this.onDragEnter,
                    dragleave: this.onDragLeave,
                    drop: this.onDrop
                }
            });
JS

        onFileSelected => func [ 'button', 'newValue', 'oldValue', 'eOpts' ], <<'JS',
            var files = button.getFiles();

            for (var i = 0; i < files.length; i++) {
                this.upload(files[i]);
            }

            button.buttonElement.dom.value = '';
JS

        # DRAG & DROP
        onDragEnter => func [ 'zone', 'info', 'eOpts' ], <<'JS',
            this.lookup('drop-zone').element.dom.style['border-color'] = 'red';
JS

        onDragLeave => func [ 'zone', 'info', 'eOpts' ], <<'JS',
            this.lookup('drop-zone').element.dom.style['border-color'] = 'blue';
JS

        onDrop => func [ 'zone', 'info', 'eOpts' ], <<'JS',
            var files = info.files;

            this.lookup('drop-zone').element.dom.style['border-color'] = 'blue';

            if (!files) return;

            for (var i = 0; i < files.length; i++) {
                this.upload(files[i]);
            }
JS

        # UPLOAD
        upload => func [ 'file', 'data' ], <<"JS",
            var me = this,
                uploadId = 'upload' + ++this.uploadId,
                upload = pcoreApi.newUpload( file, me.getView().getApi(), function (upload, status, reason, progress) {
                    var viewModel = me.getViewModel();

                    if (progress !== undefined) viewModel.set( uploadId + '.progressValue', progress );

                    viewModel.set( uploadId + '.progressText', me.getUploadStatusTextProgress(status, reason, progress) );

                    // upload is starting
                    if (upload.isStarting()) {

                        // increase uploading files counter
                        viewModel.set('uploading', viewModel.get('uploading') + 1);

                        let cancelButton = me.lookup('cancel-button');
                        if (cancelButton) cancelButton.setText($l10n{Cancel});
                    }

                    // upload is finished
                    else if (upload.isFinished()) {
                        let uploadCancelButton = me.lookup(uploadId + '-cancel-button');
                        if (uploadCancelButton) uploadCancelButton.disable();

                        viewModel.set('uploading', viewModel.get('uploading') - 1);

                        if (upload.isCancelled()) {
                            viewModel.set('cancelled', viewModel.get('cancelled') + 1);
                        }
                        else if (upload.isError()) {
                            viewModel.set('error', viewModel.get('error') + 1);
                        }
                        else if (upload.isDone()) {
                            viewModel.set('done', viewModel.get('done') + 1);
                        }

                        if (!viewModel.get('uploading')) {
                            let cancelButton = me.lookup('cancel-button');
                            if (cancelButton) cancelButton.setText($l10n{Close});
                        }

                        delete me.uploads[uploadId];
                    }
                });

            // create component
            me._createUploadComponent(file, uploadId);

            // register upload
            this.uploads[uploadId] = upload;
            this.getViewModel().set(uploadId, {});

            // run upload
            upload.start(data);
JS

        _createUploadComponent => func [ 'file', 'uploadId' ], <<"JS",
            this.lookup('uploads').add({
                layout: 'vbox',
                items: [
                    {
                        html: file.name
                    },
                    {
                        layout: {
                            type: 'hbox',
                            align: 'center',
                            pack: 'space-between',
                        },

                        items: [
                            {
                                xtype: 'progress',
                                flex: 1,
                                bind: {
                                    text: '{' + uploadId + '.progressText}',
                                    value: '{' + uploadId + '.progressValue}',
                                },
                            },
                            {
                                reference: uploadId + '-cancel-button',
                                xtype: 'button',
                                iconCls: '$FAS_TIMES',
                                handler: 'cancelUpload',
                                tooltip: $l10n{'Cancel upload'},
                                value: uploadId,
                            }
                        ],
                    }
                ],
            });
JS

        cancelUpload => func ['button'], <<'JS',
            this.uploads[button.getValue()].cancel();
JS

        cancellAll => func <<'JS',
            for (let uploadId in this.uploads) {
                let upload = this.uploads[uploadId];

                delete this.uploads[uploadId];

                upload.cancel();
            }
JS

        onDestroy => func [], <<"JS",
            this.cancellAll();
JS

        close => func [], <<"JS",
            this.getView().destroy();
JS
    };
}

sub EXT_dialog : Extend('Ext.Dialog') {
    return {
        controller => $type{controller},

        viewModel => {
            data => {
                uploading => 0,
                cancelled => 0,
                error     => 0,
                done      => 0,
            },
        },

        config => {
            api      => undef,
            accept   => undef,
            multiple => \0,
        },

        closable  => \1,
        draggable => \0,
        title     => { text => l10n('UPLOAD FILES') },
        width     => 600,
        maxHeight => '90%',

        listeners => { destroy => 'onDestroy' },

        layout => 'vbox',

        items => [
            {   reference => 'drop-zone',
                xtype     => 'container',
                height    => 100,
                layout    => 'fit',
                border    => \1,
                style     => 'border:5px dashed blue;color:grey;font-size:2em;text-align:center;',
                html      => '<br/><br/>' . l10n('Drop files here'),
            },
            {   layout => {
                    type  => 'hbox',
                    align => 'center',
                },
                padding => '10 0 0 0',
                items   => [
                    {   xtype => 'component',
                        bind  => { html => 'Uploading: {uploading} / Cancelled: {cancelled} / Error: {error} / Done: {done}' },
                    },
                    { xtype => 'spacer' },
                    {   reference => 'file-button',
                        xtype     => 'filebutton',
                        text      => l10n('Select files'),
                        listeners => { change => 'onFileSelected', },
                    },
                    {   reference => 'cancel-button',
                        xtype     => 'button',
                        text      => l10n('Close'),
                        ui        => 'decline',
                        handler   => 'close',
                        margin    => '0 0 0 10',
                        minWidth  => 100,
                    },
                ],
            },
            {   reference  => 'uploads',
                layout     => 'vbox',
                scrollable => \1,
                flex       => 1,
            },
        ],
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Upload

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
