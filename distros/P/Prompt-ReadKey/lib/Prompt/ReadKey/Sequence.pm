#!/usr/bin/perl

package Prompt::ReadKey::Sequence;
use Moose;

use Prompt::ReadKey;
use Prompt::ReadKey::Util;

use Tie::RefHash;
use Set::Object qw(set);

use List::Util qw(first);

has items => (
	isa => "ArrayRef",
	is  => "rw",
	default => sub { [ ] },
);

has default_prompt => (
	init_arg => "prompt",
	isa => "Str",
	is  => "rw",
);

has default_options => (
	init_arg => "options",
	isa => "ArrayRef[HashRef]",
	is  => "rw",
	default => sub { [ ] },
);

has item_arguments => (
	isa => "HashRef[HashRef]",
	is  => "rw",
	default => sub { tie my %hash, 'Tie::RefHash'; \%hash },
);

has prompt_object => (
	isa => "Object",
	is  => "rw",
	default => sub { Prompt::ReadKey->new },
);

has additional_prompt_args => (
	isa => "ArrayRef",
	is  => "rw",
	default => sub { [] },
);

has prompt_format => (
	isa => "Str",
	is  => "rw",
	default => '%(prompt)s  (%(item_num)d/%(item_count)d)  [%(option_keys)s] ',
);

has movement => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has wait => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has wait_help => (
	isa => "Str",
	is  => "rw",
	default => "Wait with this item, and reprompt later.",
);

has wait_keys => (
	isa => "ArrayRef",
	is  => "rw",
	default => sub { [qw(w)] },
);

has prev_help => (
	isa => "Str",
	is  => "rw",
	default => "Skip to previous item.",
);

has prev_keys => (
	isa => "ArrayRef[Str]",
	is  => "rw",
	default => sub { ["k", "\x{1b}[A", "\x{1b}[D" ] }, # up arrow, left arrow
);

has next_help => (
	isa => "Str",
	is  => "rw",
	default => "Skip to next item.",
);

has next_keys => (
	isa => "ArrayRef[Str]",
	is  => "rw",
	default => sub { ["j", "\x{1b}[B", "\x{1b}[C" ] }, # down arrow, right arrow
);

# trés ugly...
# perhaps it should be converted to CPS style code
sub run {
	my ( $self, @args ) = @_;

	my @items = $self->_get_arg_or_default( "items", @args );

	my $item_args = $self->_get_arg_or_default( "item_arguments", @args );

	tie my %answers, 'Tie::RefHash';

	my $cur_item = 0;
	my $done = set();

	foreach my $arg (qw(options prompt prompt_format)) {
		unshift @args, $arg => scalar( $self->_get_arg_or_default($arg, @args) );
	}

	@answers{@items} = map { $self->get_prompt_object_and_args( @args, item => $_ ) } @items;

	loop: while ( $done->size < @items ) {
		my $item = $items[$cur_item];

		local $@;

		my $option = $self->prompt_for_item(
			@args,
			%{ $answers{$item} }, # reuse the existing objects, and also pass default_option if it was already answered
			done       => $done,
			done_count => $done->size,
			items      => \@items,
			item_count => scalar(@items),
			last_item  => $#items,
			item_index => $cur_item,
			item_num   => $cur_item + 1,
			item       => $item,
		);

		if ( $option ) {
			if ( $option->{sequence_command} ) {
				if ( my $cb = $option->{callback} ) {
					$self->$cb(
						@args,
						option       => $option,
						item_index   => $cur_item,
						cur_item_ref => \$cur_item,
						items        => \@items,
						done         => $done,
						answer       => $answers{$item},
						answers      => \%answers,
					);
				} else {
					die "Sequence commands must have a callback";
				}

				next loop;
			} else {
				$answers{$item}{default_option} = $option;

				$done->insert($item);
				$cur_item = first { not exists $answers{ $items[$_] }{default_option} } 0 .. $#items;
				$cur_item ||= 0;
			}
		} else {
			# move to the end of the queue
			push @items, splice( @items, $cur_item, 1 );
		}
	}

	return $self->return_answers(
		answers => \%answers,
		items   => \@items,
	);
}

