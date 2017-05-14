all : Ui_Form.pm Ui_SslErrors.pm Ui_CertificateInfo.pm SecureSocketClientResources.pm

Ui_CertificateInfo.pm : certificateinfo.ui
	puic4 certificateinfo.ui -o Ui_CertificateInfo.pm

Ui_Form.pm : sslclient.ui
	puic4 sslclient.ui -o Ui_Form.pm

Ui_SslErrors.pm : sslerrors.ui
	puic4 sslerrors.ui -o Ui_SslErrors.pm

SecureSocketClientResources.pm : securesocketclient.qrc encrypted.png
	prcc4 securesocketclient.qrc -o SecureSocketClientResources.pm

clean :
	rm -f Ui_CertificateInfo.pm Ui_Form.pm Ui_SslErrors.pm SecureSocketClientResources.pm
