cmake_minimum_required(VERSION 2.8)

set(PROJECT panda-lib)

project(${PROJECT})

include_directories(src)

file(GLOB source
        "src/panda/*.h"
        "src/panda/*.cc"
        "src/panda/lib/*.h"
        "src/panda/lib/*.cc"
)

set(CMAKE_CXX_STANDARD 11)

add_compile_options(
        -v
        -Wall
        -Wextra
)

add_library(${PROJECT} ${source})