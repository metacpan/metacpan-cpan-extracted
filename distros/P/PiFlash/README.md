# NAME

piflash - Raspberry Pi SD-flashing script with safety checks to avoid erasing the wrong device

# SYNOPSIS

    piflash [--verbose] input-file output-device

    piflash [--verbose] --SDsearch

# DESCRIPTION

This script flashes an SD card for a Raspberry Pi. It includes safety checks so that it can only erase and write to an SD card, not another device on the system. The safety checks are probably of most use to beginners. For more advanced users (like the author) it also has the convenience of flashing directly from the file formats downloadable from raspberrypi.org without extracting a .img file from a zip/gz/xz file.

- The optional parameter --verbose makes much more verbose status and error messages.  Use this when troubleshooting any problem or preparing program output to ask for help or report a bug.
- input-file is the path of the binary image file used as input for flashing the SD card. If it's a .img file then it will be flashed directly. If it's a gzip (.gz), xz (.xz) or zip (.zip) file then the .img file will be extracted from it to flash the SD card. It is not necessary to unpack the file if it's in one of these formats. This covers most of the images downloadable from the Raspberry Pi foundation's web site.
- output-file is the path to the block device where the SSD card is located. The device should not be mounted - if it ismounted the script will detect it and exit with an error. This operation will erase the SD card and write the new image from the input-file to it. (So make sure it's an SD card you're willing to have erased.)
- The --SDsearch parameter tells piflash to print a list of device names for SD cards available on the system and then exit. Do not specify an input file or output device when using this option - it will exit before they would be used.

## Safety Checks

The program makes a number of safety checks for you. Since the SD card flashing process may need root permissions, these are considered prudent precautions.

- The input file's format will be checked. If it ends in .img then it will be flashed directly as a binary image file. If it ends in .xz, .gzip or .zip, it will extract the binary image from the file. If the filename doesn't have a suffix, libmagic will be used to inspect the contents of the file (for "magic numbers") to determine its format.
- The output device must be a block device.
- If the output device is a mounted filesystem, it will refuse to erase it.
- If the output device is not an SD card, it will refuse to erase it.
Piflash has been tested with USB and PCI based SD card interfaces.

## Automated Flashing Procedure

Piflash automates the process of flashing an SD card from various Raspberry Pi OS images.

- For most disk images, either in a raw \*.img file, compressed in a \*.gz or \*.xz file, or included in a \*.zip archive, piflash recognizes the file format and extracts the disk image for flashing, eliminating the step of uncompressing or unarchiving it before it can be flashed to the SD.
- For zip archives, it checks if it contains the Raspberry Pi NOOBS (New Out Of the Box System), in which case it handles it differently. The steps it takes are similar to the instructions that one would have to follow manually.  It formats a new VFAT filesystem on the card. (FAT/VFAT is the only format recognized by the Raspberry Pi's simple boot loader.) Then it copies the contents of the zip archive into the card, automating the entire flashing process even for a NOOBS system, which previously didn't even have instructions to be done from Linux systems.

# INSTALLATION

The piflash script only works on Linux systems. It depends on features of the Linux kernel to look up whether the output device is an SD card and other information about it. It has been tested so far on Fedora 25, and some experimentation with Ubuntu 16.04 (in a virtual machine) to get the kernel parameters right for a USB SD card reader.

## System Dependencies

Some programs and libraries must be installed on the system for piflash to work - most packages have such dependencies.

On RPM-based Linux systems (Red Hat, Fedora, CentOS) the following command, run as root, will install the dependencies.

        dnf install coreutils util-linux sudo perl file-libs perl-File-LibMagic perl-IO gzip unzip xz e2fsprogs dosfstools

On Deb-based Linux systems (Debian, Ubuntu, Raspbian) the following command, run as root, will install the dependencies.

        apt-get install coreutils util-linux klibc-utils sudo perl-base libmagic1 libfile-libmagic-perl gzip xz-utils e2fsprogs dosfstools

On source-based or other Linux distributions, make sure the following are installed:

- programs:
blockdev, dd, echo, gunzip, lsblk, mkdir, mkfs.vfat, mount, perl, sfdisk, sudo, sync, true, umount, unzip, xz
- libraries:
libmagic/file-libs, File::LibMagic (perl)

## Piflash script

This is the Perl distribution PiFlash.
 
Installing PiFlash is straightforward.
 
### Installation with cpanm
 
If you have cpanm, you only need one line:
 
    % cpanm PiFlash
 
If it does not have permission to install modules to the current perl, cpanm
will automatically set up and install to a local::lib in your home directory.
See the local::lib documentation (https://metacpan.org/pod/local::lib) for
details on enabling it in your environment.
 
### Installing with the CPAN shell
 
Alternatively, if your CPAN shell is set up, you should just be able to do:
 
    % cpan PiFlash
 
### Manual installation
 
As a last resort, you can manually install it. Download the tarball, untar it,
install configure prerequisites (see below), then build it:
 
    % perl Makefile.PL
    % make && make test
 
Then install it:
 
    % make install
 
On Windows platforms, you should use `dmake` or `nmake`, instead of `make`.
 
If your perl is system-managed, you can create a local::lib in your home
directory to install modules to. For details, see the local::lib documentation:
https://metacpan.org/pod/local::lib
 
The prerequisites of this distribution will also have to be installed manually. The
prerequisites are listed in one of the files: `MYMETA.yml` or `MYMETA.json` generated
by running the manual build process described above.
 
### Configure Prerequisites
 
This distribution requires other modules to be installed before this
distribution's installer can be run.  They can be found under the
"configure_requires" key of META.yml or the
"{prereqs}{configure}{requires}" key of META.json.
 
### Documentation
 
PiFlash documentation is available as POD.
You can run `perldoc` from a shell to read the documentation:
 
    % perldoc piflash
 
For more information on installing Perl modules via CPAN, please see:
https://www.cpan.org/modules/INSTALL.html

## Bug reporting

Report bugs via GitHub at https://github.com/ikluft/piflash/issues - this location may eventually change
if piflash becomes popular enough to warrant having its own source code repository.

When reporting a bug, please include the full output using the --verbose option. That will include all of the
program's state information, which will help understand the bigger picture what was happening on your system.
Feel free to remove information you don't want to post in a publicly-visible bug report - though it's helpful
to add "\[redacted\]" where you removed something so it's clear what happened.

For any SD card reader hardware which piflash fails to recognize (and therefore refuses to write to),
please describe the hardware as best you can including name, product number, bus (USB, PCI, etc),
any known controller chips.
