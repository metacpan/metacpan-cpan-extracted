#!perl
use Test::More tests => 11;

use_ok('Parse::SpectrumDirect::RadioFrequency');

my $p = Parse::SpectrumDirect::RadioFrequency->new();
isa_ok($p, 'Parse::SpectrumDirect::RadioFrequency');

# Some failures
is($p->parse(undef),         undef, 'cannot parse undef');
is($p->parse(''),            undef, 'cannot parse empty string');
is($p->parse('adsfasdfasd'), undef, 'cannot parse gobbledygook');

# some success
my $raw = do { local $/; open(FH, '<t/data/ontario.txt'); <FH> };
ok($raw,            'Have some data');
ok($p->parse($raw), '->parse() worked on it');

my $expected_legend = [ {
		'len'   => 14,
		'name'  => 'Tx Frequency (MHz)',
		'start' => 0,
		'units' => 'MHz',
		'key'   => 'Tx_Frequency'
	},
	{
		'len'   => 14,
		'name'  => 'Rx Frequency (MHz)',
		'start' => 15,
		'units' => 'MHz',
		'key'   => 'Rx_Frequency'
	},
	{
		'len'   => 11,
		'name'  => 'Necessary Bandwidth-1 (kHz)',
		'start' => 30,
		'units' => 'kHz',
		'key'   => 'Necessary_Bandwidth-1'
	},
	{
		'len'   => 5,
		'name'  => 'Class of Emission-1',
		'start' => 42,
		'units' => undef,
		'key'   => 'Class_of_Emission-1'
	},
	{
		'len'   => 2,
		'name'  => 'ITU Class of Station-1',
		'start' => 48,
		'units' => undef,
		'key'   => 'ITU_Class_of_Station-1'
	},
	{
		'len'   => 2,
		'name'  => 'ITU Class of Station-2',
		'start' => 51,
		'units' => undef,
		'key'   => 'ITU_Class_of_Station-2'
	},
	{
		'len'   => 10,
		'name'  => 'Radio Model Code',
		'start' => 54,
		'units' => undef,
		'key'   => 'Radio_Model_Code'
	},
	{
		'len'   => 1,
		'name'  => 'Conformity to Frequency Plan',
		'start' => 65,
		'units' => undef,
		'key'   => 'Conformity_to_Frequency_Plan'
	},
	{
		'len'   => 1,
		'name'  => 'Frequency Status',
		'start' => 67,
		'units' => undef,
		'key'   => 'Frequency_Status'
	},
	{
		'len'   => 11,
		'name'  => 'Frequency Record ID',
		'start' => 69,
		'units' => undef,
		'key'   => 'Frequency_Record_ID'
	},
	{
		'len'   => 6,
		'name'  => 'Latitude (ddmmss)',
		'start' => 81,
		'units' => 'decimal degrees',
		'key'   => 'Latitude'
	},
	{
		'len'   => 7,
		'name'  => 'Longitude (dddmmss)',
		'start' => 88,
		'units' => 'decimal degrees',
		'key'   => 'Longitude'
	},
	{
		'len'   => 35,
		'name'  => 'Station Location',
		'start' => 96,
		'units' => undef,
		'key'   => 'Station_Location'
	},
	{
		'len'   => 5,
		'name'  => 'Site Elevation (m)',
		'start' => 132,
		'units' => 'm',
		'key'   => 'Site_Elevation'
	},
	{
		'len'   => 4,
		'name'  => 'Antenna Structure Height AGL (m)',
		'start' => 138,
		'units' => 'm',
		'key'   => 'Antenna_Structure_Height_AGL'
	},
	{
		'len'   => 1,
		'name'  => 'Transportable Flag',
		'start' => 143,
		'units' => undef,
		'key'   => 'Transportable_Flag'
	},
	{
		'len'   => 5,
		'name'  => 'Transportable Radius (km)',
		'start' => 145,
		'units' => 'km',
		'key'   => 'Transportable_Radius'
	},
	{
		'len'   => 1,
		'name'  => 'Mobile to Mobile Flag',
		'start' => 151,
		'units' => undef,
		'key'   => 'Mobile_to_Mobile_Flag'
	},
	{
		'len'   => 4,
		'name'  => 'Mobile Radius of Operation (km)',
		'start' => 153,
		'units' => 'km',
		'key'   => 'Mobile_Radius_of_Operation'
	},
	{
		'len'   => 4,
		'name'  => 'Tx Antenna Pattern Code',
		'start' => 158,
		'units' => undef,
		'key'   => 'Tx_Antenna_Pattern_Code'
	},
	{
		'len'   => 2,
		'name'  => 'Tx Channel Capacity Code',
		'start' => 163,
		'units' => undef,
		'key'   => 'Tx_Channel_Capacity_Code'
	},
	{
		'len'   => 5,
		'name'  => 'Tx Antenna Gain (dBi > 960 MHz, dBd < 960 MHz)',
		'start' => 166,
		'units' => 'dBi > 960 MHz, dBd < 960 MHz',
		'key'   => 'Tx_Antenna_Gain'
	},
	{
		'len'   => 5,
		'name'  => 'Tx Total Losses (dB)',
		'start' => 172,
		'units' => 'dB',
		'key'   => 'Tx_Total_Losses'
	},
	{
		'len'   => 1,
		'name'  => 'Tx Antenna Polarization Code',
		'start' => 178,
		'units' => undef,
		'key'   => 'Tx_Antenna_Polarization_Code'
	},
	{
		'len'   => 3,
		'name'  => 'Tx Spectrum Signature Code',
		'start' => 180,
		'units' => undef,
		'key'   => 'Tx_Spectrum_Signature_Code'
	},
	{
		'len'   => 6,
		'name'  => 'Tx Antenna Azimuth (deg)',
		'start' => 184,
		'units' => 'deg',
		'key'   => 'Tx_Antenna_Azimuth'
	},
	{
		'len'   => 5,
		'name'  => 'Tx Power (dBW)',
		'start' => 191,
		'units' => 'dBW',
		'key'   => 'Tx_Power'
	},
	{
		'len'   => 7,
		'name'  => 'Tx Antenna Vertical Elevation Angle (deg)',
		'start' => 197,
		'units' => 'deg',
		'key'   => 'Tx_Antenna_Vertical_Elevation_Angle'
	},
	{
		'len'   => 5,
		'name'  => 'Tx Effective Radiated Power (ERP) (dBW)',
		'start' => 205,
		'units' => 'ERP) (dBW',
		'key'   => 'Tx_Effective_Radiated_Power'
	},
	{
		'len'   => 4,
		'name'  => 'Tx Antenna Height Above Ground Level (m)',
		'start' => 211,
		'units' => 'm',
		'key'   => 'Tx_Antenna_Height_Above_Ground_Level'
	},
	{
		'len'   => 6,
		'name'  => 'Tx Antenna Beamwidth (deg)',
		'start' => 216,
		'units' => 'deg',
		'key'   => 'Tx_Antenna_Beamwidth'
	},
	{
		'len'   => 4,
		'name'  => 'Rx Antenna Pattern Code',
		'start' => 223,
		'units' => undef,
		'key'   => 'Rx_Antenna_Pattern_Code'
	},
	{
		'len'   => 2,
		'name'  => 'Rx Channel Capacity Code',
		'start' => 228,
		'units' => undef,
		'key'   => 'Rx_Channel_Capacity_Code'
	},
	{
		'len'   => 5,
		'name'  => 'Rx Antenna Gain (dBi > 960 MHz, dBd < 960 MHz)',
		'start' => 231,
		'units' => 'dBi > 960 MHz, dBd < 960 MHz',
		'key'   => 'Rx_Antenna_Gain'
	},
	{
		'len'   => 5,
		'name'  => 'Rx Total Losses (dB)',
		'start' => 237,
		'units' => 'dB',
		'key'   => 'Rx_Total_Losses'
	},
	{
		'len'   => 1,
		'name'  => 'Rx Antenna Polarization Code',
		'start' => 243,
		'units' => undef,
		'key'   => 'Rx_Antenna_Polarization_Code'
	},
	{
		'len'   => 3,
		'name'  => 'Rx Spectrum Signature Code',
		'start' => 245,
		'units' => undef,
		'key'   => 'Rx_Spectrum_Signature_Code'
	},
	{
		'len'   => 6,
		'name'  => 'Rx Antenna Azimuth (deg)',
		'start' => 249,
		'units' => 'deg',
		'key'   => 'Rx_Antenna_Azimuth'
	},
	{
		'len'   => 6,
		'name'  => 'Rx Threshold Level for BER 10E-3 (dBW)',
		'start' => 256,
		'units' => 'dBW',
		'key'   => 'Rx_Threshold_Level_for_BER_10E-3'
	},
	{
		'len'   => 7,
		'name'  => 'Rx Antenna Vertical Elevation Angle (deg)',
		'start' => 263,
		'units' => 'deg',
		'key'   => 'Rx_Antenna_Vertical_Elevation_Angle'
	},
	{
		'len'   => 6,
		'name'  => 'Unfaded Received Signal Level (dBW)',
		'start' => 271,
		'units' => 'dBW',
		'key'   => 'Unfaded_Received_Signal_Level'
	},
	{
		'len'   => 4,
		'name'  => 'Rx Antenna Height Above Ground Level (m)',
		'start' => 278,
		'units' => 'm',
		'key'   => 'Rx_Antenna_Height_Above_Ground_Level'
	},
	{
		'len'   => 6,
		'name'  => 'Rx Antenna Beamwidth (deg)',
		'start' => 283,
		'units' => 'deg',
		'key'   => 'Rx_Antenna_Beamwidth'
	},
	{
		'len'   => 10,
		'name'  => 'Link Call Sign',
		'start' => 290,
		'units' => undef,
		'key'   => 'Link_Call_Sign'
	},
	{
		'len'   => 7,
		'name'  => 'Link Licence Number',
		'start' => 301,
		'units' => undef,
		'key'   => 'Link_Licence_Number'
	},
	{
		'len'   => 25,
		'name'  => 'Link Station Location',
		'start' => 309,
		'units' => undef,
		'key'   => 'Link_Station_Location'
	},
	{
		'len'   => 7,
		'name'  => 'Azimuth (deg)',
		'start' => 335,
		'units' => 'deg',
		'key'   => 'Azimuth'
	},
	{
		'len'   => 9,
		'name'  => 'Distance (km)',
		'start' => 343,
		'units' => 'km',
		'key'   => 'Distance'
	},
	{
		'len'   => 35,
		'name'  => 'Licensee Name Part 1',
		'start' => 353,
		'units' => undef,
		'key'   => 'Licensee_Name_Part_1'
	},
	{
		'len'   => 35,
		'name'  => 'Licensee Name Part 2',
		'start' => 389,
		'units' => undef,
		'key'   => 'Licensee_Name_Part_2'
	},
	{
		'len'   => 80,
		'name'  => 'Company Address',
		'start' => 425,
		'units' => undef,
		'key'   => 'Company_Address'
	},
	{
		'len'   => 12,
		'name'  => 'Company Telephone No.',
		'start' => 506,
		'units' => undef,
		'key'   => 'Company_Telephone_No.'
	},
	{
		'len'   => 9,
		'name'  => 'Company Code',
		'start' => 519,
		'units' => undef,
		'key'   => 'Company_Code'
	},
	{
		'len'   => 7,
		'name'  => 'Licence Number',
		'start' => 529,
		'units' => undef,
		'key'   => 'Licence_Number'
	},
	{
		'len'   => 10,
		'name'  => 'Call Sign',
		'start' => 537,
		'units' => undef,
		'key'   => 'Call_Sign'
	},
	{
		'len'   => 1,
		'name'  => 'Licence Type',
		'start' => 548,
		'units' => undef,
		'key'   => 'Licence_Type'
	},
	{
		'len'   => 10,
		'name'  => 'Frequency Authorization Date',
		'start' => 550,
		'units' => undef,
		'key'   => 'Frequency_Authorization_Date'
	},
	{
		'len'   => 2,
		'name'  => 'Processing Office',
		'start' => 561,
		'units' => undef,
		'key'   => 'Processing_Office'
	},
	{
		'len'   => 1,
		'name'  => 'Noise Environment Code',
		'start' => 564,
		'units' => undef,
		'key'   => 'Noise_Environment_Code'
	},
	{
		'len'   => 10,
		'name'  => 'Tx Antenna Model Number',
		'start' => 566,
		'units' => undef,
		'key'   => 'Tx_Antenna_Model_Number'
	},
	{
		'len'   => 10,
		'name'  => 'Rx Antenna Model Number',
		'start' => 577,
		'units' => undef,
		'key'   => 'Rx_Antenna_Model_Number'
	},
	{
		'len'   => 1,
		'name'  => 'Metropolitan Area Flag',
		'start' => 588,
		'units' => undef,
		'key'   => 'Metropolitan_Area_Flag'
	},
	{
		'len'   => 1,
		'name'  => 'Congestion Flag',
		'start' => 590,
		'units' => undef,
		'key'   => 'Congestion_Flag'
	},
	{
		'len'   => 1,
		'name'  => 'Fee Table Code 1',
		'start' => 592,
		'units' => undef,
		'key'   => 'Fee_Table_Code_1'
	},
	{
		'len'   => 1,
		'name'  => 'Fee Table Code 2',
		'start' => 594,
		'units' => undef,
		'key'   => 'Fee_Table_Code_2'
	},
	{
		'len'   => 22,
		'name'  => 'Holder Name',
		'start' => 596,
		'units' => undef,
		'key'   => 'Holder_Name'
	},
	{
		'len'   => 5,
		'name'  => 'Number of Identical Mobile Stations',
		'start' => 619,
		'units' => undef,
		'key'   => 'Number_of_Identical_Mobile_Stations'
	},
	{
		'len'   => 1,
		'name'  => 'International Coordination Required Flag',
		'start' => 625,
		'units' => undef,
		'key'   => 'International_Coordination_Required_Flag'
	},
	{
		'len'   => 7,
		'name'  => 'International Coordination Serial Number',
		'start' => 627,
		'units' => undef,
		'key'   => 'International_Coordination_Serial_Number'
	}
];
is_deeply($p->get_legend(), $expected_legend, 'Legend parses correctly');

