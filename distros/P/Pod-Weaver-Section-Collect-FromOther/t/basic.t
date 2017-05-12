use strict;
use warnings;

use Test::More 0.88;
use Test::Differences;

use FindBin;
use PPI;
use Pod::Weaver;
use Pod::Elemental;

my $weaver = Pod::Weaver->new_from_config({
    root => $FindBin::Bin,
});

sub woven_ok {
    my ($comment, $string) = @_;
    my ($input, $want) = split /^-{10,}$/m, $string;
    $want =~ s/\A\n//; # stupid

    local @INC = ('t', @INC);

    #$input = "=pod\n\n$input";
    #$want  = "=pod\n\n$want\n=cut\n";
    my $doc = Pod::Elemental->read_string($input);

    my $woven = $weaver->weave_document({
        pod_document => $doc,
    });

    eq_or_diff($woven->as_pod_string, $want, $comment);
}

woven_ok section => <<'END_POD';
=from_other TestClass / SIMPLE SECTION
--------------------------------------
=pod

=cut
END_POD

woven_ok section_with_all => <<'END_POD';
=from_other TestClass / SIMPLE SECTION / all
--------------------------------------
=pod

Something, something

=cut
END_POD

woven_ok section_and_command => <<'END_POD';
=from_other TestClass / SECTION AND COMMAND
--------------------------------------
=pod

=head2 woo!

yada, yada

=cut
END_POD

woven_ok section_and_command_with_all => <<'END_POD';
=from_other TestClass / SECTION AND COMMAND / all
--------------------------------------
=pod

Something, something

=head2 woo!

yada, yada

=cut
END_POD

woven_ok last_section => <<'END_POD';
=from_other TestClass / LAST SECTION / all
--------------------------------------
=pod

Yay!

=cut
END_POD

woven_ok list_section => <<'END_POD';
=from_other TestClass / LIST
--------------------------------------
=pod

=head2 Bla

Whee

=head2 BlaBla

=cut
END_POD

done_testing;
