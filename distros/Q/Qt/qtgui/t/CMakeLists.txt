# Class tests
add_test(perlqt_qtgui4_load        prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/a_loading.t)
add_test(perlqt_qpolygon           prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/qpolygon.t)
add_test(perlqt_qpolygonf          prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/qpolygonf.t)
add_test(perlqt_qstringlistmodel   prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/qstringlistmodel.t)

# GUI tests
add_test(perlqt_itemviewspixelator       ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/itemviews/pixelator       prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/itemviewspixelator.t)
add_test(perlqt_itemviewspuzzle          ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/itemviews/puzzle          prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/itemviewspuzzle.t)
add_test(perlqt_helpcontextsensitivehelp ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/help/contextsensitivehelp prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/helpcontextsensitivehelp.t)
add_test(perlqt_mainwindowsmdi           ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/mainwindows/mdi           prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/mainwindowsmdi.t)
add_test(perlqt_networkbroadcast         ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/network/broadcastsender   prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/networkbroadcast.t)
add_test(perlqt_networkfortune           ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/network/fortuneserver     prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/networkfortune.t)
add_test(perlqt_networkgooglesuggest     ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/network/googlesuggest     prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/networkgooglesuggest.t)
add_test(perlqt_paintingfontsampler      ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/painting/fontsampler      prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/paintingfontsampler.t)
add_test(perlqt_richtextcalendar         ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/richtext/calendar         prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/richtextcalendar.t)
add_test(perlqt_sqlquerymodel            ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/sql/querymodel            prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/sqlquerymodel.t)
add_test(perlqt_widgetscalculator        ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/widgets/calculator        prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/widgetscalculator.t)
add_test(perlqt_xmlstreambookmarks       ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/qtgui/examples/xml/streambookmarks       prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/xmlstreambookmarks.t)
