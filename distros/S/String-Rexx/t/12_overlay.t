use strict     ;
use Test::More ;
use String::Rexx qw(overlay);
 
BEGIN { plan tests =>  15  };


### Basic Usage
is   overlay( 'YAS',  'The Republic'       )     =>   'YAS Republic'     ;
is   overlay( 'YAS',  'The Republic', 1    )     =>   'YAS Republic'     ;
is   overlay( 'YAS',  'The Republic', 2    )     =>   'TYASRepublic'     ;


is   overlay( 'YAS',  'The Republic', 1, 1 )     =>   'Yhe Republic'     ;
is   overlay( 'YAS',  'The Republic', 1, 2 )     =>   'YAe Republic'     ;
is   overlay( 'YAS',  'The Republic', 1, 3 )     =>   'YAS Republic'     ;
is   overlay( 'YAS',  'The Republic', 1, 5 )     =>   'YAS  epublic'     ;

is   overlay( ''   ,  'The Republic', 1, 1 )     =>   ' he Republic'     ;
is   overlay( ''   ,  'The Republic', 1, 2 )     =>   '  e Republic'     ;

### Extra

is   overlay( 'YAS',  '', 1, 1             )     =>   'Y'                ;
is   overlay( 'YAS',  '', 1, 2             )     =>   'YA'               ;
is   overlay( 'YAS',  '', 1, 4             )     =>   'YAS '             ;
is   overlay( 'YAS',  '', 1, 4, '_'        )     =>   'YAS_'             ;
is   overlay( 'YAS',  '', 1, 5, '_'        )     =>   'YAS__'            ;
is   overlay( 'YAS',  'The Republic', 1, 5, '_') =>   'YAS__epublic'     ;
