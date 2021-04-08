#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "panda-net-sockaddr" for configuration ""
set_property(TARGET panda-net-sockaddr APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(panda-net-sockaddr PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libpanda-net-sockaddr.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS panda-net-sockaddr )
list(APPEND _IMPORT_CHECK_FILES_FOR_panda-net-sockaddr "${_IMPORT_PREFIX}/lib/libpanda-net-sockaddr.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
