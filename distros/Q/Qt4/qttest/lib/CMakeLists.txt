add_custom_target(qttest4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtTest4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtTest4.pm)
install(FILES QtTest4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
