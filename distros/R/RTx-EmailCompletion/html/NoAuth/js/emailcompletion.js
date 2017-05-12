function initPage() {
    addAutoComplete();
} // initPage

/* CUSTOMIZE PART */

// documentation can be found in lib/RTx/EmailCompletion.pm

// we need two Arrays :
// one for input with multiple email address allowed
var multipleCompletion = new Array("Requestors", "To", "Bcc", "Cc", "AdminCc", "WatcherAddressEmail[123]", "UpdateCc", "UpdateBcc");

// and one for input with only one email address allowed
var singleCompletion   = new Array("(Add|Delete)Requestor", "(Add|Delete)Cc", "(Add|Delete)AdminCc");

/* END OF CUSTOMIZE PART */

var globalRegexp   = new RegExp('^(' + multipleCompletion.concat(singleCompletion).join('|') + ')$');
var multipleRegexp = new RegExp('^(' + multipleCompletion.join('|') + ')$');

function addAutoComplete() {
    var inputs = document.getElementsByTagName("input");
    
    for (var i = 0; i < inputs.length; i++) {
	var input = inputs[i];
	var inputName = input.getAttribute("name");

	// if empty or not defined
	if (! inputName)
	    continue;

	// only input's names defined in global vars at the beginning
	// are concerned
	if ( ! inputName.match(globalRegexp) )
	    continue;
	
	// if multiple email address are allowed we add the token
	// option to Autocompleter
	var options = '';
	if (inputName.match(multipleRegexp))
	    options = "tokens: ','";

	// we must set an id for scriptaculous
	// we use the name that seems to be uniq
	input.id = inputName;

	// DEBUGGING PURPOSE 
	// input.className += input.className? " emailcompletiondebug" : "emailcompletiondebug";

	var div = '<div class="autocomplete" id="' + inputName + '_to_auto_complete" />';
	div += '<script type="text/javascript">new Ajax.Autocompleter(\'' + inputName;
	div += "', '" + inputName + "_to_auto_complete', '<%$RT::WebPath%>/SelfService/Ajax/EmailCompletion\', {" + options + "})</script>";
	
	// use prototype to add the div after input
	new Insertion.After(inputName,div);
    }
	
} //addAutoComplete

Event.observe(window, 'load', initPage);
