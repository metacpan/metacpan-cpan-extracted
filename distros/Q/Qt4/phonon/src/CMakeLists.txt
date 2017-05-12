include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on Phonon.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Phonon.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} Phonon.xs ${CMAKE_CURRENT_BINARY_DIR}/Phonon.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Phonon.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build Phonon.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/Phonon.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(phonon_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/Phonon.c
    phononhandlers.cpp
)

if(WIN32)
    set(libraryName PerlPhonon)
else()
    set(libraryName Phonon)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_phonon SHARED ${phonon_LIBRARY_SRC})

target_link_libraries(perl_phonon
    ${SMOKE_PHONON_LIBRARY}
    perlqtcore4)

set_target_properties(perl_phonon PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_phonon PROPERTIES PREFIX "")

install(TARGETS perl_phonon DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
