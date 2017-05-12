Textarea = function (textarea) {
    if ( textarea.tagName != "TEXTAREA" ) {
        throw "Textarea requires a textarea as its constructor argument";
    }

    /* IE just does not work yet */
    if ( document.selection && document.selection.createRange ) {
        return;
    }

    this.textarea = textarea;
};

if ( document.selection && document.selection.createRange ) {
    Textarea.prototype.selectedText = function () {
        var text = document.selection.createRange().text;

        if ( typeof text == "undefined" ) {
            return "";
        }

        return text;
    };

    Textarea.prototype.replaceSelectedText = function (text) {
        this.textarea.focus();

        var range = document.selection.createRange();
        range.text = text;

        range.select();
    };

    Textarea.prototype.caretPosition = function () {
        this.textarea.focus();
        return this.textarea.selectionStart;
    };

    Textarea.prototype.selectText = function ( start, end ) {
        this.textarea.focus();

        var range = this._makeNewRange( start, end );
    };

    Textarea.prototype.moveCaret = function (offset) {
        var pos = this.caretPosition() + offset;

        var range = this._makeNewRange( pos, pos );
        range.select();
    };

    Textarea.prototype._makeNewRange = function ( start, end ) {
        this.textarea.focus();

        var range = document.selection.createRange();
        range.collapse(true);
        range.moveEnd( "character", start );
        range.moveStart( "character", end );

        return range();
    };
}
else {
    Textarea.prototype.selectedText = function () {
        var start = this.textarea.selectionStart;
        var end = this.textarea.selectionEnd;

        var text = this.textarea.value.substring( start, end );

        if ( typeof text == "undefined" ) {
            return "";
        }

        return text;
    };

    Textarea.prototype.replaceSelectedText = function (text) {
        var start = this.textarea.selectionStart;
        var end = this.textarea.selectionEnd;

        var scroll = this.textarea.scrollTop;

        this.textarea.value =
            this.textarea.value.substring( 0, start )
            + text
            + this.textarea.value.substring( end, this.textarea.value.length );

        this.textarea.focus();

        this.textarea.selectionStart = start + text.length;
        this.textarea.selectionEnd = start + text.length;
        this.textarea.scrollTop = scroll;
    };

    Textarea.prototype.caretPosition = function () {
        return this.textarea.selectionStart;
    };

    Textarea.prototype.selectText = function ( start, end ) {
        this.textarea.selectionStart = start;
        this.textarea.selectionEnd = end;
    };

    Textarea.prototype.moveCaret = function (offset) {
        var new_pos = this.caretPosition() + offset;

        this.textarea.setSelectionRange( new_pos, new_pos );
    };
}

Textarea.prototype.previousLine = function () {
    var text = this.textarea.value;

    var last_line_end = text.lastIndexOf( "\n", this.caretPosition() - 1);

    if ( ! last_line_end ) {
        return "";
    }
    else {
        var prev_line_start = text.lastIndexOf( "\n", last_line_end - 1 ) + 1;
        return text.substr( prev_line_start, last_line_end - prev_line_start );
    }
}

Textarea.prototype.caretIsMidLine = function () {
    var pos = this.caretPosition();

    if ( pos == 0 ) {
        return false;
    }

    var char_before = this.textarea.value.substr( pos - 1, 1 );
    if ( char_before == "\n" || char_before == "" ) {
        return false;
    }
    else {
        return true;
    }
};

Textarea.prototype.moveCaretToBeginningOfLine = function () {
    var pos = this.textarea.value.lastIndexOf( "\n", this.caretPosition() );

    if ( pos == -1 ) {
        this.moveCaret( -1 * this.caretPosition() );
        return;
    }

    if ( pos == this.caretPosition() ) {
        /* If we take the char before and the char after the caret
         * and they're both newlines, then that means the caret is
         * currently at the head of an empty line. If, however, the
         * character before the caret's position is _not_ a newline,
         * it means we're at the end of a line. */
        if ( this.textarea.value.substr( this.caretPosition() -1, 2 ) != "\n\n" ) {
            this.moveCaret( -1 * this.caretPosition() );
        }
        return;
    }

    this.moveCaret( ( pos - this.caretPosition() ) + 1 );
};
