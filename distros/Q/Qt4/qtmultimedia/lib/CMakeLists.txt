add_custom_target(qtmultimedia4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtMultimedia4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtMultimedia4.pm)
install(FILES QtMultimedia4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
