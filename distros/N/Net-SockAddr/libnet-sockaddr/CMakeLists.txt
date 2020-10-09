CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(Net-Sockadr VERSION 1.1.5 LANGUAGES CXX)
enable_testing()
set(CMAKE_CXX_EXTENSIONS OFF)

set(LIB_TYPE STATIC)

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
add_library(net-sockaddr ${LIB_TYPE} ${libSource})
target_include_directories(net-sockaddr PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(net-sockaddr PUBLIC cxx_std_14)

find_package(panda-lib REQUIRED)
target_link_libraries(net-sockaddr panda::panda-lib)

if (WIN32)
    target_link_libraries(net-sockaddr ws2_32)
endif()

########################tests#######################################
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")
list(FILTER testSource EXCLUDE REGEX "tests/main.cc")

add_library(lib-tests  STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(lib-tests PUBLIC net-sockaddr)

find_package(Catch2)
target_link_libraries(lib-tests PUBLIC Catch2::Catch2)

########################ctests######################################
#executable should be MyTest to pass test esception.cc that checks "library" name
add_executable(MyTest ${testSource} "tests/main.cc")
target_link_libraries(MyTest lib-tests)
add_test(test-all MyTest)

########################install#####################################
install(DIRECTORY src/ DESTINATION include
    FILES_MATCHING PATTERN "*.h")
install(TARGETS net-sockaddr EXPORT net-sockaddrTargets
    ARCHIVE DESTINATION lib
)

install(EXPORT net-sockaddrTargets
    FILE net-sockaddrConfig.cmake
    NAMESPACE panda::
    DESTINATION lib/cmake/net-sockaddr
)
