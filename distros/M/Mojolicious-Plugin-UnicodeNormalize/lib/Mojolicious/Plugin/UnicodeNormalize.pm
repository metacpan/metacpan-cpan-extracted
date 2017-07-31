package Mojolicious::Plugin::UnicodeNormalize;
$Mojolicious::Plugin::UnicodeNormalize::VERSION = '1.20170726';
use Mojolicious 7.0;
use Mojo::Base 'Mojolicious::Plugin';
use Unicode::Normalize ();

sub register {
    my ($self, $app, $conf) = @_;

    my $form       = $conf->{form} // 'NFC';
    my $normalizer = Unicode::Normalize->can( $form );

    unless ($normalizer) {
        require Carp;
        Carp::croak( "Invalid normalization form '$form' requested" );
    }

    my $sub = sub {
        my $params = $_[0]->req->params;
        my $pairs  = [
            map { ref( $_ ) ? $_ : $normalizer->( $_ ) } @{ $params->pairs }
        ];

        $params->pairs( $pairs );
    };

    $app->hook( before_dispatch => $sub );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::UnicodeNormalize - normalize incoming Unicode parameters

=head1 SYNOPSIS

    # Mojolicious
    sub startup {
        my $self = shift;
        $self->plugin( 'UnicodeNormalize' );

        ...
    }

    # Mojolicious::Lite
    plugin 'UnicodeNormalize';

    ...

=head1 DESCRIPTION

Mojolicious::Plugin::UnicodeNormalize allows you to normalize all incoming
Unicode parameters to a single normalization form. (For more information on why
Unicode normalization is important, see Tom Christiansen's Unicode cookbook,
especially
L<http://www.perl.com/pub/2012/05/perlunicookbook-unicode-normalization.html>.)

This plugin sets up a normalization hook to run before Mojolicious dispatch. It
will normalize all non-reference parameters. By default, this uses Unicode
Normalization Form C, which is almost always what you want. You may specify
another form when you register the plugin:

    # Mojolicious
    sub startup {
        my $self = shift;
        $self->plugin( 'UnicodeNormalize', { form => 'NFD' } );

        ...
    }

Any normalization form supported by L<Unicode::Normalize> is valid; currently
this list is:

=over 4

=item * NFC (the default)

=item * NFD

=item * NFKC

=item * NFKD

=back

Unless you know why you might use an alternate form, use the default of NFC.

=head1 AUTHOR

chromatic E<lt>chromatic@cpan.orgE<gt>.

=head1 SEE ALSO

L<Mojolicious>, L<Unicode::Normalize>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License, version 2 (the same terms as Perl 5.26
itself).
