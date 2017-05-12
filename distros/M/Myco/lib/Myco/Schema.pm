package Myco::Schema;

#  $Id: Schema.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $

use Tangram;
use Tangram::PerlDump;
use Tangram::RawDate;
use Set::Object;

use Myco::Base::Association;
use Myco::Base::Entity::Event;
use Myco::Query;
use Myco::Base::Entity::SampleEntity;
use Myco::Base::Entity::SampleEntityAddress;
use Myco::Base::Entity::SampleEntityBase;

my $dbschema;

sub mkschema {
    $dbschema = Tangram::Schema->new
      ({ classes =>
         [
          'Myco::Base::Association' => $Myco::Base::Association::schema,
          'Myco::Base::Entity::Event' => $Myco::Base::Entity::Event::schema,

          'Myco::Base::Entity::SampleEntity' =>
           $Myco::Base::Entity::SampleEntity::schema,

          'Myco::Base::Entity::SampleEntityAddress' =>
           $Myco::Base::Entity::SampleEntityAddress::schema,

          'Myco::Query' => $Myco::Query::schema,

          'Myco::Base::Entity::SampleEntityBase' =>
           $Myco::Base::Entity::SampleEntityBase::schema,
         ]
       });
}

sub schema { $dbschema };

1;
__END__

