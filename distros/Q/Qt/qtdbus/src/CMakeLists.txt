include_directories(
    ${CMAKE_SOURCE_DIR}/generator
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QtDBus4.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QtDBus4.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} QtDBus4.xs ${CMAKE_CURRENT_BINARY_DIR}/QtDBus4.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QtDBus4.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build QtDBus4.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QtDBus4.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qtdbus4_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/QtDBus4.c
    qtdbus4handlers.cpp
)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/QtDBus4)
add_library(perl_qtdbus4 MODULE ${qtdbus4_LIBRARY_SRC})

target_link_libraries(perl_qtdbus4
    ${SMOKE_QTDBUS_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qtdbus4 PROPERTIES OUTPUT_NAME "QtDBus4")
set_target_properties(perl_qtdbus4 PROPERTIES PREFIX "")

install(TARGETS perl_qtdbus4 DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/QtDBus4/)