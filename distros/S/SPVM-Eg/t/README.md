# Cotton

Cotton is a portable application example using SPVM::Eg.

# Required Modules Installation

  cpanm --installdeps .

# Executable File Generating

  # Compile Engine - development mode
  spvmcc -o t/.spvm_build/cotton -c t/cotton.config -I lib/SPVM -I t/lib/SPVM Cotton
  
  # Compile Engine - producetion mode
  spvmcc -o t/.spvm_build/cotton -c t/cotton.production.config -I lib/SPVM -I t/lib/SPVM Cotton

# Run Application

  t/.spvm_build/cotton
  
  # Compile and run application
  spvmcc -o t/.spvm_build/cotton -c t/cotton.config -I lib/SPVM -I t/lib/SPVM Cotton && t/.spvm_build/cotton
