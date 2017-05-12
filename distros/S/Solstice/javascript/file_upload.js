/**
 * @fileoverview Functions pertaining to the Solstice::FormInput::FileUpload
 */
Solstice.FileUploadRegistry = new Array();

/**
 * @class Contains the file_upload functionality
 * @constructor
 */
Solstice.FileUpload = function(params) {
    this.name          = params['name'];
    // Number of input widgets to start with; this also acts as a minimum
    this.start_count   = params['start_count'];
    // Maximum number of input widgets to display
    this.max_count     = params['max_count'];
    // The upload form action attribute
    this.upload_url    = params['upload_url'];
    this.disabled      = params['disabled'];
    // Customizable labels
    this.add_label     = params['add_label'];
    this.another_label = params['another_label'];
    this.remove_label  = params['remove_label'];
    // Extends the css with a custom class, optional
    this.class_name    = params['class_name'];

    // Internal attributes
    // Tracks the current number of upload widgets present
    this.current_count = 0;
    // Used to generate IDs for the lifetime of the page
    this.id_counter    = 0;
    this.initialized   = false;
    
    this.onChangeHandlers = new Array();
    this.onUploadHandlers = new Array();
    this.onFormUpdateHandlers = new Array();

    Solstice.FileUploadRegistry[params['name']] = this;
    
    if (window.frames[params['name']]) {
        this.initialize();
    }
}

/**
 * Adds an onchange handler to the file upload object 
 * @param {string} fname The name of a function 
 */
Solstice.FileUpload.prototype.addOnChangeEvent = function(fname) {
    this.onChangeHandlers.push(eval(fname));
}

/**
 * Adds an onupload handler to the file upload object 
 * @param {string} fname The name of a function 
 */
Solstice.FileUpload.prototype.addOnUploadEvent = function(fname) {
    this.onUploadHandlers.push(eval(fname));
}

/**
 * Adds a form update handler to the file upload object 
 * @param {string} fname The name of a function 
 */
Solstice.FileUpload.prototype.addOnFormUpdateEvent = function(fname) {
    this.onFormUpdateHandlers.push(eval(fname));
}

/**
 * Append a new file input widget
 * @type void
 */
Solstice.FileUpload.prototype.addInput = function() {
    var upload_document = Solstice.getWindow(this.name).document;
    var file_container = upload_document.getElementById('file_upload_container');
    
    this.current_count++;
    var id = this.id_counter++;

    var file_input = this._getInputHTML(id);
    file_container.appendChild(file_input);

    this.updateAddButton();
}

/**
 * Remove an existing file input widget
 * @param {integer} id Position identifier for the input
 * @type void
 */
Solstice.FileUpload.prototype.removeInput = function(id) {
    var upload_document = Solstice.getWindow(this.name).document;
    var file_container = upload_document.getElementById('file_upload_container');

    // Do not go less than start_count
    if (this.current_count <= this.start_count) {
        return this.resetInput(id);
    }

    // Remove the visible input
    var input = upload_document.getElementById('upload_form_container_' + id);
    if (input) {
        file_container.removeChild(input);
        this.current_count--;
        this.updateAddButton();
    }

    // Remove the hidden input
    var hidden_input = document.getElementById(this.name + '_' + id);
    if (hidden_input) {
        var hidden_container = document.getElementById(this.name + '_inputs');
        hidden_container.removeChild(hidden_input);
    }
    if (this.current_count <= this.start_count) {
        var input_forms = upload_document.getElementsByTagName('form');
        for (i = 0; i < input_forms.length; i++) {
            var file_form = input_forms[i];
            var anchors = file_form.getElementsByTagName('a');
            var anchor = anchors[0];
            var parentNode = anchor.parentNode;
            var parent_type = parentNode.toString();
            //do not remove the 'remove link' unless it is a file upload widget
            if(parent_type.match(/HTMLFormElement/)){
                anchor.style.display = 'none';
            }
        }
        upload_document.close();
    }
}

/**
 * Reset an existing file input widget
 * @param {integer} id Position identifier for the input
 * @type void
 */
