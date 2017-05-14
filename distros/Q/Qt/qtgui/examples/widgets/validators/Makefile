all : Ui_ValidatorsForm.pm ValidatorsResources.pm

Ui_ValidatorsForm.pm : validators.ui
	puic4 validators.ui -o Ui_ValidatorsForm.pm

ValidatorsResources.pm : validators.qrc
	prcc4 validators.qrc -o ValidatorsResources.pm

clean :
	rm -f Ui_ValidatorsForm.pm ValidatorsResources.pm
