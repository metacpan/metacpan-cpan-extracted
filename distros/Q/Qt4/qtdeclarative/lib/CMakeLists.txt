add_custom_target(qtdeclarative4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtDeclarative4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtDeclarative4.pm)
install(FILES QtDeclarative4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
