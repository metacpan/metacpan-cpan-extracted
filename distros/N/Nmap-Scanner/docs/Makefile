HTDOCS=/home/groups/n/nm/nmap-scanner/htdocs/
all: docs
docs: html css
html:
	scp -r docs/*.html perldork@shell.sf.net:$(HTDOCS)
css:
	scp -r docs/nmap.css perldork@shell.sf.net:$(HTDOCS)
