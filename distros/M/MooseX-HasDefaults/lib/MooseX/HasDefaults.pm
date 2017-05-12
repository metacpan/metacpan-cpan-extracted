package MooseX::HasDefaults;
our $VERSION = '0.03';

die "Do not use MooseX::HasDefaults, use MooseX::HasDefaults::RO or MooseX::HasDefaults::RW";

"Screw you Perl, I want to return a true value just to spite you even though it's a load failure. Can we PLEASE get rid of the required module return value? Require modules to die instead, like I just did. SIGH!";

__END__

=head1 NAME

MooseX::HasDefaults - default "is" to "ro" or "rw" for all attributes

=head1 SYNOPSIS

    package Person;
    use Moose;
    use MooseX::HasDefaults::RO;

    has name => (
        isa => 'Str',
    );

    has age => (
        is  => 'rw',
        isa => 'Int',
        documentation => "Changes most years",
    );

=head1 DESCRIPTION

The module L<MooseX::HasDefaults::RO> defaults C<is> to C<ro>.

The module L<MooseX::HasDefaults::RW> defaults C<is> to C<rw>.

If you pass a specific value to any C<has>'s C<is>, that overrides the default. If you do not want an accessor, pass C<< is => undef >>.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 SEE ALSO

=over 4

=item L<MooseX::AttributeDefaults>

This requires its users to be MOP savvy, and is a bit too much typing for
the common case of defaulting C<is>.

=item L<MooseX::Attributes::Curried>

This solves a similar need by letting users create sugar functions. But
people like C<has>.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

