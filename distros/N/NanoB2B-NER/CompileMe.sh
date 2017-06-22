#!bin/bash

echo "---Recompiling NanoB2B---"
sudo -u milk perl Makefile.PL
sudo -u milk make
echo "DO SUDO MAKE INSTALL"
echo "---Compile finished!---"

