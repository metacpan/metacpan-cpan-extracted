add_custom_target(qtuitools4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtUiTools4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtUiTools4.pm)
install(FILES QtUiTools4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
