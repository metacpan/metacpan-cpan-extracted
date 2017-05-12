use Test::More tests => 1;
use Protocol::Modbus;
use Protocol::Modbus::Exception;
use Protocol::Modbus::RTU;
use Protocol::Modbus::Request;
use Protocol::Modbus::Response;
use Protocol::Modbus::TCP;
use Protocol::Modbus::Transaction;
use Protocol::Modbus::Transport;
## Avoid forced dependency on Device::SerialPort
## if you don't use it.
#use Protocol::Modbus::Transport::Serial;
use Protocol::Modbus::Transport::TCP;

ok(1);
