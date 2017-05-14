cmake_minimum_required(VERSION 2.8)
set(PROJECT panda-uri)

project(${PROJECT})

include_directories(
        src
        ../Panda-XS/src/
        ../Panda-Lib/src
)

file(GLOB source
        src/panda/uri.h
        "src/panda/uri/*.h"
        "src/panda/uri/*.cc"
)

set(CMAKE_CXX_STANDARD 11)

add_compile_options(
        -v
        -Wall
        -Wextra
)

add_library(${PROJECT} ${source})