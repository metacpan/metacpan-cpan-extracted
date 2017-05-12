package Parley::App::I18N;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use Perl6::Export::Attrs;

sub first_valid_locale :Export( :locale ) {
    my ($c, $path_parts) = @_;

    $c->log->debug(
          'first_valid_locale language list: '
        . "@{$c->languages}"
    )
    if $ENV{CATALYST_DEBUG};

    foreach my $lang ( @{$c->languages} ) {
        if (-d $c->path_to( 'root', @{$path_parts}, $lang) ) {
            $c->log->info(
                'Apparently this exists: ',
                $c->path_to( 'root', @{$path_parts}, $lang)
            );
            return $lang;
        }
    }

    # default to a generic english variant
    return 'i_default';
}

1;

__END__

=head1 NAME

Parley::App::I18N - i18n helper functions

=head1 SYNOPSIS

  use Parley::App::I18N qw( :locale );

  first_valid_locale($c, [qw/path parts/]);

=head1 SEE ALSO

L<Parley::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
