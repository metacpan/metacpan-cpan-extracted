use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Printer::Thermal;

#Serial Printer
$printer_serial = Printer::Thermal->new(serial_device_path => '/dev/ttyS0');

$printer_serial->test();

#usb printer
#$printer_usb = Printer::Thermal->new(usb_device_path => '/dev/usb/lp0');

#$printer_usb->test();

$printer_usb_sinocan = Printer::Thermal->new(usb_device_path => '/dev/ttyACM0');

$printer_usb_sinocan->test();

#ethernet printer
$printer_ethernet = Printer::Thermal->new(device_ip => '192.168.168.80', device_port => '9100');

$printer_ethernet->test();

