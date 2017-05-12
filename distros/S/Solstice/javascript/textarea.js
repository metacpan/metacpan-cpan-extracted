/**
 * @fileoverview Functions pertaining to the Solstice::FormInput::TextArea
 */

/**
 * @class Contains the textarea functionality
 * @constructor
 */
Solstice.TextArea = function(){};

Solstice.TextArea.isRichTextEnabled = true;

/**
 * The container to be resized 
 */
Solstice.TextArea.resize_target = null;
Solstice.TextArea.currid = null;
/**
 * The grey border to indicate new textarea size
 */
Solstice.TextArea.resize_guide = null;

/**
 * An array to hold the original height/widths prior to resizing
 */
Solstice.TextArea.Orig = new Array();

/**
 * Sets initial style and attaches the resize events.
 * @param {event} event the mouseclick that began the resize
 * @param {string} id the id prefix of the textearea/resizing group
 */
Solstice.TextArea.startResize = function(event, id) {
    Solstice.Event.add(document, 'mouseup', Solstice.TextArea.stopResize);

    // Get the resize target obj
    Solstice.TextArea.resize_target = document.getElementById(id + '_container');

    if (Solstice.TextArea.resize_target) {
        // Set the resizing event handlers
        Solstice.Event.add(document, 'mousemove', Solstice.TextArea.resizeGuide);
        Solstice.Event.add(document, 'selectstart', function(){return false;});
        document.oncontextmenu = Solstice.TextArea.stopResize;

        var targetTop = Solstice.Geometry.getOffsetTop(Solstice.TextArea.resize_target);
        var targetLeft = Solstice.Geometry.getOffsetLeft(Solstice.TextArea.resize_target);

        // Remember original dimensions before resizing
        if (!Solstice.TextArea.Orig[id]) {
            Solstice.TextArea.Orig[id] = { 
                'width'  : Solstice.TextArea.resize_target.offsetWidth,
                'height' : Solstice.TextArea.resize_target.offsetHeight
            };
        }
        Solstice.TextArea.currid = id;
            
        // Move the resize guide into position and synchronize its
        // size with the target
        Solstice.TextArea.resize_guide = document.getElementById(id + '_resize');
        Solstice.TextArea.resize_guide = Solstice.TextArea.resize_guide;
        Solstice.TextArea.resize_guide.top = targetTop;
        Solstice.TextArea.resize_guide.left = targetLeft;
        Solstice.TextArea.resize_guide.style.top = targetTop + 'px';
        Solstice.TextArea.resize_guide.style.left = targetLeft + 'px';
        Solstice.TextArea.resizeGuide(event);
    }
    return false;
}

/**
 * The resizing code called to update the grey outline's shape. Used as 
 * an onmousemove handler.
 * @param {event} event the mousemove event.
 */
Solstice.TextArea.resizeGuide = function(event) {
    if (!event) event = window.event;

    // Get the current mouse position
    var newHeight = Solstice.Geometry.getEventY(event) - Solstice.TextArea.resize_guide.top + 10;
    var newWidth = Solstice.Geometry.getEventX(event) - Solstice.TextArea.resize_guide.left + 10; 

    // Impose minimum contraints, equal to the original size of the container
    if (newWidth < Solstice.TextArea.Orig[Solstice.TextArea.currid]['width']) 
        newWidth = Solstice.TextArea.Orig[Solstice.TextArea.currid]['width'];
    if (newHeight < Solstice.TextArea.Orig[Solstice.TextArea.currid]['height'])
        newHeight = Solstice.TextArea.Orig[Solstice.TextArea.currid]['height'];
    
    // Resize the guide box
    Solstice.TextArea.resize_guide.style.width = newWidth + 'px'; 
    Solstice.TextArea.resize_guide.style.height = newHeight + 'px';
}

/**
 * Dismisses the resize box, removes the event listeners and changes the actual textarea.
 */
Solstice.TextArea.stopResize = function() {
    // Remove the event handlers
    Solstice.Event.remove(document, 'mouseup', Solstice.TextArea.stopResize);
    Solstice.Event.remove(document, 'mousemove', Solstice.TextArea.resizeGuide);
    Solstice.Event.remove(document, 'selectstart', Solstice.TextArea.returnFalse);
    document.oncontextmenu = null;

    if (Solstice.TextArea.resize_guide) {
        resize_guide = Solstice.TextArea.resize_guide;
        resize_target = Solstice.TextArea.resize_target;

        // Move the guide out of the viewable area
        resize_guide.style.top = '-1' + resize_guide.style.height;

        // Synchronize the editor with the guide
        resize_target.style.width = resize_guide.style.width;
        resize_target.style.height = resize_guide.style.height;

        // A concession for IE; since its textareas do not support 
        // "height: 100%", set it explicitly
        var textarea = resize_target.getElementsByTagName('textarea')[0];
        if (textarea) textarea.style.height = resize_guide.style.height;
    }

    // Null the current objects
    Solstice.TextArea.resize_target = null;
    Solstice.TextArea.resize_guide = null;

    return false;
}

