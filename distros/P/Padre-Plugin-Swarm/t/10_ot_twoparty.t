use Test::More tests => 2;
use Data::Dumper;
use t::lib::OTDoc;
use Padre::Plugin::Swarm::Resource;
use Padre::Plugin::Swarm::Resource::Edit;

my $owner = t::lib::OTDoc->new(<<ORIGIN
.+,.+,.+,.+,.+,.+,.+,.+,.+,.+,
ORIGIN
);
my $owner_resource = 
        Padre::Plugin::Swarm::Resource->new(
                id   => "$owner",
                body => $$owner,
                
        );
my $remote = t::lib::OTDoc->new($$owner);
my $remote_resource = 
        Padre::Plugin::Swarm::Resource->new(
                id   => "$owner",
                body => $$remote,
        );

## my edits
my @owner_edits = 
        map { Padre::Plugin::Swarm::Resource::Edit->new(@$_) }
(
# seq  dtime  op       pos  body
[ sequence=>1  , delta_time=>0   , operation=>'insert' , position=>0, body=>''  ], # document opened
[ sequence=>2  , delta_time=>0.1 , operation=>'insert' , position=>5, body=>'a' ],
[ sequence=>3  , delta_time=>0.5 , operation=>'insert' , position=>6, body=>'b' ],
[ sequence=>4  , delta_time=>1.0 , operation=>'delete' , position=>5, body=>'a' ],
);

## remote edits
my @remote_edits = 
        map { Padre::Plugin::Swarm::Resource::Edit->new(@$_) }
(
[ sequence=>2  , delta_time=>0.2 ,  operation=>'insert' , position=>7, body=>'x'  ],
[ sequence=>3  , delta_time=>0.4 ,  operation=>'insert' , position=>1, body=>'y'  ],
[ sequence=>4  , delta_time=>0.9 ,  operation=>'delete' , position=>8, body=>'x'  ], 
);


##
#diag( Dumper $remote_resource );

TODO: {
        local $TODO = 'work in progress';
        $remote_resource->perform_edit( $_ ) for @remote_edits;
        $owner_resource->perform_edit( $_ ) for @owner_edits;
        ok( $$owner ne $$remote  , 'Documents differ after isolated edits' );

        $remote_resource->perform_remote_edit( $_ ) for @owner_edits;
        $owner_resource->perform_remote_edit( $_ ) for @remote_edits;
        
        ok( $$owner eq $$remote , 'Documents converge after all edits landed' );
        

}