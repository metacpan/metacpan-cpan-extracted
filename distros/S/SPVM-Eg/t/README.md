# Engine

Engine is a portable application example using SPVM::Eg.

# Required Modules Installation

  cpanm --installdeps .

# Executable File Generating

  # Compile Engine - development mode
  spvmcc -o t/.spvm_build/spvm-engine -c t/spvm-engine.config -I lib/SPVM -I t/lib/SPVM Engine
  
  # Compile Engine - producetion mode
  spvmcc -o t/.spvm_build/spvm-engine -c t/spvm-engine.production.config -I lib/SPVM -I t/lib/SPVM Engine

# Run Application

  t/.spvm_build/spvm-engine
  
  # Compile and run application
  spvmcc -o t/.spvm_build/spvm-engine -c t/spvm-engine.config -I lib/SPVM -I t/lib/SPVM Engine && t/.spvm_build/spvm-engine
