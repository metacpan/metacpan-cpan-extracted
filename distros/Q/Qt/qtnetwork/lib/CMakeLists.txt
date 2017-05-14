add_custom_target(qtnetwork4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtNetwork4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtNetwork4.pm)
install(FILES QtNetwork4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
