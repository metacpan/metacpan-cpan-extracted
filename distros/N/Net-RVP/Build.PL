# dbr 20040315

use Module::Build;

my $build = Module::Build->new(
 dist_name    => 'Net-RVP',
 dist_version => '0.02',
 license => 'perl',
 requires     => {
  perl                => '5.6.0',
  'Event'             => 0,
  'Event::IO::Record' => 0,
  'Event::IO::Server' => 0,
  'HTTP::Parser'      => '0.02',
  'LWP::UserAgent'    => 0,
  'Authen::NTLM'      => '1.02',
  'URI'               => 0,
  'XML::Simple'       => 0,
  'Digest::MD5'       => 0,
  'Time::HiRes'       => 0,
 },
);

$build->create_build_script();
