cmake_minimum_required(VERSION 3.10)
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 OLD)
endif()

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

project(panda-protocol-http LANGUAGES CXX)

set(LIB_TYPE STATIC)
option(PROTOCOL_HTTP_TESTS OFF)
option(PROTOCOL_HTTP_TESTS_IN_ALL ${NOT_SUBPROJECT})
if (${PROTOCOL_HTTP_TESTS_IN_ALL})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

if (${PROTOCOL_HTTP_FETCH_DEPS})
    include(FetchDeps.cmake)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
LIST(APPEND libSource "src/panda/protocol/http/CookieParser.cc" "src/panda/protocol/http/CookieStorage.cc" "src/panda/protocol/http/MessageParser.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)

target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)
set_source_files_properties(src/panda/protocol/http/CookieParser.cc  PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")
set_source_files_properties(src/panda/protocol/http/CookieStorage.cc PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")
set_source_files_properties(src/panda/protocol/http/MessageParser.cc PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")

find_program(ragel_bin ragel)
if (ragel_bin)
    foreach(fpath src/panda/protocol/http/CookieParser src/panda/protocol/http/CookieStorage src/panda/protocol/http/MessageParser)
        add_custom_command(
            OUTPUT  ${CMAKE_CURRENT_SOURCE_DIR}/${fpath}.cc
            COMMAND ragel -C -G2 ${fpath}.rl -o ${fpath}.cc
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${fpath}.rl
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
    endforeach()
endif()

if (NOT TARGET Boost::headers)
    find_package(Boost REQUIRED)
endif()
if (NOT TARGET range-v3::range-v3)
    find_package(range-v3 REQUIRED)
endif()
if (NOT TARGET panda-uri)
    find_package(panda-uri REQUIRED)
endif()
if (NOT TARGET panda-date)
    find_package(panda-date REQUIRED)
endif()
if (NOT TARGET ZLIB::ZLIB)
    find_package(ZLIB REQUIRED)
endif()

target_link_libraries(${PROJECT_NAME} PUBLIC range-v3::range-v3 panda-uri panda-date ZLIB::ZLIB Boost::headers)

########################tests#######################################
if (${PROTOCOL_HTTP_TESTS})

file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

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

endif() # if (${PROTOCOL_HTTP_TESTS})

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
