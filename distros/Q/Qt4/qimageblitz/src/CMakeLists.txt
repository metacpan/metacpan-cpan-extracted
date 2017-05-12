include_directories(
    ${CMAKE_SOURCE_DIR}/qtcore/src
    ${PERL_INCLUDE_PATH}
    ${QT_INCLUDES} )

# Run doxsubpp.pl to run xsubpp on QImageBlitz.xs
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/QImageBlitz.c
                   COMMAND ${PERL_EXECUTABLE} ARGS ${CMAKE_SOURCE_DIR}/qtcore/src/doxsubpp.pl ${PERL_EXECUTABLE} QImageBlitz.xs ${CMAKE_CURRENT_BINARY_DIR}/QImageBlitz.c
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/QImageBlitz.xs
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# Make sure we build QImageBlitz.c as c++ code
set_source_files_properties( ${CMAKE_CURRENT_BINARY_DIR}/QImageBlitz.c 
    PROPERTIES LANGUAGE CXX
)

set( CMAKE_CXX_FLAGS ${PERL_CXX_FLAGS} )

set(qimageblitz_LIBRARY_SRC
    ${CMAKE_CURRENT_BINARY_DIR}/QImageBlitz.c
    qimageblitzhandlers.cpp
)

if(WIN32)
    set(libraryName PerlQImageBlitz)
else()
    set(libraryName QImageBlitz)
endif(WIN32)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/blib/arch/auto/${libraryName})
add_library(perl_qimageblitz SHARED ${qimageblitz_LIBRARY_SRC})

target_link_libraries(perl_qimageblitz
    ${SMOKE_QIMAGEBLITZ_LIBRARY}
    perlqtcore4)

set_target_properties(perl_qimageblitz PROPERTIES OUTPUT_NAME ${libraryName})
set_target_properties(perl_qimageblitz PROPERTIES PREFIX "")

install(TARGETS perl_qimageblitz DESTINATION ${CUSTOM_PERL_SITE_ARCH_DIR}/auto/${libraryName}/)
