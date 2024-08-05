#include "spvm_native.h"

#include "Eigen/Core"
#include "Eigen/Dense"

#include <complex>

extern "C" {

int32_t SPVM__TestCase__Resource__Eigen__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  Eigen::MatrixXd X(3, 3);
  
  {
    std::complex<double> x_data[2] = {};
    
    int32_t x_nrow = 2;
    
    int32_t x_ncol = 2;
    
    std::complex<double> y_data[2] = {};
    
    int32_t y_nrow = 2;
    
    int32_t y_ncol = 2;
    
    Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> x_matrix = Eigen::Map<Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic>>(x_data, x_nrow, x_ncol);
    
    Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> y_matrix = Eigen::Map<Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic>>(y_data, y_nrow, y_ncol);
    
    Eigen::Matrix<std::complex<double>, Eigen::Dynamic, Eigen::Dynamic> ret_matrix = x_matrix * y_matrix;
  }
  
  stack[0].ival = 1;
  
  return 0;
}

}
