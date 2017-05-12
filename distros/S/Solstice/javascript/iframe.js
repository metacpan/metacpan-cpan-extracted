Solstice.IFrame = function () {};

Solstice.IFrame.addFocus = function(destination, name) {
    var inner_doc = Solstice.getWindow(name).document;
    var links = inner_doc.getElementsByTagName('a');

    if (destination == 'top') {
        var obj_after_first_link = Solstice.IFrame.findNextTag(links[0], true);
        if (obj_after_first_link) {
            obj_after_first_link.focus();
        }
    }
    else {
        var obj_before_last_link = Solstice.IFrame.findPreviousTag(links[links.length-1], true);
        if (obj_before_last_link) {
            obj_before_last_link.focus();
        }
    }
}

Solstice.IFrame.moveFocusDown = function(element) {
    var move_down = Solstice.IFrame.findNextTag(element, true);
    var next_focus = Solstice.IFrame.findNextTag(move_down, true);
    if (!next_focus) {
        window.focus();
        return;
    }

    next_focus.focus();
}

// Finds the next element node.  First does a depth first search on the given element, and then does a depth first search of it's next peers.
Solstice.IFrame.findNextTag = function(element, is_top) {
    if (!element) {
        return;
    }
    var child_length = element.childNodes.length;
    if (child_length) {
        // Depth first search...
        for (var i = 0; i < child_length; i++) {
            var child = element.childNodes[i];
            if (child.nodeType == 1 && Solstice.IFrame.isTabbableElement(child)) {
                return child;
            }
            var next_in_child = Solstice.IFrame.findNextTag(child, false);
            if (next_in_child) {
                return next_in_child;
            }
        }
    }
    // Find next among peers
    var sibling = element.nextSibling;
    if (sibling) {
        // 1 is an element node...
        if (sibling.nodeType == 1 && Solstice.IFrame.isTabbableElement(sibling)) {
            return sibling;
        }
        // Do the depth first search on the peer element, then look at it's peer.
        var next_tag = Solstice.IFrame.findNextTag(sibling, false);
        if (next_tag) {
            return next_tag;
        }
    }

    if (element.parentNode != window.document && is_top) {
        var next = Solstice.IFrame.findNextTag(element.parentNode.nextSibling, true);
        if (next) {
            return next;
        }
    }


    return;
}


Solstice.IFrame.moveFocusUp = function(element) {
    var move_down = Solstice.IFrame.findPreviousTag(element, true);
    var next_focus = Solstice.IFrame.findPreviousTag(move_down, true);
    if (!next_focus) {
        window.focus();
        return;
    }

    next_focus.focus();
}

// Finds the previous tag.  does a reverse depth-first search, and then moves on to the previous element, doing a depth first search there.
Solstice.IFrame.findPreviousTag = function(element, is_top) {
    if (!element) {
        return;
    }
    var child_length = element.childNodes.length;
    if (child_length) {
        // Depth first search...
        for (var i = child_length-1; i >= 0; i--) {
            var child = element.childNodes[i];

            if (child.nodeType == 1 && Solstice.IFrame.isTabbableElement(child)) {
                return child;
            }
            var next_in_child = Solstice.IFrame.findPreviousTag(child, false);
            if (next_in_child) {
                return next_in_child;
            }
        }
    }
    // Find next among peers
    var sibling = element.previousSibling;
    if (sibling) {
        // 1 is an element node...
        if (sibling.nodeType == 1 && Solstice.IFrame.isTabbableElement(sibling)) {
            return sibling;
        }
        // Do the depth first search on the peer element, then look at it's peer.
        var previous = Solstice.IFrame.findPreviousTag(sibling, false);
        if (previous) {
            return previous;
        }
    }

    if (element.parentNode != window.document && is_top) {
        var previous = Solstice.IFrame.findPreviousTag(element.parentNode.previousSibling, true);
        if (previous) {
            return previous;
        }
    }



    return;
}

Solstice.IFrame.isTabbableElement = function(element) {
    var tagname = element.tagName;
    switch (tagname.toLowerCase()) {
        case 'a':
        case 'input':
        case 'button':
        case 'select':
        case 'textarea':
            break;
        default:
            return false;
    }

    if (element.getAttribute('type') && element.getAttribute('type') == 'hidden') {
        return false;
    }
    return true;
}

