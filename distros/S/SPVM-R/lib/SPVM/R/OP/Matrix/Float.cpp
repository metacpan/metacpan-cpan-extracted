// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "Eigen/Core"
#include "Eigen/Dense"

extern "C" {

static const char* FILE_NAME = "R/OP/Matrix/Float.cpp";

int32_t SPVM__R__OP__Matrix__Float___mul(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_ret_data_ref = stack[0].oval;
  
  int32_t* ret_nrow_ref = stack[1].iref;
  
  int32_t* ret_ncol_ref = stack[2].iref;
  
  void* obj_x_data = stack[3].oval;
  float* x_data = (float*)env->get_elems_float(env, stack, obj_x_data);
  
  int32_t x_nrow = stack[4].ival;
  
  int32_t x_ncol = stack[5].ival;
  
  void* obj_y_data = stack[6].oval;
  float* y_data = (float*)env->get_elems_float(env, stack, obj_y_data);
  
  int32_t y_nrow = stack[7].ival;
  
  int32_t y_ncol = stack[8].ival;
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> y_matrix = Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>>(y_data, y_nrow, y_ncol);
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> ret_matrix = x_matrix * y_matrix;
  
  int32_t ret_length = ret_matrix.rows() * ret_matrix.cols();
  void* obj_ret_data = env->new_float_array(env, stack, ret_length);
  
  float* ret_data = (float*)env->get_elems_float(env, stack, obj_ret_data);
  
  memcpy(ret_data, ret_matrix.data(), sizeof(float) * ret_length);
  
  env->set_elem_object(env, stack, obj_ret_data_ref, 0, obj_ret_data);
  
  *ret_nrow_ref = ret_matrix.rows();
  
  *ret_ncol_ref = ret_matrix.cols();
  
  return 0;
}

int32_t SPVM__R__OP__Matrix__Float___t(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_ret_data_ref = stack[0].oval;
  
  int32_t* ret_nrow_ref = stack[1].iref;
  
  int32_t* ret_ncol_ref = stack[2].iref;
  
  void* obj_x_data = stack[3].oval;
  float* x_data = (float*)env->get_elems_float(env, stack, obj_x_data);
  
  int32_t x_nrow = stack[4].ival;
  
  int32_t x_ncol = stack[5].ival;
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> ret_matrix = x_matrix;
  
  ret_matrix.transposeInPlace();
  
  int32_t ret_length = ret_matrix.rows() * ret_matrix.cols();
  void* obj_ret_data = env->new_float_array(env, stack, ret_length);
  
  float* ret_data = (float*)env->get_elems_float(env, stack, obj_ret_data);
  
  memcpy(ret_data, ret_matrix.data(), sizeof(float) * ret_length);
  
  env->set_elem_object(env, stack, obj_ret_data_ref, 0, obj_ret_data);
  
  *ret_nrow_ref = ret_matrix.rows();
  
  *ret_ncol_ref = ret_matrix.cols();
  
  return 0;
}

int32_t SPVM__R__OP__Matrix__Float___det(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_ret_data_ref = stack[0].oval;
  
  int32_t* ret_nrow_ref = stack[1].iref;
  
  int32_t* ret_ncol_ref = stack[2].iref;
  
  void* obj_x_data = stack[3].oval;
  float* x_data = (float*)env->get_elems_float(env, stack, obj_x_data);
  
  int32_t x_nrow = stack[4].ival;
  
  int32_t x_ncol = stack[5].ival;
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
  
  float ret = x_matrix.determinant();
  
  int32_t ret_length = 1;
  void* obj_ret_data = env->new_float_array(env, stack, ret_length);
  
  float* ret_data = (float*)env->get_elems_float(env, stack, obj_ret_data);
  
  memcpy(ret_data, &ret, sizeof(float) * ret_length);
  
  env->set_elem_object(env, stack, obj_ret_data_ref, 0, obj_ret_data);
  
  *ret_nrow_ref = 1;
  
  *ret_ncol_ref = 1;
  
  return 0;
}

int32_t SPVM__R__OP__Matrix__Float___solve(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_ret_data_ref = stack[0].oval;
  
  int32_t* ret_nrow_ref = stack[1].iref;
  
  int32_t* ret_ncol_ref = stack[2].iref;
  
  void* obj_x_data = stack[3].oval;
  float* x_data = (float*)env->get_elems_float(env, stack, obj_x_data);
  
  int32_t x_nrow = stack[4].ival;
  
  int32_t x_ncol = stack[5].ival;
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> ret_matrix = x_matrix.inverse();
  
  int32_t ret_length = ret_matrix.rows() * ret_matrix.cols();
  void* obj_ret_data = env->new_float_array(env, stack, ret_length);
  
  float* ret_data = (float*)env->get_elems_float(env, stack, obj_ret_data);
  
  memcpy(ret_data, ret_matrix.data(), sizeof(float) * ret_length);
  
  env->set_elem_object(env, stack, obj_ret_data_ref, 0, obj_ret_data);
  
  *ret_nrow_ref = ret_matrix.rows();
  
  *ret_ncol_ref = ret_matrix.cols();
  
  return 0;
}

int32_t SPVM__R__OP__Matrix__Float___eigen(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_eigen_vectors_data_ref = stack[0].oval;
  
  int32_t* eigen_vectors_nrow_ref = stack[1].iref;
  
  int32_t* eigen_vectors_ncol_ref = stack[2].iref;
  
  void* obj_eigen_values_data_ref = stack[3].oval;
  
  int32_t* eigen_values_nrow_ref = stack[4].iref;
  
  int32_t* eigen_values_ncol_ref = stack[5].iref;
  
  void* obj_x_data = stack[6].oval;
  float* x_data = (float*)env->get_elems_float(env, stack, obj_x_data);
  
  int32_t x_nrow = stack[7].ival;
  
  int32_t x_ncol = stack[8].ival;
  
  Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
  
  Eigen::EigenSolver<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic>> eigen_solver(x_matrix);
  
  Eigen::Matrix<std::complex<float>, Eigen::Dynamic, Eigen::Dynamic> eigen_vectors = eigen_solver.eigenvectors();
  
  Eigen::Matrix<std::complex<float>, Eigen::Dynamic, 1> eigen_values = eigen_solver.eigenvalues();
  
  int32_t eigen_vectors_length = eigen_vectors.rows() * eigen_vectors.cols();
  void* obj_eigen_vectors_data = env->new_mulnum_array_by_name(env, stack, "Complex_2f", eigen_vectors_length, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  std::complex<float>* eigen_vectors_data = (std::complex<float>*)env->get_elems_float(env, stack, obj_eigen_vectors_data);
  
  memcpy(eigen_vectors_data, eigen_vectors.data(), sizeof(std::complex<float>) * eigen_vectors_length);
  
  env->set_elem_object(env, stack, obj_eigen_vectors_data_ref, 0, obj_eigen_vectors_data);
  
  *eigen_vectors_nrow_ref = eigen_vectors.rows();
  
  *eigen_vectors_ncol_ref = eigen_vectors.cols();
  
  int32_t eigen_values_length = eigen_values.rows() * eigen_values.cols();
  void* obj_eigen_values_data = env->new_mulnum_array_by_name(env, stack, "Complex_2f", eigen_values_length, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  std::complex<float>* eigen_values_data = (std::complex<float>*)env->get_elems_float(env, stack, obj_eigen_values_data);
  
  memcpy(eigen_values_data, eigen_values.data(), sizeof(std::complex<float>) * eigen_values_length);
  
  env->set_elem_object(env, stack, obj_eigen_values_data_ref, 0, obj_eigen_values_data);
  
  *eigen_values_nrow_ref = eigen_values.rows();
  
  *eigen_values_ncol_ref = eigen_values.cols();
  
  return 0;
}

}
