
function ppiHtmlCF(startlines, endlines) 
{
	this.startlines = startlines;
	this.endlines = endlines;
	this.foldstate = [];
	for (var i = 0; i < startlines.length; i++)
		this.foldstate[startlines[i]] = "closed";
}

// Clears the cookie
ppiHtmlCF.prototype.clearCookie = function()
{
	var now = new Date();
	var yesterday = new Date(now.getTime() - 1000 * 60 * 60 * 24);
	this.setCookie('', yesterday);
};

// Sets value in the cookie
ppiHtmlCF.prototype.setCookie = function(cookieValue, expires)
{
	document.cookie =
		'ppihtmlcf=' + escape(cookieValue) + ' ' + 
		+ (expires ? '; expires=' + expires.toGMTString() : '')
		+ ' path=' + location.pathname;
};

// Gets the cookie
ppiHtmlCF.prototype.getCookie = function() {
	var cookieValue = '';
	var posName = document.cookie.indexOf('ppihtmlcf=');
	if (posName != -1) {
		var posValue = posName + 'ppihtmlcf='.length;
		var endPos = document.cookie.indexOf(';', posValue);
		if (endPos != -1) cookieValue = unescape(document.cookie.substring(posValue, endPos));
		else cookieValue = unescape(document.cookie.substring(posValue));
	}
	return (cookieValue);
};

// updates cookie with current set of unfolded section startlines as a string
ppiHtmlCF.prototype.updateCookie = function()
{
	var str = ':';
	for (var n = 0; n < this.startlines.length; n++) {
		line = this.startlines[n];
	   	if ((this.foldstate[line] != null) && (this.foldstate[line] == "open"))
			str += line + ':';
	}
	if (str == ':')
		this.setCookie('');
	else
		this.setCookie(str);
};

// forces all folds to current cookie state
ppiHtmlCF.prototype.openFromCookie = function()
{
	var opened = this.getCookie();
	if (opened == '') {
	/*
	 *	no cookie, create one w/ all folds closed
	 */
		this.setCookie('');
	}
	else {
		for (var n = 0; n < this.startlines.length; n++) {
			line = this.startlines[n];
		   	if (this.foldstate[line] == null) 
		   		this.foldstate[line] = "closed";

			if (opened.indexOf(':' + line + ':') >= 0) {
				if (this.foldstate[line] == "closed")
					this.accordian(line, this.endlines[n]);
			}
			else {
				if (this.foldstate[line] == "open")
					this.accordian(line, this.endlines[n]);
			}
		}
	}
};

/*
 *	renders line number and fold button margins
 */
ppiHtmlCF.prototype.renderMargins = function(lastline)
{
	var start = 1;
	var lnmargin = '';
	var btnmargin = '';
    for (var i = 0; i < this.startlines.length; i++) {
		if (start != this.startlines[i]) {
	        for (var j = start; j < this.startlines[i]; j++) {
	    		lnmargin += j + "\n";
	    		btnmargin += "\n";
	    	}
	    }
	    start = this.endlines[i] + 1;
		lnmargin += "<span id='lm" + this.startlines[i] + "' class='lnpre'>" + this.startlines[i] + "</span>\n";
		btnmargin += "<a id='ll" + this.startlines[i] + "' class='foldbtn' " + 
			"onclick=\"ppihtml.accordian(" + this.startlines[i] + "," + this.endlines[i] + ")\">&oplus;</a>\n";
	}
	if (lastline > this.endlines[this.endlines.length - 1]) {
		for (var j = start; j <= lastline; j++) {
			lnmargin += j + "\n";
			btnmargin += "\n";
		}
	}
	lnmargin += "\n";
	btnmargin += "\n";
	buttons = document.getElementById("btnmargin");
	lnno = document.getElementById("lnnomargin");
	if (navigator.appVersion.indexOf("MSIE")!=-1) {
		lnno.outerHTML = "<pre id='lnnomargin' class='lnpre'>" + lnmargin + "</pre>";
		buttons.outerHTML = "<pre id='btnmargin' class='lnpre'>" + btnmargin + "</pre>";
	}
	else {
		lnno.innerHTML = lnmargin;
		buttons.innerHTML = btnmargin;
	}
}

/*
 *	Accordian function for folded code
 *
 *	if clicked fold is closed
 *		replace contents of specified lineno margin span
 *			with complete lineno list
 *		replace contents of specified link span with end - start + 1 oplus's + linebreaks
 *		replace contents of insert span with contents of src_div
 *		foldstate = open
 *	else
 *		replace contents of specified lineno margin span with start lineno
 *		replace contents of specified link span with single oplus
 *		replace contents of specified insert span with "Folded lines start to end"
 *		foldstate = closed
 *
 *	For fancier effect, use delay to add/remove a single line at a time, with
 *	delay millsecs between updates
 */
ppiHtmlCF.prototype.accordian = function(startline, endline)
{
    if (document.getElementById) {
		if (navigator.appVersion.indexOf("MSIE")!=-1) {
    		this.ie_accordian(startline, endline);
    	}
    	else {
    		this.ff_accordian(startline, endline);
    	}
    }
}
/*
 *	MSIE is a pile of sh*t, so we have to bend over
 *	backwards and completely rebuild the document elements
 *	Bright bunch of folks up there in Redmond...BTW this bug
 *	exists in IE 4 thru 7, despite people screaming for a solution
 *	for a decade. So MSFT is deaf as well as dumb
 */
