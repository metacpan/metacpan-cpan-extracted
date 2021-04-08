#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "panda-protocol-websocket" for configuration ""
set_property(TARGET panda-protocol-websocket APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(panda-protocol-websocket PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libpanda-protocol-websocket.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS panda-protocol-websocket )
list(APPEND _IMPORT_CHECK_FILES_FOR_panda-protocol-websocket "${_IMPORT_PREFIX}/lib/libpanda-protocol-websocket.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
