var memoObjectType, memoObjectId, memoDiv, memoTextarea, memoValue, memoEditor;

function setDisplayMode(doUpdate) {
    // For some reason, PhantomJS does not like default value for parameters
    doUpdate = typeof doUpdate !== 'undefined' ? doUpdate : true;

    // Replace ckeditor by textarea
    if (memoEditor) {
        if (doUpdate) {
            if (RT.MemoRT6) {
                memoEditor.updateSourceElement();
            } else {
                memoEditor.updateElement();
            }
        }
        memoEditor.destroy();
    }

    // Replace div content by textarea content
    if (doUpdate) {
        memoValue = memoTextarea.value;
        memoDiv.innerHTML = memoValue;
        if (! RT.Config.MemoRichText) {
            memoDiv.innerHTML = memoValue.replace(/\n/g, '<br />');
        }
    }
    // Cancel textarea content
    else {
        memoTextarea.value = memoValue;
    }

    // Hide textarea
    jQuery(memoTextarea).hide();

    // Hide div if empty
    if (memoValue.length === 0 || !memoValue.trim()) {
        jQuery(memoDiv).hide();
    }
    // Show div otherwise
    else {
        jQuery(memoDiv).show();
    }

    // Display Add/Edit button
    if (memoValue.length === 0 || !memoValue.trim()) {
        jQuery('#ActionMemo').val(loc_key('MemoAdd'));
        jQuery('#ActionMemo').attr('data-action', 'Add');
    } else {
        jQuery('#ActionMemo').val(loc_key('MemoEdit'));
        jQuery('#ActionMemo').attr('data-action', 'Edit');
    }

    // Hide Cancel button
    jQuery('#CancelMemo').hide();
}

function setEditMode() {
    // Hide div
    jQuery(memoDiv).hide();

    // Show textarea
    jQuery(memoTextarea).show();

    // Replace textarea by ckeditor
    if (RT.Config.MemoRichText) {
        // Turn the original plain text content into HTML
        var type = jQuery("#"+memoTextarea.name+"Type");
        if (type.val() != "text/html") {
            memoTextarea.value = textToHTML(memoValue);
        }
        // Set the type
        type.val("text/html");
        if (RT.MemoRT6) {
            var height = RT.Config.MemoRichTextHeight + 'px';

            // Customize shouldNotGroupWhenFull based on textarea width
            const initArgs = JSON.parse(JSON.stringify(RT.Config.MessageBoxRichTextInitArguments));
            initArgs.toolbar.shouldNotGroupWhenFull = memoTextarea.offsetWidth >= 600 ? true : false;

            // Load core CKEditor plugins
            const corePlugins = [];
            for (const plugin of initArgs.plugins || []) {
                if (CKEDITOR?.[plugin]) {
                    corePlugins.push(CKEDITOR[plugin]);
                } else {
                    console.error(`Core CKEditor plugin "${plugin}" not found.`);
                }
            }

            // Load extra plugins
            // The source JS must already be loaded by the extension.
            const thirdPartyPlugins = [];
            for (const plugin of initArgs.extraPlugins || []) {
                if (window[plugin]?.[plugin]) {
                    thirdPartyPlugins.push(window[plugin][plugin]);
                } else {
                    console.error(`Extra CKEditor plugin "${plugin}" not found.`);
                }
            }

            // Combine core and third-party plugins
            initArgs.plugins = [...corePlugins, ...thirdPartyPlugins];
            initArgs.extraPlugins = []; // Clear extraPlugins as they're now included

            initArgs.emoji.definitionsUrl = RT.Config.WebURL + initArgs.emoji.definitionsUrl;

            CKEDITOR.ClassicEditor
                .create( memoTextarea, initArgs )
                .then(editor => {
                    RT.CKEditor.instances[editor.sourceElement.name] = editor;
                    memoEditor = editor;
                    // the height of element(.ck-editor__editable_inline) is reset on focus,
                    // here we set height of its parent(.ck-editor__main) instead.
                    editor.ui.view.editable.element.parentNode.style.height = height;
                    AddAttachmentWarning(editor);

                    const parse_cf = /^Object-([\w:]+)-(\d*)-CustomField(?::\w+)?-(\d+)-(.*)$/;
                    const parsed = parse_cf.exec(editor.sourceElement.name);
                    if (parsed) {
                        const name_filter_regex = new RegExp(
                            "^Object-" + parsed[1] + "-" + parsed[2] +
                            "-CustomField(?::\\w+)?-" + parsed[3] + "-" + parsed[4] + "$"
                        );
                        editor.model.document.on('change:data', () => {
                            const value = editor.getData();
                            jQuery('textarea.richtext').filter(function () {
                                return RT.CKEditor.instances[this.name] && name_filter_regex.test(this.name);
                            }).not(jQuery(editor.sourceElement)).each(function () {
                                if ( RT.CKEditor.instances[this.name].getData() !== value ) {
                                    RT.CKEditor.instances[this.name].setData(value);
                                };
                            });
                        });
                    }
                    editor.on('destroy', () => {
                        if (RT.CKEditor.instances[editor.sourceElement.name]) {
                            delete RT.CKEditor.instances[editor.sourceElement.name];
                        }
                    });
                })
                .catch( error => {
                    console.error( error );
                } );
        } else {
            memoEditor = CKEDITOR.replace(memoTextarea.name, {width: '100%', height: RT.Config.MemoRichTextHeight});
            jQuery("#" + memoTextarea.name + "___Frame").addClass("richtext-editor");
        }
    }

    // Display Save and Cancel buttons
    jQuery('#ActionMemo').val(loc_key('MemoSave'));
    jQuery('#ActionMemo').attr('data-action', 'Save');
    jQuery('#CancelMemo').show();
}

function processMemoAction(src) {
    switch(src.dataset.action) {
        case 'Add':
            setEditMode();
            break;
        case 'Edit':
            // Reload attribute in case someone has changed its value
            // since the page has been loaded
            jQuery.getJSON(RT.Config.WebPath + '/Helpers/GetMemo', {ObjectType: memoObjectType, ObjectId: memoObjectId}, function(value) {
                if (value) {
                    memoValue = value;
                    memoTextarea.value = memoValue;
                }
                setEditMode();
            });
            break;
        case 'Save':
            setDisplayMode();
            // Save attribute
            jQuery.post(RT.Config.WebPath + '/Helpers/SetMemo', {ObjectType: memoObjectType, ObjectId: memoObjectId, Value: memoValue}, 'json');
            break;
        case 'Cancel':
            setDisplayMode(false);
            break;
    }
}

function memoInit() {
    var allDivs = document.getElementsByClassName("memo-content");
    if (allDivs.length == 1) {
        memoDiv = allDivs[0];
        memoObjectType = memoDiv.dataset.objectclass;
        memoObjectId = memoDiv.dataset.objectid;

        var allTextareas = document.getElementsByClassName("memo-edit-content");
        if (allTextareas.length == 1) {
            memoTextarea = allTextareas[0];
            memoValue = memoTextarea.value;

            // Initialize in Display mode
            setDisplayMode(false);
        }
    }
}

jQuery(document).ready(function() {
    if (RT.MemoRT6) {
        document.body.addEventListener('htmx:load', function(evt) {
            if (jQuery(evt.detail.elt).hasClass('history') && jQuery(evt.detail.elt).hasClass('ticket')) {
                memoInit();
            }
        });
    } else {
        memoInit();
    }
});
