# Name

*piflash* - Raspberry Pi SD-flashing script with safety checks to avoid erasing the wrong device

# Synopsis

    piflash [--verbose] [--resize] [--config conf-file] input-file output-device

    piflash [--verbose] --sdsearch

    piflash --version

# Featured article

<a href="https://opensource.com/article/19/3/piflash">
<img src="doc/raspberrypi_board_vector_red.png" height=176 width="312" align="left">
<b>"Getting started with PiFlash: Booting your Raspberry Pi on Linux"</b>
</a>
<br>
by Ian Kluft at OpenSource.com
<br>
March 15, 2019
<br clear=all>

# Description

This script writes (or "flashes") an SD card for a Raspberry Pi. It includes safety checks so that it can only erase and write to an SD card, not another device on the system. The safety checks are probably of most use to beginners. For more advanced users (like the author) it also has the convenience of flashing directly from the file formats downloadable from raspberrypi.org without extracting a .img file from a zip/gz/xz file.

## User documentation

* [PiFlash program usage and installation](https://metacpan.org/pod/distribution/PiFlash/bin/piflash)
* [Online resources for PiFlash](https://github.com/ikluft/piflash/blob/master/doc/resources.md)
  * [Where to download Raspberry Pi bootable images](https://github.com/ikluft/piflash/blob/master/doc/resources.md#where-to-download-raspberry-pi-bootable-images)
  * [Presentations and Articles](https://github.com/ikluft/piflash/blob/master/doc/resources.md#presentations-and-articles)
* [PiFlash release on CPAN](https://metacpan.org/release/PiFlash)
* [PiFlash source code on GitHub](https://github.com/ikluft/piflash)

PiFlash documentation is available as POD.
Once installed, you can run `perldoc` from a shell to read the documentation:
 
    % perldoc piflash
 
## Developer documentation

* [PiFlash](https://metacpan.org/pod/PiFlash) - Raspberry Pi SD-flashing script with safety checks to avoid erasing the wrong device
* [PiFlash::Command](https://metacpan.org/pod/PiFlash::Command) - process/command running utilities for piflash
* [PiFlash::Hook](https://metacpan.org/pod/PiFlash::Hook) - named dispatch/hook library for PiFlash
* [PiFlash::Inspector](https://metacpan.org/pod/PiFlash::Inspector) - PiFlash functions to inspect Linux system devices to flash an SD card for Raspberry Pi
* [PiFlash::MediaWriter](https://metacpan.org/pod/PiFlash::MediaWriter) - write to Raspberry Pi SD card installation with scriptable customization
* [PiFlash::Object](https://metacpan.org/pod/PiFlash::Object) - object functions for PiFlash classes
* [PiFlash::Plugin](https://metacpan.org/pod/PiFlash::Plugin) - plugin extension interface for PiFlash
* [PiFlash::State](https://metacpan.org/pod/PiFlash::State) - PiFlash::State class to store configuration, device info and program state

## Participation in PiFlash

See the [Contributing to PiFlash](CONTRIBUTING.md) docs.

* [Code of Conduct](CONTRIBUTING.md#code-of-conduct)
* [Submitting an issue](CONTRIBUTING.md#submitting-an-issue)
* [Submitting a Pull Request](CONTRIBUTING.md#submitting-a-pull-request)

When reporting a bug, please include the full output using the --verbose option. That will include all of the
program's state information, which will help understand the bigger picture what was happening on your system.
Feel free to remove information you don't want to post in a publicly-visible bug report - though it's helpful
to add "[redacted]" where you removed something so it's clear what happened.

For any SD card reader hardware which piflash fails to recognize (and therefore refuses to write to),
please describe the hardware as best you can including name, product number, bus (USB, PCI, etc),
any known controller chips.
