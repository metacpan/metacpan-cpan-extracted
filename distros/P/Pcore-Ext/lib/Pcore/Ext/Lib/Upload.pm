package Pcore::Ext::Lib::Upload;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

# accept
# https://www.w3schools.com/tags/att_input_accept.asp
# image/*|video/*

# TODO setAccept is not working
sub EXT_controller : Extend('Ext.app.ViewController') {
    return {
        uploads    => [],
        dropTarget => undef,    # drop target

        # TODO move to pcoreApi
        createPcoreUpload => func [ 'file', 'api', 'calcHash', 'onProgress' ], <<"JS",
            return {
                file: file,
                api: api,
                calcHash: calcHash,
                onProgress: onProgress,

                cancelled: 0,
                chunkSize: 1024 * 1024, // 1M
                hash: null,

                cancel: function () {
                    this.cancelled = 1;

                    if (this.onProgress) this.onProgress(1, $l10n{Cancelled});
                },

                onRequestError: function (res) {
                    this.cancelled = 1;

                    if (this.onProgress) this.onProgress(1, res);
                },

                    getFileReader: function (cb) {
                        var me = this,
                            offset = 0;

                        return function () {
                            var chunk = me.file.slice(offset, offset + me.chunkSize);

                            // finished
                            if (!chunk.size) {
                                cb();

                                return;
                            }

                            var reader = new FileReader();

                            reader.onload = (function () {
                                var oldOffset = offset;

                                offset += me.chunkSize;

                                cb( oldOffset, reader.result );
                            });

                            reader.readAsBinaryString(chunk);

                            return;
                        };
                    },

                    getHash: function (cb) {
                        if (this.hash) {
                            cb(this.hash);

                            return;
                        }

                        var me = this,
                            hash = new jsSHA("SHA-1", "BYTES"),
                            readChunk = me.getFileReader(function (offset, chunk) {

                                // upload is cancelled
                                if (me.cancelled) {
                                    cb();
                                }

                                // next chunk
                                else if ( chunk !== undefined ) {
                                    hash.update(chunk);

                                    if (me.onProgress) me.onProgress(0, $l10n{'Calculating checksum'}, offset / me.file.size);

                                    readChunk();
                                }

                                // finished
                                else {
                                    me.hash = hash.getHash("HEX");

                                    if (me.onProgress) me.onProgress(0, $l10n{'Calculating checksum'}, 1);

                                    cb(me.hash);
                                }

                                return;
                            });

                        readChunk();
                    },

                    upload: function (cb) {
                        var me = this,
                        uploadCb = function(hash) {
                            if (me.cancelled) {
                                return;
                            }

                            me.api({
                                name: me.file.name,
                                size: me.file.size,
                                type: me.file.type,
                                hash: hash,
                            }, function(res) {

                                // request error
                                if (!res.isSuccess()) {
                                    me.onRequestError(res);

                                    return;
                                }

                                var id = res.data,
                                    readChunk = me.getFileReader(function (offset, chunk) {

                                        // upload is cancelled
                                        if (me.cancelled) {
                                            return;
                                        }

                                        // next chunk
                                        else if ( chunk !== undefined ) {
                                            me.api({
                                                id: id,
                                                offset: offset,
                                                chunk: btoa(chunk)
                                            }, function (res) {

                                                // upload is cancelled
                                                if (me.cancelled) {
                                                    return;
                                                }

                                                // upload error
                                                if (!res.isSuccess()) {
                                                    me.onRequestError(res);
                                                }

                                                // chunk uploaded
                                                else {
                                                    if (me.onProgress) me.onProgress(0, $l10n{Uploading}, offset / me.file.size);

                                                    readChunk();
                                                }

                                                return;
                                            });
                                        }

                                        // finished
                                        else {
                                            if (me.onProgress) me.onProgress(1, $l10n{Uploaded}, 1);
                                        }

                                        return;
                                    });

                                readChunk();
                            });
                        };

                        if (me.calcHash) {
                            me.getHash(uploadCb);
                        }
                        else {
                            uploadCb();
                        }
                    },
                };
JS

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
        upload => func ['file'], <<"JS",
            var me = this,
                view = me.getView(),
                upload = {
                    pcoreUpload: me.createPcoreUpload(file, view.getApi(), view.getCalcHash()),
                    progressBar: null,
                    cancelButton: null,
                    component: me.lookup('uploads').add({
                        layout: 'vbox',
                        items: [{
                            html: file.name
                        }],
                    }),

                    cancel: function () {
                        this.pcoreUpload.cancel();
                    },
                };

            upload.pcoreUpload.onProgress = function (final, text, progress) {
                if (final) {
                    upload.cancelButton.disable();
                }

                var percent;

                if (progress !== undefined) {
                    upload.progressBar.setValue(progress);

                    percent = Math.round(progress * 100);
                }
                else {
                    percent = Math.round(upload.progressBar.getValue() * 100);
                }

                upload.progressBar.setText(text + ' ' + percent + '%');
            };

            var progressCmp = upload.component.add({
                layout: {
                    type: 'hbox',
                    align: 'center',
                    pack: 'space-between',
                },
            });

            upload.progressBar = progressCmp.add({
                xtype: 'progress',
                flex: 1,
            });

            upload.cancelButton = progressCmp.add({
                xtype: 'button',
                iconCls: '$FAS_TIMES',
                handler: function() {upload.cancel()},
                tooltip: $l10n{'Cancel upload'},
            });

            this.uploads.push(upload);

            // run upload
            upload.pcoreUpload.upload(function () {
                return;
            });

            return;
JS

        cancellAll => func <<"JS",
            this.uploads.forEach(function(el) {
                el.pcoreUpload.onProgress = null;
                Ext.destroy(el.pcoreUpload);
                Ext.destroy(el);
            });
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

        config => {
            api      => undef,
            calcHash => \0,
            accept   => undef,
            multiple => \0,
        },

        closable  => \1,
        draggable => \0,
        title     => { text => l10n('UPLOAD FILES') },
        width     => 500,
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
            {   layout  => 'hbox',
                padding => '10 0 0 0',
                items   => [
                    { xtype => 'spacer' },
                    {   reference => 'file-button',
                        xtype     => 'filebutton',
                        text      => l10n('Select files'),
                        listeners => { change => 'onFileSelected', },
                    },
                    {   xtype   => 'button',
                        text    => l10n('Cancel'),
                        ui      => 'decline',
                        handler => 'close',
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
