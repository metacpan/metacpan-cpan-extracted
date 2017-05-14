all : QueriesResources.pm Ui_MainWindow.pm

QueriesResources.pm : queries.qrc queries/wholeTree.xq queries/listCPPFiles.xq
	prcc4 queries.qrc -o QueriesResources.pm

Ui_MainWindow.pm : forms/mainwindow.ui
	puic4 forms/mainwindow.ui -o Ui_MainWindow.pm

clean :
	rm -f QueriesResources.pm Ui_MainWindow.pm
