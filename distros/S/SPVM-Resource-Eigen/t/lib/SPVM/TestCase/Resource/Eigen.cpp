#include "spvm_native.h"

#include "Eigen/Core"
#include "Eigen/Dense"

extern "C" {

int32_t SPVM__TestCase__Resource__Eigen__test(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  Eigen::MatrixXd X(3, 3);
  
  stack[0].ival = 1;
  
  return 0;
}

}
