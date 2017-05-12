include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on Qwt.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Qwt.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} Qwt.xs ${CMAKE_CURRENT_BINARY_DIR}/Qwt.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/Qwt.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build Qwt.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/Qwt.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qwt_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/Qwt.c
    qwthandlers.cpp
)

if(WIN32)
    set(libraryName PerlQwt)
else()
    set(libraryName Qwt)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_qwt SHARED ${qwt_LIBRARY_SRC})

target_link_libraries(perl_qwt
    ${SMOKE_QWT_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qwt PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_qwt PROPERTIES PREFIX "")

install(TARGETS perl_qwt DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
