package Mozilla::PromptService;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::PromptService ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Mozilla::PromptService', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mozilla::PromptService - Perl interface to the Mozilla nsIPromptService 

=head1 SYNOPSIS

    use Mozilla::PromptService;

    Mozilla::PromptService::Register({
        Alert => sub {
            my ($parent, $title, $dialog_text) = @_;
            # do something smart on alert ...
        },
	# Prompt callback should return result
	Prompt => sub { return "Prompt Result" },
        DEFAULT => sub {
            my ($name, $parent, $title, $dialog_text) = @_;
            # some other confirmation is needed
        }
    }

=head1 DESCRIPTION

Mozilla::PromptService uses Mozilla nsIPromptService to allow perl callbacks on
prompt events.

For a much more detailed information on nsIPromptService see documentation on
L<mozilla.org|mozilla.org>

=head1 METHODS

=head2 Register($callbacks_hash)

Registers callbacks (values of the C<$callbacks_hash>) to the prompt events
specified by corresponding keys of the C<$callbacks_hash>.

Each callback function gets parent window, dialog title, dialog text as its
parameters.

Special C<DEFAULT> key can be used to provide one callback for all events.
The callback function will get name of the event as its first parameter.

C<Prompt> callback should return result which will be passed back to JavaScript.
If it returns C<undef> cancel flag will be set.

=head1 SEE ALSO

Mozilla nsIPromptService documentation at L<mozilla.org|mozilla.org>,
L<Gtk2::MozEmbed|Gtk2::MozEmbed>,
L<Mozilla::DOM|Mozilla::DOM>,
L<Mozilla::Mechanize|Mozilla::Mechanize>.

=head1 AUTHOR

Boris Sukholitko, E<lt>boris@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Boris Sukholitko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
