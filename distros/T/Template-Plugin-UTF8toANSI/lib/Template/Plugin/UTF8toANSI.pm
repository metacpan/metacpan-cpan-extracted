package Template::Plugin::UTF8toANSI;

use 5.006;
use strict;



my $FILTER_NAME = 'utf8_to_ansi';

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use Unicode::String qw(utf8 latin1);

our $VERSION = '0.02';

sub init {
    my $self = shift;

    $self->install_filter($FILTER_NAME);

    return $self;
}
   
sub filter {
    my ($self, $text) = @_;
   

    $text = latin1( utf8( $text ) );
 
   
    return $text;
}

1;

__END__

=head1 NAME

Template::Plugin::UTF8toANSI - Filter for Template Toolkit to convert UTF8 to ANSI

=head1 SYNOPSIS

  [% USE UTF8toANSI %]

  [% ansi_string_var | utf8_to_ansi %]

=head1 DESCRIPTION

This module converts strings in template toolkit from UTF8 to ansi. I use that to prepare RTF documents, which are
ansi coded by using text from UTF8 coded MySQL databases.

=head1 METHODS

=head2 init

Installs the filter as 'utf8_to_ansi'.

=head2 filter

Receives a reference to the plugin object, along with the text to be
filtered.

=head1 AUTHOR

Andreas Hernitscheck ahernit AT cpan . org

=head1 COPYRIGHT AND LICENSE

This module is under the artistic licence and LGPL.

=cut