my @partial_expected_stations = ({
		'Licensee_Name_Part_2'                     => undef,
		'Transportable_Flag'                       => undef,
		'Company_Telephone_No.'                    => undef,
		'ITU_Class_of_Station-1'                   => undef,
		'Site_Elevation'                           => undef,
		'Tx_Antenna_Azimuth'                       => undef,
		'Number_of_Identical_Mobile_Stations'      => undef,
		'Frequency_Record_ID'                      => undef,
		'Licence_Type'                             => undef,
		'Mobile_to_Mobile_Flag'                    => undef,
		'Link_Station_Location'                    => undef,
		'Frequency_Authorization_Date'             => undef,
		'Latitude'                                 => '0',
		'Company_Code'                             => undef,
		'Rx_Total_Losses'                          => undef,
		'Metropolitan_Area_Flag'                   => undef,
		'Rx_Frequency'                             => undef,
		'Tx_Antenna_Height_Above_Ground_Level'     => undef,
		'Company_Address'                          => undef,
		'Rx_Channel_Capacity_Code'                 => undef,
		'Tx_Antenna_Pattern_Code'                  => undef,
		'Distance'                                 => undef,
		'Rx_Antenna_Gain'                          => undef,
		'Mobile_Radius_of_Operation'               => undef,
		'Licence_Number'                           => undef,
		'Processing_Office'                        => undef,
		'Unfaded_Received_Signal_Level'            => undef,
		'Licensee_Name_Part_1'                     => undef,
		'Rx_Antenna_Beamwidth'                     => undef,
		'Call_Sign'                                => undef,
		'ITU_Class_of_Station-2'                   => undef,
		'Rx_Antenna_Vertical_Elevation_Angle'      => undef,
		'Radio_Model_Code'                         => undef,
		'Rx_Spectrum_Signature_Code'               => undef,
		'Tx_Spectrum_Signature_Code'               => undef,
		'International_Coordination_Required_Flag' => undef,
		'Rx_Antenna_Model_Number'                  => undef,
		'Tx_Antenna_Polarization_Code'             => undef,
		'Tx_Antenna_Vertical_Elevation_Angle'      => undef,
		'Necessary_Bandwidth-1'                    => undef,
		'Rx_Antenna_Height_Above_Ground_Level'     => undef,
		'Conformity_to_Frequency_Plan'             => undef,
		'Rx_Threshold_Level_for_BER_10E-3'         => undef,
		'Fee_Table_Code_2'                         => undef,
		'Station_Location'                         => undef,
		'Rx_Antenna_Pattern_Code'                  => undef,
		'Congestion_Flag'                          => undef,
		'Tx_Channel_Capacity_Code'                 => undef,
		'Tx_Frequency'                             => undef,
		'Longitude'                                => 0,
		'International_Coordination_Serial_Number' => undef,
		'Fee_Table_Code_1'                         => undef,
		'Tx_Power'                                 => undef,
		'Antenna_Structure_Height_AGL'             => undef,
		'Azimuth'                                  => undef,
		'Tx_Total_Losses'                          => undef,
		'Tx_Antenna_Model_Number'                  => undef,
		'Link_Call_Sign'                           => undef,
		'Class_of_Emission-1'                      => undef,
		'Link_Licence_Number'                      => undef,
		'Noise_Environment_Code'                   => undef,
		'Holder_Name'                              => undef,
		'Tx_Antenna_Gain'                          => undef,
		'Rx_Antenna_Azimuth'                       => undef,
		'Frequency_Status'                         => undef,
		'Tx_Antenna_Beamwidth'                     => undef,
		'Rx_Antenna_Polarization_Code'             => undef,
		'Tx_Effective_Radiated_Power'              => undef,
		'Transportable_Radius'                     => undef
	},
	{
		'Licensee_Name_Part_2'                     => 'Attn: Ahmed Derini',
		'Transportable_Flag'                       => '2',
		'Company_Telephone_No.'                    => '416-637-3525',
		'ITU_Class_of_Station-1'                   => 'FX',
		'Site_Elevation'                           => '106',
		'Tx_Antenna_Azimuth'                       => '263.0',
		'Number_of_Identical_Mobile_Stations'      => '',
		'Frequency_Record_ID'                      => '41062825001',
		'Licence_Type'                             => '1',
		'Mobile_to_Mobile_Flag'                    => '',
		'Link_Station_Location'                    => 'OTTAWA ON',
		'Frequency_Authorization_Date'             => '',
		'Latitude'                                 => '45.355833',
		'Company_Code'                             => '090045300',
		'Rx_Total_Losses'                          => '0.0',
		'Metropolitan_Area_Flag'                   => '1',
		'Rx_Frequency'                             => '15045.000000',
		'Tx_Antenna_Height_Above_Ground_Level'     => '41',
		'Company_Address'                          => '207 Queens Quay West, P.O. Box 114, Toronto ON, M5J1A7',
		'Rx_Channel_Capacity_Code'                 => 'I',
		'Tx_Antenna_Pattern_Code'                  => '5399',
		'Distance'                                 => '',
		'Rx_Antenna_Gain'                          => '39.7',
		'Mobile_Radius_of_Operation'               => '',
		'Licence_Number'                           => '5093262',
		'Processing_Office'                        => '41',
		'Unfaded_Received_Signal_Level'            => '-74.0',
		'Licensee_Name_Part_1'                     => 'Globalive Wireless Management Corp.',
		'Rx_Antenna_Beamwidth'                     => '',
		'Call_Sign'                                => 'CHK958',
		'ITU_Class_of_Station-2'                   => '',
		'Rx_Antenna_Vertical_Elevation_Angle'      => '-0.200',
		'Radio_Model_Code'                         => '15HC20HIC1',
		'Rx_Spectrum_Signature_Code'               => '540',
		'Tx_Spectrum_Signature_Code'               => '540',
		'International_Coordination_Required_Flag' => '0',
		'Rx_Antenna_Model_Number'                  => 'ANT15G2.5C',
		'Tx_Antenna_Polarization_Code'             => 'B',
		'Tx_Antenna_Vertical_Elevation_Angle'      => '-0.200',
		'Necessary_Bandwidth-1'                    => '20000.00',
		'Rx_Antenna_Height_Above_Ground_Level'     => '41',
		'Conformity_to_Frequency_Plan'             => 'A',
		'Rx_Threshold_Level_for_BER_10E-3'         => '-105.0',
		'Fee_Table_Code_2'                         => '',
		'Station_Location'                         => 'OTTAWA (1339 MEADOWLANDS) ON',
		'Rx_Antenna_Pattern_Code'                  => '5399',
		'Congestion_Flag'                          => 'B',
		'Tx_Channel_Capacity_Code'                 => 'I',
		'Tx_Frequency'                             => '14570.000000',
		'Longitude'                                => '-75.729167',
		'International_Coordination_Serial_Number' => '',
		'Fee_Table_Code_1'                         => 'E',
		'Tx_Power'                                 => '-9.5',
		'Antenna_Structure_Height_AGL'             => '41',
		'Azimuth'                                  => '',
		'Tx_Total_Losses'                          => '0.0',
		'Tx_Antenna_Model_Number'                  => 'ANT15G2.5C',
		'Link_Call_Sign'                           => 'CHK980',
		'Class_of_Emission-1'                      => 'G7WET',
		'Link_Licence_Number'                      => '5093524',
		'Noise_Environment_Code'                   => '',
		'Holder_Name'                              => '',
		'Tx_Antenna_Gain'                          => '39.7',
		'Rx_Antenna_Azimuth'                       => '263.0',
		'Frequency_Status'                         => '0',
		'Tx_Antenna_Beamwidth'                     => '',
		'Rx_Antenna_Polarization_Code'             => 'B',
		'Tx_Effective_Radiated_Power'              => '30.2',
		'Transportable_Radius'                     => ''
	},
	{
		'Licensee_Name_Part_2'                     => 'Attn: Ahmed Derini',
		'Transportable_Flag'                       => '2',
		'Company_Telephone_No.'                    => '416-637-3525',
		'ITU_Class_of_Station-1'                   => '',
		'Site_Elevation'                           => '',
		'Tx_Antenna_Azimuth'                       => '',
		'Number_of_Identical_Mobile_Stations'      => '',
		'Frequency_Record_ID'                      => '41062198001',
		'Licence_Type'                             => '1',
		'Mobile_to_Mobile_Flag'                    => '',
		'Link_Station_Location'                    => '',
		'Frequency_Authorization_Date'             => '2009-09-01',
		'Latitude'                                 => '0',
		'Company_Code'                             => '090045300',
		'Rx_Total_Losses'                          => '',
		'Metropolitan_Area_Flag'                   => '2',
		'Rx_Frequency'                             => '39900.000000',
		'Tx_Antenna_Height_Above_Ground_Level'     => '',
		'Company_Address'                          => '207 Queens Quay West, P.O. Box 114, Toronto ON, M5J1A7',
		'Rx_Channel_Capacity_Code'                 => '01',
		'Tx_Antenna_Pattern_Code'                  => '',
		'Distance'                                 => '',
		'Rx_Antenna_Gain'                          => '',
		'Mobile_Radius_of_Operation'               => '',
		'Licence_Number'                           => '5089668',
		'Processing_Office'                        => '41',
		'Unfaded_Received_Signal_Level'            => '',
		'Licensee_Name_Part_1'                     => 'Globalive Wireless Management Corp.',
		'Rx_Antenna_Beamwidth'                     => '',
		'Call_Sign'                                => '',
		'ITU_Class_of_Station-2'                   => '',
		'Rx_Antenna_Vertical_Elevation_Angle'      => '',
		'Radio_Model_Code'                         => '',
		'Rx_Spectrum_Signature_Code'               => '',
		'Tx_Spectrum_Signature_Code'               => '',
		'International_Coordination_Required_Flag' => '0',
		'Rx_Antenna_Model_Number'                  => '',
		'Tx_Antenna_Polarization_Code'             => '',
		'Tx_Antenna_Vertical_Elevation_Angle'      => '',
		'Necessary_Bandwidth-1'                    => '',
		'Rx_Antenna_Height_Above_Ground_Level'     => '',
		'Conformity_to_Frequency_Plan'             => '',
		'Rx_Threshold_Level_for_BER_10E-3'         => '',
		'Fee_Table_Code_2'                         => '',
		'Station_Location'                         => 'OTTAWA, ONTARIO',
		'Rx_Antenna_Pattern_Code'                  => '',
		'Congestion_Flag'                          => '',
		'Tx_Channel_Capacity_Code'                 => '01',
		'Tx_Frequency'                             => '39200.000000',
		'Longitude'                                => 0,
		'International_Coordination_Serial_Number' => '',
		'Fee_Table_Code_1'                         => '',
		'Tx_Power'                                 => '',
		'Antenna_Structure_Height_AGL'             => '',
		'Azimuth'                                  => '',
		'Tx_Total_Losses'                          => '',
		'Tx_Antenna_Model_Number'                  => '',
		'Link_Call_Sign'                           => '',
		'Class_of_Emission-1'                      => '',
		'Link_Licence_Number'                      => '',
		'Noise_Environment_Code'                   => '',
		'Holder_Name'                              => '',
		'Tx_Antenna_Gain'                          => '',
		'Rx_Antenna_Azimuth'                       => '',
		'Frequency_Status'                         => '6',
		'Tx_Antenna_Beamwidth'                     => '',
		'Rx_Antenna_Polarization_Code'             => '',
		'Tx_Effective_Radiated_Power'              => '',
		'Transportable_Radius'                     => ''
	}

);
foreach my $i (0, 1, -1) {
	is_deeply($p->get_stations()->[$i], $partial_expected_stations[$i], "Got expected item at offset $i");
}
