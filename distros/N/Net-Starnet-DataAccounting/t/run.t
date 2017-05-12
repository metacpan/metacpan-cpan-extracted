use Carp;
use Data::Dumper;
use Test::More tests => 11;
use strict;
use warnings;

$|++;

my $pkg = 'Net::Starnet::DataAccounting';
my $sda;

# Test set 1 - Can we load it?
#
BEGIN
{
    use_ok('Net::Starnet::DataAccounting');
}

do {
    my ($user, $pass) = qw/truskiai 118277/;

    $sda = $pkg->new(
	user => $user,
	pass => $pass,
	verbose => 0,
	login => \&login,
	logout => \&logout,
	update => \&update,
    );

    sub login  { return $_[1] };
    sub logout { return (@_) };
    sub update { return (@_) };
};

# Check that it instantiated correctly:
do {
    isa_ok $sda => $pkg;
};

# Check for appropriate methods:
do {
    my @methods = qw/_decode _encode login logout new update verbose/;
    can_ok($sda => @methods);
};

# Check that the verbose method works:
do {
    $sda->verbose(1);
    ok 1 == $sda->verbose, "Verbose set";
    $sda->verbose(0);
    ok 0 == $sda->verbose, "Verbose unset";
};

# Check that _encode and _decode work properly:
do {
    my @strings = (
	"1 truskiai 118277 150.203.232.210 0 Spoon-v1.1",
	'1 0 3 Login_Deny: Please check your data quota.',
    );
    my @values = (
	'1!vuyxqibk#56>289#5:6.3262792/444%6 Trrss3v204',
	'1!2#7%RohkqcIknz<#Tqkatg#gmkcl"|szx ecwe%wupvd2',
    );

    my @encoded   = map { Net::Starnet::DataAccounting::_encode($_) } @strings;
    my @decoded   = map { Net::Starnet::DataAccounting::_decode($_) } @values;
    my @deencoded = map { Net::Starnet::DataAccounting::_decode($_) } @encoded;
    my @endecoded = map { Net::Starnet::DataAccounting::_encode($_) } @decoded;

    ok eq_array(\@encoded   => \@values)    => " (\@encoded,   \@values)";
    ok eq_array(\@deencoded => \@strings)   => " (\@deencoded, \@strings)";
    ok eq_array(\@decoded   => \@strings)   => " (\@decoded,   \@strings)";
    ok eq_array(\@endecoded => \@values)    => " (\@endecoded, \@values)";
    ok eq_array(\@encoded   => \@endecoded) => "(\@encoded,   \@endecoded)";
    ok eq_array(\@decoded   => \@deencoded) => "(\@decoded,   \@deencoded)";
};

# Check response:
#TODO: {
    #    local $TODO = "Can we connect and make sense?";
#
#    my $response = $sda->login;
#
#    is($response, '1 0 3 Login_Deny: Please check your data quota.', "Response comparison.");
#};

