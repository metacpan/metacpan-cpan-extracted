#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "panda-protocol-http" for configuration ""
set_property(TARGET panda-protocol-http APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(panda-protocol-http PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libpanda-protocol-http.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS panda-protocol-http )
list(APPEND _IMPORT_CHECK_FILES_FOR_panda-protocol-http "${_IMPORT_PREFIX}/lib/libpanda-protocol-http.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
