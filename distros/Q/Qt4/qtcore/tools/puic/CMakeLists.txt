
include_directories( ${CMAKE_CURRENT_SOURCE_DIR} )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/perl )

########### next target ###############

set(puic4_bin_SRCS 
   customwidgetsinfo.cpp 
   databaseinfo.cpp 
   driver.cpp 
   treewalker.cpp 
   ui4.cpp 
   uic.cpp 
   validator.cpp 
   perl/plextractimages.cpp 
   perl/plwritedeclaration.cpp 
   perl/plwriteicondata.cpp 
   perl/plwriteicondeclaration.cpp 
   perl/plwriteiconinitialization.cpp 
   perl/plwriteinitialization.cpp 
   perl/plwriteincludes.cpp
   main.cpp )

add_executable(puic4_bin ${puic4_bin_SRCS})
set_target_properties(puic4_bin PROPERTIES OUTPUT_NAME puic4)
set_target_properties(puic4_bin PROPERTIES COMPILE_FLAGS -DQT_UIC)

target_link_libraries(puic4_bin  ${QT_QTCORE_LIBRARY} ${QT_QTXML_LIBRARY} )

install(TARGETS puic4_bin DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)


########### next target ###############


########### install files ###############
