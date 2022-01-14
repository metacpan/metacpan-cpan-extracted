#!/bin/bash
set -e
set -a

BUILD_DIR=$(cd $(dirname $0); pwd)/build
TOOLS_BUILD_DIR=$BUILD_DIR/kaldi/tools

if [ ! -d "$BUILD_DIR" ]; then mkdir -p "$BUILD_DIR"; fi
cd "$BUILD_DIR/"

if [ ! -d vosk-api ]; then
    git clone --single-branch https://github.com/alphacep/vosk-api
fi

if [ ! -d kaldi ]; then 
    git clone -b vosk --single-branch https://github.com/alphacep/kaldi
fi

cd "$TOOLS_BUILD_DIR"

if [ ! -d OpenBLAS ]; then 
    git clone -b v0.3.19 --single-branch https://github.com/xianyi/OpenBLAS
fi
if [ ! -d clapack ]; then 
    git clone -b v3.2.1  --single-branch https://github.com/alphacep/clapack 
fi

if [ ! -d openfst ]; then 
    git clone --single-branch https://github.com/alphacep/openfst openfst
fi

# This would be great, but we need/want the C version, not the Fortran version ...
#git clone --single-branch https://github.com/Reference-LAPACK/lapack

# Now, collect all C files to build a frankensteinian amalgamation?!

make -C OpenBLAS ONLY_CBLAS=1 DYNAMIC_ARCH=1 TARGET=NEHALEM USE_LOCKING=1 USE_THREAD=0 all
make -C OpenBLAS PREFIX=$(pwd)/OpenBLAS/install install

mkdir -p clapack/BUILD && cd clapack/BUILD && cmake .. && make -j $(nproc) || /bin/true
# the above fails due to some files in TESTING/ ?!
find . -name "*.a" | xargs cp -t ../../OpenBLAS/install/lib

cd $TOOLS_BUILD_DIR/openfst
autoreconf -i
CFLAGS="-g -O3" ./configure --prefix=$TOOLS_BUILD_DIR/openfst --enable-static --enable-shared --enable-far --enable-ngram-fsts --enable-lookahead-fsts --with-pic --disable-bin \
    && make -j $(nproc) && make install 

# Build the Kaldi stuff we need for vosk (?)
cd $BUILD_DIR/kaldi/src
./configure --mathlib=OPENBLAS_CLAPACK --shared --use-cuda=no 
sed -i 's:-msse -msse2:-msse -msse2:g' kaldi.mk 
sed -i 's: -O1 : -O3 :g' kaldi.mk
make -j $(nproc) online2 lm rnnlm 

cd $BUILD_DIR/vosk-api/src
KALDI_ROOT=$BUILD_DIR/kaldi OPENFST_ROOT=$TOOLS_BUILD_DIR/openfst OPENBLAS_ROOT=$TOOLS_BUILD_DIR/OpenBLAS/install make -j $(nproc)

