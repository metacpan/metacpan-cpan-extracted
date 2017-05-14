add_custom_target(qtscript4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtScript4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtScript4.pm)
install(FILES QtScript4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
