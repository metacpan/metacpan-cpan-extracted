package Telegram::BotKit::Screens;
$Telegram::BotKit::Screens::VERSION = '0.03';
# ABSTRACT: Implements navigation by screens JSON file. Used by Telegram::BotKit::Wizard


use common::sense;
use Data::Dumper;

sub new {
    my $class = shift;
    my $s = {};
    $s->{scrns} = shift; # Array with all screens
    bless $s, $class;
    return $s; 
}


sub _get_all_screens {
    my $self = shift;
    return $self->{scrns};
}


sub get_screen_by_name {
	my ($self, $screen_name) = @_;
	for (@{$self->_get_all_screens}) {
		if ($_->{name} eq $screen_name) {
			return $_;
		}
	}
	return undef;
}


sub get_next_screen_by_name {
	my ($self, $screen_name, $text) = @_;
	my @candidates_to_return = grep ($_->{parent} eq $screen_name, @{$self->_get_all_screens});
	if (scalar @candidates_to_return == 1) {
		return $candidates_to_return[0];
	} 
	elsif (scalar @candidates_to_return > 1) {
		if ($text) {
			for (@candidates_to_return) {
				if ($_->{callback_msg} eq $text) {
					return $_;
				}
			}
		} else {
			if ($candidates_to_return[0]->{callback_msg}) {
				# patch for is_last screen() function, it has only one argument ($screen name) and must "screen" object
				return $candidates_to_return[0];
			} else {
				# two or more child screens with same parent and without callback_msg specific  
				die "wrong json file";
			}
		}
	} else {
		return undef;
	}
}


sub get_prev_screen_by_name {
	my ($self, $screen_name) = @_;
	for (@{$self->_get_all_screens}) {
		if ($_->{name} eq $screen_name) {
			return $self->get_screen_by_name($_->{parent});
		}
	}
	return undef;
}



sub level {
	my ($self, $screen_name) = @_;
	my $i = 0;
	my $prev_screen = $self->get_prev_screen_by_name($screen_name);

	while (defined $prev_screen )  {
		$i++;
		$prev_screen = $self->get_prev_screen_by_name($prev_screen->{name});
	}
	return $i;
}




sub get_screen_by_start_cmd {
	my ($self, $cmd) = @_;
	for my $s (@{$self->_get_all_screens}) {
		if ($s->{start_command} eq $cmd) {   # don't use eq here
			return $s;
		}
	}
	return undef;
}


sub is_last_screen {
    my ($self, $screen_name) = @_;
    if (defined $self->get_next_screen_by_name($screen_name)) {
    	return 0;
    }
    return 1;
}



sub is_first_screen {
    my ($self, $screen_name) = @_;
    if (defined $self->get_prev_screen_by_name($screen_name)) {
    	return 0;
    }
    return 1;
}


sub is_static {
	my ($self, $screen) = @_;
	if ($screen->{keyboard}) {
		return 1;
	} else {
		return 0;
	}
}



sub get_keys_arrayref {
	my ($self, $screen_name) = @_;
	my @a;
	for (@{$self->get_screen_by_name($screen_name)->{keyboard}}) {
		push @a, $_->{key};
	}
	return \@a;
}



sub get_answers_arrayref {
	my ($self, $screen_name) = @_;
	my @a;
	for (@{$self->get_screen_by_name($screen_name)->{keyboard}}) {
		push @a, $_->{answ};
	}
	return \@a;
}



sub get_answ_by_key {
	my ($self, $screen_name, $msg) = @_;
	my $s = $self->get_screen_by_name($screen_name)->{keyboard};
	for (@$s) {
		if ($msg eq $_->{key}) {
			return $_->{answ};
		}
	}
	return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::BotKit::Screens - Implements navigation by screens JSON file. Used by Telegram::BotKit::Wizard

=head1 VERSION

version 0.03

=head1 SYNOPSIS

	# $screens_arrayref:

	"screens" : [
	    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
	      [
	        { "key": "Item 1", "answ" : "Good" },
	        { "key": "Item 2", "answ" : "Well" },
	        { "key": "Item 3", "answ" : "Fine" }
	      ] 
	    }, 
	    { "name": "day_select", "parent": "item_select", "welcome_msg": "Please select a day", "keyboard":
	      [
	        { "key": "today" }, 
	        { "key": "tomorrow" }
	      ]
    	},
	    { "name": "today_time_picker", 
	      "parent": "day_select", 
	      "callback_msg": "today", 
	      "kb_build_func": "dynamic1_build_func"
	    },
	    { "name": "tomorrow_time_picker", 
	      "parent": "day_select", 
	      "callback_msg": "tomorrow", 
	      "kb_build_func": "dynamic2_build_func"
	    }
    ]

	use Telegram::Screens;
	my $screens->Telegram::Screens->new($screens_arrayref);
	
	$screens->get_screen_by_name("item_select")->{name}; # day_select
	
	$screens->get_next_screen_by_name("item_select")->{name}; # day_select
	$screens->get_next_screen_by_name("day_select", "today")->{name}; # today_time_picker
	
	$screens->get_prev_screen_by_name("day_select")->{name}; # item_select
	
	$screens->level("item_select");  # 0
	$screens->level("day_select");  # 1
	$screens->level("today_time_picker");  # 2
	$screens->level("tomorrow_time_picker");  # 2

	$screens->get_screen_by_start_cmd("/book")->{name}; # item_select

	$screen->is_last_screen('item_select'); # 0
	$screen->is_last_screen('tomorrow_time_picker'); # 1

	$screens->get_keys_arrayref('item_select'); # ["Item 1", "Item 2", "Item 3"]
	
	$screens->get_keys_arrayref('item_select'); # ["Good", "Well", "Fine"]

	$screens->get_answ_by_key('item_select', 'Item 1');  # Good

