all : Ui_ChatMainWindow.pm Ui_ChatSetNickname.pm

Ui_ChatMainWindow.pm : chatmainwindow.ui
	puic4 chatmainwindow.ui -o Ui_ChatMainWindow.pm

Ui_ChatSetNickname.pm : chatsetnickname.ui
	puic4 chatsetnickname.ui -o Ui_NicknameDialog.pm

clean :
	rm Ui_ChatMainWindow.pm Ui_NicknameDialog.pm
