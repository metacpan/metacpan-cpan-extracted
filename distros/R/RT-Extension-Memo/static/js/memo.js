var memoObjectType, memoObjectId, memoDiv, memoTextarea, memoValue, memoEditor;

function setDisplayMode(doUpdate) {
    // For some reason, PhantomJS does not like default value for parameters
    doUpdate = typeof doUpdate !== 'undefined' ? doUpdate : true;

    // Replace ckeditor by textarea
    if (memoEditor) {
        if (doUpdate) {
            memoEditor.updateElement();
        }
        memoEditor.destroy();
    }

    // Replace div content by textarea content
    if (doUpdate) {
        memoValue = memoTextarea.value;
        memoDiv.innerHTML = memoValue.replace(/\n/g, '<br />');
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
        memoEditor = CKEDITOR.replace(memoTextarea.name, {width: '100%', height: RT.Config.MessageBoxRichTextHeight});
        jQuery("#" + memoTextarea.name + "___Frame").addClass("richtext-editor");
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
    memoInit();
});