ppiHtmlCF.prototype.ie_accordian = function(startline, endline)
{
   	src = document.getElementById("preft" + startline);
   	foldbtn = document.getElementById('btnmargin');
   	lineno = document.getElementById('lnnomargin');
   	insert = document.getElementById("src" + startline);
	linenos = lineno.innerHTML;
	buttons = foldbtn.innerHTML;
   	if ((this.foldstate[startline] == null) || (this.foldstate[startline] == "closed")) {
	   	lnr = "<span[^>]+>" + startline + "[\r\n]*</span>";
	   	lnre = new RegExp(lnr, "i");
	   	bnr = "id=ll" + startline + "[^<]+</a>";
	   	btnre = new RegExp(bnr, "i");

   		lnfill = startline + "\n";
   		btnfill = "&oplus;\n";
   		for (i = startline + 1; i <= endline; i++) {
   			lnfill += i + "\n";
   			btnfill += "&oplus;\n";
   		}

		linenos = linenos.replace(lnre, "<span id='lm" + startline + "' class='lnpre'>" + lnfill + "</span>");
		buttons = buttons.replace(btnre, "id='ll" + startline + "' class='foldbtn' style='background-color: yellow' onclick=\"ppihtml.accordian(" + 
			startline + ", " + endline + ")\">" + btnfill + "</a>");

   		foldbtn.outerHTML = "<pre id='btnmargin' class='lnpre'>" + buttons + "</pre>";
   		lineno.outerHTML = "<pre id='lnnomargin' class='lnpre'>" + linenos + "</pre>";
   		insert.outerHTML = "<span id='src" + startline + "'><pre class='bodypre'>" + src.innerHTML + "</pre></span>";
      	this.foldstate[startline] = "open";
	}
	else {
	   	lnr = "<span[^>]+>" + startline + "[\r\n][^<]*</span>";
	   	lnre = new RegExp(lnr, "i");
	   	bnr = "id=ll" + startline + "[^<]+</a>";
	   	btnre = new RegExp(bnr, "i");

		if (! linenos.match(lnre))
			alert("linenos no match");
		if (! buttons.match(btnre))
			alert("buttons no match");
		linenos = linenos.replace(lnre, "<span id='lm" + startline + "' class='lnpre'>" + startline + "\n</span>");
		buttons = buttons.replace(btnre, "id='ll" + startline + "' class='foldbtn' style='background-color: #E9E9E9' onclick=\"ppihtml.accordian(" +
			startline + ", " + endline + ")\">&oplus;\n</a>");

   		foldbtn.outerHTML = "<pre id='btnmargin' class='lnpre'>" + buttons + "</pre>";
   		lineno.outerHTML = "<pre id='lnnomargin' class='lnpre'>" + linenos + "</pre>";
   		insert.outerHTML = "<span id='src" + startline + "'><pre class='foldfill'>Folded lines " + startline + " to " + endline + "</pre></span>";

       	this.foldstate[startline] = "closed";
	}
	this.updateCookie();
}

ppiHtmlCF.prototype.ff_accordian = function(startline, endline)
{
  	src = document.getElementById("preft" + startline);
   	foldbtn = document.getElementById("ll" + startline);
   	lineno = document.getElementById("lm" + startline);
   	insert = document.getElementById("src" + startline);
   	if ((this.foldstate[startline] == null) || (this.foldstate[startline] == "closed")) {
   		lnfill = startline + "\n";
   		btnfill = "&oplus;\n";
   		for (i = startline + 1; i <= endline; i++) {
   			lnfill += (i < endline) ? i + "\n" : i;
   			btnfill += (i < endline) ? "&oplus;\n" : "&oplus;";
   		}
   		foldbtn.innerHTML = btnfill;
   		lineno.innerHTML = lnfill;
   		foldbtn.style.backgroundColor = "yellow";
   		insert.innerHTML = src.innerHTML;
   		insert.className = "bodypre";
       	this.foldstate[startline] = "open";
	}
	else {
		foldbtn.innerHTML = "&oplus;";
   		foldbtn.style.backgroundColor = "#E9E9E9";
   		lineno.innerHTML = startline;
   		insert.innerHTML = "Folded lines " + startline + " to " + endline;
   		insert.className = "foldfill";
       	this.foldstate[startline] = "closed";
	}
	this.updateCookie();
}

/*
 *	open/close all folds
 */
ppiHtmlCF.prototype.fold_all = function(foldstate)
{
	for (i = 0; i < this.startlines.length; i++) {
		line = this.startlines[i];
	   	if (this.foldstate[line] == null) 
	   		this.foldstate[line] = "closed";

		if (this.foldstate[line] != foldstate)
	   		this.accordian(line, this.endlines[i]);
	}
	this.updateCookie();
}

ppiHtmlCF.prototype.add_fold = function(startline, endline)
{
	this.startlines[this.startlines.length] = startline;
	this.endlines[this.endlines.length] = endline;
	this.foldstate[this.foldstate.length] = "closed";
}

