
set ( perlqtui_SRCS
    dbus/chat/chatmainwindow.ui                        dbus/chat/Ui_ChatMainWindow.pm
    dbus/chat/chatsetnickname.ui                       dbus/chat/Ui_NicknameDialog.pm
    dbus/remotecontrolledcar/controller/controller.ui  dbus/remotecontrolledcar/controller/Ui_Controller.pm
    designer/calculatorform/calculatorform.ui          designer/calculatorform/Ui_CalculatorForm.pm
    graphicsview/padnavigator/backside.ui              graphicsview/padnavigator/Ui_BackSide.pm
    help/contextsensitivehelp/wateringconfigdialog.ui  help/contextsensitivehelp/Ui_WateringConfigDialog.pm
    help/remotecontrol/remotecontrol.ui                help/remotecontrol/Ui_RemoteControlClass.pm
    itemviews/editabletreemodel/mainwindow.ui          itemviews/editabletreemodel/Ui_MainWindow.pm
    network/http/authenticationdialog.ui               network/http/Ui_Dialog.pm
    network/securesocketclient/sslclient.ui            network/securesocketclient/Ui_Form.pm 
    network/securesocketclient/certificateinfo.ui      network/securesocketclient/Ui_CertificateInfo.pm
    network/securesocketclient/sslerrors.ui            network/securesocketclient/Ui_SslErrors.pm
    network/network-chat/chatdialog.ui                 network/network-chat/Ui_ChatDialog.pm
    painting/fontsampler/mainwindowbase.ui             painting/fontsampler/Ui_MainWindowBase.pm
    painting/svggenerator/window.ui                    painting/svggenerator/Ui_Window.pm
    widgets/stylesheet/mainwindow.ui                   widgets/stylesheet/Ui_MainWindow.pm
    widgets/stylesheet/stylesheeteditor.ui             widgets/stylesheet/Ui_StyleSheetEditor.pm
    widgets/validators/validators.ui                   widgets/validators/Ui_ValidatorsForm.pm
    xmlpatterns/qobjectxmlmodel/forms/mainwindow.ui    xmlpatterns/qobjectxmlmodel/Ui_MainWindow.pm
)

set ( perlqtrc_SRCS
    draganddrop/puzzle/puzzle.qrc                     draganddrop/puzzle/PuzzleResources.pm
    help/remotecontrol/remotecontrol.qrc              help/remotecontrol/RemoteControlResources.pm
    graphicsview/diagramscene/diagramscene.qrc        graphicsview/diagramscene/DiagramSceneResources.pm
    graphicsview/portedasteroids/portedasteroids.qrc  graphicsview/portedasteroids/PortedAsteroidsResources.pm
    network/securesocketclient/securesocketclient.qrc network/securesocketclient/SecureSocketClientResources.pm
    tools/customcompleter/customcompleter.qrc         tools/customcompleter/CustomCompleterResources.pm
    tools/treemodelcompleter/treemodelcompleter.qrc   tools/treemodelcompleter/TreeModelCompleterResources.pm
    tools/undoframework/undoframework.qrc             tools/undoframework/UndoFrameworkResources.pm
    widgets/validators/validators.qrc                 widgets/validators/ValidatorsResources.pm
    xmlpatterns/filetree/queries.qrc                  xmlpatterns/filetree/QueriesResources.pm
    xmlpatterns/qobjectxmlmodel/queries.qrc           xmlpatterns/qobjectxmlmodel/QueriesResources.pm
)

set( uifileindex 0 )
list( LENGTH perlqtui_SRCS numsrcs )
while ( uifileindex LESS numsrcs)
    list ( GET perlqtui_SRCS ${uifileindex} uifile )
    set ( pmfileindex ${uifileindex} )
    math ( EXPR pmfileindex "${pmfileindex} + 1" )
    list ( GET perlqtui_SRCS ${pmfileindex} pmfile )
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/${pmfile}
        COMMAND puic4_bin -o ${pmfile} ${uifile}
        DEPENDS puic4_bin
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        VERBATIM
    )
    list( APPEND perlqtuipm_SRCS ${pmfile} )
    MATH ( EXPR uifileindex "${uifileindex} + 2" )
endwhile ( uifileindex LESS numsrcs)

set( rcfileindex 0 )
list( LENGTH perlqtrc_SRCS numsrcs )
while ( rcfileindex LESS numsrcs)
    list ( GET perlqtrc_SRCS ${rcfileindex} rcfile )
    set ( pmfileindex ${rcfileindex} )
    math ( EXPR pmfileindex "${pmfileindex} + 1" )
    list ( GET perlqtrc_SRCS ${pmfileindex} pmfile )
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/${pmfile}
        COMMAND prcc4_bin -o ${pmfile} ${rcfile}
        DEPENDS prcc4_bin
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        VERBATIM
    )
    list( APPEND perlqtrcpm_SRCS ${pmfile} )
    MATH ( EXPR rcfileindex "${rcfileindex} + 2" )
endwhile ( rcfileindex LESS numsrcs)

add_custom_target( perlqtgui4examples ALL
    DEPENDS ${perlqtuipm_SRCS} ${perlqtrcpm_SRCS}
)
