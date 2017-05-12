package SHARYANTO::Hash::Util;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.77'; # VERSION

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(rename_key replace_hash_content);

sub rename_key {
    my ($h, $okey, $nkey) = @_;
    die unless    exists $h->{$okey};
    die if        exists $h->{$nkey};
    $h->{$nkey} = delete $h->{$okey};
}

sub replace_hash_content {
    my $hashref = shift;
    %$hashref = @_;
    $hashref;
}

1;
# ABSTRACT: Hash utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::Hash::Util - Hash utilities

=head1 VERSION

This document describes version 0.77 of SHARYANTO::Hash::Util (from Perl distribution SHARYANTO-Utils), released on 2015-09-04.

=head1 SYNOPSIS

 use SHARYANTO::Hash::Util qw(rename_key);
 my %h = (a=>1, b=>2);
 rename_key(\%h, "a", "alpha"); # %h = (alpha=>1, b=>2)

=head1 FUNCTIONS

=head2 rename_key(\%hash, $old_key, $new_key)

Rename key. This is basically C<< $hash{$new_key} = delete $hash{$old_key} >>
with a couple of additional checks. It is a shortcut for:

 die unless exists $hash{$old_key};
 die if     exists $hash{$new_key};
 $hash{$new_key} = delete $hash{$old_key};

=head2 replace_hash_content($hashref, @pairs) => $hashref

Replace content in <$hashref> with @list. Return C<$hashref>. Do not create a
new hashref object (i.e. it is different from: C<< $hashref = {new=>"content"}
>>).

Do not use this function. In Perl you can just use: C<< %$hashref = @pairs >>. I
put the function here for reminder.

=head1 SEE ALSO

L<SHARYANTO>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-Utils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Utils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-Utils>

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
