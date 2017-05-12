#include "perl_gssdp.h"

MODULE = Net::SSDP  PACKAGE = Net::SSDP

PROTOTYPES: DISABLE

BOOT:
#include "register.xsh"
#include "boot.xsh"
