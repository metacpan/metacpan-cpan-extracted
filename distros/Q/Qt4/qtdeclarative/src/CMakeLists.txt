include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QtDeclarative4.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QtDeclarative4.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} QtDeclarative4.xs ${CMAKE_CURRENT_BINARY_DIR}/QtDeclarative4.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QtDeclarative4.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build QtDeclarative4.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QtDeclarative4.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qtdeclarative4_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/QtDeclarative4.c
    qtdeclarative4handlers.cpp
)

if(WIN32)
    set(libraryName PerlQtDeclarative4)
else()
    set(libraryName QtDeclarative4)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_qtdeclarative4 SHARED ${qtdeclarative4_LIBRARY_SRC})

target_link_libraries(perl_qtdeclarative4
    ${SMOKE_QTDECLARATIVE_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qtdeclarative4 PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_qtdeclarative4 PROPERTIES PREFIX "")

install(TARGETS perl_qtdeclarative4 DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
