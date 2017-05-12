include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QtNetwork4.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QtNetwork4.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} QtNetwork4.xs ${CMAKE_CURRENT_BINARY_DIR}/QtNetwork4.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QtNetwork4.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build QtNetwork4.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QtNetwork4.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qtnetwork4_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/QtNetwork4.c
    qtnetwork4handlers.cpp
    xsfunctions.cpp
)

if(WIN32)
    set(libraryName PerlQtNetwork4)
else()
    set(libraryName QtNetwork4)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_qtnetwork4 SHARED ${qtnetwork4_LIBRARY_SRC})

target_link_libraries(perl_qtnetwork4
    ${SMOKE_QTNETWORK_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qtnetwork4 PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_qtnetwork4 PROPERTIES PREFIX "")

install(TARGETS perl_qtnetwork4 DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
