add_custom_target(qscipm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/Qsci.pm ${CMAKE_BINARY_DIR}/blib/lib/Qsci.pm)
install(FILES Qsci.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
