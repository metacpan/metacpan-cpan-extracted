package Print::Indented;
use 5.008005;
use strict;
use warnings;
use Print::Indented::Handle;

our $VERSION = '0.01';

sub import {
    my $class = shift;

    my ($pkg) = caller;
    undef $pkg if $pkg eq 'main';
    undef $pkg if grep /^:all$/, @_;

    our $STDOUT ||= Print::Indented::Handle->new(\*STDOUT);
    our $STDERR ||= Print::Indented::Handle->new(\*STDERR);

    my $pkg_re = defined $pkg ? qr/^\Q$pkg\E$/ : qr//;
    $_->add_package_re($pkg_re) for $STDOUT, $STDERR;
}

1;

__END__

=encoding utf-8

=head1 NAME

Print::Indented - Indent outputs indented as per source code indentation

=head1 SYNOPSIS

    use Print::Indented;

    print "foo\n"; # prints "foo"

    {
        print "bar\n"; # prints "    bar";
    }

=head1 DESCRIPTION

Print::Indented indents stdout/stderr outputs according to the source line indentation
where print function called, ex. C<< print >>, C<< warn >>.

=head1 LICENSE

Copyright (C) motemen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=cut

