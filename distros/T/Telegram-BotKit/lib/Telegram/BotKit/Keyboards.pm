package Telegram::BotKit::Keyboards;
$Telegram::BotKit::Keyboards::VERSION = '0.03';
# ABSTRACT: Easy creation of keyboards for Telegram bots


use common::sense;
use JSON::MaybeXS;
use Encode qw(decode);

use Exporter qw(import);
our @EXPORT_OK = qw(create_one_time_keyboard create_inline_keyboard parse_reply_markup available_keys);

my $is_inline_flag = 0;   # 1 = inline / 0 = one item at column




sub create_one_time_keyboard {
	my ($keys, $k_per_row) = @_;
	if (!(defined $k_per_row)) { 
		if ($is_inline_flag) { $k_per_row = scalar @$keys } else { $k_per_row = 1 };
	}

	my @keyboard;
	my @row;
	for my $i (1 .. scalar @$keys) { 
		my $el = $keys->[$i-1];
		push @row, $el;
		if ((($i % $k_per_row) == 0) || ($i == scalar @$keys)) {
			push (@keyboard, [ @row ]);
			@row=();
		}
	}

	my %rpl_markup = (
		keyboard => \@keyboard,
		one_time_keyboard => JSON::MaybeXS::JSON->true
		);
	my $json = JSON::MaybeXS->new(utf8 => 1);
	return decode('UTF-8', $json->encode(\%rpl_markup));
}


sub create_inline_keyboard {
	my ($keys, $k_per_row) = @_;
	if (!(defined $k_per_row)) { 
		if ($is_inline_flag) { $k_per_row = scalar @$keys } else { $k_per_row = 1 };
	}
	my @keyboard;
	my @row;
	for my $i (1 .. scalar @$keys) { 
		my $el = $keys->[$i-1];
		push @row, { "text" => $el, "callback_data" => $el };
		if ((($i % $k_per_row) == 0) || ($i == scalar @$keys)) {
			push (@keyboard, [ @row ]);
			@row=();
		}
	}
	my %rpl_markup = (
		inline_keyboard  => \@keyboard
	);
	my $json = JSON::MaybeXS->new(utf8 => 1);
	return decode('UTF-8', $json->encode(\%rpl_markup));
}



sub available_keys {
	my $arr = shift;
	my $text = '[ ';
	$text.= join(' | ',@$arr);
	$text.= ' ]';
	return $text;
}


sub parse_reply_markup {
	my $reply_markup = shift;
	my $data_structure = decode_json($reply_markup);
	my @res;
	my @keyboard;
	my $is_inline_flag = 0;

	if (defined $data_structure->{inline_keyboard}) {
		@keyboard = {$data_structure->{inline_keyboard}};
		$is_inline_flag = 1;
	} elsif (defined $data_structure->{keyboard}) {
		@keyboard = @{$data_structure->{keyboard}};
	} else {
		warn "reply_markup structure isn't recognized";
		return undef;
	}

	for my $i (@keyboard) {
		for (@$i) {
			if ($is_inline_flag) {
				push @res, $_->{text};
			} else {
				push @res, $_;
			}
		}
	}

	return \@res;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::BotKit::Keyboards - Easy creation of keyboards for Telegram bots

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Telegram::Keyboards qw(create_one_time_keyboard create_inline_keyboard);

	my $api = WWW::Telegram::BotAPI->new(token => 'my_token');

	$api->sendMessage ({
	    chat_id      => 123456,
	    text => 'This is a regular keyboard',
	    reply_markup => create_one_time_keyboard(['Button1','Button2'])
	});

	$api->sendMessage ({
	    chat_id      => 123456,
	    text => 'This is a regular keyboard',
	    reply_markup => create_inline_keyboard(['Button1','Button2'], 2)
	});

=head1 METHODS

=head2 create_one_time_keyboard

Create a regular one time keyboard. 
For using with (L<reply_markup|https://core.telegram.org/bots/api/#sendmessage>) 
param of API sendMessage method

$keyboard = create_one_time_keyboard($arrayref, $max_keys_per_row);

$api->sendMessage ({
    chat_id      => 123456,
    reply_markup => $keyboard
});

If no $max_keys_per_row specified keyboard will have only one column

=head2 create_inline_keyboard

Create an INLINE keyboard. 
For using with (L<reply_markup|https://core.telegram.org/bots/api/#sendmessage>) 
param of API sendMessage method

my $api = WWW::Telegram::BotAPI->new (
    token => 'my_token'
);

# $keyboard = create_one_time_keyboard($arrayref, $max_keys_per_row);
$keyboard = create_one_time_keyboard(['Button1', 'Button2', 'Button3'], 2);

$api->sendMessage ({
    chat_id      => 123456,
    reply_markup => $keyboard
});

=head2 available_keys

Helper function for tg-botkit simulator. 
Return string of possible answers in L<Backus–Naur notation|https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form>

print Dumper available_keys(['B1', 'B2', 'B3' ]) #  '[ B1 | B2 | B3 ]'

=head2 parse_reply_markup

Helper function for tg-botkit simulator. 
Function opposite to create_inline_keyboard and create_one_time_keyboard
Transform $reply_markup JSON object into perl array

=head1 TODO

=head2 build_optimal()

build keyboard with optimalrows and columns based on keyboard content

=head2 build_optimal_according_order()

build keyboard with optimal rows and columns based on keyboard content
WITHOUT changing buttons order

= cut

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
