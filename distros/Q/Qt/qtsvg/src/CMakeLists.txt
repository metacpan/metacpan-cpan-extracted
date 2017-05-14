include_directories(
    ${CMAKE_SOURCE_DIR}/generator
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QtSvg4.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QtSvg4.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} QtSvg4.xs ${CMAKE_CURRENT_BINARY_DIR}/QtSvg4.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QtSvg4.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build QtSvg4.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QtSvg4.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qtsvg4_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/QtSvg4.c
    qtsvg4handlers.cpp
)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/QtSvg4)
add_library(perl_qtsvg4 MODULE ${qtsvg4_LIBRARY_SRC})

target_link_libraries(perl_qtsvg4
    ${SMOKE_QTSVG_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qtsvg4 PROPERTIES OUTPUT_NAME "QtSvg4")
set_target_properties(perl_qtsvg4 PROPERTIES PREFIX "")

install(TARGETS perl_qtsvg4 DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/QtSvg4/)