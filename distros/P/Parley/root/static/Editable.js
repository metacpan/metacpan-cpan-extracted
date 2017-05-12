/*
   Heavily borrowed from the example at:

     http://blog.davclass.com/

   Objectified and extended by:

     Chisel Wright <chisel@herlpacker.co.uk>
*/

/*
    Example usage:

    <script type="text/javascript" src="/path/to/Editable.js"></script>
    <script type="text/javascript">
        // create a new object
        var E  = new YAHOO.widget.EditableElement;
        // override the default callback()
        E.callback = function(){ console.log('my callback called') };
        // initialise the widget
        E.init();
    </script>
*/

(function () {
    YAHOO.widget.EditableElement = function() {
        var Dom             = YAHOO.util.Dom,
            YU              = YAHOO.util;

        this.config = {
            class_name      : 'editable',   // the default classname to make editable
            trigger         : 'click',      // or 'doubleclick'
            input_type      : 'text',       // or 'textarea'

            //min_input_size  : 0,

            save_on_enter   : true,         // does the enter key trigger a Save?
            clear_on_escape : true,         // does the escape key trigger a Cancel?

            linebreak       : false,        // insert a linebreak before the buttons?

            save_button     : true,         // show a Save button?
            cancel_button   : true,         // show a Cancel button?

            textarea_rows   : 6,            // default rows to use if we're
                                            // working with a textarea
            textarea_cols   : 50            // default colums to use if we're
                                            // working with a textarea
        };
        this.clicked  = undefined;
        this.contents = undefined;
        this.input    = undefined;

        // set up the object to monitor relevant DOM elements
        this.init = function() {
            _items = Dom.getElementsByClassName(this.config.class_name);
            if (_items.length > 0) {
                for (i = 0; i < _items.length; i++) {
                    // make sure the item has an id
                    this.elID = YU.Dom.generateId(_items[i]);

                    // add the (double-)click listener
                    YU.Event.addListener(
                        _items[i],
                        this.config.trigger,
                        this.triggered,
                        this,
                        true);

                    /* if we need to handle any key events */
                    if (   this.config.save_on_enter
                        || this.config.clear_on_escape
                    ) {
                        var status = YU.Event.addListener(
                            _items[i],
                            'keyup',
                            this.onKeyUp,
                            this,
                            true
                        );
                    }
                }
            }
        };


        // if I new javascript better I probably wouldn't have to
        // write my own max() function
        this._max = function(x,y) {
            if (x>y) { return x; }
            return y;
        };

        /* when working with a <textarea /> this.clicked can be a node
           _inside_ the node we're monitoring, e.g. if you click on a
           <i>...</i> portion of the text.
           We want to edit the whole block, so we step up to the first node we
           find that has a className matching this.config.class_name
        */
        this.step_up = function(el) {
            if (el) {
                var tmpEl = el;
                while (tmpEl.className != this.config.class_name) {
                    tmpEl = tmpEl.parentNode;
                }
                if (tmpEl) {
                    el = tmpEl;
                }
            }
            return el;
        }

        this.triggered = function(ev) {
            if (! this.check() ) {
                return;
            }

            this.clicked = YU.Event.getTarget(ev);
            this.clicked = this.step_up(this.clicked);

            this.contents = this.clicked.innerHTML;
            this.create_input_field();
        };


        this.onKeyUp = function(p_oEvent) {
            var keyCode = YU.Event.getCharCode(p_oEvent);

            switch (keyCode) {
                case 13: // enter key
                    if (this.config.save_on_enter) {
                        this.check(p_oEvent);
                    }
                    break;

                case 27: // enter key
                    if (this.config.save_on_enter) {
                        // ideally we'd reset the box to its original value here
                        this.reset_input_field();
                    }
                    break;

                default:
                    // do nothing
                    break;
            }
        };


        this.create_input_field = function() {
            this.input = YU.Dom.generateId();

            /*
             * Create a 'input type="text"' element
             */
            if (this.config.input_type == 'text') {
                // create a new element for the input
                new_input  = document.createElement('input');
                min_size   = this._max(this.contents.length, this.config.min_size);
                with (new_input) {
                    setAttribute('type', 'text');
                    setAttribute('id', this.input);
                    value = this.contents;
                    setAttribute('size', min_size);
                    className = 'editable_input';
                }
            }
            /*
             * Create a 'textarea' element
             */
            else if (this.config.input_type == 'textarea') {
                new_input  = document.createElement('textarea');
                with (new_input) {
                    setAttribute('id', this.input);
                    value = this.contents;
                    className = 'editable_input';

                    setAttribute('rows', this.config.textarea_rows);
                    setAttribute('cols', this.config.textarea_cols);
                }
            }

            this.clicked.innerHTML = '';
            this.clicked.appendChild(new_input);

            // insert a line-break before the buttons
            if (this.config.linebreak) {
                newline = document.createElement('br');
                this.clicked.appendChild(newline);
            }

            // show the save button
            if (this.config.save_button) {
                this.create_save_button();
            }

            // show the cancel button
            if (this.config.cancel_button) {
                this.create_cancel_button();
            }

            // select the newly created input field
            new_input.select();
        };


        this.create_save_button = function() {
            // create the save button
            this.save_input  = YU.Dom.generateId();
            new_save_input   = document.createElement('input');
            with (new_save_input) {
                setAttribute('type', 'button');
                setAttribute('id', this.save_input);
                value = 'Save';
                className = 'editable_input';
            }
            // add it to the clicked element
            this.clicked.appendChild(new_save_input);
            // add a listener
            YU.Event.addListener(
                new_save_input,
                'click',
                this.check,
                this,
                true
            );
        };


        this.create_cancel_button = function() {
            // create the cancel button
            this.cancel_input  = YU.Dom.generateId();
            new_cancel_input   = document.createElement('input');
            with (new_cancel_input) {
                setAttribute('type', 'button');
                setAttribute('id', this.cancel_input);
                value = 'Cancel';
                className = 'editable_input';
            }
            // add it to the clicked element
            this.clicked.appendChild(new_cancel_input);
            // add a listener
            YU.Event.addListener(
                new_cancel_input,
                'click',
                this.reset_input_field,
                this,
                true
            );
        };


        this.reset_input_field = function() {
            this.clicked.innerHTML = this.contents;
            this.clicked  = undefined;
            this.contents = undefined;
            this.input    = undefined;
        };


        this.clear_input = function() {
            if (this.input) {
                var input_value = YU.Dom.get(this.input).value;

                if (input_value.length > 0) {
                    this.clean_input();
                    this.contents_new = input_value;
                }
                else {
                    this.contents_new = '[removed]';
                }
                this.clicked.innerHTML = this.contents_new;

                if (this.contents_new != this.contents) {
                    var el = this.step_up(this.clicked);
                    this.callback(el);
                }
            }
            this.clicked  = undefined;
            this.contents = undefined;
            this.input    = undefined;
        };


        this.clean_input = function() {
            checkText   = new String(YU.Dom.get(this.input).value);
            regEx1      = /\"/g;
            checkText       = String(checkText.replace(regEx1, ''));
            YU.Dom.get(this.input).value = checkText;
        };


        this.check = function(ev) {
            if (!ev) {
                if (this.clicked == undefined) {
                    return true;
                }
                return false;
            }
            if (this.clicked) {
                clicked = YU.Event.getTarget(ev);
                this.clear_input();
                return true;
            }
        };


        // a default callback() function; you'll want to assign your own in
        // the object you create
        this.callback = function() {
            alert('default callback() called');
        };
    };
})();
