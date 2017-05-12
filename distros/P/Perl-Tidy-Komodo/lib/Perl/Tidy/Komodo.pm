use strictures;

package Perl::Tidy::Komodo;

our $VERSION = '1.151340'; # VERSION

# ABSTRACT: tidy perl files in Komodo with a project rc

#
# This file is part of Perl-Tidy-Komodo
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

use Perl::Tidy;
use File::chdir;


sub run {
    _try_set_perltidy_env();
    Perl::Tidy::perltidy();
}

sub _try_set_perltidy_env {
    return if exists $ENV{PERLTIDY};
    my @cwd_store = @CWD;
    while ( $CWD[0] ) {
        if ( -d 'lib' and -f '.perltidyrc' ) {
            $ENV{PERLTIDY} = $CWD;
            last;
        }
        pop @CWD;
    }
    @CWD = @cwd_store;
    return;
}

1;

__END__

=pod

=head1 NAME

Perl::Tidy::Komodo - tidy perl files in Komodo with a project rc

=head1 VERSION

version 1.151340

=head1 DESCRIPTION

This file provides the functionality behind a command line script. For
usage documentation, please see: L<perltidy_ko>.

=head1 METHODS

=head2 run

Tries to find a directory that looks like a project directory, upwards
from CWD and stores its path in $ENV{PERLTIDY}. Then Perl::Tidy itself is
run.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Tidy-Komodo>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/perl-tidy-komodo>

  git clone https://github.com/wchristian/perl-tidy-komodo.git

=head1 AUTHOR

Christian Walde <walde.christian@googlemail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
