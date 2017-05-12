add_custom_target(phononpm ALL ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/Phonon.pm ${CMAKE_BINARY_DIR}/blib/lib/Phonon.pm)
install(FILES Phonon.pm DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/)
