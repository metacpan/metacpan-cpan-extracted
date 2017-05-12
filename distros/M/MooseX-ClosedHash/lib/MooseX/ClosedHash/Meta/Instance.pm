package MooseX::ClosedHash::Meta::Instance;

BEGIN {
	$MooseX::ClosedHash::Meta::Instance::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ClosedHash::Meta::Instance::VERSION   = '0.003';
}

use Moose::Role;
use Scalar::Util qw( isweak weaken );

sub get_fallback_closure
{
	return sub { die "unrecognized call to closure: $_[0]" };
}

sub get_fresh_closure
{
	my $meta  = shift;
	my %store = @_;
	
	my $fallback = $meta->get_fallback_closure;
	return sub {
		my ($action, $slot, $value) = @_;
		for (grep { defined and not ref } $action)
		{
			if (/fetch/)  { return $store{$slot} }
			if (/store/)  { return $store{$slot} = $value }
			if (/delete/) { return delete $store{$slot} }
			if (/exists/) { return exists $store{$slot} }
			if (/clone/)  { return %store }
			if (/clear/)  { return %store = () }
			if (/weaken/) { return weaken($store{$slot}) }
			if (/isweak/) { return isweak($store{$slot}) }
		}
		$fallback->(@_);
	};
}

override create_instance => sub {
	my $meta  = shift;
	my $class = $meta->associated_metaclass;
	bless($meta->get_fresh_closure => $class->name);
};

override clone_instance => sub {
	my ($meta, $instance) = @_;
	my $class = $meta->associated_metaclass;
	bless $meta->get_fresh_closure($instance->(clone => ())) => $class->name;
};

override get_slot_value => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->(fetch => $slot_name);
};

override set_slot_value => sub {
	my ($meta, $instance, $slot_name, $value) = @_;
	$instance->(store => $slot_name, $value);
};

override initialize_slot => sub { 1 };

override deinitialize_slot => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->(delete => $slot_name);
};

override deinitialize_all_slots => sub {
	my ($meta, $instance) = @_;
	$instance->(clear => ());
};

override is_slot_initialized => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->(exists => $slot_name);
};

override weaken_slot_value => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->(weaken => $slot_name);
};

override slot_value_is_weak => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->(isweak => $slot_name);
};

override inline_create_instance => sub {
	my ($meta, $klass) = @_;
	qq{ bless(\$meta->get_meta_instance->get_fresh_closure => $klass) }
};

override inline_slot_access => sub {
	my ($meta, $instance, $slot_name) = @_;
	qq{ $instance->(fetch => "$slot_name") }
};

override inline_get_is_lvalue => sub {
	0
};

override inline_get_slot_value => sub {
	my ($meta, $instance, $slot_name) = @_;
	qq{ $instance->(fetch => "$slot_name") }
};

override inline_set_slot_value => sub {
	my ($meta, $instance, $slot_name, $value) = @_;
	qq{ $instance->(store => "$slot_name", $value) }
};

override inline_initialize_slot => sub {
	my ($meta, $instance, $slot_name) = @_;
	qq{}
};

override inline_deinitialize_slot => sub {
	my ($meta, $instance, $slot_name) = @_;
	qq{ $instance->(delete => "$slot_name") }
};

override inline_is_slot_initialized => sub {
	my ($meta, $instance, $slot_name) = @_;
	qq{ $instance->(exists => "$slot_name") }
};

override inline_weaken_slot_value => sub {
	my ($meta, $instance, $slot_name, $value) = @_;
	qq{ $instance->(weaken => "$slot_name", $value) }
};

1;
