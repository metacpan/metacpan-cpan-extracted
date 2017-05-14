add_custom_target(qwtpm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/Qwt.pm ${CMAKE_BINARY_DIR}/blib/lib/Qwt.pm)
install(FILES Qwt.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
