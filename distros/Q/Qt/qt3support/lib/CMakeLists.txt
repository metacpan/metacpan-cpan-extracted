add_custom_target(qt3support4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/Qt3Support4.pm ${CMAKE_BINARY_DIR}/blib/lib/Qt3Support4.pm)
install(FILES Qt3Support4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
