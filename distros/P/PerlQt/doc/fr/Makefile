
index.html: PerlQt.pod
	pod2html --css ../css/pod.css PerlQt.pod > index.html
	perl -pi -e 's/cgibin/cgi-bin/' index.html
	perl -pi -e 's/#http/http/g' index.html
	rm -f pod2*~~

