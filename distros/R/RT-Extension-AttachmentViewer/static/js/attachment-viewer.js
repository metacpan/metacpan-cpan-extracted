(function() {
    function stopMediaPlayback() {
        // VIDEO
        var video = document.getElementById("attachment-video");
        if (video) {
            video.pause();
            video.currentTime = 0;
            video.src = "";
        }
        // AUDIO
        var audio = document.getElementById("attachment-audio");
        if (audio) {
            audio.pause();
            audio.currentTime = 0;
            audio.src = "";
        }
        // PDF reset
        var pdf = document.getElementById("attachment-pdf");
        if (pdf) {
            pdf.src = "";
        }
    }

    if (window.jQuery) {
        jQuery(document).on('hidden.bs.modal', '#attachment-modal', function () {
            stopMediaPlayback();
        });
    }

    async function getMimeInfo(attachmentId) {
        if (!window.fetch) {
            return { mime: "application/octet-stream" };
        }

        try {
            const base = (window.RT && RT.Config && RT.Config.WebPath) || '';
            let res = await fetch(`${base}/Helpers/AttachmentInfo?id=${attachmentId}`);
            return await res.json();
        } catch (e) {
            return { mime: "application/octet-stream" };
        }
    }


    // MODAL
    function ensureModalExists() {
        if (document.getElementById('attachment-modal')) return;

        var modal = document.createElement('div');
        modal.id = 'attachment-modal';
        modal.className = 'modal fade';
        modal.setAttribute('tabindex', '-1');
        const modal_title = loc_key('Attachment');

        var close_class, data_dismiss,  close_content, bg_transparent;
        if (RT.AttachmentViewerRT6) {
            close_class = 'btn-close m-2 end-0';
            data_dismiss = 'data-bs-dismiss';
            close_content = '';
            bg_transparent = '';
        } else {
            close_class = 'btn close dropdown-menu-right';
            data_dismiss = 'data-dismiss';
            close_content = '<span aria-hidden="true">&times;</span>';
            bg_transparent = ' style="background-color: transparent;"';
        }

        modal.innerHTML = `
        <div class="modal-dialog modal-xl" style="max-width: 90vw;">
            <div class="modal-content" style="height: 90vh;">
                <div class="modal-header position-relative pb-0" style="background-color: var(--bs-modal-bg);">
                    <div class="modal-title fs-6">${modal_title}</div>
                    <button type="button" class="${close_class} position-absolute top-0" ${data_dismiss}="modal" aria-label="Close"${bg_transparent}>${close_content}</button>
                </div>
                <div class="modal-body"
                     style="height:100%; overflow:auto; padding:0;">

                    <img id="attachment-image"
                         style="max-width:100%; max-height:100%; display:none;" />

                    <iframe id="attachment-pdf"
                            style="width:100%; height:100%; display:none;"
                            frameborder="0"></iframe>

                    <video id="attachment-video"
                           controls
                           style="max-width:100%; max-height:100%; display:none;"></video>

                    <audio id="attachment-audio"
                           controls
                           style="width:100%; display:none;"></audio>

                    <iframe id="attachment-html"
                            style="width:100%; height:100%; display:none; border:0;"
                            sandbox="allow-same-origin allow-scripts">
                    </iframe>

                    <pre id="attachment-text"
                         style="
                            display:none;
                            width:100%;
                            height:100%;
                            margin:0;
                            padding:1rem;
                            overflow:auto;
                            white-space:pre-wrap;
                            word-break:break-word;"></pre>
                </div>

            </div>
        </div>
        `;
        document.body.appendChild(modal);
    }


    // DISPLAY
    function showFile(file, mime) {
        ensureModalExists();

        var img = document.getElementById("attachment-image");
        var pdf = document.getElementById("attachment-pdf");
        var video = document.getElementById("attachment-video");
        var audio = document.getElementById("attachment-audio");
        var htmlViewer = document.getElementById("attachment-html");
        var textViewer = document.getElementById("attachment-text");

        img.src = "";
        pdf.src = "";
        video.src = "";
        audio.src = "";
        htmlViewer.src = "";
        textViewer.textContent = "";

        img.style.display = "none";
        pdf.style.display = "none";
        video.style.display = "none";
        audio.style.display = "none";
        htmlViewer.style.display = "none";
        textViewer.style.display = "none";

        let url = (file instanceof File)
            ? URL.createObjectURL(file)
            : file;

        mime = (mime || file.type || "").toLowerCase();

        // IMAGE
        if (mime.startsWith("image/")) {
            img.src = url;
            img.style.display = "block";
        // PDF
        } else if (mime === "application/pdf") {
            pdf.src = url;
            pdf.style.display = "block";
        // VIDEO
        } else if (mime.startsWith("video/")) {
            video.src = url;
            video.style.display = "block";
        // AUDIO
        } else if (mime.startsWith("audio/")) {
            audio.src = url;
            audio.style.display = "block";
        // HTML
        } else if (mime === "text/html") {
                htmlViewer.src = url;
                htmlViewer.style.display = "block";
        // TEXT / CSV / LOG
        } else if (
            mime.startsWith("text/") ||
            mime === "application/json" ||
            mime === "application/xml"
        ) {
            if (!window.fetch) {
                window.open(url);
                return;
            }

            fetch(url)
                .then(r => r.text())
                .then(txt => {
                    textViewer.textContent = txt;
                    textViewer.style.display = "block";

                    if (window.jQuery) {
                        jQuery('#attachment-modal').modal('show');
                    }
                });
            return;
        // OTHERS
        } else {
            window.open(url, "_blank");
            return;
        }

        if (window.jQuery) {
            jQuery('#attachment-modal').modal('show');
        }
    }

    // DROPZONE
    function attachDropzoneHandler(dropzone) {
        dropzone.on("addedfile", async function(file) {
            var preview = file.previewElement;
            if (!preview) return;

            if (preview.dataset.viewerBound) return;
            preview.dataset.viewerBound = "1";

            preview.style.cursor = "pointer";
            preview.onclick = async function() {
                let info = file.rtAttachmentId
                    ? await getMimeInfo(file.rtAttachmentId)
                    : { mime: file.type };
                showFile(file, info.mime);
            };
        });
    }

     // INIT
    function init() {
        if (!window.Dropzone) return;

        var instances = Dropzone.instances || [];
        instances.forEach(function(dz) {
            attachDropzoneHandler(dz);
        });

        if (!Dropzone.prototype._attachmentViewerPatched) {
            Dropzone.prototype._attachmentViewerPatched = true;

            var origInit = Dropzone.prototype.init;

            Dropzone.prototype.init = function() {
                origInit.apply(this, arguments);
                attachDropzoneHandler(this);
            };
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }

})();
