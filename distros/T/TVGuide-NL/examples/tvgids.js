//
// vim:ts=4:sw=4:noexpandtab
//

var W3CDOM = (document.createElement && document.getElementsByTagName);
window.onload = init;

var selectedRow = false;

function tdMouseOver()
{
	// the element that we want to open
	var toOpen  = this.childNodes[1].childNodes[1];
	var toColor = this.childNodes[1].childNodes[0];
	
	// close previous open description
	if (selectedRow)
	{
		selectedRow.childNodes[1].childNodes[1].style.display = 'none';
		selectedRow.childNodes[1].childNodes[0].style.color   = 'black';
	}
		
	// open a new descripton
	toOpen.style.display = 'block';

	// color the current entry
	toColor.style.color = '#0cf';

	// save currently open description
	selectedRow = this;

	//alert('«'+toOpen.innerHTML+'»');

	return true;
}

function tdMouseOut()
{
	var toClose = this.childNodes[1].childNodes[1];
	var toColor = this.childNodes[1].childNodes[0];

	toClose.style.display = 'none';
	toColor.style.color = 'black';

	return true;
}

function init()
{
	// W3C DOM supported?
	if (!W3CDOM) return;

	// iterate over all tables in the document
	var tables = document.getElementsByTagName('table');
	for (var i=0; i<tables.length; i++)
	{
		// we're only interested in class="channel" tables
		if (tables[i].className!='channel' 
			&& tables[i].className!='movies') 
			continue;

		// find name of current channel
		var netStr = '(' + tables[i].parentNode.getAttribute('id') + ')';

		// iterate over all cells in the table
		var rows = tables[i].getElementsByTagName('tr');
		for (var j=0; j<rows.length; j++)
		{
			// set the mouseover handlers for the row
			rows[j].onmouseover = tdMouseOver;
			rows[j].onmouseout  = tdMouseOut;

			// get the time, title, and cell with description
			var timeStr  = rows[j].childNodes[0].firstChild.nodeValue;
			var titleStr = rows[j].childNodes[1].firstChild.firstChild.nodeValue;
			var descCell = rows[j].childNodes[1].childNodes[1];
			
			if (tables[i].className=='movies')
				netStr = rows[j].childNodes[2].firstChild.nodeValue;

			// fill empty descriptions
			if (descCell.childNodes.length == 0)
			{
				var myTextNode = document.createTextNode('Geen ' 
					+ 'omschrijving bekend');
				descCell.appendChild(myTextNode);
			}

			// add time/title to description
			var timeNode = document.createElement('span');
			timeNode.setAttribute('class','time');
			timeNode.appendChild( document.createTextNode(timeStr) );
			timeNode.appendChild( document.createTextNode(' ') );
			timeNode.appendChild( document.createTextNode(netStr) );

			var titleNode =  document.createElement('div');
			titleNode.setAttribute('class','prog');
			titleNode.appendChild( timeNode );
			titleNode.appendChild( document.createTextNode(titleStr) );
			
			descCell.insertBefore(titleNode, descCell.firstChild);
		}
	}
	return true;
}

