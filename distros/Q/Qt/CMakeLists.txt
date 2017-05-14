cmake_minimum_required(VERSION 2.6)

project(PerlQt)

enable_testing()
set(ENABLE_GUI_TESTS OFF CACHE BOOL "Run GUI tests in the \"test\" target")
set(USE_BUILD_DIR_FOR_TESTS OFF CACHE BOOL "Use to toggle between using the build dir or the install dir for tests.")
if ( USE_BUILD_DIR_FOR_TESTS )
    set(prove_args -I${CMAKE_BINARY_DIR}/blib/lib -I${CMAKE_BINARY_DIR}/blib/arch)
endif ( USE_BUILD_DIR_FOR_TESTS )

find_package(Perl REQUIRED)
find_package(PerlLibs REQUIRED)
find_package(Qt4 REQUIRED)
find_package(Smoke REQUIRED COMPONENTS QtCore)
find_package(Smoke COMPONENTS QtCore QtGui QtNetwork Qt3Support QtDeclarative QtDBus QtHelp QtMultimedia
                              QtOpenGl QtScript QtSql QtSvg QtTest QtUiTools QtWebKit QtXml QtXmlPatterns
                              Phonon Qwt QSci QImageBlitz)
                              
include_directories(${SMOKE_INCLUDE_DIR} ${QT_INCLUDES} ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${SMOKE_CMAKE_MODULE_DIR})
include(MacroOptionalFindPackage)
include(MacroOptionalAddBindings)
include(MacroLogFeature)

macro_optional_find_package(QScintilla)
macro_log_feature(QSCINTILLA_FOUND "QScintilla2" "QScintilla2 libraries" "http://www.riverbankcomputing.co.uk/software/qscintilla/intro" FALSE "" "Needed to compile QScintilla2 bindings")

macro_optional_find_package(QImageBlitz)
macro_log_feature(QIMAGEBLITZ_FOUND "QImageBlitz" "QImageBlitz library" "http://www.kde.org" FALSE "" "Needed to compile QImageBlitz bindings")

macro_optional_find_package(Phonon)
macro_log_feature(PHONON_FOUND "Phonon" "Phonon multimedia framework" "http://www.kde.org" FALSE "" "Needed to compile Phonon bindings")

macro_optional_find_package(Qwt5)
macro_log_feature(Qwt5_Qt4_FOUND "Qwt5 for Qt4" "Qwt5 libraries for Qt4" "http://qwt.sourceforge.net" FALSE "" "Needed to compile Qwt5 bindings")

add_definitions(-DDEBUG)

include (FindPerlMore)
set(CUSTOM_PERL_SITE_ARCH_DIR ${PERL_SITE_ARCH_DIR} CACHE DIR "Custom installation directory for perl binary extension")

# the RPATH to be used when installing, but only if it's not a system directory
GET_FILENAME_COMPONENT(SMOKE_LIB_DIR ${SMOKE_BASE_LIBRARY} PATH)
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES ${SMOKE_LIB_DIR} isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}:${SMOKE_LIB_DIR}")
ENDIF("${isSystemDir}" STREQUAL "-1")

GET_FILENAME_COMPONENT(PERL_LIB_DIR ${PERL_LIBRARY} PATH)
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES ${PERL_LIB_DIR} isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}:${PERL_LIB_DIR}")
ENDIF("${isSystemDir}" STREQUAL "-1")

# This assumes there will be a release version of the qtcore library available
GET_FILENAME_COMPONENT(QT_LIB_DIR ${QT_QTCORE_LIBRARY_RELEASE} PATH)
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES ${QT_LIB_DIR} isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
   SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}:${QT_LIB_DIR}")
ENDIF("${isSystemDir}" STREQUAL "-1")


add_subdirectory(qtcore)

macro_optional_add_bindings(SMOKE_QT3SUPPORT_FOUND    "Qt3Support"    qt3support)
macro_optional_add_bindings(SMOKE_QTDBUS_FOUND        "QtDBus"        qtdbus)
macro_optional_add_bindings(SMOKE_QTDECLARATIVE_FOUND "QtDeclarative" qtdeclarative)
macro_optional_add_bindings(SMOKE_QTGUI_FOUND         "QtGui"         qtgui)
macro_optional_add_bindings(SMOKE_QTHELP_FOUND        "QtHelp"        qthelp)
macro_optional_add_bindings(SMOKE_QTMULTIMEDIA_FOUND  "QtMultimedia"  qtmultimedia)
macro_optional_add_bindings(SMOKE_QTNETWORK_FOUND     "QtNetwork"     qtnetwork)
macro_optional_add_bindings(SMOKE_QTOPENGL_FOUND      "QtOpenGL"      qtopengl)
macro_optional_add_bindings(SMOKE_QTSCRIPT_FOUND      "QtScript"      qtscript)
macro_optional_add_bindings(SMOKE_QTSQL_FOUND         "QtSql"         qtsql)
macro_optional_add_bindings(SMOKE_QTSVG_FOUND         "QtSvg"         qtsvg)
macro_optional_add_bindings(SMOKE_QTTEST_FOUND        "QtTest"        qttest)
macro_optional_add_bindings(SMOKE_QTUITOOLS_FOUND     "QtUiTools"     qtuitools)
macro_optional_add_bindings(SMOKE_QTWEBKIT_FOUND      "QtWebKit"      qtwebkit)
macro_optional_add_bindings(SMOKE_QTXML_FOUND         "QtXml"         qtxml)
macro_optional_add_bindings(SMOKE_QTXMLPATTERNS_FOUND "QtXmlPatterns" qtxmlpatterns)

macro_optional_add_bindings(SMOKE_PHONON_FOUND "Phonon" phonon)

macro_optional_add_bindings(QSCINTILLA_FOUND "QScintilla" qsci)

macro_optional_add_bindings(SMOKE_Qwt5_Qt4_FOUND "Qwt" qwt)

macro_optional_add_bindings(SMOKE_QIMAGEBLITZ_FOUND "QImageBlitz" qimageblitz)

macro_display_bindings_log()

macro_display_feature_log()

install(EXPORT PerlQtExport DESTINATION ${CMAKE_INSTALL_PREFIX}/share/perlqt/cmake NAMESPACE PERLQT_)
add_subdirectory(cmake)
