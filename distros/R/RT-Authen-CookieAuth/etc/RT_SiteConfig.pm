# This determines whether a cookie service should be used to
# attempt to authenticate users. 

Set($UseExternalCookieAuthService,  1);

# AN EXAMPLE COOKIE SERVICE
#
# This cookie service was designed for a bespoke customer-facing website and may not 
# suit yours. The design is such that, when the user logs into a website, the website 
# will set a cookie with a hash_string, and then record in a database table what the 
# string was and what userID was assigned it (as well as when and to what IP).
#
# RT authenticates with it like this (auth if user found):
# SELECT users_table.username 
# FROM users_table,cookie_table 
# WHERE users_table.userID = cookie_table.userID
# AND cookie_table.COOKIE_NAME = COOKIE_VALUE
#
# If one and only one result is found, the username returned is considered a valid user.
#
# DB Service name is the name of an ExternalAuth database service as configured for
# RT-Authen-ExternalAuth

Set($CookieSettings,    {   # The name of the cookie to be used
                            'name'                      =>  'loginCookieValue',
                            # The users table
                            'u_table'                   =>  'users',
                            # The username field in the users table
                            'u_field'                   =>  'username',
                            # The field in the users table that uniquely identifies a user
                            # and also exists in the cookies table
                            'u_match_key'               =>  'userID',
                            # The cookies table
                            'c_table'                   =>  'login_cookie',
                            # The field that stores cookie values
                            'c_field'                   =>  'loginCookieValue',
                            # The field in the cookies table that uniquely identifies a user
                            # and also exists in the users table
                            'c_match_key'               =>  'loginCookieUserID',
                            # The DB service to use to lookup the cookie information
                            'db_service_name'           =>  'My_MySQL'
                    }
);

1;
