
/**
*	Vitaly Tskhovrebov, 2009
*	GPLv2
**/

function getElementsByClass( searchClass, domNode, tagName) {
	if (domNode == null) domNode = document;
	if (tagName == null) tagName = '*';
	var el = new Array();
	var tags = domNode.getElementsByTagName(tagName);
	var tcl = " "+searchClass+" ";
	for(i=0,j=0; i<tags.length; i++) {
		var test = " " + tags[i].className + " ";
		if (test.indexOf(tcl) != -1)
			el[j++] = tags[i];
	}
	return el;
}


function skipQuotes()
{
	var k = getElementsByClass('message-stanza-depth-0');

	var quotHeaders=new Array();

	// If there will be another type of header of quotation, add here.
	quotHeaders[0]="(________________________________________)|(\-\-\-\-\-Original Message\-\-\-\-\-)|(On .* wrote)";
	
	for (var i=0; i<k.length; i++)
	{
		for (var j=0; j<quotHeaders.length; j++)
		{
			var re = new RegExp(quotHeaders[j]);
			var m = re.exec(k[i].innerHTML);
			if (m != null && m.index>0)
			{
				k[i].innerHTML=k[i].innerHTML.substr(0,m.index) + "<a style=\"color: green;\" onclick=\"document.getElementById('K"+i+"').style.display='block'; this.style.display='none'\">&gt; Click to expand quotation.</a><div style=\"display: none;\" id=\"K"+i+"\">"+k[i].innerHTML.substr(m.index, k[i].innerHTML.length)+"</div>";
				
				
				break;
			}
		}
	}
}
