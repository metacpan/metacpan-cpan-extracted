use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'P2P::pDonkey',
    'VERSION'	=> '0.05',
    'PREREQ_PM'		=> {
						'Digest::MD4' => 1.3,
						'Tie::IxHash' => 1.21,
						'Tie::RefHash' => 1.30,
						'Data::Hexdumper' => 1.0,
						'Video::Info' => 0,
					   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Set of tools for eDonkey peer2peer protocol.',
       AUTHOR     => 'Alexey Klimkin <klimkin at cpan.org>') : ()),
);
