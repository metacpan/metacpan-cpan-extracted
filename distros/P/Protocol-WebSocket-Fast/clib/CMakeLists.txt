cmake_minimum_required(VERSION 3.0)

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

project(panda-protocol-websocket LANGUAGES CXX)

set(LIB_TYPE STATIC)
option(PROTOCOL_WEBSOCKET_TESTS OFF)
option(PROTOCOL_WEBSOCKET ${NOT_SUBPROJECT})

if (${PROTOCOL_WEBSOCKET})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

if (PROTOCOL_WEBSOCKET_FETCH_DEPS)
    include(FetchDeps.cmake)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)
set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_STANDARD 14
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS NO
)

target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)

if (NOT TARGET panda-uri)
    find_package(panda-uri REQUIRED)
endif()
if (NOT TARGET panda-encode-base2n)
    find_package(panda-encode-base2n REQUIRED)
endif()
if (NOT TARGET panda-protocol-http)
    find_package(panda-protocol-http REQUIRED)
endif()
find_package(OpenSSL REQUIRED)
target_link_libraries(${PROJECT_NAME} PUBLIC panda-uri panda-encode-base2n panda-protocol-http OpenSSL::SSL)

########################tests#######################################
if (PROTOCOL_WEBSOCKET_TESTS)
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

set_source_files_properties(tests/bench.cc PROPERTIES COMPILE_FLAGS -O2)

add_library(${PROJECT_NAME}-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(${PROJECT_NAME}-tests PUBLIC ${PROJECT_NAME})

if (NOT TARGET Catch2::Catch2)
    find_package(Catch2)
endif()
target_link_libraries(${PROJECT_NAME}-tests PUBLIC Catch2::Catch2)

########################ctests######################################
enable_testing()
add_executable(${PROJECT_NAME}-runtests ${EXCLUDE_TEST} ${testSource} "tests/main.cc")
target_link_libraries(${PROJECT_NAME}-runtests ${PROJECT_NAME}-tests Catch2::Catch2WithMain)
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME}-runtests WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

endif() #PROTOCOL_WEBSOCKET_TESTS

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
