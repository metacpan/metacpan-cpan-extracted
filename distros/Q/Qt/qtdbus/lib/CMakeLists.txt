add_custom_target(qtdbus4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtDBus4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtDBus4.pm)
install(FILES QtDBus4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
