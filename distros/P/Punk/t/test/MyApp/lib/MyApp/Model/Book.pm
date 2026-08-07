package MyApp::Model::Book;

use Punk::Model;

# The Book model over Punk::Model::DBI (the SQLite fixture is built by
# t/13-myapp.t). Both controller trees reach it through $c->model('Book').

table 'books';

field id      => { type => 'integer', primary => 1 };
field title   => { type => 'string', required => 1, minLength => 1 };
field author  => { type => 'string' };
field created => { type => 'string' };

1;
