use utf8;
package Rapi::Demo::CrudModes::DB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-05-30 05:32:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k4L9fzxLIc2uX2IG9+peGw


sub _auto_populate {
  my $self = shift;
  
  $self->resultset('Alpha')->populate([ 
  
    [qw/string1                string2         number       bool    date/         ],
    ['something',             'blah',          23,          1,      '2015-02-15'  ],
    ['sfdgsdgf',              'bHHlah',        7.4,         0,      '2011-02-06'  ],
    ['something',             'blah',          23,          1,      '2009-06-29'  ],
    ['Table',                 'Apple',         10023.5,     0,      '1987-05-01'  ],
    ['Blah foo run',          'blah',          0.0034,      1,      '1783-10-31'  ],
    ['something',             'joe',           90,          0,      '1944-06-04'  ],
  
  ]);
  
  $self->resultset('Bravo')->populate([ 
  
    { title => 'Mustang',  price => 3500        },
    { title => 'Corvette', price => 7200.32     },
    
    { 
      title => 'Ferrari',  
      price => 234123.54, 
      bravo_notes => [
        
        { text => 'When bravo table was added', timestamp => '2015-06-20 22:20' },
        { text => 'Comment two' },
        { text => 'sdfgsd' },
        { text => 'Foo' },
        { text => undef },
        { text => 'blarg' }
        
      ]
    },
    
    { 
      title => 'F-150',  
      bravo_notes => [
        
        { text => 'DDEJFFE fgb' },
        { text => 'dfgdfgdfgdfg' },
        { text => '00sdf #$6' },
        { text => 'w00t!!!' }
        
      ]
    },
    
    { title => 'Mango' }
    
  ]);


}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
