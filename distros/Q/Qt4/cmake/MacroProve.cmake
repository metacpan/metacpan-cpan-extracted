
MACRO( MACRO_PROVE _testname _path)

    if(WIN32)
        set(prove_cmd "prove.bat")
        string(REGEX REPLACE " " "\\\\\\\\ " escaped_path ${_path})
    else()
        set(prove_cmd "prove")
        set(escaped_path ${_path})
    endif(WIN32)

    if ( USE_BUILD_DIR_FOR_TESTS )
        set(prove_args -I${CMAKE_BINARY_DIR}/blib/lib -I${CMAKE_BINARY_DIR}/blib/arch)
    endif ( USE_BUILD_DIR_FOR_TESTS )

    set(_workingdir ${ARGV2})
    if(_workingdir)
        set(prove_args -E chdir ${_workingdir} ${prove_cmd} ${prove_args})
        set(prove_cmd ${CMAKE_COMMAND})
    endif(_workingdir)

    add_test(${_testname} ${prove_cmd} ${prove_args} ${escaped_path})
ENDMACRO( MACRO_PROVE _testname _path )
