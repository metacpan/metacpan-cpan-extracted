all : Ui_MainWindow.pm Ui_StyleSheetEditor.pm

Ui_MainWindow.pm : mainwindow.ui
	puic4 mainwindow.ui -o Ui_MainWindow.pm

Ui_StyleSheetEditor.pm : stylesheeteditor.ui
	puic4 stylesheeteditor.ui -o Ui_StyleSheetEditor.pm

clean :
	rm Ui_StyleSheetEditor.pm Ui_MainWindow.pm
