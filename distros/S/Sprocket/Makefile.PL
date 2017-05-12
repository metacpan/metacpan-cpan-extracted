#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'			=> 'Sprocket',
    'VERSION_FROM'	=> 'lib/Sprocket.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Carp'                          => undef,
        'POE'                           => '0.3502',
        'Class::Accessor::Fast'         => undef,
        'POE::Component::Client::DNS'   => undef,
        'Data::UUID'                    => undef,       
        'Scalar::Util'                  => undef,
        'Time::HiRes'                   => undef,
#        'POE::Filter::JSON'            => undef,
#        'HTTP::Request'                => undef,
#        'HTTP::Status'                 => undef,
#        'HTTP::Response'               => undef,
#        'HTTP::Date'                   => undef,
#        'URI'                          => undef,
#        'Data::UUID'                   => undef,
#        'Digest::SHA1'                 => undef,
#        'MIME::Types'                  => undef,
    },
	'dist'         => {
		'SUFFIX'       => '.gz',
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => 'gzip -9vf',
	},

    # TODO other authors here
    # Add these new keywords supported since 5.005
    ( $] >= 5.005 ? (
        ABSTRACT_FROM   => 'lib/Sprocket.pm',
		AUTHOR          => 'David Davis <xantus@cometd.com>'
      ) : ()
    ),
);
