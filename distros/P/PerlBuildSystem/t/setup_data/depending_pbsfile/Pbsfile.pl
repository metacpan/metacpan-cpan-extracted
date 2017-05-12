AddRule 'all', [ 'all' => '1', '2' ]
	=> 'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';

AddRule 'all2', [ 'all2' => '2', '1' ]
	=> 'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';

AddSubpbsRule 'subpbs', qr<\./(1|2)>, 'Subpbs.pl', 'subpbs';
