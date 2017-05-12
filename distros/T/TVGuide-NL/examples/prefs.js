//
// vim:ts=4:sw=4:noexpandtab
//

var W3CDOM = (document.createElement && document.getElementsByTagName);

function switchOptions(a,b)
{
	var source  = document.getElementById(a);
	var target = document.getElementById(b);

	/* loop over all <options> */
	for (i=0; i<source.options.length; i++) 
	{
		/* if it's selected */
		if (source.options[i].selected == true)
		{
			/* move it to the other <select> */
			firstnum = target.options.length;
			target.options[firstnum] = source.options[i];
			/* the old <option> is removed, and everything shifts up by 1 */
			i--; 
		}
	}
	return true;
}

function toRight()
{
	return switchOptions('avail','select');
}

function toLeft()
{
	return switchOptions('select','avail');
}


/* insert option into <options> of <target> at pos <i> */
function insertOption(toinsert, target, i)
{
	try {
		target.add(toinsert, target.options[i]);
	}
	catch (ex) {
		target.add(toinsert, i); // IE only
	}
}

/* append option into <options> of <target> */
function appendOption(toinsert, target)
{
	try {
		target.add(toinsert, null);
	}
	catch (ex) {
		target.add(toinsert); // IE only
	}
}

function moveUp()
{
	var target = document.getElementById('select');

	/* return if list is empty */
	if (target.options.length == 0)
		return true;

	/* don't do anything if the topmost option is selected */
	if (target.options[0].selected == true)
		return true;


	/* loop over all <options>, start at 2nd */
	var i;
	for (i=1; i<target.options.length; i++) 
	{
		/* if it's selected */
		if (target.options[i].selected == true)
		{
			/* move it upwards */
			var saved = target.options[i-1];
			target.options[i-1] = null;

			if (i==target.options.length)
				appendOption( saved, target );
			else
				insertOption ( saved, target, i );
		} 
	}
	
	return true;
}

function moveDown()
{
	var target = document.getElementById('select');

	/* return if list is empty */
	if (target.options.length == 0)
		return true;

	/* don't do anything if the bottommost option is selected */
	if (target.options[target.options.length - 1].selected == true)
		return true;

	/* inverse loop over all <options>, start at last but one */
	for (i=target.options.length-2; i>=0; i--) 
	{
		/* if it's selected */
		if (target.options[i].selected == true)
		{
			/* move it downwards */
			saved = target.options[i+1];
			target.options[i+1] = null;
			target.add( saved, target.options[i] );
			
		}
	}
	
	return true;
}

function submitForm()
{
	var source  = document.getElementById('select');

	var postvar = '';
	/* loop over all <options> */
	for (i=0; i<source.options.length; i++) 
	{
		postvar += 's' + i + '=' + source.options[i].value + ';';
	}
	document.location = 'prefs.cgi?' + postvar + 'save=yes';
}
