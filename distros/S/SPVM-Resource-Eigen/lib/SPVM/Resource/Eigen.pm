package SPVM::Resource::Eigen;

our $VERSION = "0.002";

1;

=head1 Name

SPVM::Resource::Eigen - Resource for C++ Eigen library

=head1 Description

Resource::Eigen in L<SPVM> is a L<resouce|SPVM::Document::Resource> for L<C++ Eigen library|https://eigen.tuxfamily.org/index.php>.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_cpp17(file => __FILE__);
  
  $config->use_resource('Resource::Eigen');
  
  $config;

MyClass.cpp:

  #include "spvm_native.h"
  
  #include "Eigen/Core"
  #include "Eigen/Dense"
  
  extern "C" {
  
  int32_t SPVM__MyClass__test(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    Eigen::MatrixXd X(3, 3);
    
    return 0;
  }
  
  }
  
=head1 Original Product

L<Eigen|https://eigen.tuxfamily.org/index.php>

=head1 Original Product Version

3.4.0

=head1 Language

C++

=head1 Language Specification

C++17

=head1 Header Files

  Eigen/Cholesky
  Eigen/CholmodSupport
  Eigen/Core
  Eigen/Dense
  Eigen/Eigen
  Eigen/Eigenvalues
  Eigen/Geometry
  Eigen/Householder
  Eigen/IterativeLinearSolvers
  Eigen/Jacobi
  Eigen/KLUSupport
  Eigen/LU
  Eigen/MetisSupport
  Eigen/OrderingMethods
  Eigen/PardisoSupport
  Eigen/PaStiXSupport
  Eigen/QR
  Eigen/QtAlignedMalloc
  Eigen/Sparse
  Eigen/SparseCholesky
  Eigen/SparseCore
  Eigen/SparseLU
  Eigen/SparseQR
  Eigen/SPQRSupport
  Eigen/StdDeque
  Eigen/StdList
  Eigen/StdVector
  Eigen/SuperLUSupport
  Eigen/SVD
  Eigen/UmfPackSupport

=head1 How to Create Resource

=head2 Donwload

  mkdir -p original.tmp
  git clone https://gitlab.com/libeigen/eigen.git original.tmp/eigen
  git -C original.tmp/eigen checkout tags/3.4.0 -b branch_3.4.0
  git -C original.tmp/eigen branch

=head2 Extracting Header Files

Header files of C<Eigen> and its dependent source files are copied into the C<include> directory by the following way.

  rsync -av original.tmp/eigen/Eigen lib/SPVM/Resource/Eigen.native/include/

=head1 Repository

L<SPVM::Resource::Eigen - Github|https://github.com/yuki-kimoto/SPVM-Resource-Eigen>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

