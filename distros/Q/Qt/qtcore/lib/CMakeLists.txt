add_subdirectory( QtCore4 )
add_custom_target(perlqtcore4pm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/QtCore4.pm ${CMAKE_BINARY_DIR}/blib/lib/QtCore4.pm)
install( FILES QtCore4.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR} )
