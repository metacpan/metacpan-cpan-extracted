#!perl
use strict;
use warnings;
use Test::More tests => 48;
use Number::DataRate;

# Examples from
# http://en.wikipedia.org/wiki/List_of_device_bandwidths
# http://en.wikipedia.org/wiki/Data_rate_units

my $data_rate = Number::DataRate->new;

# TTY
# 0.045 kbit/s
is( $data_rate->to_bits_per_second('0.045 kbit/s'),  '45' );
is( $data_rate->to_bits_per_second('0.045 kb/s'),    '45' );
is( $data_rate->to_bits_per_second('0.045 kbitps'),  '45' );
is( $data_rate->to_bits_per_second('0.045 kbps'),    '45' );
is( $data_rate->to_bytes_per_second('0.045 kbit/s'), '5.625' );
is( $data_rate->to_bytes_per_second('0.045 kb/s'),   '5.625' );
is( $data_rate->to_bytes_per_second('0.045 kbitps'), '5.625' );
is( $data_rate->to_bytes_per_second('0.045 kbps'),   '5.625' );

is( $data_rate->to_bits_per_second('5.625Byte/s'),  '45' );
is( $data_rate->to_bits_per_second('5.625B/s'),     '45' );
is( $data_rate->to_bits_per_second('5.625Byteps'),  '45' );
is( $data_rate->to_bits_per_second('5.625Bps'),     '45' );
is( $data_rate->to_bytes_per_second('5.625Byte/s'), '5.625' );
is( $data_rate->to_bytes_per_second('5.625B/s'),    '5.625' );
is( $data_rate->to_bytes_per_second('5.625Byte/s'), '5.625' );
is( $data_rate->to_bytes_per_second('5.625Bps'),    '5.625' );

# 2400 baud modem
# 9.6 kbit/s
is( $data_rate->to_bits_per_second('9.6 kbit/s'),  '9600' );
is( $data_rate->to_bytes_per_second('9.6 kbit/s'), '1200' );

# GSM
# 14.4 kbit/s
is( $data_rate->to_bits_per_second('14.4 kbit/s'),  '14400' );
is( $data_rate->to_bytes_per_second('14.4 kbit/s'), '1800' );

# ISDN
# 64 kbit/s
is( $data_rate->to_bits_per_second('64 kbit/s'),  '64000' );
is( $data_rate->to_bytes_per_second('64 kbit/s'), '8000' );

# Bluetooth 1.1
# 1000 kbit/s
is( $data_rate->to_bits_per_second('1000 kbit/s'),  '1000000' );
is( $data_rate->to_bytes_per_second('1000 kbit/s'), '125000' );

# Bluetooth 2.0+EDR
# 3000 kbit/s
is( $data_rate->to_bits_per_second('3000 kbit/s'),  '3000000' );
is( $data_rate->to_bytes_per_second('3000 kbit/s'), '375000' );

# Ethernet (10base-X)
# 10 Mbit/s
is( $data_rate->to_bits_per_second('10 Mbit/s'),  '10000000' );
is( $data_rate->to_bytes_per_second('10 Mbit/s'), '1250000' );

# ADSL2+
# 24,576 kbit/s
is( $data_rate->to_bits_per_second('24,576 kbit/s'),  '24576000' );
is( $data_rate->to_bytes_per_second('24,576 kbit/s'), '3072000' );

# 802.11g OFDM 0.125
# 54.0 Mbit/s
is( $data_rate->to_bits_per_second('54.0 Mbit/s'),  '54000000' );
is( $data_rate->to_bytes_per_second('54.0 Mbit/s'), '6750000' );

# Fast Ethernet (100base-X)
# 100 Mbit/s
is( $data_rate->to_bits_per_second('100 Mbit/s'),  '100000000' );
is( $data_rate->to_bytes_per_second('100 Mbit/s'), '12500000' );

# 802.11n
# 248.0 Mbit/s
is( $data_rate->to_bits_per_second('248.0 Mbit/s'),   '248000000' );
is( $data_rate->to_bytes_per_second('1248.0 Mbit/s'), '156000000' );

# Gigabit Ethernet (1000base-X)
# 1000 Mbit/s
is( $data_rate->to_bits_per_second('1000 Mbit/s'),  '1000000000' );
is( $data_rate->to_bytes_per_second('1000 Mbit/s'), '125000000' );

# PC100 SDRAM
# 6.4 Gbit/s
is( $data_rate->to_bits_per_second('6.4 Gbit/s'),  '6400000000' );
is( $data_rate->to_bytes_per_second('6.4 Gbit/s'), '800000000' );

# 10 gigabit Ethernet (10Gbase-X)
# 10,000 Mbit/s
is( $data_rate->to_bits_per_second('10,000 Mbit/s'),  '10000000000' );
is( $data_rate->to_bytes_per_second('10,000 Mbit/s'), '1250000000' );

# PC2-5300 DDR2-SDRAM (dual channel)
# 84.8 Gbit/s
is( $data_rate->to_bits_per_second('84.8 Gbit/s'),  '84800000000' );
is( $data_rate->to_bytes_per_second('84.8 Gbit/s'), '10600000000' );

# 100 gigabit Ethernet (100Gbase-X)
# 100,000 Mbit/s
is( $data_rate->to_bits_per_second('100,000 Mbit/s'),  '100000000000' );
is( $data_rate->to_bytes_per_second('100,000 Mbit/s'), '12500000000' );

# SEA-ME-WE 4 submarine cable
# 1.28Tbit/s
is( $data_rate->to_bits_per_second('1.28Tbit/s'),  '1280000000000' );
is( $data_rate->to_bytes_per_second('1.28Tbit/s'), '160000000000' );
