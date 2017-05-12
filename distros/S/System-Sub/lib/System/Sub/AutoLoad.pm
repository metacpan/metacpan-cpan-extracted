use strict;
use warnings;
package System::Sub::AutoLoad;
$System::Sub::AutoLoad::VERSION = '0.162800';
use System::Sub ();

sub _croak
{
    require Carp;
    goto &Carp::croak
}

# Storage for sub options until they are installed with the AUTOLOAD
my %AutoLoad;

sub import
{
    my $pkg = caller;
    shift;

    while (@_) {
        my $name = shift;
        _croak "invalid arg: SCALAR expected" unless defined ref $name && ! ref $name;
        my $fq_name = $pkg.'::'.$name;

        $AutoLoad{$fq_name} = shift if @_ && ref $_[0];

        # Create a forward declaration that will be usable by the Perl
        # parser. See subs.pm
        no strict 'refs';
        *{$fq_name} = \&{$fq_name};
    }

    # Install the AUTOLOAD sub
    no strict 'refs';
    *{$pkg.'::AUTOLOAD'} = \&_AUTOLOAD;
}

sub _AUTOLOAD
{
    my $fq_name = our $AUTOLOAD;

    my $options = delete $AutoLoad{$fq_name};
    System::Sub->import($fq_name, $options ? ($options) : ());

    no strict 'refs';
    goto &$fq_name
}

1;
__END__

=head1 NAME

System::Sub::AutoLoad - Auto-wrap external commands as DWIM subs

=head1 VERSION

version 0.162800

=head1 SYNOPSIS

=head2 Basic usage

Any unknown sub will become a C<L<System::Sub>>.

    use System::Sub::AutoLoad;

    my $hostname = hostname();

=head2 Usage with forward declaration

Allows to avoid using parentheses. C<L<System::Sub>> import stays lazy.

    use System::Sub::AutoLoad qw(hostname);

    my $hostname = hostname;

=head2 Usage with forward declaration command options

Options definitions will be checked lazily at the first call to the AUTOLOAD
for that sub.

    use System::Sub::AutoLoad hostname => [ 0 => '/bin/hostname' ];

    my $hostname = hostname;

=head1 DESCRIPTION

Any unknown sub in your code will be transformed into a C<L<System::Sub>> at its
first call. This is L<lazy|http://en.wikipedia.org/wiki/Lazy_evaluation> import
for C<L<System::Sub>>.

To avoid using parentheses after the sub name, you usually have to predeclare
the sub with either a forward declaration (a sub without body such as
C<sub foo;>) or with the C<L<subs|subs>> module. With C<L<Sytem::Sub::AutoLoad>>
you can simply list the subs names on the C<use> line and that will be done
for you.

You can also pass C<L<System::Sub>> options to the sub, but they will be lazily
analysed: this is the full C<L<System::Sub>> power, but with lazy import.

=head2 Implementation details

This module exports an L<AUTOLOAD|perlsub/Autoloading> sub that will import
the sub with C<L<System::Sub>> at its first call.

=head1 AUTHOR

Olivier MenguE<eacute>, C<dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2012 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut

# vim:set et sw=4 sts=4:
