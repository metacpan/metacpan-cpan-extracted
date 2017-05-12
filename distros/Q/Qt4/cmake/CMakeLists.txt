set(PERLQT_EXPORT ${CMAKE_INSTALL_PREFIX}/share/perlqt/cmake/PerlQtExport.cmake)
set(PERLQT_CMAKE_DIR ${CMAKE_INSTALL_PREFIX}/share/perlqt/cmake)
set(PERLQT_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/include)
set(PERLQT_SHARE_DIR ${CMAKE_INSTALL_PREFIX}/share/perlqt)

configure_file(PerlQtConfig.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/PerlQtConfig.cmake @ONLY)

install(FILES FindPerlMore.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/PerlQtConfig.cmake
        DESTINATION share/perlqt/cmake )
