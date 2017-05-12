{
	package Local::EmailAddress;
	use Moose;
	has [qw/local_part domain_part/] => (is => 'rw', isa => 'Str');
	sub to_string {
		my ($self) = @_;
		join '@', $self->local_part, $self->domain_part;
	}
}

use Test::More tests => 5;
use MooseX::Prototype create_class_from_prototype => { -as => q(use_as_prototype) };

my $GmailAddress = use_as_prototype(
	Local::EmailAddress->new( domain_part => 'gmail.com' )
	);
ok(defined $GmailAddress);

my $HotmailAddress = use_as_prototype(
	Local::EmailAddress->new( domain_part => 'hotmail.com' ),
	'HotmailAddress',
	);
is($HotmailAddress, 'HotmailAddress');

my $alice = $GmailAddress->new(local_part => 'alice');
is($alice->to_string, 'alice@gmail.com');

my $bob = $HotmailAddress->new(local_part => 'bob');
is($bob->to_string, 'bob@hotmail.com');

my $carol = $HotmailAddress->new(local_part => 'carol', domain_part => 'hotmail.co.uk');
is($carol->to_string, 'carol@hotmail.co.uk');
