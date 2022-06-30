package Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_rwxRWX;

use 5.006001;
use strict;
use warnings;

use Readonly;

use version;

use base 'Perl::Critic::Policy';

use Perl::Critic::Utils qw{ :severities :classification :ppi :booleans
                            :language hashify };
use PPI;
use PPI::Document;

our $VERSION = '0.002';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use of file access test %s};
Readonly::Scalar my $EXPL =>
q{File access test results may not reflect actual accessability};

Readonly::Hash   my %FILE_ACCESS    => hashify( qw{ -r -w -x -R -W -X } );

#-----------------------------------------------------------------------------

sub supported_parameters { return () }

sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw( bugs trw )             }
sub applies_to           { return 'PPI::Token::Operator'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem ) = @_;

    $elem
        or return;

    $FILE_ACCESS{ $elem->content() }
        or return;

    return $self->violation(
        sprintf( $DESC, $elem->content() ),
        $EXPL,
        $elem,
    );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords builtins

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_rwxRWX - Prohibit file access tests.

=head1 AFFILIATION

This Policy is stand-alone, and is not part of the core
L<Perl::Critic|Perl::Critic>.

=head1 DESCRIPTION

This policy prohibits the file access tests C<-r>, C<-w>, C<-x>, C<-R>, C<-W>,
and C<-X>. All these do by default is to check the file's access control bits.
Access to a file can succeed or fail for other reasons such as the presence of
Access Control Lists (ACLs), a file system being mounted read-only, or an
executable being corrupt.

This policy is under the "bugs" theme, with low severity.

=head1 CONFIGURATION

This Policy has no configuration options.

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f|Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f>

L<https://blogs.perl.org/users/tom_wyant/2022/06/the-file-access-operators-to-use-or-not-to-use.html>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-ValuesAndExpressions-ProhibitFiletest_rwxRWX>,
L<https://github.com/trwyant/perl-Perl-Critic-Policy-ValuesAndExpressions-ProhibitFiletest_rwxRWX/issues>,
or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>.

=head1 COPYRIGHT

Copyright 2022 Thomas R. Wyant, III.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
