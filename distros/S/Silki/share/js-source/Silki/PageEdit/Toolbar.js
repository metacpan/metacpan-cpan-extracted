JSAN.use('DOM.Element');
JSAN.use('DOM.Events');
JSAN.use('DOM.Utils');
JSAN.use('Textarea');

Silki.PageEdit.Toolbar = function () {
    /* Not really working yet */
    return;

    this.textarea = new Textarea ( $("page-content") );

    if ( ! this.textarea ) {
        return;
    }

    for ( var i = 0; i < Silki.PageEdit.Toolbar._Buttons.length; i++ ) {
        var button_def = Silki.PageEdit.Toolbar._Buttons[i];

        var button = $( button_def[0] + "-button" );

        if ( ! button ) {
            continue;
        }

        if ( typeof button_def[1] == "function" ) {
            this._instrumentButton( button, button_def[1] );
        }
        else {
            var open = button_def[1];
            var close = button_def[2];

            var func = this._makeTagTextFunction( open, close );

            this._instrumentButton( button, func );
        }
    }

    DOM.Element.show( $("toolbar") );
};

Silki.PageEdit.Toolbar.prototype._makeTagTextFunction = function ( open, close ) {
    var self = this;

    var func = function () {
        var text = self.textarea.selectedText();

        var result = text.match( /^(\s+)?(.+?)(\s+)?$/ );

        var new_text;
        if ( result && result[0] ) {
            new_text =
                ( typeof result[1] != "undefined" ? result[1] : "" )
                + open + result[2] + close +
                ( typeof result[3] != "undefined" ? result[3] : "" );
        }
        else {
            new_text = open + text + close;
        }

        self.textarea.replaceSelectedText(new_text);

        if ( ! text.length ) {
            self.textarea.moveCaret( close.length * -1 );
        }
    };

    return func;
};

Silki.PageEdit.Toolbar.prototype._instrumentButton = function ( button, func ) {
    var self = this;

    var on_click = function () {
        /* get selected text */
       func.apply(self);
    };

    DOM.Events.addListener( button, "click", on_click );
};

Silki.PageEdit.Toolbar._insertBulletList = function () {
    this._insertBullet("*");
};

Silki.PageEdit.Toolbar._insertNumberList = function () {
    this._insertBullet("1.");
};

Silki.PageEdit.Toolbar.prototype._insertBullet = function (bullet) {
    var insert;
    var old_pos;

    if ( this.textarea.caretIsMidLine() ) {
        insert = bullet + " ";
        old_pos = this.textarea.caretPosition();
    }
    else {
        insert = bullet + " \n\n";
    }

    if ( ! this.textarea.previousLine().match(/^\n?$/) ) {
        insert = "\n" + insert;
    }

    this.textarea.moveCaretToBeginningOfLine();

    this.textarea.replaceSelectedText(insert);

    if (old_pos) {
        this.textarea.moveCaret( ( old_pos - this.textarea.caretPosition() ) + insert.length );
    }
    else {
        this.textarea.moveCaret(-2);
    }
};

Silki.PageEdit.Toolbar._makeInsertHeaderFunction = function (header) {
    var func = function () {
        var old_pos;

        var insert = header + " ";

        if ( this.textarea.caretIsMidLine() ) {
            old_pos = this.textarea.caretPosition();
        }
        else {
            insert = insert + "\n\n";
        }

        this.textarea.moveCaretToBeginningOfLine();

        this.textarea.replaceSelectedText(insert);

        if (old_pos) {
            this.textarea.moveCaret( ( old_pos - this.textarea.caretPosition() ) + insert.length );
        }
        else {
            this.textarea.moveCaret(-2);
        }
    };

    return func;
};

Silki.PageEdit.Toolbar._Buttons = [ [ "h2", Silki.PageEdit.Toolbar._makeInsertHeaderFunction('##') ],
                            [ "h3", Silki.PageEdit.Toolbar._makeInsertHeaderFunction('###') ],
                            [ "h4", Silki.PageEdit.Toolbar._makeInsertHeaderFunction('####') ],
                            [ "bold", "**", "**" ],
                            [ "italic", "*", "*" ],
                            [ "bullet-list", Silki.PageEdit.Toolbar._insertBulletList ],
                            [ "number-list", Silki.PageEdit.Toolbar._insertNumberList ]
                          ];
