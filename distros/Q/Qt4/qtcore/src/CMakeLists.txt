include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QtCore4.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QtCore4.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_CURRENT_SOURCE_DIR}/doxsubpp.pl ${PERL_EXECUTABLE} QtCore4.xs ${CMAKE_CURRENT_BINARY_DIR}/QtCore4.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QtCore4.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# I thought it'd be cool to be able to build the bindings without any runtime
# debugging compiled in.  But that turned out to not really be a good idea, as
# that information is useful in a lot of situations.
add_definitions( -DPERLQTDEBUG )

# Make sure we build QtCore4.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QtCore4.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(perlqtcore_LIBRARY_SRCS
    binding.cpp
    handlers.cpp
    marshall_types.cpp
    util.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/QtCore4.c
)

if(WIN32)
    set(libraryName PerlQtCore4)
else()
    set(libraryName QtCore4)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perlqtcore4 SHARED ${perlqtcore_LIBRARY_SRCS})

target_link_libraries(perlqtcore4
    ${QT_QTCORE_LIBRARY}
    ${QT_QTGUI_LIBRARY}
    ${QT_QTNETWORK_LIBRARY}
    ${PERL_LIBRARY}
    ${SMOKE_BASE_LIBRARY}
    ${SMOKE_QTCORE_LIBRARY}
    ${SMOKE_QTGUI_LIBRARY}
    ${SMOKE_QTNETWORK_LIBRARY}
    ${PERL_LIBS})

set_target_properties(perlqtcore4 PROPERTIES
    OUTPUT_NAME ${libraryName}
    PREFIX ""
    INSTALL_NAME_DIR ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/
)

install(TARGETS perlqtcore4 EXPORT PerlQtExport DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
install(FILES binding.h handlers.h listclass_macros.h marshall_basetypes.h marshall_complex.h
              marshall.h marshall_macros.h marshall_primitives.h marshall_types.h perlqt.h ppport.h
              QtCore4.h smokehelp.h smokeperl.h util.h
        DESTINATION include/perlqt )
install(FILES doxsubpp.pl DESTINATION share/perlqt )
