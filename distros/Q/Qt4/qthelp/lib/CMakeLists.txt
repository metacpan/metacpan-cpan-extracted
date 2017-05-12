add_custom_target(qthelp4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtHelp4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtHelp4.pm)
install(FILES QtHelp4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
