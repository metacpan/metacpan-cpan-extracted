package Telegram::BotKit::UpdateParser;
$Telegram::BotKit::UpdateParser::VERSION = '0.03';
# ABSTRACT: Module for parsing Telegram Update object. Resolve issue of getting text from inline or regular keyboard



use common::sense;

use Exporter qw(import);
our @EXPORT_OK = qw(get_chat_id get_text);


sub _parse {
	my $update = shift;
	if ($update->{message}{text}) {
		return { data => $update->{message}{text}, chat_id => $update->{message}{chat}{id} };
	}
	if ($update->{callback_query}{data}) {
		return { data => $update->{callback_query}{data}, chat_id => $update->{callback_query}{message}{chat}{id} };
	}
}


sub get_text {
	my $update = shift;
	_parse($update)->{data};
}



sub get_chat_id {
	my $update = shift;
	_parse($update)->{chat_id};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::BotKit::UpdateParser - Module for parsing Telegram Update object. Resolve issue of getting text from inline or regular keyboard

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Telegram::BotKit::UpdateParser qw(get_text get_chat_id);

	my $text = get_text($update);
	my $chat_id = get_chat_id($update);

=head1 METHODS

=head2 get_text

Get message text from L<Update object|https://core.telegram.org/bots/api/#update>

=head2 get_chat_id

Get chat_id from L<Update object|https://core.telegram.org/bots/api/#update>

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
