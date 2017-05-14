all : CustomCompleterResources.pm

CustomCompleterResources.pm : customcompleter.qrc resources/*
	prcc4 customcompleter.qrc -o CustomCompleterResources.pm

clean :
	rm -f CustomCompleterResources.pm