sub get_prompt_object_and_args {
	my ( $self, %args ) = @_;

	my $prompt_object = $self->_get_arg_or_default( "prompt_object", %args );
	my @prompt_args   = $self->_get_arg_or_default( "additional_prompt_args", %args );

	my $item = $args{item};

	return {
		%{ $self->_get_arg_or_default( item_arguments => %args )->{$item} || {} },
		item                   => $item,
		prompt_object          => $prompt_object,
		additional_prompt_args => \@prompt_args,
	}
}

sub return_answers {
	my ( $self, %args ) = @_;

	my $answers = $args{answers};

	foreach my $item ( keys %$answers ) {
		my ( $obj, $args, $opt ) = @{ $answers->{$item} }{qw(prompt_object additional_prompt_args default_option)};
		$answers->{$item} = $obj->option_to_return_value( @$args, option => $opt );
	}

	return $answers;
}

sub prompt_for_item {
	my ( $self, %args ) = @_;

	my ( $prompt, $args ) = @args{qw(prompt_object additional_prompt_args)};

	$prompt->prompt(
		%args,
		@$args,
		$self->create_movement_options( %args ),
		return_option => 1,
	);
}

sub create_movement_options {
	my ( $self, %args ) = @_;

	my $item_count = $args{item_count};

	return if $item_count == 1; # no movement if there's just one item

	my $done_count = $args{done_count};
	my $cur_item   = $args{item_index};
	my $last_item  = $args{last_item}; 

	my @additional = _get_arg( additional_options => %args );

	push @additional, $self->create_prev_command(%args) if $cur_item > 0;
	push @additional, $self->create_next_command(%args) if $cur_item < $last_item;
	push @additional, $self->create_wait_command(%args) if $item_count > ( $done_count + 1 ); # this is not the last remaining item

	return ( additional_options => \@additional );
}

sub create_prev_command {
	my ( $self, @args ) = @_;

	$self->create_movement_option(
		@args,
		name => "prev",
		doc  => $self->_get_arg_or_default( prev_help => @args ),
		keys => [ $self->_get_arg_or_default( prev_keys => @args ) ],
		callback => sub {
			my ( $self, %args ) = @_;
			${ $args{cur_item_ref} }--;
		},
	);
}

sub create_next_command {
	my ( $self, @args ) = @_;

	$self->create_movement_option(
		@args,
		name => "next",
		doc  => $self->_get_arg_or_default( next_help => @args ),
		keys => [ $self->_get_arg_or_default( next_keys => @args ) ],
		callback => sub {
			my ( $self, %args ) = @_;
			${ $args{cur_item_ref} }++;
		},
	);
}

sub create_wait_command {
	my ( $self, @args ) = @_;

	$self->create_movement_option(
		@args,
		name => "wait",
		doc  => $self->_get_arg_or_default( wait_help => @args ),
		keys => [ $self->_get_arg_or_default( wait_keys => @args ) ],
		callback => sub {
			my ( $self, %args ) = @_;
			push @{ $args{items} }, splice( @{ $args{items} }, $args{item_index}, 1 );
		},
	);
}

sub create_movement_option {
	my ( $self, %args ) = @_;

	return {
		name     => $args{name},
		doc      => $args{doc},
		keys     => $args{keys},
		callback => $args{callback},
		sequence_command => 1,
	};
}

sub set_option_for_item {
	my ( $self, %args ) = @_;

	my $item   = $args{item};

	$args{done}->insert($item);

	$args{answers}{$item}{default_option} = $args{option};
}

sub set_option_for_remaining_items {
	my ( $self, %args ) = @_;

	$args{done}->insert(@{ $args{items} });

	my $option = $args{option};

	$_->{default_option} ||= $option for values %{ $args{answers} };
}

sub set_option_for_all_items {
	my ( $self, %args ) = @_;

	$args{done}->insert(@{ $args{items} });

	my $option = $args{option};

	$_->{default_option} = $option for values %{ $args{answers} };
}

__PACKAGE__

__END__

=pod

=head1 NAME

Prompt::ReadKey::Sequence - Prompt for a series of items with additional
movement options.

=head1 SYNOPSIS

	use Prompt::ReadKey::Sequence;

	my $seq = Prompt::ReadKey::Sequence->new(
		options => ..,
		items => \@items,
	);

	my $answers = $seq->run;

	my $first_answer = $answers->{ $item[0] };

=head1 DESCRIPTION

=cut


