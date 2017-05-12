# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MySQL-Slurp.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
BEGIN { use_ok('MySQL::Slurp') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

    if ( $^O =~ /Win/i ) {
        BAIL_OUT( "MySQL::Slurp does not work on windows ... yet\n" );
    }


    my $load = MySQL::Slurp->new( 
        database => 'test', 
        table    => 'mysqlslurp', 
        args     => ["--force", "--verbose" ] ,
        buffer   => 1000 ,
        method   => 'dbi' ,
    );

    isa_ok( $load, 'MySQL::Slurp' );

  # Attributes 
    diag( "\nTesting Attributes" );
    ok( $load->database eq 'test'       , 'Attribute: database' );
    ok( $load->table    eq 'mysqlslurp' , 'Attribute: table' );
    ok( -e $load->tmp                   , 'Temporary directory exists' );
    ok( $load->force    == 1            , 'Hidden attribute recognized' );
    isa_ok( $load->tmp, "File::Temp::Dir" );      
    #     eq ( $load->tmp . '/mysqlslurp/' . $load->database ) ,
    #    'FIFO directory' 
    # );

              
  # Methods 
  if  ( ! $ENV{mysqlslurp} ) {
    diag( "In order oo run live tests set the following env variables:" );
    diag( "\tmysqlslurp=1 to indicate to run the tests and optionally, " );
    diag( "\tmysqlslurp_user" );
    diag( "\tmysqlslurp_pass" );
    diag( "\tmysqlslurp_host" );
    diag( "For a user with write create permissions on the test database.");
    diag( "A table mysqlslurp will be created for testing purposes and" );
    diag( "dropped when done." );
 }


    SKIP: {                    
        
        skip "live tests", 7 if ! $ENV{mysqlslurp} ;
        diag( "Testing Methods" );

        my $command =  "mysql";
           $command .= " -u$ENV{mysqlslurp_user}" if ( $ENV{mysqlslurp_user} );
           $command .= " -p$ENV{mysqlslurp_pass}" if ( $ENV{mysqlslurp_pass} );
           $command .= " -h$ENV{mysqlslurp_host}" if ( $ENV{mysqlslurp_host} );
           
        `$command -e"drop table if exists test.mysqlslurp"` ;
        `$command -e"
            create table test.mysqlslurp 
            ( col1 char(25), col2 char(25) ) 
        "`;

        ok( $load->open,               'Method: open' );
        ok( -p $load->fifo,            'Method: fifo' );
                                                       
        ok( $load->print( "d\te\n" ), "Method: write" );

        for( 1..10_000 ) {
            $load->print( "$_\t1\n" );  # printing to table
        }

        ok( (print { $load->writer->iofile } "a\tb\n") == 1, 'Direct print to FIFO' );

        ok( $load->close, 'Method: close' );

        `$command -e"drop table if exists test.mysqlslurp"`;

    }
    
# TO test the script
# perl -e'print "a\tb\n"' | perl -Ilib script/mysqlslurp --database test --table mysqlslurp
    

1;
