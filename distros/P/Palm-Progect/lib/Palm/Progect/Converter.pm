
use strict;
use 5.004;
use Carp;

package Palm::Progect::Converter;

=head1 NAME

Palm::Progect::Converter - delegate to specific Conversion module based on format

=head1 DESCRIPTION

Delegate to a specific Conversion class based on format.

For instance to create a Palm::Progect::Converter::Text conversion object,
the user can do the following:

    my $converter = Palm::Progect::Converter->new(
        format => 'Text',
        # ... other args ...
    );

Behind the scenes, this call will be translated into the equivalent of:

    require 'Palm/Progect/Converter/Text.pm';
    my $record = Palm::Progect::Converter::Text->new(
        # ... other args ...
    );


See also the individual converter objects.

=cut

use CLASS;
use base 'Class::Accessor';

my @Accessors = qw(
    records
    prefs
    quiet
);

CLASS->mk_accessors(@Accessors);

# Delegate to Palm::Progect::Converter::CSV, Palm::Progect::Converter::HTML, etc.

sub new {
    my $proto      = shift;
    my $this_class = ref $proto || $proto;

    my @base_class  = split /::/, $this_class; # e.g. ('Palm', 'Progect', 'Converter')

    my %args = @_;

    my $converter_format = delete $args{'format'};

    my $module_path  = File::Spec->join(@base_class, $converter_format . '.pm');
    my $module_class = join '::', @base_class, $converter_format;

    require $module_path;

    # Initialize the object with the standard Converter accessors

    my %auto_init;
    foreach my $accessor (@Accessors) {
        $auto_init{$accessor} = delete $args{$accessor};
    }
    my $converter = $module_class->new(%args);

    foreach my $accessor (@Accessors) {
        $converter->$accessor($auto_init{$accessor});
    }
    return $converter;
}

1;

__END__

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut

