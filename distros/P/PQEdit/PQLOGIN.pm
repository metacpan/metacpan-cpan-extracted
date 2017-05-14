package PQLOGIN;

use SQL::Password;

sub Fetch {
    my($server) = shift;
    my($database) = shift;
    my($login) = shift;
    my(%login_info) = (
		     "myserver1\tmydb1\t1" => ( 'myuser', 'mypassword'),
		     "myserver1\tmydb2\t1" => ( 'myuser', 'mypassword')
		     );
    return $login_info{"$server\t$database\t$login"};
}

1;
