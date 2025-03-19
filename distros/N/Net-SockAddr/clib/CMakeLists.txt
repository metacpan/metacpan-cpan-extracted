CMAKE_MINIMUM_REQUIRED(VERSION 3.10)

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

PROJECT(panda-net-sockaddr VERSION 1.1.5 LANGUAGES CXX)

set(LIB_TYPE STATIC)
set(CMAKE_CXX_EXTENSIONS OFF)

option(NET_SOCKADDR_TESTS OFF)
option(NET_SOCKADDR_TESTS_IN_ALL ${NOT_SUBPROJECT})

if (${NET_SOCKADDR_TESTS_IN_ALL})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

if (${NET_SOCKADDR_FETCH_DEPS})
    include(FetchDeps.cmake)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)
target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)

if (NOT TARGET panda-lib)
    find_package(panda-lib REQUIRED)
endif()
target_link_libraries(${PROJECT_NAME} panda-lib)

if (WIN32)
    target_link_libraries(${PROJECT_NAME} PUBLIC ws2_32)
endif()

########################tests#######################################
if (${NET_SOCKADDR_TESTS})

file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(tests  STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(tests PUBLIC ${PROJECT_NAME})

find_package(Catch2)
target_link_libraries(tests PUBLIC Catch2::Catch2)

########################ctests######################################
#executable should be MyTest to pass test esception.cc that checks "library" name
enable_testing()
add_executable(${PROJECT_NAME}-runtests ${EXCLUDE_TEST} ${testSource} "tests/main.cc")
target_link_libraries(${PROJECT_NAME}-runtests tests Catch2::Catch2WithMain)
add_test(${PROJECT_NAME} ${PROJECT_NAME}-runtests)

endif() #if (${NET_SOCKADDR_TESTS})

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
