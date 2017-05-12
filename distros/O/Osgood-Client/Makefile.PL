use inc::Module::Install;

name 		'Osgood-Client';
all_from	'lib/Osgood/Client.pm';

requires	'DateTime'	=> '0.41';
requires	'DateTime::Format::ISO8601' => '0.06';
requires    'JSON::XS';
requires    'JSON::Any';
requires	'LWP::UserAgent';
requires	'Moose'		=> '0.26';
requires	'MooseX::Iterator' => '0.07';
requires    'MooseX::Storage';
requires    'MooseX::AttributeHelpers';
requires    'URI';

WriteAll;
