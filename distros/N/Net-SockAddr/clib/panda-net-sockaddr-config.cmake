if (NOT TARGET panda-net-sockaddr)
    find_package(panda-lib REQUIRED)
    include(${CMAKE_CURRENT_LIST_DIR}/panda-net-sockaddr-targets.cmake)
endif()
