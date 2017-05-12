add_definitions(-DQT3_SUPPORT)

include_directories( ${QT_INCLUDES} ${CMAKE_CURRENT_SOURCE_DIR} )

configure_file(config.xml.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.xml @ONLY)

########### next target ###############

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/smokedata.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_1.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_2.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_3.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_4.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_5.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_6.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_7.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_8.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_9.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_10.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_11.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_12.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_13.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_14.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_15.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_16.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_17.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_18.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_19.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/x_20.cpp

    COMMAND ${SMOKE_GEN_BIN}
    ARGS -config "${CMAKE_CURRENT_BINARY_DIR}/config.xml" -smokeconfig "${CMAKE_CURRENT_SOURCE_DIR}/smokeconfig.xml"
         -- ${CMAKE_CURRENT_SOURCE_DIR}/qt3support_includes.h
    DEPENDS ${SMOKE_GEN_BIN} "${CMAKE_CURRENT_SOURCE_DIR}/smokeconfig.xml"
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

macro_add_file_dependencies( ${CMAKE_CURRENT_BINARY_DIR}/smokedata.cpp ${CMAKE_CURRENT_BINARY_DIR}/x_1.cpp )

include_directories (${CMAKE_SOURCE_DIR}/smoke ${CMAKE_SOURCE_DIR}/smoke/qt3support  )

set(smokeqt3support_LIB_SRCS ${CMAKE_CURRENT_BINARY_DIR}/smokedata.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_1.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_2.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_3.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_4.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_5.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_6.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_7.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_8.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_9.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_10.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_11.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_12.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_13.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_14.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_15.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_16.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_17.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_18.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_19.cpp
                ${CMAKE_CURRENT_BINARY_DIR}/x_20.cpp
)

IF(CMAKE_CXX_FLAGS MATCHES "-fvisibility")
    ADD_DEFINITIONS(-DGCC_VISIBILITY)
ENDIF(CMAKE_CXX_FLAGS MATCHES "-fvisibility")

add_library(smokeqt3support SHARED ${smokeqt3support_LIB_SRCS})

target_link_libraries(
    smokeqt3support
    smokeqtcore
    smokeqtgui
    smokeqtnetwork
    smokeqtsql
    smokeqtxml
    ${QT_QT3SUPPORT_LIBRARY}
    ${QT_QTCORE_LIBRARY}
    ${QT_QTGUI_LIBRARY}
    ${QT_QTNETWORK_LIBRARY}
    ${QT_QTSQL_LIBRARY}
    ${QT_QTXML_LIBRARY}
)

set_target_properties(smokeqt3support PROPERTIES VERSION 3.0.0 SOVERSION 3 )

install(TARGETS smokeqt3support
    LIBRARY DESTINATION ${LIB_INSTALL_DIR}
    ARCHIVE DESTINATION ${LIB_INSTALL_DIR}
    RUNTIME DESTINATION bin)

# Get rid of the "lib" prefix on archives/DLLs in Windows.
if (WIN32)
    set_target_properties(smokeqt3support
        PROPERTIES PREFIX "" IMPORT_PREFIX "")
endif (WIN32)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/../qt3support_smoke.h DESTINATION include/smoke)
