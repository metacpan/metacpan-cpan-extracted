# NAME

Pepper - Quick-start kit for learning and creating microservices in Perl.

# DESCRIPTION / PURPOSE

This quick-start kit is designed for new users to easily experiment and learn
about Perl and for seasoned users to quickly stand up simple web services.

This is not a framework.  This is a quick-start kit meant to simplify learning and 
small projects.  The goal is for you to fall in love with Perl and continue your 
journey on to Mojo, Dancer2, AnyEvent, Rex, PDL, POE, and all other the many terrific 
Perl libraries (more than I can list here).  This is a great community of builders, 
and there is so much to discover at [https://metacpan.org](https://metacpan.org) 
and [https://perldoc.perl.org/](https://perldoc.perl.org/)

This kit supports database connections to MySQL 5.7/8 or MariaDB 10.3+. 
There are many other great options out there, but one database driver
was chosen for the sake of simplicity.  If your heart is set on Postgres,
answer 'N' to the 'Connect to a MySQL/MariaDB database server?' prompt
and use [DBD:Pg](DBD:Pg) instead of Pepper::DB.

# SYNOPSIS

To configure Pepper:

        # pepper setup

To set up a new web service:

        # pepper set-endpoint /dogs/daisy PepperApps::Dogs::Daisy

A new Perl module is created at $ENV{HOME}/pepper/lib/PepperApps/Dogs/Daisy.pm.
Edit that module to have it perform your actions and return any content you prefer.  
You will be able to execute the service via http://you.hostname.ext:5000/dogs/daisy
If you change your code, restart the Plack service via 'pepper restart'

For a simple Perl script, just add this at the top:

        use Pepper;
        my $pepper = Pepper->new();

The $pepper object provides several conveniences for MySQL/MariaDB databases, JSON
parsing, Template Toolkit, file handling and logging.  In Web/Plack mode, 
$pepper will also include the entire PSGI (CGI) environment.

# BREAKING CHANGE IN VERSION 1.1

From version 1.1, Pepper looks for its workspace directory in your home directory.
If you installed Pepper prior to 1.1 (9/12/2020), that workspace will be under 
/opt/pepper. You can work around this via this command 'ln -s /opt/pepper ~/peper', 
or you can re-run 'pepper setup' and copy/move your custom files from /opt/pepper 
as needed.

# INSTALLATION / GETTTING STARTED

This kit has been tested with Ubuntu 18.04 & 20.04, CentOS 8, and FeeBSD 12.
**Installation on Windows is not supported at this time.**  Pepper should work
on any modern system capable of running Perl 5.22+ and Plack. I will happily add
any install notes you can provide for other systems (especially WSL or MacOS).

Ubuntu 18/20 users have a quick-start option:

        # curl https://raw.githubusercontent.com/ericschernoff/Pepper/ginger/ubuntu20_quickstart.sh | sh

## Installing the required system packages

These package-installation commands will need to be run as root or via 'sudo'.

- `Ubuntu 18 or 20`

            # apt -y install build-essential cpanminus libmysqlclient-dev perl-doc zlib1g-dev apache2 apache2-utils

- `CentOS 8`

            # yum install perl perl-utils perl-devel httpd gcc mysql mariadb-connector-c mariadb-devel 

- `FreeBSD 12`

            # pkg update -f && pkg install perl5-5.30.3 git p5-DBD-mysql p5-App-cpanminus p5-Parallel-Prefork

## Recommended: Install and configure your MySQL/MariaDB database. 

Create a designated user and database for Pepper. See the Mysql / MariaDB docs for guidance on this task.
**Note:** Use the 'mysql\_native\_password' plugin when creating your database users, as in:

        create user pepper@'127.0.0.1' identified with mysql_native_password by 'MySecurePassword!';
        

## Install Pepper:  

        # cpanm Pepper
        - or -
        # cpan Pepper

It may take several minutes to build and install the dependencies.

## Set up / configure Pepper:  

        # pepper setup

This will prompt you for the configuration options. Choose carefully, but you can
safely re-run this command if needed to make changes. This command will create the
directory under $ENV{HOME}/pepper with the needed sub-directories and templates.
Do not provide a 'Default endpoint-handler Perl module' for now. (You can update later.)

## Check out the examples:

Open up PepperExample.pm and HTMLExample.pm under $ENV{HOME}/pepper/lib/PepperApps 
and read the comments to see how easy it is to code up web endpoints.

## Start the Plack service:  

        # pepper start

Check out the results of PepperExample.pm here: https://127.0.0.1:5000 (or in your
browser, using your server's hostname:5000). You should receive basic JSON results. 
Modify PepperExample.pm to tweak those results and then restart the Plack service 
to test your changes:  

        # pepper restart

Any errors will be logged to $ENV{HOME}/pepper/log/fatals-YYYY-MM-DD.log (replacing YYYY-MM-DD).
In a dev environment, you can auto-restart, please see 'pepper help'

## Write a small script:

If you would like to write command-line Perl scripts, you can skip the Plack steps
and just start your script like this:

        use Pepper;
        my $pepper = Pepper->new();

The setup command places a simple example script at $ENV{HOME}/pepper/template/system/example\_perl\_script.pl

The $pepper object will have all the methods and variables described below.

If you are new to Perl, please have [https://perldoc.perl.org/](https://perldoc.perl.org/) handy, especially
the 'Functions' menu and 'Tutorials' under the 'Manuals' menu.

# ADDING / MANAGING ENDPOINTS

Adding a new endpoint is as easy as:

        # pepper set-endpoint /Some/URI PerlModuleDirectory::PerlModule
        

For example:

        # pepper set-endpoint /Carrboro/WeaverStreet PepperApps::Carrboro::WeaverStreet
        

That will map any request to your /Carrboro/WeaverStreet URI to the 'endpoint\_handler'
subroutine within $ENV{HOME}/pepper/lib/PepperApps/Carrboro/WeaverStreet.pm and a very basic version
of that file will be created for you.  Simply edit and test the file to power the endpoint.

If you wish to change the endpoint to another module, just re-issue the command:

        # pepper set-endpoint /Carrboro/WeaverStreet PepperApps::Carrboro::AnotherWeaverStreet

You can see your current endpoints via list-endpoints

        # pepper list-endpoints
        

To deactivate an endpoint, you might want to set it to the default:

        # pepper set-endpoint /Carrboro/WeaverStreet default
        

Or you can just delete it

        # pepper delete-endpoint /Carrboro/WeaverStreet

# BASICS OF AN ENDPOINT HANDLER

You can have any code you require within the endpoint\_handler subroutine.  You must
leave the 'my ($pepper) = @\_;' right below 'sub endpoint\_handler', and your endpoint\_handler 
subroutine must return some text or data that can be sent to the browser.

If you wish to send JSON to the client, just return a reference to the data structure
that should be converted to JSON. Otherwise, you can return HTML or text. For your convenience,
an interface to the excellent Template-Toolkit library is a part of this kit (see below).

For example:

        my $data_to_send = {
                'colors' => ['Red','Green','Blue'],
                'favorite_city' => 'Boston',
        };

        return $data_to_send;  # client gets JSON of the above
        
        return qq{
                <html>
                <body>
                        <h1>This is a bad web page</h1>
                </body>
                </html>
        }; # client gets some HTML
        
        # you can return plain text as well, i.e. generated config files
        

The $pepper object has lots of goodies, described in the following sections.  There
is also a wealth of libraries in [https://metacpan.org](https://metacpan.org) and you add include your 
own re-usable packages under $ENV{HOME}/pepper/lib .  For instance, if many of your endpoints
share some data-crunching routines, you could create $ENV{HOME}/pepper/lib/MyUtils/DataCrunch.pm
and import it as:  use MyUtils::DataCrunch; .  You can also add subroutines below
the main endpoint\_handler() subroutine.  Pepper is just plain Perl, and the only "rule"
is that endpoint\_handler() needs to return what will be sent to the client.

# WEB / PSGI ENVIRONMENT

When you are building an endpoint handler for a web URI, the $pepper object will
contain the full PSGI environment (which is the web request), including the 
parameters sent by the client.  This can be accessed as follows:

## $pepper->{params}

This is a hash of all the parameters sent via a GET or POST request or 
via a JSON request body.  For example, if a web form includes a 'book\_title'
field, the submitted value would be found in $pepper->{params}{book\_title} .

For multi-value fields, such as checkboxes or multi-select menus, those values
can be found as arrays under $pepper->{params}{multi} or comma-separated lists
under $pepper->{params}.  For example, if are two values, 'Red' and 'White', 
for the 'colors' param, you could access:

        $pepper->{params}{colors} # Would be 'Red,White'

        $pepper->{params}{multi}{colors}[0]  # would be 'Red'

        $pepper->{params}{multi}{colors}[1]  # would be 'White'

## $pepper->{cookies}

This is a name/value hash of the cookies sent by the client. If there is 
a cookie named 'Oreo' with a value of 'Delicious but unhealthy', that
text value would be accessible at $pepper->{cookies}{Oreo} .

Setting cookies can be done like so:

        $pepper->set_cookie({
                'name' => 'Oreo', # could be any name
                'value' => 'Delicious but unhealthy', # any text you wish
                'days_to_live' => integer over 0, # optional, default is 10
        }); 
        

These cookies are tied to your web service's hostname.

## $pepper->{uploaded\_files}

If there are any uploaded files, this will contain a name/value hash,
were the name (key) is the filename and the value is the path to access
the file contents on your server.  For example, to save all the
uploaded files to a permmanet space:

        use File::Copy;

        foreach my $filename (keys %{ $pepper->{uploaded_files} }) {
                my ($clean_file_name = $filename) =~ s/[^a-z0-9\.]//gi;
                copy($pepper->{uploaded_files}{$filename}, '/some/directory/'.$clean_file_name);
        }

## $pepper->{auth\_token}	

If the client sends an 'Authorization' header, that value will be stored in $pepper->{auth\_token}.
Useful for a minimally-secure API, provided you have some code to validate this token.

## $pepper->{hostname}	

This will contain the HTTP\_HOST for the request.  If the URL being accessed is
https://pepper.weaverstreet.net/All/Hail/Ginger, the value of $pepper->{hostname}
will be 'pepper.weaverstreet.net'; for http://pepper.weaverstreet.net:5000/All/Hail/Ginger,
$pepper->{hostname} will be 'pepper.weaverstreet.net:5000'.

## $pepper->{uri}	

This will contain the endpoint URI. If the URL being accessed is
https://pepper.weaverstreet.net/All/Hail/Ginger, the value of $pepper->{uri}
will be '/All/Hail/Ginger'.

## Accessing the Plack Request / Response objects.

The plain request and response Plack objects will be available at $pepper->{plack\_handler}->{request}
and $pepper->{plack\_handler}->{response} respectively.  Please only use these if you absolutely must,
and please see [Plack::Request](https://metacpan.org/pod/Plack%3A%3ARequest) and [Plack::Response](https://metacpan.org/pod/Plack%3A%3AResponse) before working with these.

# RESPONSE / LOGGING / TEMPLATE METHODS

## template\_process

This is an simple interface to the excellent Template Toolkit, which is great for generating
HTML and really any kind of text files.  Create your Template Toolkit templates 
under $ENV{HOME}/pepper/template and please see [Template](https://metacpan.org/pod/Template) and [http://www.template-toolkit.org](http://www.template-toolkit.org)
The basic idea is to process a template with the values in a data structure to create the 
appropriate text output.  

To process a template and have your endpoint handler return the results:

        return $pepper->template_process({
                'template_file' => 'some_template.tt', 
                'template_vars' => $some_data_structure,
        });

That expects to find some\_template.tt under $ENV{HOME}/pepper/template.  You can add 
subdirectories under $ENV{HOME}/pepper/template and refer to the files as
'subdirectory\_name/template\_filename.tt'.

To save the generated text as a file:

        $pepper->template_process({
                'template_file' => 'some_template.tt', 
                'template_vars' => $some_data_structure,
                'save_file' => '/some/file/path/new_filename.ext',
        });

To have the template immediate sent out, such as for a fancy error page:

        $pepper->template_process({
                'template_file' => 'some_template.tt', 
                'template_vars' => $some_data_structure,
                'send_out' => 1,
                'stop_here' => 1, # recommended to stop execution
        });
        

## logger

This adds entries to the files under $ENV{HOME}/pepper/log and is useful to log actions or
debugging messages.  You can send a plain text string or a reference to a data structure.

        $pepper->logger('A nice log message','example-log');

That will add a timestamped entry to a file named for example-log-YYYY-MM-DD.log. If you
leave off the second argument, the message is appended to today's errors-YYYY-MM-DD.log.

        $pepper->logger($hash_reference,'example-log');

This will save the output of Data::Dumper's Dumper($hash\_reference) to today's
example-log-YYYY-MM-DD.log.

## send\_response

This method will send data to the client.  It is usually unnecessary, as you will simply
return data structures or text at the end of endpoint\_handler().  
However, send\_response() may be useful in two situations:

        # To bail-out in case of an error:
        $pepper->send_response('Error, everything just blew up.',1);

        # To send out a binary file:
        $pepper->send_response($file_contents,'the_filename.ext',2,'mime/type');
        $pepper->send_response($png_file_contents,'lovely_ginger.png',2,'image/png');
        

## set\_cookie

From a web endpoint handler, you may set a cookie like this:

        $pepper->set_cookie({
                'name' => 'Cookie_name', # could be any name
                'value' => 'Cookie_value', # any text you wish
                'days_to_live' => integer over 0, # optional, default is 10
        }); 

# DATABASE METHODS

## Random hints

These method will work if you configured a MySQL or MariaDB connection
via 'pepper setup' command.  

The [DBI](https://metacpan.org/pod/DBI) database handle object is stored in $pepper->{db}->{dbh}.

The 'pepper' command can test your database connection config:

        # pepper test-db

## quick\_select

Use to get results for SQL SELECT's that will return one row of results.
The required first argument is the SELECT statement, and the optional 
second argument is an array reference of values for the placeholders.

        my ($birth_date, $adopt_date) = $pepper->quick_select(qq{
                select birth_date, adoption_date from family.dogs
                where name=? and breed=? limit 1
        }, [ 'Daisy', 'Shih Tzu' ] );
        
        ($todays_date) = $pepper->quick_select(' select curdate() ');

## sql\_hash

Very useful for SELECT's with multi-row results.  Creates a two-level 
data structure, where the top key is the values of the first column, and 
the second-level keys are either the other column names or the keys you
provide.  Returns references to the results hash and the array of
the first level keys.

        my ($results, $result_keys) = $pepper->sql_hash(qq{
                select id, name, birth_date from my_family.family_members
                where member_type=? order by name
        }, [ 'Dog'] );
        

You now have:

        $results = {
                '1' => {
                        'name' => 'Ginger',
                        'birth_date' => 1999-08-01',
                },
                '2' => {
                        'name' => 'Pepper',
                        'birth_date' => 2002-04-12',
                },
                '3' => {
                        'name' => 'Polly',
                        'birth_date' => 2016-03-31',
                },              
                '4' => {
                        'name' => 'Daisy',
                        'birth_date' => 2019-08-01',
                },
        };
        
        $result_keys = [
                '4','1','2','3'
        ];

Using alternative keys:

        my ($results, $result_keys) = $pepper->sql_hash(qq{
                select id, name, date_format(birth_date,'%Y') from my_family.family_members
                where member_type=? order by name
        },[ 'Dog' ], [ 'name','birth_year' ] );

Now, results would look like

        $results = {
                '1' => {
                        'name' => 'Ginger',
                        'birth_year' => 1999',
                },
                ...and so forth...
        };

**Note:** sql\_hash() does not work with 'select \*' queries. The column names must be
a part of your SELECT statement or provided as the third argument.

## list\_select

Useful for SELECT statements which return multiple results with one column each.
The required first argument is the SELECT statement to run. The optional second 
argument is a reference to an array of values for the placeholders (recommended).

        my $list = $pepper->list_select(
                'select name from my_family.family_members where member_type=?,
                ['Dog']
        );
        
        # $list will look like:
        $list = ['Ginger','Pepper','Polly','Daisy'];

## comma\_list\_select

Provides the same functionality as list\_select() but returns a scalar containing
a comma-separated list of the values found by the SELECT statement.

        my $text_list = $pepper->comma_list_select(
                "select name from my_family.family_members where member_type=?",
                ['Dog']
        );
        
        # $text_list will look like:
        $text_list = 'Ginger,Pepper,Polly,Daisy';

## do\_sql

Flexible method to execute a SQL statement of any kind. It may be worth noting 
that do\_sql() is the only provided method that will perform non-SELECT statements.

Args are the SQL statement itself and optionally (highly-encouraged), an arrayref
of values for placeholders.

        $pepper->do_sql(qq{
                insert into my_family.family_members
                (name, birth_date, member_type)
                values (?,?,?)
        }, \@values );

        $pepper->do_sql(qq{
                insert into my_family.family_members
                (name, birth_date, member_type)
                values (?,?,?)
        }, [ 'Daisy', '2019-08-01', 'Dog'] );
        
        $pepper->do_sql(qq{
                update my_family.family_members.
                set name=? where id=?
        }, ['Sandy', 6] );      

For a SELECT statement, do\_sql() returns a reference to an array of arrays of results.

        my $results = $pepper->do_sql(
                'select code,name from finances.properties where name=?',
                ['123 Any Street']
        );
        my ($code, $name);
        while (($code,$name) = @{shift(@$results)}) {
                print "$code == $name\n";
        }

For most uses, quick\_select() and sql\_hash() are much simpler for running SELECT's.

## change\_database

Changes the current working database.  This allows you to query tables without prepending their
DB name (i.e no 'db\_name.table\_name').

        $pepper->change_database('new_db_name');

## commit

Pepper does not turn on auto-commit, so. if you are using database support, each web request 
will be a database transaction.  This commit() method will be called automatically at the end 
of the web request, but if you wish to manually commit changes, just call $pepper->commit(); .

If a request fails before completely, commit() is not called and the changes should be rolled-back.
(Unless you already called 'commit()' prior to the error.)

# JSON METHODS

These methods provide default/basic functions of the excellent [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS) library.

## json\_from\_perl

Accepts a reference to a data structure and converts it to JSON text:

        my $json_string = $pepper->json_from_perl($hash_reference);

        my $json_string = $pepper->json_from_perl(\%some_hash);

        # in either case, $json_string now contains a JSON representation of the data structure

## json\_to\_perl

Accepts a scalar with a JSON string and converts it into a reference to a Perl data structure.

        my $data = $pepper->json_to_perl($json_text);
        
        # now you have $$data{name} or other keys / layers to access like 
        # any other Perl hashref
        

## read\_json\_file

Similar to json\_to\_perl() but added convenience of retrieving the JSON string from a file:

        my $data = $pepper->read_json_file('path/to/data_file.json');

## write\_json\_file

Converts Perl data structure to JSON and saves it to a file.

        $pepper->write_json_file('path/to/data_file.json', $data_structure);

        $pepper->write_json_file('path/to/data_file.json', \%data_structure);

# GENERAL / DATE UTILITY METHODS

## filer

This is a basic interface for reading, writing, and appending files using the Path::Tiny library.

To load the contents of a file into a scalar (aka 'slurp'):

        my $file_contents = $pepper->filer('/path/to/file.ext');
        

To save the contents of a scalar into a file:

        $pepper->filer('/path/to/new_file.ext','write',$scalar_of_content);

        # or maybe you have an array
        $pepper->filer('/path/to/new_file.ext','write', join("\n",@array_of_lines)  );

To append a file with additional content

        $pepper->filer('/path/to/new_file.ext','append',$scalar_of_content);

## random\_string

Handy method to generate a random string of numbers and uppercase letters. 

To create a 10-character random string:

        my $random_string = $pepper->random_string();
        

To specify that it be 25 characters long;

        my $longer_random_string = $pepper->random_string(25);

## time\_to\_date

Useful method for converting UNIX epochs or YYYY-MM-DD dates to more human-friendly dates.
This takes three arguments:

1\. A timestamp, preferably an epoch like 1018569600, but can be a date like 2002-04-12 or 'April 12, 2002'.
The epochs are best for functions that will include the time.

2\. An action / command, such as 'to\_year' or 'to\_date\_human\_time'. See below for full list.

3\. Optionally, an Olson DB time zone name, such as 'America/New\_York'.  The default is UTC / GMT.
You can set your own default via the PERL\_DATETIME\_DEFAULT\_TZ environmental variable or placing 
in $pepper->{utils}->{time\_zone\_name}.  Most of examples below take the default time zone, which is
UTC. **Be sure to set the time zone if you need local times.**

To get the epoch of 00:00:00 on a particular date:

        my $epoch_value = $pepper->time_to_date('2002-04-12', 'to_unix_start');
        # $epoch_value is now something like 1018569600

To convert an epoch into a YYYY-MM-DD date:

        my $date = $pepper->time_to_date(1018569600, 'to_date_db');
        # $date is now something like '2002-04-12'
        

To convert a date or epoch to a more friendly format, such as April 12, 2002:

        my $peppers_birthday = $pepper->time_to_date('2002-04-12', 'to_date_human');
        my $peppers_birthday = $pepper->time_to_date(1018569600, 'to_date_human');
        # for either case, $peppers_birthday is now 'April 12, 2002'
        

You can always use time() to get values for the current moment:

        my $todays_date_human = $pepper->time_to_date(time(), 'to_date_human');
        # $todays_date_human is 'September 1' at the time of this writing

'to\_date\_human' leaves off the year if the moment is within the last six months.
This can be useful for displaying a history log.

Use 'to\_date\_human\_full' to force the year to be included:

        my $todays_date_human = $pepper->time_to_date(time(), 'to_date_human_full');
        # $todays_date_human is now 'September 1, 2020'
        

Use 'to\_date\_human\_abbrev' to abbreviate the month name:

        my $nice_date_string = $pepper->time_to_date('2020-09-01', 'to_date_human_abbrev');
        # $nice_date_string is now 'Sept. 1, 2020'

To include the weekday with 'to\_date\_human\_abbrev' output:

        my $nicer_date_string = $pepper->time_to_date('2002-04-12', 'to_date_human_dayname');
        # $nicer_date_string is now 'Friday, Apr 12, 2002'

To find just the year from a epoch:

        my $year = $pepper->time_to_date(time(), 'to_year');
        # $year is now '2020' (as of this writing)
        
        my $year = $pepper->time_to_date(1018569600, 'to_year');
        # $year is now '2002'

To convert an epoch to its Month/Year value:

        my $month_year = $pepper->time_to_date(1018569600, 'to_month');
        # $month_year is now 'April 2002'

To convert an epoch to an abbreviated Month/Year value (useful for ID's):

        my $month_year = $pepper->time_to_date(1018569600, 'to_month_abbrev');
        # $month_year is now 'Apr02'

To retrieve a human-friendly date with the time:

        my $date_with_time = $pepper->time_to_date(time(), 'to_date_human_time');
        # $date_with_time is now 'Sep 1 at 2:59pm' as of this writing
        
        my $a_time_in_the_past = $pepper->time_to_date(1543605300,'to_date_human_time','America/Chicago');
        # $a_time_in_the_past is now 'Nov 30, 2018 at 1:15pm'

Use 'to\_just\_human\_time' to retrieve just the human-friendly time part;

        my $a_time_in_the_past = $pepper->time_to_date(1543605300,'to_just_human_time','America/Chicago');
        # $a_time_in_the_past is now '1:15pm'

To get the military time:

        my $past_military_time = $pepper->time_to_date(1543605300,'to_just_military_time');
        # $past_military_time is now '19:15' 
        # I left off the time zone, so that's UTC time

To extract the weekday name

        my $weekday_name = $pepper->time_to_date(1018569600, 'to_day_of_week');
        my $weekday_name = $pepper->time_to_date('2002-04-12', 'to_day_of_week');
        # in both cases, $weekday_name is now 'Friday'

To get the numeric day of the week (0..6):

        my $weekday_value = $pepper->time_to_date(1543605300,'to_day_of_week_numeric');
        # weekday_value is now '5'

To retrieve an ISO-formatted timestamp, i.e. 2004-10-04T16:12:00+00:00

        my $iso_timestamp = $pepper->time_to_date(1096906320,'to_datetime_iso');
        # $iso_timestamp is now '2004-10-04T16:12:00+0000'

        my $iso_timestamp = $pepper->time_to_date(1096906320,'to_datetime_iso','America/Los_Angeles');
        # $iso_timestamp is now '2004-10-04T09:12:00+0000' (it displays the UTC value)

# THE pepper DIRECTORY

After running 'pepper setup', a 'pepper' directory will be created in your home directory,
aka $ENV{HOME}/pepper.  This should contain the following subdirectories:

- `lib`

    This is where your endpoint handler modules go.  This will be added to the library path
    in the Plack service, so you can place any other custom modules/packages that you create
    to use in your endpoints. You may choose to store scripts in here.

- `config`

    This will contain your main pepper.cfg file, which should only be updated via 'pepper setup'.
    If you do not opt to specify an option for 'url\_mappings\_database', the pepper\_endpoints.json file
    will be stored here as well.  Please store any other custom configurations.

- `psgi`

    This contains the pepper.psgi script used to run your services via Plack/Gazelle. 
    Please only modify if you are 100% sure of the changes you are making.

- `log`

    All logs generated by Pepper are kept here. This includes access and error logs, as well
    as any messages you save via $pepper->logger(). The primary process ID file is also 
    kept here.  Will not contain the logs created by Apache/Nginx or the database server.

- `template`

    This is where your Template Toolkit templates are kept. These can be used to create text
    files of any type, including HTML to return via the web.  Be sure to not remove the 
    'system' subdirectory or any of its files.

# USING APACHE AND SYSTEMD

Plack services, like Pepper, should not be exposed directly to the internet.
Instead, you should always have a full-featured web server like Apache and 
Nginx as a front-end for Plack, and be sure to use HTTPS / TLS.  The good news is 
that you only need to configure Apache / Nginx once (in a while).  

A sample pepper\_apache.conf file will be saved under $ENV{HOME}/pepper/template/system
after you run 'pepper setup'. Use this file as a basis for adding a virtual
host configuration under /etc/apache2/conf-enabled .  Several comments have been
added with friendly suggestions.  You will want to enable several Apahce modules:

        # a2enmod proxy ssl headers proxy_http rewrite

Nginx is a fine web server, but I recommend Apache as it can be integrated with
ModSecurity with much less effort.  

Use Systemd keep Pepper online as a server (like Apache or MySQL).  You will 
find an example SystemD service/config file at $ENV{HOME}/pepper/template/system/pepper.service .
Customize this to your needs, such as changing the '30' on the 'ExecStart' line 
to have more/less workers, and follow your OS guides to install as a SystemD service.

# REGARDING AUTHENTICATION & SECURITY

Pepper does not provide user authentication beyond looking for the 'Authorization'
header -- but you will need to validate that in your custom code. 

For basic projects, Auth0 has a generous free tier and can be easily integrated with
Apache [https://auth0.com/docs/quickstart/webapp/apache](https://auth0.com/docs/quickstart/webapp/apache) so your Perl code will
be able to see the user's confirmed identify in %ENV.

You can also configure Apache/OpenID to authenticate against Google's social login
without modifying your Perl code: [https://spin.atomicobject.com/2020/05/09/google-sso-apache/](https://spin.atomicobject.com/2020/05/09/google-sso-apache/)

It is easy to configure htaccess/htpasswd authentication in Apache, which places
the username in $ENV{REMOTE\_USER} for your Perl.  This may not be the most secure solution,
but it may suit your needs fine.  [https://httpd.apache.org/docs/2.4/howto/auth.html](https://httpd.apache.org/docs/2.4/howto/auth.html)

Please do set up HTTPS with TLS 1.2+, and please look into ModSecurity with the OWASP ruleset.

# ABOUT THE NAME

Our first two Shih Tzu's were Ginger and Pepper.  Ginger was the most excellent, amazing
creature to ever grace the world. Pepper was a sickly ragamuffin. Ginger chased pit bulls 
like mice and commanded the wind itself, but Pepper was your friend.  Pepper was easy to love 
and hard to disappoint, just like Perl.  

# SEE ALSO

[https://perlmaven.com/](https://perlmaven.com/)

[https://perldoc.perl.org/](https://perldoc.perl.org/)

[http://www.template-toolkit.org/](http://www.template-toolkit.org/)

[https://metacpan.org](https://metacpan.org)

[DBI](https://metacpan.org/pod/DBI)

[DateTime](https://metacpan.org/pod/DateTime)

[Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS)

[Mojolicious](https://metacpan.org/pod/Mojolicious)

[Mojolicious::Lite](https://metacpan.org/pod/Mojolicious%3A%3ALite)

[Dancer2](https://metacpan.org/pod/Dancer2)

# AUTHOR

Eric Chernoff <eric@weaverstreet.net>

Please send me a note with any bugs or suggestions.

# LICENSE

MIT License

Copyright (c) 2020 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
