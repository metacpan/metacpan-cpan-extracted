package Mozilla::ConsoleService;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::ConsoleService ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Mozilla::ConsoleService', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mozilla::ConsoleService - Perl interface to Mozilla nsIConsoleService

=head1 SYNOPSIS

  use Mozilla::ConsoleService;

  my $handle = Mozilla::PromptService::Register(sub { print $_[0]; });

  # when no longer needed
  Mozilla::PromptService::Unregister($handle);

=head1 DESCRIPTION

Mozilla::ConsoleService uses Mozilla nsIConsoleService to pass log messages to
perl code, similar to JavaScript Console in Mozilla.

For more detailed documentation on nsIConsoleService see Mozilla's
documentation.

=head1 METHODS

=head2 Register($callback)

Registers callback to get log messages. Log messages are passed as strings.

Returns handle to be used for Unregister

=head2 Unregister($handle)

Unregisters ConsoleService listener.

=head1 SEE ALSO

Mozilla nsIConsoleService documentation,
L<Mozilla::Mechanize|Mozilla::Mechanize>.

=head1 AUTHOR

Boris Sukholitko, E<lt>boriss@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Boris Sukholitko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
