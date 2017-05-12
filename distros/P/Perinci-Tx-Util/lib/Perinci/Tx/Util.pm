package Perinci::Tx::Util;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Util qw(err);
use UUID::Random;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       use_other_actions
               );

our $VERSION = '0.39'; # VERSION

sub use_other_actions {
    my %args = @_;
    my $actions = $args{actions};

    no strict 'refs';

    my ($has_unfixable, $has_fixable, $has_error);
    my (@do, @undo);
    my ($res, $a);
    my $i = 0;
    for (@$actions) {
        $a = $_;
        my $f = $a->[0];
        my ($pkg) = $a->[0] =~ /(.+)::.+/;
        $pkg or
            return [400, "action #$i: please supply qualified function name"];

        $res = $f->(%{$a->[1]},
                    -tx_action=>'check_state',
                    -tx_v=>2,
                    # it's okay to use random here, when tm records undo data it
                    # will record by calling actions in do_actions directly, not
                    # using our undo data
                    -tx_action_id=>UUID::Random::generate(),
                );
        if ($res->[0] == 200) {
            $has_fixable++;
            push @do, $a;
            my $uu = $res->[3]{undo_actions};
            for my $u (@$uu) {
                $u->[0] = "$pkg\::$u->[0]" unless $u->[0] =~ /::/;
            }
            unshift @undo, @$uu;
        } elsif ($res->[0] == 304) {
            # fixed
        } elsif ($res->[0] == 412) {
            $has_unfixable++;
            last;
        } else {
            $has_error++;
            last;
        }
        $i++;
    }

    if ($has_error) {
        err(500, "There is an error: action #$i: ", $res);
    } elsif ($has_unfixable) {
        err(412, "There is an unfixable state: action #$i: ", $res);
    } elsif ($has_fixable) {
        [200, "Some action needs to be done", undef, {
            do_actions => \@do,
            undo_actions => \@undo,
        }];
    } else {
        [304, "No action needed"];
    }
}

1;
# ABSTRACT: Helper when writing transactional functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Tx::Util - Helper when writing transactional functions

=head1 VERSION

This document describes version 0.39 of Perinci::Tx::Util (from Perl distribution Perinci-Tx-Util), released on 2015-09-04.

=head1 SYNOPSIS

 use Perinci::Tx::Util qw(use_other_actions);

 sub foo {
     my %args = @_;
     use_other_actions(actions => [
         ["My::action1", {arg=>1}],
         ["My::action2", {arg=>2}],
         # ...
     ]);
 }

=head1 FUNCTIONS

=head2 use_other_actions(actions=>$actions) => RES

Generate envelope response for transactional function. Can be used to say that
function entirely depends on other actions.

Each action in C<$actions> will be called with C<< -tx_action => 'check_state'
>>. If all actions return 304, response status will be 304. If some or all
actions return 200 and the rest 304, response status will be 200 with
C<undo_actions> result metadata taken from the actions' metadata and
C<do_actions> from C<$actions>. If any action returns 412, response will be 412.
If any action return other status, response will be 500 (error).

It is your responsibility to load required modules.

Does not perform checking on actions like L<Perinci::Tx::Manager>, but
eventually actions will be checked by Perinci::Tx::Manager anyway.

=head1 SEE ALSO

L<Perinci::Util>

L<Perinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Tx-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Tx-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Tx-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
