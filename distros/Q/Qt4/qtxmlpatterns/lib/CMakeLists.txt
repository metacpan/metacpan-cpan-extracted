add_custom_target(qtxmlpatterns4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtXmlPatterns4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtXmlPatterns4.pm)
install(FILES QtXmlPatterns4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
