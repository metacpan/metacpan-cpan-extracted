package TAP::Parser::SourceHandler::PHP;

use warnings;
use strict;

use TAP::Parser::IteratorFactory   ();
use TAP::Parser::Iterator::Process ();

our @ISA = qw( TAP::Parser::SourceHandler );
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head1 NAME

TAP::Parser::SourceHandler::PHP - Runs PHP programs to get their TAP for prove

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module is a plugin to let you run PHP programs under F<prove>.

  prove --source Perl \
        --source PHP  --php-option include_path=/tmp/foo

=head1 CLASS METHODS

=head2 $handler->can_handle( $source )

Tells whether we should handle the file as a PHP test.

=cut

sub can_handle {
    my ( $class, $source ) = @_;

    my $meta = $source->meta;
    my $config = $source->config_for( 'PHP' );

    return 0 unless $meta->{is_file};

    my $suf = $meta->{file}{lc_ext};

    my $wanted_extension = $config->{extension} || '.php';

    return 1 if $suf eq $wanted_extension;

    return 0;
}

=head2 C<make_iterator>

    my $iterator = $class->make_iterator( $source );

Returns a new iterator for the source. C<< $source->raw >> must be either
a file name or a scalar reference to the file name.

=over

=item include_path

Paths to include for PHP to search for files.

=back

=cut

sub make_iterator {
    my ( $class, $source ) = @_;
    my $config = $source->config_for('PHP');

    my @command = ( $config->{php} || '/usr/local/bin/php' );

    my $include_path = $config->{include_path};
    if ( $include_path ) {
        push( @command, "-dinclude_path=$include_path" );
    }

    my $fn = ref $source->raw ? ${ $source->raw } : $source->raw;
    push( @command, $fn );

    return TAP::Parser::Iterator::Process->new( {
        command => \@command,
        merge   => $source->merge
    });
}

=head1 SEE ALSO

L<TAP::Object>,
L<TAP::Parser>,
L<TAP::Parser::IteratorFactory>,
L<TAP::Parser::SourceHandler>,
L<TAP::Parser::SourceHandler::Executable>,
L<TAP::Parser::SourceHandler::Perl>,
L<TAP::Parser::SourceHandler::File>,
L<TAP::Parser::SourceHandler::Handle>,
L<TAP::Parser::SourceHandler::RawTAP>

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tap-parser-sourcehandler-php at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TAP-Parser-SourceHandler-PHP>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TAP::Parser::SourceHandler::PHP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TAP-Parser-SourceHandler-PHP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TAP-Parser-SourceHandler-PHP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TAP-Parser-SourceHandler-PHP>

=item * Search CPAN

L<http://search.cpan.org/dist/TAP-Parser-SourceHandler-PHP/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to David Wheeler for being able to steal from his pgTAP
SourceHandler.

L<http://www.justatheory.com/computers/programming/perl/tap-parser-sourcehandler.html>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Andy Lester.

This program is released under the Artistic License v2.0.


=cut

1; # End of TAP::Parser::SourceHandler::PHP
