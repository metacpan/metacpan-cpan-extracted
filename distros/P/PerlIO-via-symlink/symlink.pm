package PerlIO::via::symlink;
use 5.008;
use warnings;
use strict;
our $VERSION = '0.05';

=head1 NAME

PerlIO::via::symlink - PerlIO layers for create symlinks

=head1 SYNOPSIS

 open $fh, '>:via(symlink)', $fname;
 print $fh "link foobar";
 close $fh;

=head1 DESCRIPTION

The PerlIO layer C<symlink> allows you to create a symbolic link by
writing to the file handle.

You need to write C"link $name" to the file handle. If the format does
not match, C<close> will fail with EINVAL.

=cut

use Errno qw(EINVAL ENOENT);
use Symbol qw(gensym);

sub PUSHED {
    $! = EINVAL, return -1
	unless $_[1] eq 'w' || $_[1] eq 'r';
    my $self = bless gensym(), $_[0];
    *$self->{mode} = $_[1];
    return $self;
}

sub OPEN {
    my ($self, $fname) = @_;
    *$self->{fname} = $fname;
    return 1 if *$self->{mode} eq 'w';
    lstat ($fname) or return -1;
    $! = EINVAL, return -1 unless -l $fname;
    *$self->{content} = 'link '.readlink ($fname);
    return 1;
}

sub WRITE {
    my ($self, $buf) = @_;
    *$self->{content} .= $buf;
    return length($buf);
}

sub FILL {
    my ($self) = @_;
    return if *$self->{filled};
    ++*$self->{filled};
    return *$self->{content};
}

sub SEEK {
    my ($self) = @_;
    delete *$self->{filled};
}

sub CLOSE {
    my ($link, $fname, $mode) = @{*{$_[0]}}{qw/content fname mode/};
    return 0 if $mode eq 'r';
    $link =~ s/^link // or $! = EINVAL, return -1;
    symlink $link, $fname or return -1;
    return 0;
}

=head1 TEST COVERAGE

 ----------------------------------- ------ ------ ------ ------ ------ ------
 File                                  stmt branch   cond    sub   time  total
 ----------------------------------- ------ ------ ------ ------ ------ ------
 blib/lib/PerlIO/via/symlink.pm       100.0  100.0    n/a  100.0  100.0  100.0
 Total                                100.0  100.0    n/a  100.0  100.0  100.0
 ----------------------------------- ------ ------ ------ ------ ------ ------

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2005 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
