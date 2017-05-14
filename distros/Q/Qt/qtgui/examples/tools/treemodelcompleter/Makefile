all : TreeModelCompleterResources.pm

TreeModelCompleterResources.pm : treemodelcompleter.qrc resources/*
	prcc4 treemodelcompleter.qrc -o TreeModelCompleterResources.pm

clean :
	rm -f TreeModelCompleterResources.pm
