#include "spvm_native.h"

#include "Eigen/Core"
#include "Eigen/Dense"

#include <complex>

extern "C" {

int32_t SPVM__TestCase__Resource__Eigen__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  std::complex<double>* x_data = (std::complex<double>*)env->new_memory_block(env, stack, sizeof(std::complex<double>) * 4);
  
  int32_t x_nrow = 2;
  
  int32_t x_ncol = 2;
  
  std::complex<double>* y_data = (std::complex<double>*)env->new_memory_block(env, stack, sizeof(std::complex<double>) * 4);
  
  int32_t y_nrow = 2;
  
  int32_t y_ncol = 2;
  
  Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
  
  Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> y_matrix = Eigen::Map<Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic>>(y_data, y_nrow, y_ncol);
  
  Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> ret_matrix = x_matrix * y_matrix;
  
  int32_t ret_length = ret_matrix.rows() * ret_matrix.cols();
  
  env->free_memory_block(env, stack, x_data);
  
  env->free_memory_block(env, stack, y_data);
  
  if (!(ret_length == 4)) {
    stack[0].ival = 0;
    return 0;
  }
  
  stack[0].ival = 1;
  
  return 0;
}

}
