add_custom_target(qtsql4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtSql4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtSql4.pm)
install(FILES QtSql4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
