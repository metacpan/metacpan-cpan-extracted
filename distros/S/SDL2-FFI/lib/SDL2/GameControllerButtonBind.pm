package SDL2::GameControllerButtonBind {

    package SDL2::GameControllerButtonBind_Hat {
        use SDL2::Utils;
        has hat => 'int', hat_mask => 'int';
    };
    use SDL2::Utils;
    has
        button => 'int',
        axis   => 'int',
        hat    => 'opaque';    # GameControllerButtonBind_Hat

=encoding utf-8

=head1 NAME

SDL2::GameControllerButtonBind - SDL joystick layer binding

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

Get the SDL joystick layer binding for this controller button/axis mapping.

=head1 Fields

=over

=item C<button>

=item C<axis>

=item C<hat>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
