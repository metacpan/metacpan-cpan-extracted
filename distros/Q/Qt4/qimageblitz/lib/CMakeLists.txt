add_custom_target(qimageblitzpm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QImageBlitz.pm ${CMAKE_BINARY_DIR}/blib/lib/QImageBlitz.pm)
install(FILES QImageBlitz.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
