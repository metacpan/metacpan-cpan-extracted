function search(args) {
    $Browser.get('http://www.google.se');

    document.forms["f"].submit({
	    q: "bla bla bla"
		});
 
    var links = document.images;

    $Browser.log(links[0].src);
    $Browser.log(links[1].src);
    $Browser.log(links[2].alt);
    $Browser.log(links[3].innerHTML);
    $Browser.log(links[4].innerHTML);
}