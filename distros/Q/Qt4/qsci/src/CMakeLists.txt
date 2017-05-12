include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on Qsci.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Qsci.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} Qsci.xs ${CMAKE_CURRENT_BINARY_DIR}/Qsci.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Qsci.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build Qsci.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/Qsci.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qsci_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/Qsci.c
    qscihandlers.cpp
)

if(WIN32)
    set(libraryName PerlQsci)
else()
    set(libraryName Qsci)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_qsci SHARED ${qsci_LIBRARY_SRC})

target_link_libraries(perl_qsci
    ${SMOKE_QSCI_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qsci PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_qsci PROPERTIES PREFIX "")

install(TARGETS perl_qsci DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
