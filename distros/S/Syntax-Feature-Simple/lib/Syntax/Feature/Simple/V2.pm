use strictures 1;

# ABSTRACT: Version 2 of bundled syntax enhancements

package Syntax::Feature::Simple::V2;
{
  $Syntax::Feature::Simple::V2::VERSION = '0.002';
}
BEGIN {
  $Syntax::Feature::Simple::V2::AUTHORITY = 'cpan:PHAYLON';
}

use parent 'Syntax::Feature::Simple::V1';
use syntax qw( method );

method _available_extensions {
    return qw(
        function_keyword
        moose_param_role_method_sugar
        method_keyword
        modifier_sugar
        moose_param_role_body_sugar
    );
}

method _can_setup_moose_param_role_body_sugar_ext ($class: $target) {
    $class->_check_is_moose_param_role($target)
}

method _can_setup_method_keyword_ext ($class: $target) {
    not $class->_check_is_moose_param_role($target)
}

1;



=pod

=head1 NAME

Syntax::Feature::Simple::V2 - Version 2 of bundled syntax enhancements

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use syntax qw( simple/v2 );

=head1 DESCRIPTION

This is the second version of the syntax dispatcher. It will setup a function
and a method keyword in all cases, and a set of method modifiers if any kind
of L<Moose> metaclass was detected. For roles parameterized with
L<MooseX::Role::Parameterized> it will also setup a C<role> keyword for the
body.

=head1 SEE ALSO

=over

=item L<Syntax::Feature::Simple>

Main feature documentation.

=back

=head1 BUGS

Please report any bugs or feature requests to bug-syntax-feature-simple@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-Simple

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

