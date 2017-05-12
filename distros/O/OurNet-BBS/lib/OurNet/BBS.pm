# See BBS.pod for documentations.

package OurNet::BBS;
use 5.006001;

our $VERSION = 1.67;
our $Encoding = '';
our $CurrentUser = '';

use strict;
use warnings;
no warnings 'deprecated';
use OurNet::BBS::Utils;
use OurNet::BBS::Base (
    # the default fields for Maple2- and Maple3- derived BBS systems
    '@BOARDS'   => [qw/bbsroot brdshmkey maxboard/],
    '@FILES'    => [qw/bbsroot/],
    '@GROUPS'   => [qw/bbsroot/],
    '@SESSIONS' => [qw/bbsroot sessionshmkey maxsession chatport passwd/],
    '@USERS'    => [qw/bbsroot usershmkey maxuser/],
);

no strict 'refs';
my $sub_new = *{'new'}{CODE};

{
    no warnings 'redefine';

    sub new { 
	goto &{$sub_new} unless $_[0] eq __PACKAGE__;

	return $_[0]->fillmod(
	    (ref($_[1]) ? $_[1]->{backend} : $_[1]),  'BBS'
	)->new(@_[1 .. $#_])
    }           
}

# default permission settings
use constant readok  => 1;
use constant writeok => 0;

sub refresh_meta {
    my ($self, $key) = @_;

    return $self->fillin(
	$key, substr(ucfirst($key), 0, -1).'Group', 
	map($self->{$_}, @{uc($key)})
    );
}

sub import {
    my $class = shift;
    $Encoding = shift if @_;
}

1;
