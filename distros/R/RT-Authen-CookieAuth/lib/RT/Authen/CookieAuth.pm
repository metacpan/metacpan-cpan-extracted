package RT::Authen::CookieAuth;

use strict;
use DBI;
use CGI::Cookie;

our $VERSION = '0.02';

=head1 NAME

  RT::Authen::CookieAuth - Pulls a Cookie and checks it against an External DB

=head1 SYNOPSIS

  use lib "!!RT_LIB_PATH!!";
  use lib "!!RT_ETC_PATH!!";

  use RT::Authen::CookieAuth;

  RT::Authen::CookieAuth::CheckCookies();

=head1 DESCRIPTION


=begin testing

ok(require RT::Authen::CookieAuth);
ok(require RT::Authen::ExternalAuth);

=end testing


=head1 METHODS

=cut

# {{{ sub CheckCookies
sub CheckCookies {
    my $self = RT::User->new($RT::SystemUser);

    $RT::Logger->debug( (caller(0))[3],
                        "Checking Browser Cookies for an Authenticated User");

    my $confirmed_by_cookie = 0;
    my $user;

    my %cookies = CGI::Cookie->fetch();

    # Get our cookie and database info...
    my $config = $RT::CookieSettings;

    unless ($RT::UseExternalCookieAuthService){
        $RT::Logger->debug( "External Cookie Auth is not enabled.",
                            "Please check your config for \$UseExternalCookieAuthService");
        return (undef,0);
    }
    
    # The name of the cookie
    my $cookie_name = $config->{'name'};

    # The table mapping usernames to the Username Match Key
    my $u_table     = $config->{'u_table'};
    # The username field in that table
    my $u_field     = $config->{'u_field'};
    # The field that contains the Username Match Key
    my $u_match_key = $config->{'u_match_key'};
    
    # The table mapping cookie values to the Cookie Match Key
    my $c_table     = $config->{'c_table'};
    # The cookie field in that table - The same as the cookie name if unspecified
    my $c_field     = $config->{'c_field'};
    # The field that connects the Cookie Match Key
    my $c_match_key = $config->{'c_match_key'};

    # These are random characters to assign as table aliases in SQL
    # It saves a lot of garbled code later on
    my $u_table_alias = "u";
    my $c_table_alias = "c";

    # $tables will be passed straight into the SQL query
    my $tables;
    
    # If the tables are the same, then the aliases should be the same
    # and the match key becomes irrelevant. Ensure this all works out 
    # fine by setting both sides the same. In either case, set an
    # appropriate value for $tables.
    if ($u_table eq $c_table) {
	    $u_table_alias  = $c_table_alias;
	    $u_match_key    = $c_match_key;
	    $tables         = "$c_table $c_table_alias";	
    } else {
   	    $tables = "$c_table $c_table_alias, $u_table $u_table_alias";
    }

    # If the cookie is set, get the value, if it's not set, get out now!
    my $cookie_value;
    if (defined $cookies{$cookie_name}) {
       $cookie_value = $cookies{$cookie_name}->value;
       $RT::Logger->debug(  "Cookie Found!",
                            ":: $cookie_name ::",
                            "Attempting to use for authentication");
    } else {
        $RT::Logger->debug( "Cookie Auth Failed:",
                            "Cookie Not Assigned");
        return ($user,$confirmed_by_cookie);
    }

    my $select_fields = "$u_table_alias.$u_field";
    my $where_statement = "$c_table_alias.$c_field = ? AND $c_table_alias.$c_match_key = $u_table_alias.$u_match_key";

    my $query = "SELECT $select_fields FROM $tables WHERE $where_statement";
    my @params = ($cookie_value);
    my $service = 'Auth';

    # Use this if you need to debug the DBI SQL process
    # DBI->trace(1,'/tmp/dbi.log');        

    my $dbh = $self->_GetBoundDBIObj($RT::ExternalSettings->{$config->{'db_service_name'}});
    my $query_result_arrayref = $dbh->selectall_arrayref($query,{},@params);
    $dbh->disconnect();
    
    # The log messages say it all here...
    my $num_rows = scalar @$query_result_arrayref;
    my $confirmed_user;
    if ($num_rows < 1) {
        $RT::Logger->info(  "AUTH FAILED", 
                            $cookie_name,
                            "Cookie value not found in database.",
                            "User passed an authentication token they were not given by us!",
                            "Is this nefarious activity?");
    } elsif ($num_rows > 1) {
        $RT::Logger->error( "AUTH FAILED", 
                            $cookie_name,
                            "Cookie's value is duplicated in the database! This should not happen!!");
    } else {
        $user = $query_result_arrayref->[0][0];
        $confirmed_by_cookie = 1;
    }

    if ($confirmed_by_cookie == 1) {
        $RT::Logger->debug( "User (",
                            $user,
                            ") was authenticated by a browser cookie");
    } else {
        $RT::Logger->debug( "No user was authenticated by browser cookie");
    }

    return ($user,$confirmed_by_cookie);
}

# }}}

1;
