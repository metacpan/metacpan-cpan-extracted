add_custom_target(qtsvg4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtSvg4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtSvg4.pm)
install(FILES QtSvg4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