Solstice.FileUpload.prototype.resetInput = function(id) {
    var upload_document = Solstice.getWindow(this.name).document;
    var file_container = upload_document.getElementById('file_upload_container');   
 
    var input = upload_document.getElementById('upload_form_container_' + id);
    if (input) {
        var hidden_input = document.getElementById(this.name + '_' + id);
        
        // Update the visible input 
        id = this.id_counter++;
        var new_input = this._getInputHTML(id);
        file_container.replaceChild(new_input, input);
        
        // Remove the hidden input    
        if (hidden_input) {
            hidden_input.parentNode.removeChild(hidden_input);
        }

        // If the uploader supports multiple uploads, ensure that things
        // are still sized correctly
        if (this.max_count > 1) {
            this.updateAddButton();
        }
    }
}

/**
 * Initialize the upload object
 * @type void
 */
Solstice.FileUpload.prototype.initialize = function() {
    if (this.initialized) return;

    var upload_document = Solstice.getWindow(this.name).document;
    
    var body_class = 'file_upload_container';
    if (this.class_name) body_class += (' ' + this.class_name);
    
    // Initialize the basic html for the main iframe
    upload_document.write('<html><head><base id="solstice_base" href="' +
        Solstice.getDocumentBase() + '"/></head><body class="' + body_class + '"><a href="" onfocus="window.parent.document.getElementById(\'above_iframe_'+this.name+'\').focus()"></a><div id="file_upload_container"></div><div id="file_upload_add"></div><a href="" onfocus="window.parent.document.getElementById(\'below_iframe_'+this.name+'\').focus()"></a></body></html>');
    upload_document.close();
    
    // Transfer stylesheets into the upload iframe
    var doc_head = upload_document.getElementsByTagName('head')[0];
    for (i = 0; i < document.styleSheets.length; i++) {
        var stylesheet = upload_document.createElement('link');
        stylesheet.setAttribute('rel', 'stylesheet');
        stylesheet.setAttribute('type', 'text/css');
        stylesheet.setAttribute('href', document.styleSheets[i].href);
        doc_head.appendChild(stylesheet);
    }

    // Initialize the file input widgets
    this._createInitialInputs();

    this.initialized = true;
}

/**
 * Reset the upload object 
 * @type void
 */
Solstice.FileUpload.prototype.reset = function() {
    if (!this.initialized) return;

    var upload_document = Solstice.getWindow(this.name).document;
   
    // Remove the visible inputs
    var file_container = upload_document.getElementById('file_upload_container');
    file_container.innerHTML = '';
    
    // Remove the hidden inputs
    var hidden_container = document.getElementById(this.name + '_inputs');
    hidden_container.innerHTML = '';
   
    // Note: This method should NOT reset the id_counter variable!
    this.current_count = 0;

    this._createInitialInputs();
}


Solstice.FileUpload.prototype._createInitialInputs = function() {
    for (i=0; i<this.start_count; i++) {
        if (this.current_count < this.max_count) {
            this.addInput();
        }
    }
    if (!this.start_count) this.updateAddButton();
}


/**
 * Update the state of the add button 
 * @type void
 */
Solstice.FileUpload.prototype.updateAddButton = function() {
    var upload_document = Solstice.getWindow(this.name).document;
    var button_container = upload_document.getElementById('file_upload_add');
    button_container.innerHTML = '';

    if (this.current_count < this.max_count) {
        var add_btn = upload_document.createElement('a');
        add_btn.setAttribute('id', 'file_upload_add_button');
        add_btn.setAttribute('href', "javascript: parent.Solstice.FileUploadRegistry['" + this.name + "'].addInput()");
        add_btn.setAttribute('onmouseover', "window.status=''; return true;");
		var label = (this.current_count) ? this.another_label : this.add_label;    
        add_btn.appendChild(upload_document.createTextNode(label));
    
        button_container.appendChild(add_btn);
    }
    this._updateSize();
}

/**
 * Return a boolean describing whether an upload is in progress 
 * @return {boolean} 
 */
Solstice.FileUpload.prototype.hasInProgressUpload = function() {
    var upload_document = Solstice.getWindow(this.name).document;
    
    // This could be somewhat inefficient, but we prefer not using a
    // separate counter...The iterator treats the nodes array as a 
    // static list; nodes is a dynamic list, and calling 
    // nodes.length would rebuild the list, so we avoid it
    var nodes = upload_document.getElementsByTagName('div');
    for ( var i = 0, node; node = nodes[i]; i++ ) {
        if (node.className == 'sol_upload_meter_container') return true;
    }
    return false;
}

/**
 * Main handler for completed upload events 
 * @param {integer} id Position identifier for the form 
 */
