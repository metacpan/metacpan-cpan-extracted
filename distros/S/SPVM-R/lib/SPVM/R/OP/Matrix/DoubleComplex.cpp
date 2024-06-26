// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "Eigen/Core"
#include "Eigen/Dense"

#include <complex.h>

extern "C" {

static const char* FILE_NAME = "R/OP/Matrix/DoubleComplex.cpp";

int32_t SPVM__R__OP__Matrix__DoubleComplex__mul(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_x_data = stack[0].oval;
  std::complex<double>* x_data = (std::complex<double>*)env->get_elems_double(env, stack, obj_x_data);
  
  int32_t x_row = stack[1].ival;
  
  int32_t x_column = stack[2].ival;
  
  void* obj_y_data = stack[3].oval;
  std::complex<double>* y_data = (std::complex<double>*)env->get_elems_double(env, stack, obj_y_data);
  
  int32_t y_row = stack[4].ival;
  
  int32_t y_column = stack[5].ival;
  
  void* ret_ndarray_ref = stack[6].oval;
  
  int32_t* ret_row_ref = stack[7].iref;
  
  int32_t* ret_column_ref = stack[8].iref;
  
  Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_row, x_column);
  
  Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> y_matrix = Eigen::Map<Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic>>(y_data, y_row, y_column);
  
  Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> ret_matrix = x_matrix * y_matrix;
  
  int32_t ret_length = ret_matrix.rows() * ret_matrix.cols();
  void* obj_ret_data = env->new_mulnum_array_by_name(env, stack, "Complex_2d", ret_length, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  std::complex<double>* ret_data = (std::complex<double>*)env->get_elems_double(env, stack, obj_ret_data);
  
  memcpy(ret_data, ret_matrix.data(), sizeof(std::complex<double>) * ret_length);
  
  env->set_elem_object(env, stack, ret_ndarray_ref, 0, ret_data);
  
  *ret_row_ref = ret_matrix.rows();
  
  *ret_column_ref = ret_matrix.cols();
  
  return 0;
}

}
