add_custom_target(qtgui4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtGui4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtGui4.pm)
install(FILES QtGui4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