Solstice.FileUpload.prototype.uploadComplete = function(id) {
    var name = this.name;
    var upload_document = Solstice.getWindow(name).document;
    
    // Remove the temporary text and progress meter
    var file_name_container = upload_document.getElementById('file_name_container_' + id);
    file_name_container.innerHTML = '';

    var upload_form = upload_document.getElementById('upload_form_' + id);
    upload_form.removeChild(upload_document.getElementById('meter_container_' + id));
   
    var results_document = Solstice.getWindow(name).frames['results_frame_' + id].document; 
    var hidden_input;
    if (file_key = results_document.getElementById('file_key')) {
        // File icon
        var icon_img = upload_document.createElement('img');
        icon_img.setAttribute('src', results_document.getElementById('file_icon').value);
        icon_img.setAttribute('title', results_document.getElementById('file_desc').value); 
        icon_img.style.verticalAlign = 'middle';
        
        // File name
        var file_name = results_document.getElementById('file_name').value;
        var content_node = upload_document.createTextNode(' ' + file_name);

        file_name_container.appendChild(icon_img);
        file_name_container.appendChild(content_node);
        
        // Expose the reset button
        var remove_btn = upload_document.getElementById('file_upload_remove_' + id);
        file_name_container.appendChild(remove_btn);
        remove_btn.setAttribute('href', "javascript: parent.Solstice.FileUploadRegistry['" + this.name + "'].resetInput(" + id + ")"); 
        remove_btn.style.display = 'inline';
        
        // Create a hidden input in the main document to hold the returned file key
        hidden_input = document.getElementById(name + '_' + id);
        if (!hidden_input) {
            hidden_input = document.createElement('input');
            hidden_input.setAttribute('type', 'hidden');
            hidden_input.setAttribute('name', name);
            hidden_input.setAttribute('id', name + '_' + id);        
        }
        hidden_input.setAttribute('value', file_key.value);

    } else {
        this.resetInput(id);
    }

    // Run the onupload handlers
    for (i = 0; i < this.onUploadHandlers.length; i++) {
        if (!this.onUploadHandlers[i](this, id, results_document)) {
            return;
        }
    }

    // Add the hidden input to the main document
    if (hidden_input) {
        document.getElementById(name + '_inputs').appendChild(hidden_input);
    }

    // Run the form update handlers
    for (i = 0; i < this.onFormUpdateHandlers.length; i++) {
        if (!this.onFormUpdateHandlers[i](this, id, results_document)) {
            return;
        }
    }
}

/**
 * Main handler for input change events 
 * @param {integer} id Position identifier for the form 
 */
Solstice.FileUpload.prototype.beginUpload = function(id) {
    var name = this.name;
    var upload_document = Solstice.getWindow(name).document;
    
    var file_input = upload_document.getElementById('file_input_' + id);
    file_input.blur();
    
    var file_name  = file_input.value;
    file_name = file_name.replace(/^\s*|\s*$/g, ''); // Trim whitespace
   
    // Check for invalid input
    if (file_name == '') return;
    var matches = file_name.match(/([^\/\\]+)$/);
    if (!matches) return;
   
    // Run the onchange handlers
    for (i = 0; i < this.onChangeHandlers.length; i++) {
        if (!this.onChangeHandlers[i](file_input)) {
            return;
        }
    }
  
    // Listen for the submitted form's return
    var results_frame = upload_document.getElementById('results_frame_'+id);
    Solstice.Event.add(results_frame, 'load', function() {
        parent.Solstice.FileUpload.uploadComplete(name, id);
    });
    
    // Hide the file input and the remove button
    file_input.className = 'sol_hidden_input';
    upload_document.getElementById('file_upload_remove_' + id).style.display = 'none';
    
    // Add temporary content to the file name span
    var file_name_container = upload_document.getElementById('file_name_container_'+id);
    var new_file_name = Solstice.String.truncate(matches[0], 40);
    file_name_container.innerHTML = '<span style="font-size: .8em;">Uploading file <i>' + new_file_name + '</i></span>';

    // Create the progress meter
    var upload_form = upload_document.getElementById('upload_form_'+id);
    var meter = this._getMeterHTML(id);
    upload_form.appendChild(meter);
  
    Solstice.FileUpload.updateMeter(0, 0, upload_document.getElementById('upload_key_'+id).value, name, id);
     
    upload_form.submit();
}

/**
 * Build the html for a file upload widget 
 * @param {integer} id Position identifier for the form
 * @private
 */
