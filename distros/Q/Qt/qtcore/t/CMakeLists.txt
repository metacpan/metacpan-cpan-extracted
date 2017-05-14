add_test(perlqt_qtcore4_load           prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/a_loading.t)
add_test(perlqt_qtcore4_qapp              prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/c_qapp.t)
add_test(perlqt_qtcore4_sigslot           prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/d_sigslot.t)
add_test(perlqt_qtcore4_sigslot_inherit   prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/e_sigslot_inherit.t)
add_test(perlqt_qtcore4_handlers          prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/f_handlers.t)

add_test(perlqt_qabstractitemmodel prove ${prove_args} ${CMAKE_CURRENT_SOURCE_DIR}/qabstractitemmodel.t)
