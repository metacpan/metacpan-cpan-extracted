# Class tests
add_test(perlqt_qttest4_load prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/a_loading.t)

add_test(perlqt_qsignalspy prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/qsignalspy.t)
add_test(perlqt_qtesteventlist prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/qtesteventlist.t)
