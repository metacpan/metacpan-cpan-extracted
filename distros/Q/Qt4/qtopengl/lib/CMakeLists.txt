add_custom_target(qtopengl4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtOpenGL4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtOpenGL4.pm)
install(FILES QtOpenGL4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
