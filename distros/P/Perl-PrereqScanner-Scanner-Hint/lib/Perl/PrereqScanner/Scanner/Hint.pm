#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Perl/PrereqScanner/Scanner/Hint.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Perl-PrereqScanner-Scanner-Hint.
#
#   perl-Perl-PrereqScanner-Scanner-Hint is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Perl-PrereqScanner-Scanner-Hint is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Perl-PrereqScanner-Scanner-Hint. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Perl::PrereqScanner::Scanner::Hint> module documentation. Read this if you are going to hack or
#pod extend C<Manifest::Write>.
#pod
#pod =for :those If you want to specify implicit prerequisites directly in Perl code, read the L<user manual|Perl::PrereqScanner::Scanner::Hint::Manual>.
#pod General topics like getting source, building, installing, bug reporting and some others are covered
#pod in the F<README>.
#pod
#pod =for test_synopsis my $path;
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Perl::PrereqScanner;
#pod     my $scanner = Perl::PrereqScanner->new( {
#pod         extra_scanners => [ qw{ Hint } ],
#pod     } );
#pod     my $prereqs = $scanner->scan_file( $path );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a trivial scanner which utilizes power of C<Perl::PrereqScanner> and C<PPI>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod *   L<Perl::PrereqScanner>
#pod *   L<PPI>
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Perl::PrereqScanner::Scanner::Hint;

use Moose;
use namespace::autoclean;
use version 0.77;
use warnings::register;

# ABSTRACT: Plugin for C<Perl::PrereqScanner> looking for C<## REQUIRE:> comments
our $VERSION = 'v0.1.1'; # VERSION

use Module::Runtime qw{ is_module_name };
use Try::Tiny;

with 'Perl::PrereqScanner::Scanner';

# --------------------------------------------------------------------------------------------------

my $error = sub {
    my ( $self, $what, $elem ) = @_;
    my $line = $elem->logical_line_number;
    my $file = $elem->logical_filename || '(*UNKNOWN*)';
    die "$what at $file line $line.\n";
};

my $warning = sub {
    my ( $self, $what, $elem ) = @_;
    my $line = $elem->logical_line_number;
    my $file = $elem->logical_filename || '(*UNKNOWN*)';
    warnings::warnif( $self, "$what at $file line $line.\n" );
};

# --------------------------------------------------------------------------------------------------

#pod =method scan_for_prereqs
#pod
#pod     my $doc = PPI::Document->new( ... );
#pod     my $req = CPAN::Meta::Requirements->new;
#pod     $self->scan_for_prereqs( $doc, $req );
#pod
#pod The method scans document C<$doc>, which is expected to be an objects of C<PPI::Document> class.
#pod The methods looks for comments starting with C<# REQUIRE:>, and adds found requirements to C<$req>,
#pod by calling C<< $req->add_string+requirement >>. C<$req> is expected to be an object of
#pod C<CPAN::Meta::Requirements> class.
#pod
#pod =cut

sub scan_for_prereqs {
    my ( $self, $doc, $req ) = @_;
    my $comments = $doc->find( 'Token::Comment' ) || [];
    for my $comment ( @$comments ) {
        if ( $comment->content =~ m{ ^ \h* (\#{1,2}) \h* REQUIRES? \h* : \h* (.*) \h* $ }x ) {
            my ( $hashes, $requirement ) = ( $1, $2 );
            if ( length( $hashes ) == 1 ) {
                $self->$warning(
                    "Starting a hint with one hash is deprecated, use two hashes instead",
                    $comment
                );
            };
            $requirement =~ s{ \h* \# .* \z }{}x;  # Strip trailing comment, if any.
            my ( $mod, $ver ) = ( split( m{\h+}x, $requirement, 2 ), '0' );
            if ( is_module_name( $mod ) ) {
                try {
                    $req->add_string_requirement( $mod, $ver );
                } catch {
                    my $ex = "$_";
                    chomp( $ex );
                    $self->$error( "$ex", $comment );
                };
            } else {
                $self->$error( "'$mod' is not a valid module name", $comment );
            };
        };
    };
    return;
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Perl-PrereqScanner-Scanner-Hint.
#
#   ------------------------------------------------------------------------------------------------

#pod =pod
#pod
#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Perl::PrereqScanner::Scanner::Hint> (or just C<Scanner::Hint> for brevity) is a plugin for C<Perl::PrereqScanner>
#pod tool. C<Scanner::Hint> looks for C<# REQUIRE: I<ModuleName> I<VersionRange>> comments in the code.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::Hint - Plugin for C<Perl::PrereqScanner> looking for C<## REQUIRE:> comments

=head1 VERSION

Version v0.1.1, released on 2016-12-28 20:18 UTC.

=head1 WHAT?

C<Perl::PrereqScanner::Scanner::Hint> (or just C<Scanner::Hint> for brevity) is a plugin for C<Perl::PrereqScanner>
tool. C<Scanner::Hint> looks for C<# REQUIRE: I<ModuleName> I<VersionRange>> comments in the code.

This is C<Perl::PrereqScanner::Scanner::Hint> module documentation. Read this if you are going to hack or
extend C<Manifest::Write>.

If you want to specify implicit prerequisites directly in Perl code, read the L<user manual|Perl::PrereqScanner::Scanner::Hint::Manual>.
General topics like getting source, building, installing, bug reporting and some others are covered
in the F<README>.

=for test_synopsis my $path;

=head1 SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new( {
        extra_scanners => [ qw{ Hint } ],
    } );
    my $prereqs = $scanner->scan_file( $path );

=head1 DESCRIPTION

This is a trivial scanner which utilizes power of C<Perl::PrereqScanner> and C<PPI>.

=head1 OBJECT METHODS

=head2 scan_for_prereqs

    my $doc = PPI::Document->new( ... );
    my $req = CPAN::Meta::Requirements->new;
    $self->scan_for_prereqs( $doc, $req );

The method scans document C<$doc>, which is expected to be an objects of C<PPI::Document> class.
The methods looks for comments starting with C<# REQUIRE:>, and adds found requirements to C<$req>,
by calling C<< $req->add_string+requirement >>. C<$req> is expected to be an object of
C<CPAN::Meta::Requirements> class.

=head1 SEE ALSO

=over 4

=item *

L<Perl::PrereqScanner>

=item *

L<PPI>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
