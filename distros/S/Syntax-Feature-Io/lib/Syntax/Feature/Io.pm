use strictures 1;

# ABSTRACT: Provides IO::All

package Syntax::Feature::Io;
BEGIN {
  $Syntax::Feature::Io::VERSION = '0.001';
}
BEGIN {
  $Syntax::Feature::Io::AUTHORITY = 'cpan:PHAYLON';
}

use Params::Classify        0.013   qw( is_ref );
use Carp                            qw( croak );
use Sub::Install            0.925   qw( install_sub );
use IO::All                 0.41    ();
use B::Hooks::EndOfScope    0.09;

use namespace::clean;

$Carp::Internal{ +__PACKAGE__ }++;



sub install {
    my ($class, %args) = @_;
    my $target  = $args{into};
    my $options = $args{options};
    $options = { -import => $options }
        if is_ref $options, 'ARRAY';
    $options = {}
        unless defined $options;
    croak qq{Options for $class have to be in array or hash ref}
        unless is_ref $options, 'HASH';
    $options->{ -import } = []
        unless defined $options->{ -import };
    croak qq{Option -import for $class has to be array ref}
        unless is_ref $options->{ -import }, 'ARRAY';
    my $name = $options->{ -as };
    $name = 'io'
        unless defined $name;
    install_sub {
        into => $target,
        as   => $name,
        code => IO::All
            ->generate_constructor(@{ $options->{ -import } }),
    };
    on_scope_end {
        namespace::clean->clean_subroutines($name);
    };
}


1;



=pod

=head1 NAME

Syntax::Feature::Io - Provides IO::All

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use syntax qw( io );

    my @own_lines = io(__FILE__)->getlines;

=head1 DESCRIPTION

This is a syntax feature extension for L<syntax> providing L<IO::All>.

Not much additional use is provided, besides much easier access if you are
already using L<syntax> in one way or another.

=head1 METHODS

=head2 install

    $class->install( %arguments )

Used by L<syntax> to install the extension in the requesting namespace.
Only the arguments C<into> and C<options> are recognized.

=head1 OPTIONS

=head2 -import

    use syntax io => { -import => [-strict] };

You can use this option to pass import flags to L<IO::All>. Since this is
the option you'll most likely use, if any, you can skip the hash reference
and provide the import list directly if you wish:

    use syntax io => [-strict];

Please see L<IO::All/USAGE> for documentation on the import arguments.

=head2 -as

    use syntax io => { -as => 'IO' };

    my @own_lines = IO(__FILE)->getlines;

Set the name of the import.

=head1 SEE ALSO

=over

=item * L<IO::All>

=item * L<syntax>

=back

=head1 BUGS

Please report any bugs or feature requests to bug-syntax-feature-io@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-Io

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