Solstice.FileUpload.prototype._getInputHTML = function(id) {
    var name = this.name;
    var upload_document = Solstice.getWindow(name).document;
    
    var date = new Date();
    var key = date.getTime() + '.' + Math.random() + '.' +
        window.document.location + '.' + Math.random();

    // Create an iframe that will be the target of the upload form
    var results_iframe;
    try {
        results_iframe = upload_document.createElement('<iframe name="results_frame_' + id + '">');
        results_iframe.style.display = 'none';
    }
    catch (e) {
        results_iframe = upload_document.createElement('iframe');
        results_iframe.setAttribute('name', 'results_frame_' + id);
        results_iframe.style.width  = '1px';
        results_iframe.style.height = '1px';
        results_iframe.style.border = '0px';
    }
    results_iframe.setAttribute('id', 'results_frame_' + id);
    results_iframe.setAttribute('src', Solstice.getDocumentBase() + '/content/blank.html');
    results_iframe.setAttribute('tabindex', '-1');

    // Create the upload form
    var upload_form = upload_document.createElement('form');
    upload_form.setAttribute('id', 'upload_form_' + id);
    upload_form.setAttribute('target', 'results_frame_' + id);
    upload_form.setAttribute('method', 'post');
    upload_form.setAttribute('action', this.upload_url + '?upload_key=' + key);
    upload_form.setAttribute('enctype', 'multipart/form-data');
    upload_form.setAttribute('encoding', 'multipart/form-data');
    upload_form.setAttribute('accept-charset', 'UTF-8');

    // Create the actual file input
    var file_input = upload_document.createElement('input');
    file_input.setAttribute('type', 'file');
    file_input.setAttribute('name', 'file');
    file_input.setAttribute('id', 'file_input_' + id);
    if (this.disabled) {
        file_input.setAttribute('disabled', true);
    }
    file_input.style.verticalAlign = 'middle';
    Solstice.Event.add(file_input, 'keypress', function(e) {
        parent.Solstice.FileUpload.blockInput(e, file_input);
    });
    Solstice.Event.add(file_input, 'change', function() {
        parent.Solstice.FileUpload.beginUpload(name, id);
    });
    
    // Create a hidden input to hold the upload key
    var key_input = upload_document.createElement('input');
    key_input.setAttribute('type', 'hidden');
    key_input.setAttribute('name', 'upload_key');
    key_input.setAttribute('id', 'upload_key_' + id);
    key_input.setAttribute('value', key);

    // Create a span to contain returned file data
    var file_name = upload_document.createElement('span');
    file_name.setAttribute('id', 'file_name_container_' + id);
 
    // Create a remove/reset button
    var remove_btn = upload_document.createElement('a');
    remove_btn.setAttribute('id', 'file_upload_remove_' + id);
    remove_btn.className = 'sol_file_upload_remove';
    if (this.current_count > this.start_count) {
        remove_btn.setAttribute('href', "javascript: parent.Solstice.FileUploadRegistry['" + this.name + "'].removeInput(" + id + ")");   
    } else {
        remove_btn.setAttribute('href', "javascript: parent.Solstice.FileUploadRegistry['" + this.name + "'].resetInput(" + id + ")");
        remove_btn.style.display = 'none';
    }
    remove_btn.appendChild(upload_document.createTextNode(this.remove_label));
    
    upload_form.appendChild(key_input);
    upload_form.appendChild(file_input);
    upload_form.appendChild(file_name);
    upload_form.appendChild(results_iframe);
    upload_form.appendChild(remove_btn);
        
    var upload_form_container = upload_document.createElement('div');
    upload_form_container.setAttribute('id', 'upload_form_container_' + id);
    upload_form_container.className = 'sol_upload_form_container';
    upload_form_container.appendChild(upload_form);

    return upload_form_container;
}

/**
 * Build the html for a file upload progress meter 
 * @param {integer} id Position identifier for the form
 * @private
 */
Solstice.FileUpload.prototype._getMeterHTML = function(id) {
    var upload_document = Solstice.getWindow(this.name).document;

    var upload_key = upload_document.getElementById('upload_key_' + id).value;

    var meter_container = upload_document.createElement('div');
    meter_container.setAttribute('id', 'meter_container_' + id);
    meter_container.className = 'sol_upload_meter_container';

    var meter_progress_bar = upload_document.createElement('div');
    meter_progress_bar.setAttribute('id', 'meter_progress_bar_' + upload_key);
    meter_progress_bar.className = 'sol_upload_meter_progress_bar';

    var meter_percentage = upload_document.createElement('div');
    meter_percentage.setAttribute('id', 'meter_percentage_' + upload_key);
    meter_percentage.className = 'sol_upload_meter_percentage';

    meter_container.appendChild(meter_progress_bar);
    meter_container.appendChild(meter_percentage);

    return meter_container;
}

