
AddConfig a => 1 ;

AddRule 'all', [ all => '1', '2', 'cyclic'] ;

AddRule 'cyclic', [cyclic => 'cyclic2'] ;
AddRule 'cyclic2', [cyclic2 => 'cyclic3'] ;
AddRule 'cyclic3', [cyclic3 => 'cyclic'] ;

