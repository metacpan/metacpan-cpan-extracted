include(FetchContent)
include(CMakeDependentOption)

set(panda-lib_repository https://github.com/CrazyPandaLimited/panda-lib.git)
set(panda-date_repository https://github.com/CrazyPandaLimited/Date)
set(panda-uri_repository https://github.com/CrazyPandaLimited/Panda-URI)
set(range_repository https://github.com/ericniebler/range-v3.git)
set(range_repository_tag 0.12.0)

set(Catch2_repository https://github.com/catchorg/Catch2.git)
set(Catch2_repository_tag devel)

set(deps panda-lib panda-date panda-uri range)

set(PANDA_DATE_FETCH_DEPS ON)
set(PANDA_URI_FETCH_DEPS ON)

if (${PROTOCOL_HTTP_TESTS})
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