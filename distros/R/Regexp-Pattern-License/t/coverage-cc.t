use Test2::V0;

use lib 't/lib';
use Test2::Regexp::Pattern::License;

plan 1;

# Key is spdx:name.
# Value is spdx:licenseId.

# Data sources: <https://wiki.creativecommons.org/wiki/License_Versions#Licenses>
# and https://creativecommons.org/publicdomain/zero/1.0/

like(
	license_org_metadata( 'cc', { date => 99999999 } ),
	hash {
		# Attribution
		field 'Creative Commons Attribution' => 'CC-BY';
		field 'Creative Commons Attribution 1.0 Generic License' =>
			'CC-BY-1.0';    # grant
		field 'Creative Commons Attribution 2.0 Generic License' =>
			'CC-BY-2.0';    # grant
		field 'Creative Commons Attribution 2.5 Generic License' =>
			'CC-BY-2.5';    # grant
		field 'Creative Commons Attribution 3.0 Unported License' =>
			'CC-BY-3.0';    # grant
		field 'Creative Commons Attribution 3.0 International License' =>
			'CC-BY-3.0';    # grant modern
		field 'Creative Commons Attribution 4.0 International License' =>
			'CC-BY-4.0';    # grant
		field 'Attribution 1.0'               => 'CC-BY-1.0';    # legal
		field 'Attribution 2.0'               => 'CC-BY-2.0';    # legal
		field 'Attribution 2.5'               => 'CC-BY-2.5';    # legal
		field 'Attribution 3.0 Unported'      => 'CC-BY-3.0';    # legal
		field 'Attribution 4.0 International' => 'CC-BY-4.0';    # legal
		field 'CC BY 1.0'                     => 'CC-BY-1.0';    # shortname
		field 'CC BY 2.0'                     => 'CC-BY-2.0';    # shortname
		field 'CC BY 2.5'                     => 'CC-BY-2.5';    # shortname
		field 'CC BY 3.0'                     => 'CC-BY-3.0';    # shortname
		field 'CC BY 4.0'                     => 'CC-BY-4.0';    # shortname
		field 'Attribution 1.0 Generic (CC BY 1.0)'  => 'CC-BY-1.0';    # deed
		field 'Attribution 2.0 Generic (CC BY 2.0)'  => 'CC-BY-2.0';    # deed
		field 'Attribution 2.5 Generic (CC BY 2.5)'  => 'CC-BY-2.5';    # deed
		field 'Attribution 3.0 Unported (CC BY 3.0)' => 'CC-BY-3.0';    # deed
		field 'Attribution 4.0 International (CC BY 4.0)' =>
			'CC-BY-4.0';                                                # deed

		# Attribution-NonCommercial
		field 'Creative Commons Attribution-NonCommercial' => 'CC-BY-NC';
		field 'Creative Commons Attribution-NonCommercial 1.0 Generic License'
			=> 'CC-BY-NC-1.0';    # grant
		field 'Creative Commons Attribution-NonCommercial 2.0 Generic License'
			=> 'CC-BY-NC-2.0';    # grant
		field 'Creative Commons Attribution-NonCommercial 2.5 Generic License'
			=> 'CC-BY-NC-2.5';    # grant
		field
			'Creative Commons Attribution-NonCommercial 3.0 Unported License'
			=> 'CC-BY-NC-3.0';    # grant
		field
			'Creative Commons Attribution-NonCommercial 3.0 International License'
			=> 'CC-BY-NC-3.0';    # grant modern
		field
			'Creative Commons Attribution-NonCommercial 4.0 International License'
			=> 'CC-BY-NC-4.0';    # grant
		field 'Attribution-NonCommercial 1.0' => 'CC-BY-NC-1.0';    # legal
		field 'Attribution-NonCommercial 2.0' => 'CC-BY-NC-2.0';    # legal
		field 'Attribution-NonCommercial 2.5' => 'CC-BY-NC-2.5';    # legal
		field 'Attribution-NonCommercial 3.0 Unported' =>
			'CC-BY-NC-3.0';                                         # legal
		field 'Attribution-NonCommercial 4.0 International' =>
			'CC-BY-NC-4.0';                                         # legal
		field 'CC BY-NC 1.0' => 'CC-BY-NC-1.0';    # shortname
		field 'CC BY-NC 2.0' => 'CC-BY-NC-2.0';    # shortname
		field 'CC BY-NC 2.5' => 'CC-BY-NC-2.5';    # shortname
		field 'CC BY-NC 3.0' => 'CC-BY-NC-3.0';    # shortname
		field 'CC BY-NC 4.0' => 'CC-BY-NC-4.0';    # shortname
		field 'Attribution-NonCommercial 1.0 Generic (CC BY-NC 1.0)' =>
			'CC-BY-NC-1.0';                        # deed
		field 'Attribution-NonCommercial 2.0 Generic (CC BY-NC 2.0)' =>
			'CC-BY-NC-2.0';                        # deed
		field 'Attribution-NonCommercial 2.5 Generic (CC BY-NC 2.5)' =>
			'CC-BY-NC-2.5';                        # deed
		field 'Attribution-NonCommercial 3.0 Unported (CC BY-NC 3.0)' =>
			'CC-BY-NC-3.0';                        # deed
		field 'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)' =>
			'CC-BY-NC-4.0';                        # deed

		# Attribution-NonCommercial-NoDerivatives
		field 'Creative Commons Attribution-NonCommercial-NoDerivatives' =>
			'CC-BY-NC-ND';
		field 'Creative Commons Attribution-NonCommercial-NoDerivs' =>
			'CC-BY-NC-ND';                         # abbrev
		field 'Creative Commons Attribution-NoDerivs-NonCommercial' =>
			'CC-BY-NC-ND';                         # abbrev swapped
		field
			'Creative Commons Attribution-NoDerivs-NonCommercial 1.0 Generic License'
			=> 'CC-BY-ND-NC-1.0';                  # grant
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 2.0 Generic License'
			=> 'CC-BY-NC-ND-2.0';                  # grant
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 2.5 Generic License'
			=> 'CC-BY-NC-ND-2.5';                  # grant
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License'
			=> 'CC-BY-NC-ND-3.0';                  # grant
		field
			'Creative Commons Attribution-NonCommercial-NoDerivs 3.0 International License'
			=> 'CC-BY-NC-ND-3.0';                  # grant modern
		field
			'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License'
			=> 'CC-BY-NC-ND-4.0';                  # grant
		field 'Attribution-NoDerivs-NonCommercial 1.0' =>
			'CC-BY-ND-NC-1.0';                     # legal
		field 'Attribution-NonCommercial-NoDerivs 2.0' =>
			'CC-BY-NC-ND-2.0';                     # legal
		field 'Attribution-NonCommercial-NoDerivs 2.5' =>
			'CC-BY-NC-ND-2.5';                     # legal
		field 'Attribution-NonCommercial-NoDerivs 3.0 Unported' =>
			'CC-BY-NC-ND-3.0';                     # legal
		field 'Attribution-NonCommercial-NoDerivatives 4.0 International' =>
			'CC-BY-NC-ND-4.0';                     # legal
		field 'CC BY-ND-NC 1.0' => 'CC-BY-ND-NC-1.0';    # shortname
		field 'CC BY-NC-ND 2.0' => 'CC-BY-NC-ND-2.0';    # shortname
		field 'CC BY-NC-ND 2.5' => 'CC-BY-NC-ND-2.5';    # shortname
		field 'CC BY-NC-ND 3.0' => 'CC-BY-NC-ND-3.0';    # shortname
		field 'CC BY-NC-ND 4.0' => 'CC-BY-NC-ND-4.0';    # shortname
		field
			'Attribution-NoDerivs-NonCommercial 1.0 Generic (CC BY-ND-NC 1.0)'
			=> 'CC-BY-ND-NC-1.0';                        # deed
		field
			'Attribution-NonCommercial-NoDerivs 2.0 Generic (CC BY-NC-ND 2.0)'
			=> 'CC-BY-NC-ND-2.0';                        # deed
		field
			'Attribution-NonCommercial-NoDerivs 2.5 Generic (CC BY-NC-ND 2.5)'
			=> 'CC-BY-NC-ND-2.5';                        # deed
		field
			'Attribution-NonCommercial-NoDerivs 3.0 Unported (CC BY-NC-ND 3.0)'
			=> 'CC-BY-NC-ND-3.0';                        # deed
		field
			'Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)'
			=> 'CC-BY-NC-ND-4.0';                        # deed

		# Attribution-NonCommercial-ShareAlike
		field 'Creative Commons Attribution-NonCommercial-ShareAlike' =>
			'CC-BY-NC-SA';
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 1.0 Generic License'
			=> 'CC-BY-NC-SA-1.0';                        # grant
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License'
			=> 'CC-BY-NC-SA-2.0';                        # grant
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 2.5 Generic License'
			=> 'CC-BY-NC-SA-2.5';                        # grant
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License'
			=> 'CC-BY-NC-SA-3.0';                        # grant
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 3.0 International License'
			=> 'CC-BY-NC-SA-3.0';                        # grant modern
		field
			'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License'
			=> 'CC-BY-NC-SA-4.0';                        # grant
		field 'Attribution-NonCommercial-ShareAlike 1.0' =>
			'CC-BY-NC-SA-1.0';                           # legal
		field 'Attribution-NonCommercial-ShareAlike 2.0' =>
			'CC-BY-NC-SA-2.0';                           # legal
		field 'Attribution-NonCommercial-ShareAlike 2.5' =>
			'CC-BY-NC-SA-2.5';                           # legal
		field 'Attribution-NonCommercial-ShareAlike 3.0 Unported' =>
			'CC-BY-NC-SA-3.0';                           # legal
		field 'Attribution-NonCommercial-ShareAlike 4.0 International' =>
			'CC-BY-NC-SA-4.0';                           # legal
		field 'CC BY-NC-SA 1.0' => 'CC-BY-NC-SA-1.0';    # shortname
		field 'CC BY-NC-SA 2.0' => 'CC-BY-NC-SA-2.0';    # shortname
		field 'CC BY-NC-SA 2.5' => 'CC-BY-NC-SA-2.5';    # shortname
		field 'CC BY-NC-SA 3.0' => 'CC-BY-NC-SA-3.0';    # shortname
		field 'CC BY-NC-SA 4.0' => 'CC-BY-NC-SA-4.0';    # shortname
		field
			'Attribution-NonCommercial-ShareAlike 1.0 Generic (CC BY-NC-SA 1.0)'
			=> 'CC-BY-NC-SA-1.0';                        # deed
		field
			'Attribution-NonCommercial-ShareAlike 2.0 Generic (CC BY-NC-SA 2.0)'
			=> 'CC-BY-NC-SA-2.0';                        # deed
		field
			'Attribution-NonCommercial-ShareAlike 2.5 Generic (CC BY-NC-SA 2.5)'
			=> 'CC-BY-NC-SA-2.5';                        # deed
		field
			'Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)'
			=> 'CC-BY-NC-SA-3.0';                        # deed
		field
			'Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)'
			=> 'CC-BY-NC-SA-4.0';                        # deed

		# Attribution-NoDerivatives
		field 'Creative Commons Attribution-NoDerivatives' => 'CC-BY-ND';
		field 'Creative Commons Attribution-NoDerivs' => 'CC-BY-ND';  # abbrev
		field 'Creative Commons Attribution-NoDerivs 1.0 Generic License' =>
			'CC-BY-ND-1.0';                                           # grant
		field 'Creative Commons Attribution-NoDerivs 2.0 Generic License' =>
			'CC-BY-ND-2.0';                                           # grant
		field 'Creative Commons Attribution-NoDerivs 2.5 Generic License' =>
			'CC-BY-ND-2.5';                                           # grant
		field 'Creative Commons Attribution-NoDerivs 3.0 Unported License' =>
			'CC-BY-ND-3.0';                                           # grant
		field
			'Creative Commons Attribution-NoDerivs 3.0 International License'
			=> 'CC-BY-ND-3.0';    # grant modern
		field
			'Creative Commons Attribution-NoDerivatives 4.0 International License'
			=> 'CC-BY-ND-4.0';    # grant
		field 'Attribution-NoDerivs 1.0'          => 'CC-BY-ND-1.0';   # legal
		field 'Attribution-NoDerivs 2.0'          => 'CC-BY-ND-2.0';   # legal
		field 'Attribution-NoDerivs 2.5'          => 'CC-BY-ND-2.5';   # legal
		field 'Attribution-NoDerivs 3.0 Unported' => 'CC-BY-ND-3.0';   # legal
		field 'Attribution-NoDerivatives 4.0 International' =>
			'CC-BY-ND-4.0';                                            # legal
		field 'CC BY-ND 1.0' => 'CC-BY-ND-1.0';    # shortname
		field 'CC BY-ND 2.0' => 'CC-BY-ND-2.0';    # shortname
		field 'CC BY-ND 2.5' => 'CC-BY-ND-2.5';    # shortname
		field 'CC BY-ND 3.0' => 'CC-BY-ND-3.0';    # shortname
		field 'CC BY-ND 4.0' => 'CC-BY-ND-4.0';    # shortname
		field 'Attribution-NoDerivs 1.0 Generic (CC BY-ND 1.0)' =>
			'CC-BY-ND-1.0';                        # deed
		field 'Attribution-NoDerivs 2.0 Generic (CC BY-ND 2.0)' =>
			'CC-BY-ND-2.0';                        # deed
		field 'Attribution-NoDerivs 2.5 Generic (CC BY-ND 2.5)' =>
			'CC-BY-ND-2.5';                        # deed
		field 'Attribution-NoDerivs 3.0 Unported (CC BY-ND 3.0)' =>
			'CC-BY-ND-3.0';                        # deed
		field 'Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)' =>
			'CC-BY-ND-4.0';                        # deed

		# Attribution-ShareAlike
		field 'Creative Commons Attribution-ShareAlike' => 'CC-BY-SA';
		field
			'Creative Commons Attribution-ShareAlike 1.0 Generic License' =>
			'CC-BY-SA-1.0';                        # grant
		field
			'Creative Commons Attribution-ShareAlike 2.0 Generic License' =>
			'CC-BY-SA-2.0';                        # grant
		field
			'Creative Commons Attribution-ShareAlike 2.5 Generic License' =>
			'CC-BY-SA-2.5';                        # grant
		field
			'Creative Commons Attribution-ShareAlike 3.0 Unported License' =>
			'CC-BY-SA-3.0';                        # grant
		field
			'Creative Commons Attribution-ShareAlike 3.0 International License'
			=> 'CC-BY-SA-3.0';                     # grant modern
		field
			'Creative Commons Attribution-ShareAlike 4.0 International License'
			=> 'CC-BY-SA-4.0';                     # grant
		field 'Attribution-ShareAlike 1.0'          => 'CC-BY-SA-1.0'; # legal
		field 'Attribution-ShareAlike 2.0'          => 'CC-BY-SA-2.0'; # legal
		field 'Attribution-ShareAlike 2.5'          => 'CC-BY-SA-2.5'; # legal
		field 'Attribution-ShareAlike 3.0 Unported' => 'CC-BY-SA-3.0'; # legal
		field 'Attribution-ShareAlike 4.0 International' =>
			'CC-BY-SA-4.0';                                            # legal
		field 'CC BY-SA 1.0' => 'CC-BY-SA-1.0';    # shortname
		field 'CC BY-SA 2.0' => 'CC-BY-SA-2.0';    # shortname
		field 'CC BY-SA 2.5' => 'CC-BY-SA-2.5';    # shortname
		field 'CC BY-SA 3.0' => 'CC-BY-SA-3.0';    # shortname
		field 'CC BY-SA 4.0' => 'CC-BY-SA-4.0';    # shortname
		field 'Attribution-ShareAlike 1.0 Generic (CC BY-SA 1.0)' =>
			'CC-BY-SA-1.0';                        # deed
		field 'Attribution-ShareAlike 2.0 Generic (CC BY-SA 2.0)' =>
			'CC-BY-SA-2.0';                        # deed
		field 'Attribution-ShareAlike 2.5 Generic (CC BY-SA 2.5)' =>
			'CC-BY-SA-2.5';                        # deed
		field 'Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)' =>
			'CC-BY-SA-3.0';                        # deed
		field 'Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)' =>
			'CC-BY-SA-4.0';                        # deed

		# CC0
		field 'Creative Commons CC0'     => 'CC0';
		field 'Creative Commons CC0 1.0' => 'CC0-1.0';    # generic
		field 'CC0 1.0 Universal'        => 'CC0-1.0';    # legal
		field 'CC0 1.0'                  => 'CC0-1.0';    # shortname
		field 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication' =>
			'CC0-1.0';                                    # deed

		end();
	},
	'coverage of Creative Commons Public licenses'
);

done_testing;
