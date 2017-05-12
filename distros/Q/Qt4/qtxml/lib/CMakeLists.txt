add_custom_target(qtxml4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtXml4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtXml4.pm)
install(FILES QtXml4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
