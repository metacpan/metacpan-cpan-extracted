package Mozilla::SourceViewer;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::SourceViewer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(Get_Page_Source);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Mozilla::SourceViewer', $VERSION);

use File::Slurp;
use Carp;
use File::Temp qw(tempfile);

sub Get_Page_Source {
	my (undef, $tf) = tempfile();
	Get_Page_Source_Into_File($_[0], $tf);
	confess "# Wasn't able to get $tf" unless -f $tf;
	my $res = read_file($tf);
	unlink($tf);
	return $res;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mozilla::SourceViewer - Perl extension to get current page source.

=head1 SYNOPSIS

  use Mozilla::SourceViewer;

  print Get_Page_Source($moz_embed);

=head1 DESCRIPTION

This module allows to get current page source (similar to view source in
Firefox). It exports one function Get_Page_Source which get GtkMozEmbed as a
parameter and returns source of currently loaded page.

=head2 EXPORT

This module exports Get_Page_Source function. 

=head1 SEE ALSO

Mozilla::DOM, Gtk2::MozEmbed, Mozilla::Mechanize

=head1 AUTHOR

Boris Sukholitko, E<lt>boris@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Boris Sukholitko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
