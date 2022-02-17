use Test2::V0;

use lib 't/lib';
use Test2::Tools::LicenseRegistry;

plan 1;

# Data sources:
# <https://creativecommons.org/retiredlicenses/>
# <https://web.archive.org/web/20101011132223/http://creativecommons.org:80/choose/>

like(
	license_org_metadata( 'cc', { date => 0 } ),
	hash {
		# Developing Nations
		field 'Creative Commons Developing Nations' => 'CC-DevNations';
		field 'Developing Nations 2.0'     => 'CC-DevNations-2.0';    # legal
		field 'Developing Nations License' => 'CC-DevNations-2.0';    # deed

		# ShareAlike
		field 'Creative Commons ShareAlike'                     => 'CC-SA';
		field 'Creative Commons ShareAlike 1.0 Generic License' =>
			'CC-SA-1.0';                                              # grant
		field 'ShareAlike 1.0'                     => 'CC-SA-1.0'; # legal
		field 'CC SA 1.0'                          => 'CC-SA-1.0'; # shortname
		field 'ShareAlike 1.0 Generic (CC SA 1.0)' => 'CC-SA-1.0'; # deed

		# NonCommercial
		field 'Creative Commons NonCommercial'                     => 'CC-NC';
		field 'Creative Commons NonCommercial 1.0 Generic License' =>
			'CC-NC-1.0';                                           # grant
		field 'NonCommercial 1.0' => 'CC-NC-1.0';                  # legal
		field 'CC NC 1.0'         => 'CC-NC-1.0';                  # shortname
		field 'NonCommercial 1.0 Generic (CC NC 1.0)' => 'CC-NC-1.0';   # deed

		# NonCommercial Sampling Plus
		field 'Creative Commons NonCommercial Sampling Plus' =>
			'CC-NC-Sampling+';
		field 'NonCommercial Sampling Plus 1.0' =>
			'CC-NC-Sampling+-1.0';    # legal
		field 'CC NC-Sampling+ 1.0' => 'CC-NC-Sampling+-1.0';    # shortname

		# NonCommercial-ShareAlike
		field 'Creative Commons NonCommercial-ShareAlike' => 'CC-NC-SA';
		field 'Creative Commons NonCommercial-ShareAlike 1.0 Generic License'
			=> 'CC-NC-SA-1.0';                                   # grant
		field 'NonCommercial-ShareAlike 1.0' => 'CC-NC-SA-1.0';  # legal
		field 'CC NC-SA 1.0'                 => 'CC-NC-SA-1.0';  # shortname
		field 'NonCommercial-ShareAlike 1.0 Generic (CC NC-SA 1.0)' =>
			'CC-NC-SA-1.0';                                      # deed

		# NoDerivs-NonCommercial
		field 'Creative Commons NoDerivs-NonCommercial'      => 'CC-ND-NC';
		field 'Creative Commons NoDerivatives-NonCommercial' =>
			'CC-ND-NC';                                          # long
		field 'Creative Commons NonCommercial-NoDerivs' =>
			'CC-ND-NC';                                          # flipped
		field 'Creative Commons NoDerivs-NonCommercial 1.0 Generic License' =>
			'CC-ND-NC-1.0';                                      # grant
		field 'NoDerivs-NonCommercial 1.0' => 'CC-ND-NC-1.0';    # legal
		field 'CC ND-NC 1.0'               => 'CC-ND-NC-1.0';    # shortname
		field 'NoDerivs-NonCommercial 1.0 Generic (CC ND-NC 1.0)' =>
			'CC-ND-NC-1.0';                                      # deed

		# NoDerivs
		field 'Creative Commons NoDerivs'      => 'CC-ND';
		field 'Creative Commons NoDerivatives' => 'CC-ND';       # long
		field 'Creative Commons NoDerivs 1.0 Generic License' =>
			'CC-ND-1.0';                                         # grant
		field 'NoDerivs 1.0'                     => 'CC-ND-1.0'; # legal
		field 'CC ND 1.0'                        => 'CC-ND-1.0'; # shortname
		field 'NoDerivs 1.0 Generic (CC ND 1.0)' => 'CC-ND-1.0'; # deed

		# Public Domain
		field 'Creative Commons Public Domain' => 'CC-PD';       # grant

		# Public Domain Dedication
		field 'Creative Commons Public Domain Dedication' => 'CC-PDD'; # legal
		field
			'Creative Commons Copyright-Only Dedication (based on United States law)'
			=> 'CC-PDD';                                               # deed

		# Public Domain Dedication and Certification
		field 'Creative Commons Public Domain Dedication and Certification' =>
			'CC-PDDC';                                                 # legal
		field
			'Creative Commons Copyright-Only Dedication (based on United States law) or Public Domain Certification'
			=> 'CC-PDDC';                                              # deed

		# Sampling
		field 'Creative Commons Sampling' => 'CC-Sampling';
		field 'Sampling 1.0'              => 'CC-Sampling-1.0';        # legal

		# Sampling Plus
		field 'Creative Commons Sampling Plus' => 'CC-Sampling+';
		field 'Sampling Plus 1.0'              => 'CC-Sampling+-1.0';  # legal
		field 'CC Sampling+ 1.0' => 'CC-Sampling+-1.0';    # shortname

		# Software
		field 'Creative Commons GNU GPL'  => 'GPL-2';
		field 'CC-GNU GPL'                => 'GPL-2';       # deed
		field 'Creative Commons GNU LGPL' => 'LGPL-2.1';
		field 'CC-GNU LGPL'               => 'LGPL-2.1';    # deed

		end();
	},
	'coverage of Creative Commons Public licenses'
);

done_testing;
