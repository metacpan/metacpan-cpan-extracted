use strict;
use warnings;

use Test::More;
use RPi::Const qw(:mcp23017_registers);

# MCP23017 registers

is MCP23017_IODIRA, 0x00, 'iodira';
is MCP23017_IODIRB, 0x01, 'iodirb';
is MCP23017_IPOLA, 0x02, 'ipola';
is MCP23017_IPOLB, 0x03, 'ipolb';
is MCP23017_GPINTENA, 0x04, 'gpintena';
is MCP23017_GPINTENB, 0x05, 'gpintenb';
is MCP23017_DEFVALA, 0x06, 'defvala';
is MCP23017_DEFVALB, 0x07, 'defvalb';
is MCP23017_INTCONA, 0x08, 'intcona';
is MCP23017_INTCONB, 0x09, 'intconb';
is MCP23017_IOCONA, 0x0a, 'iocona';
is MCP23017_IOCONB, 0x0b, 'ioconb';
is MCP23017_GPPUA, 0x0c, 'gppua';
is MCP23017_GPPUB, 0x0d, 'gppub';
is MCP23017_INTFA, 0x0e, 'intfa';
is MCP23017_INTFB, 0x0f, 'intfb';
is MCP23017_INTCAPA, 0x10, 'intcapa';
is MCP23017_INTCAPB, 0x11, 'intcapb';
is MCP23017_GPIOA, 0x12, 'gpioa';
is MCP23017_GPIOB, 0x13, 'gpiob';
is MCP23017_OLATA, 0x14, 'olata';
is MCP23017_OLATB, 0x15, 'olatb';
is MCP23017_INPUT, 1, 'input';
is MCP23017_OUTPUT, 0, 'output';

done_testing();
