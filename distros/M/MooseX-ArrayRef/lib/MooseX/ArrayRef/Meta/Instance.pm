package MooseX::ArrayRef::Meta::Instance;

BEGIN {
	$MooseX::ArrayRef::Meta::Instance::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ArrayRef::Meta::Instance::VERSION   = '0.005';
}

use Moose::Role;
use Scalar::Util qw( isweak weaken );

use constant EMPTY => \0;

# Delegate certain methods to the metaclass
BEGIN {
	no strict 'refs';
	foreach my $m (qw( slot_index slot_count ))
	{
		*$m = sub {
			my $meta = shift;
			$meta->associated_metaclass->$m(@_);
		}
	}
}

override create_instance => sub {
	my $meta  = shift;
	my $class = $meta->associated_metaclass;
	bless [ (EMPTY) x $meta->slot_count ] => $class->name;
};

override clone_instance => sub {
	my ($meta, $instance) = @_;
	my $class = $meta->associated_metaclass;
	bless [ @{$instance} ] => $class->name;
};

override get_slot_value => sub {
	my ($meta, $instance, $slot_name) = @_;
	my $value = $instance->[ $meta->slot_index($slot_name) ];
	return if $value == EMPTY;
	return $value;
};

override set_slot_value => sub {
	my ($meta, $instance, $slot_name, $value) = @_;
	$instance->[ $meta->slot_index($slot_name) ] = $value;
};

override initialize_slot => sub { 1 };

override deinitialize_slot => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->[ $meta->slot_index($slot_name) ] = EMPTY;
};

override deinitialize_all_slots => sub {
	my ($meta, $instance) = @_;
	@$instance = ( (EMPTY) x $meta->slot_count );
};

override is_slot_initialized => sub {
	my ($meta, $instance, $slot_name) = @_;
	$instance->[ $meta->slot_index($slot_name) ] != EMPTY;
};

override weaken_slot_value => sub {
	my ($meta, $instance, $slot_name) = @_;
	weaken $instance->[ $meta->slot_index($slot_name) ];	
};

override slot_value_is_weak => sub {
	my ($meta, $instance, $slot_name) = @_;
	isweak $instance->[ $meta->slot_index($slot_name) ];	
};

override inline_create_instance => sub {
	my ($meta, $klass) = @_;
	my $slots = $meta->slot_count;
	qq{ bless [ (MooseX::ArrayRef::Meta::Instance::EMPTY) x $slots ], $klass }
};

override inline_slot_access => sub {
	my ($meta, $instance, $slot_name) = @_;
	my $i = $meta->slot_index($slot_name);
	$instance."->[$i]"
};

override inline_get_slot_value => sub {
	my ($meta, $instance, $slot_name) = @_;
	my $get = $meta->inline_slot_access($instance, $slot_name);
	sprintf('do { no warnings; %s == MooseX::ArrayRef::Meta::Instance::EMPTY ? undef : %s }', $get, $get);
};

override inline_deinitialize_slot => sub {
	my ($meta, $instance, $slot_name) = @_;
	my $get = $meta->inline_slot_access($instance, $slot_name);
	sprintf('%s = MooseX::ArrayRef::Meta::Instance::EMPTY', $get);
};

override inline_is_slot_initialized => sub {
	my ($meta, $instance, $slot_name) = @_;
	my $get = $meta->inline_slot_access($instance, $slot_name);
	sprintf('do { no warnings; %s != MooseX::ArrayRef::Meta::Instance::EMPTY }', $get);
};

1;

