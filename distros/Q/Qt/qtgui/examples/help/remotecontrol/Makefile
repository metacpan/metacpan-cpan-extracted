all : Ui_RemoteControlClass.pm RemoteControlResources.pm

Ui_RemoteControlClass.pm : remotecontrol.ui
	puic4 -o Ui_RemoteControlClass.pm remotecontrol.ui

RemoteControlResources.pm : remotecontrol.qrc
	prcc4 -o RemoteControlResources.pm remotecontrol.qrc

clean :
	rm -f Ui_RemoteControlClass.pm RemoteControlResources.pm
