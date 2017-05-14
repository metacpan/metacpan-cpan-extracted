all : UndoFrameworkResources.pm

UndoFrameworkResources.pm : undoframework.qrc images/*
	prcc4 undoframework.qrc -o UndoFrameworkResources.pm

clean :
	rm -f UndoFrameworkResources.pm