=head1 METHODS

=head2 get_screen_by_name 

Return screen item by its name

Screen name must be unique accross json file

$screens->get_screen_by_name("item_select")->{name}; # item_select

=head2 get_next_screen_by_name

Return next screen item by current screen name and text reply on current screen

Resolve screen relationships by parent and callback_msg fields

	"screens" : [
	    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
	      [
	        { "key": "Item 1", "answ" : "Good" },
	        { "key": "Item 2", "answ" : "Well" },
	        { "key": "Item 3", "answ" : "Fine" }
	      ] 
	    }, 
		{ "name": "day_select", "parent": "item_select", "welcome_msg": "Please select a day", "keyboard":
	      [
	        { "key": "today" }, 
	        { "key": "tomorrow" }
	      ]
    	},
	    { "name": "today_time_picker", 
	      "parent": "day_select", 
	      "callback_msg": "today", 
	      "kb_build_func": "dynamic1_build_func"
	    },
	    { "name": "tomorrow_time_picker", 
	      "parent": "day_select", 
	      "callback_msg": "tomorrow", 
	      "kb_build_func": "dynamic2_build_func"
	    }
	]

$screens->get_next_screen_by_name("item_select")->{name}; # day_select
$screens->get_next_screen_by_name("day_select", "today")->{name}; # today_time_picker
$screens->get_next_screen_by_name("day_select", "todmorrow")->{name}; # tomorrow_time_picker

=head2 get_prev_screen_by_name

Return previous screen

$screens->get_prev_screen_by_name("day_select")->{name}; # item_select

=head2 level

Return screen level according call sequence. First screen has level 0.

$screens->level("item_select");  # 0
$screens->level("day_select");  # 1

=head2 get_screen_by_start_cmd 

Return screen item if it contains start_command

	"screens" : [
	    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
	      [
	        { "key": "Item 1", "answ" : "Good" },
	        { "key": "Item 2", "answ" : "Well" },
	        { "key": "Item 3", "answ" : "Fine" }
	      ] 
	    }, ...
	 ]
	
	$screens->get_screen_by_start_cmd("/book")->{name}; # item_select

=head2 is_last_screen

Return true if screen is last screen

$screen->is_last_screen('item_select'); # 0
$screen->is_last_screen('tomorrow_time_picker'); # 1

=head2 is_first_screen

Return true if screen is first screen

$screen->is_last_screen('item_select'); # 1
$screen->is_last_screen('tomorrow_time_picker'); # 0

=head2 is_static

Return true if screen item has keyboard value (sign of static screen)

=head2 get_keys_arrayref

Return all "key" fields of "keyboard" property as array

"screens" : [
	    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
	      [
	        { "key": "Item 1", "answ" : "Good" },
	        { "key": "Item 2", "answ" : "Well" },
	        { "key": "Item 3", "answ" : "Fine" }
	      ] 
	    }, ...

$screens->get_keys_arrayref('item_select'); # ["Item 1", "Item 2", "Item 3"]

=head2 get_answers_arrayref

Return all "answ" fields of "keyboard" property as array

"screens" : [
	    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
	      [
	        { "key": "Item 1", "answ" : "Good" },
	        { "key": "Item 2", "answ" : "Well" },
	        { "key": "Item 3", "answ" : "Fine" }
	      ] 
	    }, ...

$screens->get_answers_arrayref('item_select'); # ["Good", "Well", "Fine"]

=head2 get_answ_by_key

Return reply to particular button

"screens" : [
	    { "name": "item_select", "start_command": "/book", "welcome_msg": "Please select an item to book", "keyboard":
	      [
	        { "key": "Item 1", "answ" : "Good" },
	        { "key": "Item 2", "answ" : "Well" },
	        { "key": "Item 3", "answ" : "Fine" }
	      ] 
	    }, ...

$screens->get_answ_by_key('item_select', 'Item 1');  # Good

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
