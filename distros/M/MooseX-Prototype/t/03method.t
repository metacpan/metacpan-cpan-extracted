use MooseX::Prototype;

my $EmailAddress = object {
	'local_part'   => undef,
	'domain_part'  => undef,
	'&to_string'   => sub {
		my ($self) = @_;
		join '@', $self->local_part, $self->domain_part;
	},
};

use Test::More tests => 5;

my $GmailAddress = $EmailAddress->new(domain_part => 'gmail.com')->create_class;
ok(defined $GmailAddress);

my $HotmailAddress = $EmailAddress->new(domain_part => 'hotmail.com')->create_class('HotmailAddress');
is($HotmailAddress, 'HotmailAddress');

my $alice = $GmailAddress->new(local_part => 'alice');
is($alice->to_string, 'alice@gmail.com');

my $bob = $HotmailAddress->new(local_part => 'bob');
is($bob->to_string, 'bob@hotmail.com');

my $carol = $HotmailAddress->new(local_part => 'carol', domain_part => 'hotmail.co.uk');
is($carol->to_string, 'carol@hotmail.co.uk');
