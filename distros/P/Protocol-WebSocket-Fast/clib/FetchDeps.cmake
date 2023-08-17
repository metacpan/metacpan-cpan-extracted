include(FetchContent)
include(CMakeDependentOption)

set(panda-lib_repository https://github.com/CrazyPandaLimited/panda-lib.git)
set(panda-protocol-http_repository https://github.com/CrazyPandaLimited/Protocol-HTTP.git)
set(panda-uri_repository https://github.com/CrazyPandaLimited/Panda-URI)
set(panda-encode-base2n_repository https://github.com/CrazyPandaLimited/Encode-Base2N.git)

set(Catch2_repository https://github.com/catchorg/Catch2.git)
set(Catch2_repository_tag devel)

set(deps panda-lib panda-protocol-http panda-uri panda-encode-base2n)

set(PROTOCOL_HTTP_FETCH_DEPS ON)
set(PANDA_URI_FETCH_DEPS ON)

if (${PROTOCOL_WEBSOCKET_TESTS})
    list(APPEND deps Catch2)
endif()

foreach(dep ${deps})
    if (NOT DEFINED ${${dep}_repository_tag})
        set (${${dep}_repository_tag} master)
    endif()
    FetchContent_Declare(${dep}
        GIT_REPOSITORY ${${dep}_repository}
        GIT_TAG ${${dep}_repository_tag}
    )
endforeach()
FetchContent_MakeAvailable(${deps})