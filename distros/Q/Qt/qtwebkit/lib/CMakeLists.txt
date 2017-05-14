add_custom_target(qtwebkit4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtWebKit4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtWebKit4.pm)
install(FILES QtWebKit4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
