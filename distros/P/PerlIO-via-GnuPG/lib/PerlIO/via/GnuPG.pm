#
# This file is part of PerlIO-via-GnuPG
#
# This software is Copyright (c) 2013 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package PerlIO::via::GnuPG;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.005-1-gdb3e32f
$PerlIO::via::GnuPG::VERSION = '0.006';

# ABSTRACT: Layer to try to decrypt on read

# required for how we're registering a warnings category
use v5.14;

use strict;
use warnings::register qw{ unencrypted };
#use warnings::register;
use warnings;

use autodie 2.25;

use IPC::Open3 'open3';
use Symbol 'gensym';
use List::AllUtils 'part';

# gpg --decrypt -q --status-file aksdja --no-tty
# gpg --decrypt -q --status-file aksdja --no-tty .pause.gpg

sub PUSHED {
    my ($class, $mode) = @_;

    return bless { }, $class;
}

sub _passthrough_unencrypted { 0 }

sub FILL {
    my ($self, $fh) = @_;

    return shift @{ $self->{buffer} }
        if exists $self->{buffer};

    ### pull in all of fh and try to decrypt it...
    my $maybe_encrypted = do { local $/; <$fh> };

    ### $maybe_encrypted
    my ($in, $out, $error) = (gensym, gensym, gensym);
    my $run = 'gpg -qd --no-tty --command-fd 0';
    my $pid = open3($in, $out, $error, $run);

    ### $pid
    print $in $maybe_encrypted;
    close $in;
    my @output = <$out>;
    my @errors = <$error>;

    waitpid $pid, 0;

    ### @output
    ### @errors

    ### filter warnings out...
    chomp @errors;
    my ($errors, $warnings) = map { $_ || [] } part { /WARNING:/ ? 1 : 0 } @errors;

    ### $warnings
    warnings::warnif(@$warnings)
        if !!$warnings && @$warnings;

    if (!!$errors && @$errors) {

        my $not_encrypted = scalar grep { /no valid OpenPGP data found/ } @$errors;

        ### $not_encrypted
        ### passthrough: $self->_passthrough_unencrypted
        if ($not_encrypted) {

            if ($self->_passthrough_unencrypted) {
                warnings::warnif(
                    'PerlIO::via::GnuPG::unencrypted',
                    'File does not appear to be encrypted!',
                );
                @output = ($maybe_encrypted);
            }
            else {
                die "File does not appear to be encrypted!";
            }
        }
        else {

            # "@errors" here is intentional -- show the warnings, too
            die "Errors while attempting decryption: @errors";
        }
    }

    $self->{buffer} = [ @output ];
    return shift @{ $self->{buffer} };
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl decrypt

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

PerlIO::via::GnuPG - Layer to try to decrypt on read

=head1 VERSION

This document describes version 0.006 of PerlIO::via::GnuPG - released August 10, 2015 as part of PerlIO-via-GnuPG.

=head1 SYNOPSIS

    use PerlIO::via::GnuPG;

    # dies on error, and if the file is not encrypted
    open(my $fh, '<:via(GnuPG)', 'secret.txt.asc')
        or die "cannot open! $!";

    my @in = <$fh>; # or whatever...

=head1 DESCRIPTION

This is a L<PerlIO> module to decrypt files transparently.  It's pretty
simple and does not support writing, but works.

...and if it doesn't, please file an issue :)

=for Pod::Coverage FILL PUSHED

=head1 CUSTOM WARNING CATEGORIES

This package emits warnings from time to time.  To disable warnings generated
when passing through unencrypted data:

    no warnings 'PerlIO::via::GnuPG::unencrypted';

Likewise, to disable all warnings issued by this package:

    no warnings 'PerlIO::via::GnuPG';

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PerlIO::via::GnuPG::Maybe|PerlIO::via::GnuPG::Maybe>

=item *

L<PerlIO|PerlIO>

=item *

L<PerlIO::via|PerlIO::via>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/perlio-via-gnupg/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fperlio-via-gnupg&title=RsrchBoy's%20CPAN%20PerlIO-via-GnuPG&tags=%22RsrchBoy's%20PerlIO-via-GnuPG%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fperlio-via-gnupg&title=RsrchBoy's%20CPAN%20PerlIO-via-GnuPG&tags=%22RsrchBoy's%20PerlIO-via-GnuPG%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
