package MyData;
use strict;
use MongoDBx::Tiny;

CONNECT_INFO  host => 'localhost', port => 27017;
DATABASE_NAME 'mongodb_tiny_my_data';

LOAD_PLUGIN("SingleByCache");

1;
