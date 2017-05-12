include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QtGui4.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QtGui4.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} QtGui4.xs ${CMAKE_CURRENT_BINARY_DIR}/QtGui4.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QtGui4.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Make sure we build QtGui4.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QtGui4.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qtgui4_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/QtGui4.c
    qtgui4handlers.cpp
)

if(WIN32)
    set(libraryName PerlQtGui4)
else()
    set(libraryName QtGui4)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_qtgui4 SHARED ${qtgui4_LIBRARY_SRC})

target_link_libraries(perl_qtgui4
    ${SMOKE_QTGUI_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qtgui4 PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_qtgui4 PROPERTIES PREFIX "")

install(TARGETS perl_qtgui4 DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
