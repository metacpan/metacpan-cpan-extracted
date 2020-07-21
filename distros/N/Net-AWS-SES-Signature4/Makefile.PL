use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::AWS::SES::Signature4',
    VERSION_FROM      => 'lib/Net/AWS/SES/Signature4.pm', # finds $VERSION
    PREREQ_PM         => {
		'Carp'				=> '0',
		'Digest::HMAC_SHA1'		=> '0',
		'MIME::Base64'			=> '0',
		'Time::Piece'			=> '0',
		'LWP::UserAgent'		=> '0',
		'HTTP::Headers'			=> '0',
		'MIME::Entity'			=> '0',
		'XML::Simple'			=> '0',               
		'Net::AWS::SES::Response'	=> '0',
		'HTTP::Request::Common'		=> '0',
                'AWS::Signature4'		=> '0'
        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/AWS/SES/Signature4.pm', # retrieve abstract from module
       AUTHOR         => 'Partha Pratim Sarkar <partha@cpan.org>') : ()),
);