/**
 * Update the size of the file upload object
 * @private
 * @type void
 */
Solstice.FileUpload.prototype._updateSize = function() {
    var frame = Solstice.getWindow(this.name);
    var upload_document = Solstice.getWindow(this.name).document;
    
    var new_height = 0;
    var nodes = upload_document.getElementsByTagName('div'); 
    for ( var i = 0, node; node = nodes[i]; i++ ) {
        if (node.className == 'sol_upload_form_container') {
            new_height += 29;
        }
    }
    
    // Account for the 'add another' button
    if (upload_document.getElementById('file_upload_add_button')) {
        //don't change this height without checking ie7 first, while it may look like it has too much space
        //ie7 hides the upload button if this height is lowered
        new_height += 34;
    }
    
    if (new_height) {
        document.getElementById(this.name).style.height = new_height + 'px';
    }
}

/**
 * External functions for Solstice.FileUpload
 */

Solstice.FileUpload.updateMeter = function(total_size, curr_size, upload_key, name, id) {
    var upload_document = Solstice.getWindow(name).document; 
    
    var progress_meter = upload_document.getElementById('meter_progress_bar_' + upload_key);
    if (!progress_meter) return;

    var percentage = (curr_size / total_size) * 100;
    if (isNaN(percentage)) percentage = 0;
    progress_meter.style.width = percentage + '%';

    var progress_percent = upload_document.getElementById('meter_percentage_' + upload_key);
    progress_percent.innerHTML = parseInt((percentage*100) / 100) + '%';
  
    if (percentage < 100) {
        //Tell the meter to update
        Solstice.FileUpload._meterCheck(upload_key, name, id);
    }else{
        //tell the meter this upload is finished
        Solstice.FileUpload._meterFinish(upload_key);
    }
}

Solstice.FileUpload._updating_meters = new Object;

Solstice.FileUpload._meterCheck = function (upload_key, name, id) {
    if( !Solstice.FileUpload._updating_meters[upload_key] ){
        Solstice.FileUpload._updating_meters[upload_key] = {
            'upload_key': upload_key,
            'frame': name,
            'position': id
        };
    }

    Solstice.FileUpload._meterServerQuery();
}

Solstice.FileUpload._meterServerQuery = function () {
    if(!Solstice.FileUpload._update_running){
        Solstice.FileUpload._update_running = true;
        window.setTimeout("Solstice.Remote.run('Solstice', 'upload_meter', Solstice.FileUpload._updating_meters);", 1000);
    }
}

Solstice.FileUpload._meterFinish = function (upload_key) {
    delete Solstice.FileUpload._updating_meters[upload_key];
}


Solstice.FileUpload.initialize = function(name) {
    var uploader = Solstice.FileUploadRegistry[name];
    if (uploader) {
        uploader.initialize();
    }
}

Solstice.FileUpload.reset = function(name) {
    var uploader = Solstice.FileUploadRegistry[name];
    if (uploader) {
        uploader.reset();
    }
}

Solstice.FileUpload.beginUpload = function(name, id) {
    var uploader = Solstice.FileUploadRegistry[name];
    if (uploader) {
        uploader.beginUpload(id);
    }
}

Solstice.FileUpload.uploadComplete = function(name, id) {
    var uploader = Solstice.FileUploadRegistry[name];
    if (uploader) {
        uploader.uploadComplete(id);
    }
}

Solstice.FileUpload.getFilenameFromPath = function(path) {
    var nodes = (path.search(/\\/) != -1) ? path.split(/\\/) : path.split("/");
    return (nodes.length) ? nodes[nodes.length - 1] : path; 
}

Solstice.FileUpload.blockInput = function(e, file_input) {
    if (e.keyCode == 9) { // tab
        return true;
    } else if (e.keyCode == 13) { // enter
        file_input.click();
        e.returnValue = true; // IE ?
        return true;
    } else {
        if (e.preventDefault) e.preventDefault(); // Mozilla
        e.returnValue = false; // IE
        return false;
    }
}


