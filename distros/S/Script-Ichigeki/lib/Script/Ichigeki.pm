package Script::Ichigeki;
use 5.008_001;
use strict;
use warnings;
our $VERSION = '0.04';

use Script::Ichigeki::Hissatsu;

sub import {
    my $pkg = shift;
    $pkg->hissatsu(@_, in_compilation => 1);
}

{
    my $_HISSATSU;
    sub hissatsu {
        die "Already running!\n" if $_HISSATSU;
        my $pkg = shift;

        $_HISSATSU = Script::Ichigeki::Hissatsu->new(@_);
        $_HISSATSU->execute;
    }

    END {
        undef $_HISSATSU;
    }
}

1;
__END__

=head1 NAME

Script::Ichigeki - Perl extension for one time script.

=head1 VERSION

This document describes Script::Ichigeki version 0.04.

=head1 SYNOPSIS

    use Script::Ichigeki;

It is same as

    use Script::Ichigeki (
        exec_date       => 'XXXX-XX-XX', # today
        confirm_dialog  => 1,
        dialog_message  => 'Do you really execute `%s` ?',
    );

or

    use Script::Ichigeki ();
    Script::Ichigeki->hissatsu(
        exec_date       => 'XXXX-XX-XX', # today
        confirm_dialog  => 1,
        dialog_message  => 'Do you really execute `%s` ?',
    );

=head1 DESCRIPTION

Script::Ichigeki is the module for one time script for mission critical
(especially for preventing rerunning it).

Only describing `use Script::Ichigeki`, confirm dialog is displayed and execution result
is saved in log file automatically. This log file double with lock file for mutual exclusion
and preventing rerunning.

=head1 CAUTION

THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.

If forking in your script, the software may not be properly handling it.

=head1 INTERFACE

=head2 Functions

=head3 C<< hissatsu(%options) >>

Automatically called in use phase.

Available options are:

=head4 C<< exec_date => 'Str|Time::Piece' >>

Date for execution date. Format is '%Y-%m-%d'.

=head4 C<< confirm_dialog => 'Bool' >>

Confirm dialog is to be displayed or not.
default: 1

=head4 C<< dialog_message => 'Str' >>

Message of confirm dialog.
Script name is expanded to '%s'.
If using multibyte strings, you should C<$ use utf8;> before C<$ use Script::Ichigeki>.
default: 'Do you really execute `%s` ?',

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
